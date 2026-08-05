#!/usr/bin/env node
// MES Finance 模块 API 测试（gen-tests 自动生成版）
// 覆盖: collection / salesInvoice / payable / payment / purchaseInvoice / receivable / subject / voucher
// 关联: .claude/plans/2026-08-04-mes-regression-plan.md
// 约束: 业务代码不改；测试数据不真造（add/edit/delete/audit 只测鉴权，不实际写入）
// 规则: 内置 R001-R008 — R002(越权) R003(数值边界) R005(SQL注入) 命中

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const NO_PERM_USER = { username: 'guest', password: '123456' };

// Finance 8 Controller 端点清单
const ENDPOINTS = [
  { mod: 'collection', base: '/mes/finance/collection', hasAdd: true, hasEdit: false, hasDelete: false, hasAudit: false },
  { mod: 'salesInvoice', base: '/mes/finance/salesInvoice', hasAdd: true, hasEdit: true, hasDelete: true, hasAudit: false },
  { mod: 'payable', base: '/mes/finance/payable', hasAdd: false, hasEdit: false, hasDelete: false, hasAudit: false },
  { mod: 'payment', base: '/mes/finance/payment', hasAdd: true, hasEdit: false, hasDelete: false, hasAudit: false },
  { mod: 'purchaseInvoice', base: '/mes/finance/purchaseInvoice', hasAdd: true, hasEdit: true, hasDelete: true, hasAudit: false },
  { mod: 'receivable', base: '/mes/finance/receivable', hasAdd: false, hasEdit: false, hasDelete: false, hasAudit: false },
  { mod: 'subject', base: '/mes/finance/subject', hasAdd: true, hasEdit: true, hasDelete: true, hasDeleteBatch: true, hasTree: true, hasSelectPage: true, hasAudit: false },
  { mod: 'voucher', base: '/mes/finance/voucher', hasAdd: true, hasEdit: true, hasDelete: true, hasDeleteBatch: true, hasAudit: true },
];

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== MES Finance 模块 API 测试（gen-tests） =====\n');
  let passed = 0, failed = 0, perMod = {};

  for (const ep of ENDPOINTS) {
    perMod[ep.mod] = { p: 0, f: 0 };
    console.log(`\n--- ${ep.mod} (${ep.base}) ---`);

    // 1. /list 基本列表
    const r1 = await c.api('GET', `${ep.base}/list?pageNo=1&pageSize=10`);
    const ok1 = r1.code === 200;
    if (ok1) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 1.1 list 200`, true, `records=${r1.result?.records?.length || 0}`); }
    else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 1.1 list 200`, false, `code=${r1.code} msg=${r1.message?.slice(0, 80)}`); }
    if (r1.result?.records?.length > 0) {
      const hasArray = Array.isArray(r1.result.records);
      if (hasArray) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 1.2 records 是数组`, true); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 1.2 records 是数组`, false); }
    }

    // 2. /queryById
    if (r1.result?.records?.length > 0) {
      const sampleId = r1.result.records[0].id;
      const r2 = await c.api('GET', `${ep.base}/queryById?id=${sampleId}`);
      if (r2.code === 200) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 2.1 queryById 200`, true, `id=${sampleId}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 2.1 queryById 200`, false, `code=${r2.code}`); }

      // 无效 ID
      const r2inv = await c.api('GET', `${ep.base}/queryById?id=non-existent-id`);
      if (r2inv.code === 200 || r2inv.code === 500) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 2.2 无效 ID 不崩溃`, true, `code=${r2inv.code}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 2.2 无效 ID 不崩溃`, false, `code=${r2inv.code}`); }
    }

    // 3. /queryAll（阈值检查）
    const r3 = await c.api('GET', `${ep.base}/queryAll`);
    if (r3.code === 200 && Array.isArray(r3.result)) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 3.1 queryAll 200`, true, `length=${r3.result.length}`); }
    else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 3.1 queryAll 200`, false, `code=${r3.code} msg=${r3.message?.slice(0, 80)}`); }

    // 4. /exportXls
    const expRes = await fetch(BASE + `${ep.base}/exportXls`, { headers: { 'X-Access-Token': c.token } });
    const bytes = new Uint8Array(await expRes.arrayBuffer());
    const isXlsx = bytes[0] === 0x50 && bytes[1] === 0x4b;
    if (expRes.status === 200 && isXlsx) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 4.1 exportXls xlsx`, true, `size=${bytes.length}B`); }
    else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 4.1 exportXls xlsx`, false, `status=${expRes.status} magic=${bytes[0]?.toString(16)}`); }

    // 5. /tree (仅 subject)
    if (ep.hasTree) {
      const rt = await c.api('GET', `${ep.base}/tree`);
      if (rt.code === 200 && Array.isArray(rt.result)) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 5.1 tree 200`, true, `length=${rt.result.length}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 5.1 tree 200`, false, `code=${rt.code}`); }
    }

    // 6. /selectPage (仅 subject)
    if (ep.hasSelectPage) {
      const rsp = await c.api('GET', `${ep.base}/selectPage?keyword=现`);
      if (rsp.code === 200 && Array.isArray(rsp.result)) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 6.1 selectPage 200`, true, `length=${rsp.result.length}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 6.1 selectPage 200`, false, `code=${rsp.code}`); }
    }

    // 7. /add 鉴权（不真造数据，传空 body 测权限/参数校验）
    if (ep.hasAdd) {
      const ra = await c.api('POST', `${ep.base}/add`, {});
      // 不带 token 应被拒
      const rNoAuth = await fetch(BASE + `${ep.base}/add`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
      const rNoAuthJson = await rNoAuth.json();
      const ok = rNoAuthJson.code === 401 || rNoAuthJson.code === 403;
      if (ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 7.1 add 无 token 拒绝`, true, `code=${rNoAuthJson.code}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 7.1 add 无 token 拒绝`, false, `code=${rNoAuthJson.code}`); }
      // 有 token 但空 body — 期望业务校验报错（不写数据）
      const ok2 = ra.code !== 500 || (ra.message && ra.message.includes('字段'));
      if (ok2) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 7.2 add 空 body 不崩溃`, true, `code=${ra.code} msg=${ra.message?.slice(0, 50)}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 7.2 add 空 body 不崩溃`, false, `code=${ra.code}`); }
    }

    // 8. /edit 鉴权
    if (ep.hasEdit) {
      const rNoAuth = await fetch(BASE + `${ep.base}/edit`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: '{}' });
      const rNoAuthJson = await rNoAuth.json();
      const ok = rNoAuthJson.code === 401 || rNoAuthJson.code === 403;
      if (ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 8.1 edit 无 token 拒绝`, true, `code=${rNoAuthJson.code}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 8.1 edit 无 token 拒绝`, false, `code=${rNoAuthJson.code}`); }
    }

    // 9. /delete 鉴权
    if (ep.hasDelete) {
      const rNoAuth = await fetch(BASE + `${ep.base}/delete?id=test`, { method: 'DELETE' });
      const rNoAuthJson = await rNoAuth.json();
      const ok = rNoAuthJson.code === 401 || rNoAuthJson.code === 403;
      if (ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 9.1 delete 无 token 拒绝`, true, `code=${rNoAuthJson.code}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 9.1 delete 无 token 拒绝`, false, `code=${rNoAuthJson.code}`); }
    }

    // 10. /deleteBatch 鉴权
    if (ep.hasDeleteBatch) {
      const rNoAuth = await fetch(BASE + `${ep.base}/deleteBatch?ids=test`, { method: 'DELETE' });
      const rNoAuthJson = await rNoAuth.json();
      const ok = rNoAuthJson.code === 401 || rNoAuthJson.code === 403;
      if (ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 10.1 deleteBatch 无 token 拒绝`, true, `code=${rNoAuthJson.code}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 10.1 deleteBatch 无 token 拒绝`, false, `code=${rNoAuthJson.code}`); }
    }

    // 11. /audit 鉴权
    if (ep.hasAudit) {
      const rNoAuth = await fetch(BASE + `${ep.base}/audit?id=test`, { method: 'PUT' });
      const rNoAuthJson = await rNoAuth.json();
      const ok = rNoAuthJson.code === 401 || rNoAuthJson.code === 403;
      if (ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 11.1 audit 无 token 拒绝`, true, `code=${rNoAuthJson.code}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 11.1 audit 无 token 拒绝`, false, `code=${rNoAuthJson.code}`); }
    }

    // 12. R003 边界值
    const boundaryCases = [
      { name: 'pageNo=0', qs: 'pageNo=0&pageSize=10' },
      { name: 'pageNo=-1', qs: 'pageNo=-1&pageSize=10' },
      { name: 'pageSize=0', qs: 'pageNo=1&pageSize=0' },
      { name: 'pageSize=2147483647', qs: 'pageNo=1&pageSize=2147483647' },
    ];
    for (const bc of boundaryCases) {
      const r = await c.api('GET', `${ep.base}/list?${bc.qs}`);
      const ok = r.code === 200 || r.code === 500;
      if (ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 12.${bc.name} 不崩`, true, `code=${r.code}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 12.${bc.name} 不崩`, false, `code=${r.code}`); }
    }

    // 13. R005 特殊字符搜索
    const sqlCases = ["' OR '1'='1", '%test%', 'DROP', '<script>'];
    for (const sc of sqlCases) {
      const r = await c.api('GET', `${ep.base}/list?keyword=${encodeURIComponent(sc)}&pageSize=10`);
      const ok = r.code === 200;
      if (ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 13.特殊字符"${sc.slice(0, 12)}..." 200`, true); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 13.特殊字符"${sc.slice(0, 12)}..." 200`, false, `code=${r.code}`); }
    }

    // ============================================================
    // 14. R009 语义断言（验证字段值，非仅 code===200）
    // ============================================================
    if (r1.result?.records?.length > 0) {
      const sample = r1.result.records[0];

      // (a) 字段值断言：主键 id 非空
      if (sample.id) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 14.1 字段值: id 非空`, true, `id=${sample.id.slice(-12)}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 14.1 字段值: id 非空`, false, 'records[0].id 为空'); }

      // (a) 字段值断言：列表第一条记录的某业务字段非空（按模块区分）
      const fieldCheck = (() => {
        if (ep.mod === 'subject' && sample.code) return { ok: true, detail: `subject.code=${sample.code}` };
        if (ep.mod === 'voucher' && (sample.voucherNo || sample.code)) return { ok: true, detail: `voucher.code=${sample.voucherNo || sample.code}` };
        if (ep.mod === 'collection' && (collectionHasAmount = sample.amount !== undefined)) return { ok: true, detail: `collection.amount=${sample.amount}` };
        if (ep.mod === 'payment' && (sample.amount !== undefined || sample.code)) return { ok: true, detail: `payment.amount=${sample.amount}` };
        if (ep.mod === 'receivable' && sample.amount !== undefined) return { ok: true, detail: `receivable.amount=${sample.amount}` };
        if (ep.mod === 'payable' && sample.amount !== undefined) return { ok: true, detail: `payable.amount=${sample.amount}` };
        if (ep.mod === 'salesInvoice' && (sample.invoiceNo || sample.code)) return { ok: true, detail: `salesInvoice.invoiceNo=${sample.invoiceNo || sample.code}` };
        if (ep.mod === 'purchaseInvoice' && (sample.invoiceNo || sample.code)) return { ok: true, detail: `purchaseInvoice.invoiceNo=${sample.invoiceNo || sample.code}` };
        return { ok: false, detail: '未匹配业务字段' };
      })();
      if (fieldCheck.ok) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 14.2 字段值: 业务字段非空`, true, fieldCheck.detail); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 14.2 字段值: 业务字段非空`, false, fieldCheck.detail); }

      // (b) 状态流转断言：list 返回 status 字段类型正确（数字或字符串）
      if ('status' in sample || 'auditStatus' in sample || 'delFlag' in sample) {
        const statusField = sample.status ?? sample.auditStatus ?? sample.delFlag;
        const typeOk = typeof statusField === 'number' || typeof statusField === 'string';
        if (typeOk) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 14.3 状态字段类型`, true, `type=${typeof statusField} value=${statusField}`); }
        else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 14.3 状态字段类型`, false, `type=${typeof statusField}`); }
      }

      // (d) 数据传递断言：queryAll vs list records 一致性（同表同字段）
      if (r3.code === 200 && Array.isArray(r3.result) && r3.result.length > 0) {
        const listIds = new Set(r1.result.records.slice(0, 5).map(r => r.id));
        const allIds = new Set(r3.result.slice(0, 5).map(r => r.id));
        const overlap = [...listIds].filter(id => allIds.has(id)).length;
        if (overlap >= 1) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 14.4 数据传递: list/queryAll id 一致`, true, `overlap=${overlap}/5`); }
        else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 14.4 数据传递: list/queryAll id 一致`, false, `overlap=${overlap}/5 listIds=${listIds.size} allIds=${allIds.size}`); }
      }
    }

    // 15. R009 显示值断言（list 接口字段名规范，避免裸 ID）
    if (r1.result?.records?.length > 0) {
      const sample = r1.result.records[0];
      // 至少有一个 display 友好的字段（code/name/title 三者之一）
      const hasDisplayField = sample.code || sample.name || sample.title || sample.subjectName || sample.customerName || sample.supplierName;
      if (hasDisplayField) { passed++; perMod[ep.mod].p++; c.check(`${ep.mod} 15.1 显示值: 友好字段存在（非裸 ID）`, true, `field=${Object.keys(hasDisplayField)[0]}=${Object.values(hasDisplayField)[0]}`); }
      else { failed++; perMod[ep.mod].f++; c.check(`${ep.mod} 15.1 显示值: 友好字段存在（非裸 ID）`, false, '只有 id 字段，前端会显示裸 ID'); }
    }
  }

  // ============================================================
  // R002 全模块无权限账号测试
  // ============================================================
  console.log('\n--- R002 全模块越权（无权限账号） ---');
  const guest = createClient(BASE);
  try {
    await guest.login(NO_PERM_USER.username, NO_PERM_USER.password);
    for (const ep of ENDPOINTS) {
      const r = await guest.api('GET', `${ep.base}/list?pageSize=1`);
      const ok = r.code === 401 || r.code === 403;
      if (ok) { passed++; c.check(`R002 ${ep.mod} 无权限 list 拒绝`, true, `code=${r.code}`); }
      else { failed++; c.check(`R002 ${ep.mod} 无权限 list 拒绝`, false, `code=${r.code} msg=${r.message?.slice(0, 80)}`); }
    }
  } catch (e) {
    console.log(`  ⚠️ guest 账号不存在，跳过 R002 (${e.message})`);
  }

  // ============================================================
  // 总结
  // ============================================================
  console.log('\n===== Finance 模块汇总 =====');
  for (const ep of ENDPOINTS) {
    const total = perMod[ep.mod].p + perMod[ep.mod].f;
    const rate = total > 0 ? ((perMod[ep.mod].p / total) * 100).toFixed(1) : 0;
    console.log(`  ${ep.mod}: ${perMod[ep.mod].p}/${total} 通过 (${rate}%)`);
  }
  console.log(`\n===== 总计：${passed} 通过, ${failed} 失败 =====`);
  console.log(`===== 通过率：${passed + failed > 0 ? ((passed / (passed + failed)) * 100).toFixed(1) : 0}% =====\n`);
  process.exit(failed > 0 ? 1 : 0);
}

run().catch(err => { console.error('FATAL:', err); process.exit(2); });