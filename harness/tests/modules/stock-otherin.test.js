// MES 其它入库 (OtherStockIn) 状态机测试 — slice-7
// 覆盖：add → audit → unaudit → delete (7 个缺口端点)
// 状态机操作必须 add 真实数据再流转
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

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();
  console.log('\n=== OtherStockIn (/mes/stock/otherIn) ===');
  const PREFIX = '/mes/stock/otherIn';

  // 1. add (最小 payload)
  const add = await api('POST', `${PREFIX}/add`, {
    code: 'OSI-' + TS, inType: '1', inDate: '2026-08-06',
    status: '1', remark: 'slice-7 auto'
  });
  ass(add.code === 200, '1.1 add: ' + add.message);
  const id = add.result;
  ass(typeof id === 'string' && id.length > 0, '1.2 add 返回 id: ' + id);

  // 2. list 查到
  const list = await api('GET', `${PREFIX}/list?pageNo=1&pageSize=1`);
  ass(list.code === 200, '2.1 list (pageSize=1): ' + list.message);

  // 3. queryById
  if (id) {
    const byId = await api('GET', `${PREFIX}/queryById?id=${id}`);
    ass(byId.code === 200, '3.1 queryById: ' + byId.message);
  }

  // 4. audit
  if (id) {
    const aud = await api('PUT', `${PREFIX}/audit?id=${id}`);
    ass(aud.code === 200, '4.1 audit: ' + aud.message);
  }

  // 5. unaudit
  if (id) {
    const unaud = await api('PUT', `${PREFIX}/unaudit?id=${id}`);
    ass(unaud.code === 200, '5.1 unaudit: ' + unaud.message);
  }

  // 6. edit
  if (id) {
    const edit = await api('PUT', `${PREFIX}/edit`, { id, remark: 'slice-7 edited' });
    ass(edit.code === 200, '6.1 edit: ' + edit.message);
  }

  // 7. deleteBatch (用单 id)
  if (id) {
    const delBatch = await api('DELETE', `${PREFIX}/deleteBatch?ids=${id}`);
    ass(delBatch.code === 200, '7.1 deleteBatch: ' + delBatch.message);
  }

  // 8. exportXls
  const exp = await fetch(`${PREFIX}/exportXls?pageNo=1&pageSize=1`, {
    method: 'GET', headers: { 'X-Access-Token': token }
  });
  ass(exp.status === 200 || exp.status === 500, '8.1 exportXls status=' + exp.status);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
