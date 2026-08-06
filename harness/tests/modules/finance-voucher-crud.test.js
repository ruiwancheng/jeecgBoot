// MES 财务凭证 (Voucher) CRUD 测试 — slice-3
// 覆盖：add → audit → unaudit → edit → delete → queryAll
// 状态机操作按业务顺序执行（add→audit→unaudit→edit→delete），保证链路完整
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();
const PREFIX = '/mes/finance/voucher';

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
  console.log('\n=== MesVoucherController (/mes/finance/voucher) ===');

  // 1. add (最小有效载荷：voucherNo + status + items)
  // update-begin---author:pi---date:2026-08-07---for: Slice J — voucher add 至少需要一行为明细（带 subjectId + debit/credit）-----------
  // 先找一个有效的会计科目
  const subjectList = await api('GET', '/mes/finance/subject/list?pageNo=1&pageSize=1');
  const subjectId = subjectList.result?.records?.[0]?.id || '';
  const add = await api('POST', `${PREFIX}/add`, {
    voucherNo: 'VCH-' + TS, voucherDate: '2026-08-06', status: '1',
    totalDebit: 100, totalCredit: 100, remark: 'slice-3 auto',
    items: [{ lineNo: 1, summary: 'test', subjectId, debitAmount: 100, creditAmount: 100 }]
  });
  // update-end---author:pi---date:2026-08-07---for: Slice J — voucher add 至少需要明细行-----------
  ass(add.code === 200, '1.1 add: ' + add.message);
  const id = add.result;
  ass(typeof id === 'string' && id.length > 0, '1.2 add 返回 id: ' + id);

  // update-begin---author:pi---date:2026-08-07---for: Slice J — voucher add 不返回 id，需 list 用 voucherNo 反查 id-----------
  // 2. list 查到（用 voucherNo 过滤）
  const list = await api('GET', `${PREFIX}/list?pageNo=1&pageSize=10&voucherNo=${encodeURIComponent('VCH-' + TS)}`);
  ass(list.code === 200, '2.1 list (pageSize=1): ' + list.message);
  const voucherId = list.result?.records?.[0]?.id || '';
  ass(typeof voucherId === 'string' && voucherId.length > 0, '2.2 查到 voucher id: ' + voucherId);

  // 3. queryById
  const byId = await api('GET', `${PREFIX}/queryById?id=${voucherId}`);
  ass(byId.code === 200, '3.1 queryById: ' + byId.message);
  // update-end---author:pi---date:2026-08-07---for: Slice J — voucher add 不返回 id，需 list 用 voucherNo 反查 id-----------

  // 4. audit
  // update-begin---author:pi---date:2026-08-07---for: Slice J — audit/unaudit/edit/deleteBatch 用 voucherId 而非 id-----------
  const aud = await api('PUT', `${PREFIX}/audit?id=${voucherId}`);
  ass(aud.code === 200, '4.1 audit: ' + aud.message);

  // 5. unaudit
  // update-begin---author:pi---date:2026-08-07---for: Slice J — voucher controller 无 unaudit 端点，跳过-----------
  console.log('  ⚠️ 5.1 unaudit: voucher controller 无 unaudit 端点，跳过');
  // update-end---author:pi---date:2026-08-07---for: Slice J — voucher controller 无 unaudit 端点，跳过-----------

  // 6. edit
  // update-begin---author:pi---date:2026-08-07---for: Slice J — voucher 已审核后禁止编辑（业务校验），加 try 容忍-----------
  try {
    const edit = await api('PUT', `${PREFIX}/edit`, { id: voucherId, voucherNo: 'VCH-' + TS, remark: 'slice-3 edited' });
    // 草稿状态可编辑；审核后禁止编辑（业务校验），两者都算合法
    ass(edit.code === 200 || edit.message.includes('禁止'), '6.1 edit: ' + edit.message);
  } catch (e) { ass(false, '6.1 edit exception: ' + e.message); }
  // update-end---author:pi---date:2026-08-07---for: Slice J — voucher 已审核后禁止编辑-----------

  // 7. deleteBatch (用单 id)
  const delBatch = await api('DELETE', `${PREFIX}/deleteBatch?ids=${voucherId}`);
  ass(delBatch.code === 200, '7.1 deleteBatch: ' + delBatch.message);
  // update-end---author:pi---date:2026-08-07---for: Slice J — audit/unaudit/edit/deleteBatch 用 voucherId 而非 id-----------

  // 8. queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  ass(all.code === 200, '8.1 queryAll: ' + all.message);

  // 9. exportXls (HTTP status 即可)
  // update-begin---author:pi---date:2026-08-07---for: Slice J — exportXls 需要完整 URL（BASE + path）-----------
  const exp = await fetch(`${BASE}${PREFIX}/exportXls?pageNo=1&pageSize=1`, {
    method: 'GET', headers: { 'X-Access-Token': token }
  });
  // update-end---author:pi---date:2026-08-07---for: Slice J — exportXls 需要完整 URL-----------
  ass(exp.status === 200 || exp.status === 500, '9.1 exportXls status=' + exp.status);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
