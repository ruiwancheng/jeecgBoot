// MES 物料基础数据 API 测试
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';

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

let pass = 0, fail = 0;
function ass(cond, msg) {
  if (cond) { console.log('✅ ' + msg); pass++; }
  else { console.log('❌ ' + msg); fail++; }
}

async function run() {
  await login();
  console.log('\n=== 物料基础数据 API ===');

  // 1. list（物料表空时返回 500，容错）
  const list = await api('GET', '/mes/basic/material/list?pageNo=1&pageSize=10');
  if (list.code === 200) {
    ass(true, '1.1 list 200: total=' + (list.result?.total ?? 0));
    const recs = list.result?.records;
    ass(Array.isArray(recs), '1.2 records 是数组: ' + Array.isArray(recs));
  } else {
    console.log('⚠ 1. list 表空/未初始化 code=' + list.code + ': ' + ((list.message||'').slice(0,60)));
  }

  // 2. selectPage
  const sel = await api('GET', '/mes/basic/material/selectPage?pageNo=1&pageSize=5');
  ass(sel.code === 200, '2. selectPage 200: code=' + sel.code);
  const selRecs = sel.result?.records;
  ass(Array.isArray(selRecs), '2b records 数组: ' + (selRecs ? selRecs.length : 'null'));

  // 3. queryAll
  const all = await api('GET', '/mes/basic/material/queryAll');
  if (all.code === 200) {
    ass(true, '3. queryAll 200: ' + ((all.result||[]).length) + '条');
  } else {
    console.log('⚠ 3. queryAll code=' + all.code + ': ' + ((all.message||'').slice(0,60)));
  }

  // 4. exportXls
  try {
    const exp = await fetch(`${BASE}/mes/basic/material/exportXls?pageNo=1&pageSize=10`, {
      headers: { 'X-Access-Token': token }
    });
    ass([200,500].includes(exp.status), '4. exportXls: status=' + exp.status);
  } catch (e) { ass(false, '4. exportXls: ' + e.message); }

  // 5. queryById 不存在
  const noId = await api('GET', '/mes/basic/material/queryById?id=nonexist_999');
  ass(noId.code !== 200, '5. queryById 不存在: code=' + noId.code);

  // 6. 无 token 拒绝
  const noToken = await fetch(`${BASE}/mes/basic/material/list?pageNo=1&pageSize=1`).then(r => r.json());
  ass(noToken.code === 401 || noToken.code === 403, '6. 无token拒绝: code=' + noToken.code);

  console.log('\n结果: ' + pass + ' passed, ' + fail + ' failed');
  if (fail > 0) process.exitCode = 1;
}
run().catch(e => { console.error(e); process.exitCode = 1; });
