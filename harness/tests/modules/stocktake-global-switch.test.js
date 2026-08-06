// MES 盘点 (Stocktake) + 全局开关 (GlobalSwitch) 测试 — slice-8
// Stocktake: audit+delete+queryById+refreshItems
// GlobalSwitch: save+closeBatchSwitch+closeCheck
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

  console.log('\n=== Stocktake (/mes/stock/stocktake) ===');
  const ST = '/mes/stock/stocktake';

  // 1. add (最小 payload)
  const add = await api('POST', `${ST}/add`, {
    code: 'STK-' + TS, stocktakeType: '1', stocktakeDate: '2026-08-06',
    status: '1', remark: 'slice-8 auto'
  });
  ass(add.code === 200, '1.1 add: ' + add.message);
  const id = add.result;
  ass(typeof id === 'string' && id.length > 0, '1.2 add 返回 id: ' + id);

  // 2. queryById
  if (id) {
    const byId = await api('GET', `${ST}/queryById?id=${id}`);
    ass(byId.code === 200, '2.1 queryById: ' + byId.message);
  }

  // 3. refreshItems
  if (id) {
    const ref = await api('POST', `${ST}/refreshItems?id=${id}`);
    ass(ref.code === 200, '3.1 refreshItems: ' + ref.message);
  }

  // 4. audit
  if (id) {
    const aud = await api('PUT', `${ST}/audit?id=${id}`);
    ass(aud.code === 200, '4.1 audit: ' + aud.message);
  }

  // 5. delete
  if (id) {
    const del = await api('DELETE', `${ST}/delete?id=${id}`);
    ass(del.code === 200, '5.1 delete: ' + del.message);
  }

  console.log('\n=== GlobalSwitch (/mes/system/globalSwitch) ===');
  const SW = '/mes/system/globalSwitch';

  // 6. save
  const save = await api('POST', `${SW}/save`, {
    switchKey: 'slice8_key_' + TS, switchValue: 1,
    switchName: 'slice-8 测试开关', description: 'auto-test'
  });
  ass(save.code === 200, '6.1 save: ' + save.message);

  // 7. closeBatchSwitch (无参)
  const cbs = await api('POST', `${SW}/closeBatchSwitch`);
  ass(cbs.code === 200, '7.1 closeBatchSwitch: ' + cbs.message);

  // 8. closeCheck (用刚保存的 key)
  const cc = await api('GET', `${SW}/closeCheck?switchKey=slice8_key_${TS}`);
  ass(cc.code === 200, '8.1 closeCheck: ' + cc.message);

  // 9. list
  const lst = await api('GET', `${SW}/list`);
  ass(lst.code === 200, '9.1 list: ' + lst.message);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
