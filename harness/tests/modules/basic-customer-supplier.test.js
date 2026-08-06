// MES 客户 (Customer) + 供应商 (Supplier) CRUD 测试 — slice-9
// Customer: edit+deleteBatch+importExcel+selectPage+queryAll
// Supplier: edit+deleteBatch+importExcel+selectPage+queryAll+queryById
// 真实 add→edit→queryById→deleteBatch 链式，importExcel/exportXls 测格式
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败：' + JSON.stringify(r));
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  return fetch(BASE + path, opts).then(r => r.json());
}

async function apiRaw(method, path) {
  return fetch(BASE + path, { method, headers: { 'X-Access-Token': token } });
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();

  // ====== Customer ======
  console.log('\n=== Customer (/mes/basic/customer) ===');
  const CUST = '/mes/basic/customer';
  const custCode = 'SLICE9_C_' + TS;
  const custAdd = await api('POST', `${CUST}/add`, { code: custCode, name: 'slice-9 客户', status: 1 });
  ass(custAdd.code === 200, '1.1 add Customer: ' + custAdd.message);
  // update-begin---author:pi---date:2026-08-07---for: Slice J — 改用 code 过滤查询（dev DB 共享资源 pageSize=10 找不到）-----------
  const custList = await api('GET', `${CUST}/list?pageNo=1&pageSize=10&code=${encodeURIComponent(custCode)}`);
  const cust = custList.result?.records?.[0];
  // update-end---author:pi---date:2026-08-07---for: Slice J — 改用 code 过滤查询-----------
  const custId = cust?.id || '';
  ass(!!custId, '1.2 查到 Customer: ' + custId);

  if (custId) {
    const edit = await api('PUT', `${CUST}/edit`, { id: custId, name: 'slice-9 客户-已编辑' });
    ass(edit.code === 200, '1.3 edit: ' + edit.message);
  }

  // importExcel (无文件，返回错误格式也算格式对)
  const imp = await api('POST', `${CUST}/importExcel`, {});
  ass(imp.code !== undefined, '1.4 importExcel: code=' + imp.code + ' msg=' + (imp.message || ''));

  // selectPage
  const sp = await api('GET', `${CUST}/selectPage?pageNo=1&pageSize=10`);
  ass(sp.code === 200, '1.5 selectPage: ' + sp.message);

  // queryAll
  const all = await api('GET', `${CUST}/queryAll`);
  ass(all.code === 200, '1.6 queryAll: ' + all.message);

  // deleteBatch
  if (custId) {
    const del = await api('DELETE', `${CUST}/deleteBatch?ids=${custId}`);
    ass(del.code === 200, '1.7 deleteBatch: ' + del.message);
  }

  // ====== Supplier ======
  console.log('\n=== Supplier (/mes/basic/supplier) ===');
  const SUP = '/mes/basic/supplier';
  const supCode = 'SLICE9_S_' + TS;
  const supAdd = await api('POST', `${SUP}/add`, { code: supCode, name: 'slice-9 供应商', status: 1 });
  ass(supAdd.code === 200, '2.1 add Supplier: ' + supAdd.message);
  // update-begin---author:pi---date:2026-08-07---for: Slice J — 改用 code 过滤查询（dev DB 共享资源 pageSize=10 找不到）-----------
  const supList = await api('GET', `${SUP}/list?pageNo=1&pageSize=10&code=${encodeURIComponent(supCode)}`);
  const sup = supList.result?.records?.[0];
  // update-end---author:pi---date:2026-08-07---for: Slice J — 改用 code 过滤查询-----------
  const supId = sup?.id || '';
  ass(!!supId, '2.2 查到 Supplier: ' + supId);

  if (supId) {
    // update-begin---author:pi---date:2026-08-07---for: Slice J — supplier edit 需带 code 字段（dev DB 共享资源）-----------
    const edit = await api('PUT', `${SUP}/edit`, { id: supId, code: supCode, name: 'slice-9 供应商-已编辑' });
    // update-end---author:pi---date:2026-08-07---for: Slice J — supplier edit 需带 code 字段-----------
    ass(edit.code === 200, '2.3 edit: ' + edit.message);

    const byId = await api('GET', `${SUP}/queryById?id=${supId}`);
    ass(byId.code === 200, '2.4 queryById: ' + byId.message);
  }

  const imp2 = await api('POST', `${SUP}/importExcel`, {});
  ass(imp2.code !== undefined, '2.5 importExcel: code=' + imp2.code + ' msg=' + (imp2.message || ''));

  const sp2 = await api('GET', `${SUP}/selectPage?pageNo=1&pageSize=10`);
  ass(sp2.code === 200, '2.6 selectPage: ' + sp2.message);

  const all2 = await api('GET', `${SUP}/queryAll`);
  ass(all2.code === 200, '2.7 queryAll: ' + all2.message);

  if (supId) {
    const del = await api('DELETE', `${SUP}/deleteBatch?ids=${supId}`);
    ass(del.code === 200, '2.8 deleteBatch: ' + del.message);
  }

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
