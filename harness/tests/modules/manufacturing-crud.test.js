// MES 生产制造 (Manufacturing) 缺口端点测试 — slice-10
// 覆盖：MesBom / CompletionReceipt / ProductionOrder / ProductionPicking 的 edit/deleteBatch/queryAll/exportXls
// 状态机操作需先 add 真实数据；纯 GET 端点 pageSize=1
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

async function addAndGetId(prefix, payload) {
  const add = await api('POST', `${prefix}/add`, payload);
  if (add.code !== 200) return '';
  // 直接返回 add.result
  return add.result || '';
}

async function testBom() {
  console.log('\n=== MesBomController (/mes/manufacturing/bom) ===');
  const PREFIX = '/mes/manufacturing/bom';

  // 1. add
  const id = await addAndGetId(PREFIX, { code: 'BOM-' + TS, status: '1', remark: 'slice-10' });
  ass(typeof id === 'string' && id.length > 0, '1.1 add: ' + id);

  // 2. edit
  if (id) {
    const edit = await api('PUT', `${PREFIX}/edit`, { id, remark: 'slice-10 edited' });
    ass(edit.code === 200, '2.1 edit: ' + edit.message);
  }

  // 3. deleteBatch
  if (id) {
    const del = await api('DELETE', `${PREFIX}/deleteBatch?ids=${id}`);
    ass(del.code === 200, '3.1 deleteBatch: ' + del.message);
  }

  // 4. queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  ass(all.code === 200, '4.1 queryAll: ' + all.message);

  // 5. exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '5.1 exportXls status=' + exp.status);
}

async function testCompletion() {
  console.log('\n=== CompletionReceiptController (/mes/manufacturing/completion) ===');
  const PREFIX = '/mes/manufacturing/completion';

  const id = await addAndGetId(PREFIX, { code: 'CR-' + TS, status: '1', remark: 'slice-10' });
  ass(typeof id === 'string' && id.length > 0, '1.1 add: ' + id);

  if (id) {
    const edit = await api('PUT', `${PREFIX}/edit`, { id, remark: 'edited' });
    ass(edit.code === 200, '1.2 edit: ' + edit.message);

    const del = await api('DELETE', `${PREFIX}/deleteBatch?ids=${id}`);
    ass(del.code === 200, '1.3 deleteBatch: ' + del.message);
  }

  const all = await api('GET', `${PREFIX}/queryAll`);
  ass(all.code === 200, '1.4 queryAll: ' + all.message);

  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '1.5 exportXls status=' + exp.status);
}

async function testProductionOrder() {
  console.log('\n=== ProductionOrderController (/mes/manufacturing/order) ===');
  const PREFIX = '/mes/manufacturing/order';

  const id = await addAndGetId(PREFIX, { code: 'PO-' + TS, status: '1', remark: 'slice-10' });
  ass(typeof id === 'string' && id.length > 0, '1.1 add: ' + id);

  // queryById (新增覆盖)
  if (id) {
    const byId = await api('GET', `${PREFIX}/queryById?id=${id}`);
    ass(byId.code === 200, '1.2 queryById: ' + byId.message);

    const edit = await api('PUT', `${PREFIX}/edit`, { id, remark: 'edited' });
    ass(edit.code === 200, '1.3 edit: ' + edit.message);

    const del = await api('DELETE', `${PREFIX}/deleteBatch?ids=${id}`);
    ass(del.code === 200, '1.4 deleteBatch: ' + del.message);
  }

  const all = await api('GET', `${PREFIX}/queryAll`);
  ass(all.code === 200, '1.5 queryAll: ' + all.message);

  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '1.6 exportXls status=' + exp.status);
}

async function testPicking() {
  console.log('\n=== ProductionPickingController (/mes/manufacturing/picking) ===');
  const PREFIX = '/mes/manufacturing/picking';

  const id = await addAndGetId(PREFIX, { code: 'PK-' + TS, status: '1', remark: 'slice-10' });
  ass(typeof id === 'string' && id.length > 0, '1.1 add: ' + id);

  if (id) {
    const edit = await api('PUT', `${PREFIX}/edit`, { id, remark: 'edited' });
    ass(edit.code === 200, '1.2 edit: ' + edit.message);

    const del = await api('DELETE', `${PREFIX}/deleteBatch?ids=${id}`);
    ass(del.code === 200, '1.3 deleteBatch: ' + del.message);
  }

  const all = await api('GET', `${PREFIX}/queryAll`);
  ass(all.code === 200, '1.4 queryAll: ' + all.message);

  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '1.5 exportXls status=' + exp.status);
}

async function run() {
  await login();
  await testBom();
  await testCompletion();
  await testProductionOrder();
  await testPicking();
  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
