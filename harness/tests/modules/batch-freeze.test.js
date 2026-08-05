// MES 批次冻结/解冻状态机测试
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败: ' + r.message);
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const r = await fetch(BASE + path, opts);
  return r.json();
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();
  console.log('\n=== 批次冻结/解冻 ===');

  // 0. 动态获取真实物料和仓库 ID
  const matList = await api('GET', '/mes/basic/material/list?pageNo=1&pageSize=5');
  let matId = matList.result?.records?.[0]?.id || '';
  let whId = '';

  // 物料不存在则先创建一个
  if (!matId) {
    const matCode = 'MAT_BF_' + TS;
    const matAdd = await api('POST', '/mes/basic/material/add', {
      code: matCode, name: '批次冻结测试料', type: '1', status: 1
    });
    if (matAdd.code === 200) {
      const matDoc = await api('GET', '/mes/basic/material/list?pageNo=1&pageSize=10');
      matId = matDoc.result?.records?.find(x => x.code === matCode)?.id || '';
    }
  }
  ass(matId !== '', '0a 获取/创建物料ID: ' + matId);

  // 获取仓库
  const whList = await api('GET', '/mes/basic/warehouse/list?pageNo=1&pageSize=5');
  whId = whList.result?.records?.[0]?.id || '';
  ass(whId !== '', '0b 获取仓库ID: ' + whId);

  if (!matId || !whId) {
    console.log('⚠ 缺少基础数据，跳过测试');
    return;
  }

  // 1. 创建批次
  const r0 = await api('POST', '/mes/batch/master/add', {
    materialId: matId,
    batchNo: 'FREEZE-' + TS,
    warehouseId: whId,
    qty: 50,
    productionDate: '2026-07-01'
  });
  ass(r0.code === 200, '1. 创建批次: ' + r0.message);

  // 取批次 ID
  const list = await api('GET', '/mes/batch/master/list?pageNo=1&pageSize=20');
  const batch = list.result?.records?.find(x => x.batchNo === 'FREEZE-' + TS);
  const bid = batch?.id || '';
  ass(bid !== '', '1b 获取批次ID: ' + bid);

  if (!bid) {
    console.log('⚠ 未找到批次，跳过冻结测试');
    return;
  }

  console.log('   批次ID: ' + bid + ' 状态: ' + batch?.status);

  // 2. freeze 冻结
  const frz = await api('PUT', '/mes/batch/master/freeze?id=' + bid);
  ass(frz.code === 200, '2. freeze 冻结: ' + frz.message);

  // 3. 冻结后状态验证
  const frzGet = await api('GET', '/mes/batch/master/queryById?id=' + bid);
  if (frzGet.code === 200) {
    ass(frzGet.result?.status === 'frozen', '3. 冻结后 status=frozen: ' + frzGet.result?.status);
  }

  // 4. unfreeze 解冻
  const ufrz = await api('PUT', '/mes/batch/master/unfreeze?id=' + bid);
  ass(ufrz.code === 200, '4. unfreeze 解冻: ' + ufrz.message);

  // 5. 解冻后状态
  const ufrzGet = await api('GET', '/mes/batch/master/queryById?id=' + bid);
  if (ufrzGet.code === 200) {
    ass(ufrzGet.result?.status !== 'frozen', '5. 解冻后 status 非 frozen: ' + ufrzGet.result?.status);
  }

  // 6. 清理
  await api('DELETE', '/mes/batch/master/delete?id=' + bid);
  console.log('✅ 清理完成');

  console.log(process.exitCode ? '❌ 有失败项' : '✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
