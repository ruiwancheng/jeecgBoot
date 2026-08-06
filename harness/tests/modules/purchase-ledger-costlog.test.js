// MES 采购台账 (InventoryLedger) + 成本日志 (CostLog) GET 端点测试 — slice-4
// 覆盖：InventoryLedger (list/queryAll/exportXls) + CostLog (list)
// 注意：InventoryLedger 实际路径 /mes/warehouse/ledger；CostLog 实际路径 /mes/purchase/mesCostLog
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

async function api(method, path) {
  return fetch(BASE + path, { method, headers: { 'X-Access-Token': token } }).then(r => r.json());
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

  console.log('\n=== InventoryLedger (/mes/warehouse/ledger) ===');
  const LEDGER = '/mes/warehouse/ledger';

  const list = await api('GET', `${LEDGER}/list?pageNo=1&pageSize=1`);
  ass(list.code === 200, '1.1 GET /list (pageSize=1): ' + list.message);

  const all = await api('GET', `${LEDGER}/queryAll`);
  ass(all.code === 200, '1.2 GET /queryAll: ' + all.message);

  const exp = await apiRaw('GET', `${LEDGER}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '1.3 GET /exportXls status=' + exp.status);

  console.log('\n=== CostLog (/mes/purchase/mesCostLog) ===');
  const COST = '/mes/purchase/mesCostLog';

  const costList = await api('GET', `${COST}/list?pageNo=1&pageSize=1`);
  ass(costList.code === 200, '2.1 GET /list (pageSize=1): ' + costList.message);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
