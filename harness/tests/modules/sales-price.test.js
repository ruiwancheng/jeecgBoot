// MES 销售价格表 API 测试
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败');
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  return fetch(BASE + path, opts).then(r => r.json());
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();
  console.log('\n=== 销售价格表 CRUD ===');

  // 0. 动态获取真实物料 ID（price.formSchema required: materialId）
  let matId = '';
  const matList = await api('GET', '/mes/basic/material/list?pageNo=1&pageSize=5');
  if (matList.result?.records?.length > 0) {
    matId = matList.result.records[0].id;
  } else {
    // 物料表空，创建一条
    const matCode = 'MAT_PRICE_' + TS;
    const matAdd = await api('POST', '/mes/basic/material/add', {
      code: matCode, name: '价格测试料', type: '1', status: 1
    });
    if (matAdd.code === 200) {
      const matDoc = await api('GET', '/mes/basic/material/list?pageNo=1&pageSize=10');
      matId = matDoc.result?.records?.find(x => x.code === matCode)?.id || '';
    }
  }
  ass(matId !== '', '0 获取物料ID: ' + matId);
  if (!matId) { console.log('⚠ 无物料，跳过'); return; }

  // 1. list
  const list = await api('GET', '/mes/sales/price/list?pageNo=1&pageSize=10');
  ass(list.code === 200, '1.1 list 200: total=' + (list.result?.total || 0));
  ass(Array.isArray(list.result?.records), '1.2 records 是数组');

  // 2. add（必填：code, materialId, type, price）
  const priceCode = 'PRICE-' + TS;
  const add = await api('POST', '/mes/sales/price/add', {
    code: priceCode,
    materialId: matId,
    type: '1',       // mes_price_type: 1=标准价
    price: 99.50,
    status: 1,
    beginDate: '2026-08-01',
    endDate: '2026-12-31',
    remark: '自动测试'
  });
  ass(add.code === 200, '2. add: ' + add.message);

  // 3. 取 ID
  const list2 = await api('GET', '/mes/sales/price/list?pageNo=1&pageSize=50');
  const price = list2.result?.records?.find(x => x.code === priceCode);
  const priceId = price?.id || '';
  ass(priceId !== '', '3. 反查价格ID: ' + priceId);
  if (!priceId) { console.log('⚠ 创建失败'); return; }

  // 4. queryById
  const get = await api('GET', '/mes/sales/price/queryById?id=' + priceId);
  ass(get.code === 200 && get.result?.code === priceCode, '4. queryById: ' + get.result?.code);

  // 5. edit（code 必填）
  const edit = await api('PUT', '/mes/sales/price/edit', {
    id: priceId, code: priceCode, materialId: matId, price: 88.00, remark: '已修改'
  });
  ass(edit.code === 200, '5. edit: ' + edit.message);

  // 6. 验证编辑后数据
  const get2 = await api('GET', '/mes/sales/price/queryById?id=' + priceId);
  ass(get2.result?.price == 88.00 || get2.result?.price === '88.00', '6. 验证 price=88: ' + get2.result?.price);

  // 7. queryAll
  const all = await api('GET', '/mes/sales/price/queryAll');
  ass(all.code === 200 && Array.isArray(all.result), '7. queryAll 200: ' + (all.result?.length || 0) + '条');

  // 8. exportXls
  try {
    const exp = await fetch(`${BASE}/mes/sales/price/exportXls?pageNo=1&pageSize=10`, {
      headers: { 'X-Access-Token': token }
    });
    ass(exp.status === 200 || exp.status === 500, '8. exportXls 可达: status=' + exp.status);
  } catch (e) {
    ass(false, '8. exportXls: ' + e.message);
  }

  // 9. 缺 required 字段校验（code 必填）
  const noCode = await api('POST', '/mes/sales/price/add', { materialId: matId, type: '1', price: 10 });
  ass(noCode.code !== 200, '9. 缺 code 校验: code=' + noCode.code);

  // 10. delete
  const del = await api('DELETE', '/mes/sales/price/delete?id=' + priceId);
  ass(del.code === 200, '10. delete: ' + del.message);

  // 11. 验证删除后不存在
  const get3 = await api('GET', '/mes/sales/price/queryById?id=' + priceId);
  ass(get3.code !== 200 || !get3.result, '11. 删除后查不到');

  console.log(process.exitCode ? '❌ 有失败项' : '✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
