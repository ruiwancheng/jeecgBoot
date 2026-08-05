#!/usr/bin/env node
// 切片 4：basic/inventoryAlert API 测试
// 覆盖: MesInventoryAlertController（仅 1 个端点 /list）
// 关联: /coverage 切片 4 P1 缺口
// 特性: 只读预警列表（实时计算 currentQty vs safetyStock）
//       业务逻辑：物料安全库存 > 0 + status=1 + 当前库存 < 安全库存
//       返回字段：materialId/materialCode/materialName/currentQty/safetyStock/maxStock/shortage

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const ENDPOINT = '/mes/basic/inventoryAlert';

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== MES basic/inventoryAlert 模块 API 测试 =====\n');
  let passed = 0, failed = 0;

  // ============================================================
  // 1. /list 列表（核心且唯一端点）
  // ============================================================
  console.log(`--- /list ---`);
  const r1 = await c.api('GET', `${ENDPOINT}/list`);
  if (r1.code === 200) { passed++; c.check('1.1 list 200', true, `alerts=${r1.result?.length || 0}`); }
  else { failed++; c.check('1.1 list 200', false, `code=${r1.code} msg=${r1.message?.slice(0, 80)}`); }

  if (Array.isArray(r1.result)) { passed++; c.check('1.2 result 是数组', true); }
  else { failed++; c.check('1.2 result 是数组', false); }

  // ============================================================
  // 2. 字段语义断言
  // ============================================================
  console.log(`\n--- 字段语义 ---`);
  if (r1.code === 200 && r1.result?.length > 0) {
    const sample = r1.result[0];

    // 必填字段
    if (sample.materialId) { passed++; c.check('2.1 字段: materialId 存在', true, `id=${sample.materialId.slice(-12)}`); }
    else { failed++; c.check('2.1 字段: materialId 存在', false); }

    if (sample.materialCode) { passed++; c.check('2.2 字段: materialCode 存在', true, `code=${sample.materialCode}`); }
    else { failed++; c.check('2.2 字段: materialCode 存在', false); }

    if (sample.materialName) { passed++; c.check('2.3 字段: materialName 存在', true, `name=${sample.materialName}`); }
    else { failed++; c.check('2.3 字段: materialName 存在', false); }

    // 业务字段
    if (sample.currentQty !== undefined) { passed++; c.check('2.4 字段: currentQty 存在', true, `qty=${sample.currentQty}`); }
    else { failed++; c.check('2.4 字段: currentQty 存在', false); }

    if (sample.safetyStock !== undefined) { passed++; c.check('2.5 字段: safetyStock 存在', true, `safety=${sample.safetyStock}`); }
    else { failed++; c.check('2.5 字段: safetyStock 存在', false); }

    if (sample.maxStock !== undefined) { passed++; c.check('2.6 字段: maxStock 存在', true, `max=${sample.maxStock}`); }
    else { failed++; c.check('2.6 字段: maxStock 存在', false); }

    if (sample.shortage !== undefined) { passed++; c.check('2.7 字段: shortage 存在', true, `shortage=${sample.shortage}`); }
    else { failed++; c.check('2.7 字段: shortage 存在', false); }
  } else {
    console.log('  ⚠️ 列表为空，跳过字段断言');
  }

  // ============================================================
  // 3. 业务逻辑验证
  // ============================================================
  console.log(`\n--- 业务逻辑 ---`);
  if (r1.code === 200 && r1.result?.length > 0) {
    // 3.1 所有预警都应满足 currentQty < safetyStock
    let logicOk = true;
    for (const a of r1.result) {
      if (a.currentQty === undefined || a.safetyStock === undefined) continue;
      if (Number(a.currentQty) >= Number(a.safetyStock)) {
        logicOk = false;
        console.log(`     ❌ 违反规则: ${a.materialCode} current=${a.currentQty} >= safety=${a.safetyStock}`);
        break;
      }
    }
    if (logicOk) { passed++; c.check('3.1 业务规则: 所有 currentQty < safetyStock', true, `count=${r1.result.length}`); }
    else { failed++; c.check('3.1 业务规则: 所有 currentQty < safetyStock', false); }

    // 3.2 shortage = safetyStock - currentQty
    const sample = r1.result[0];
    const expectedShortage = Number(sample.safetyStock) - Number(sample.currentQty);
    if (Number(sample.shortage) === expectedShortage) {
      passed++; c.check('3.2 业务规则: shortage = safetyStock - currentQty', true, `shortage=${sample.shortage}`);
    } else {
      failed++; c.check('3.2 业务规则: shortage = safetyStock - currentQty', false, `expected=${expectedShortage} actual=${sample.shortage}`);
    }

    // 3.3 排序：按 shortage 降序（Controller 显式 sort）
    let sortedOk = true;
    for (let i = 1; i < r1.result.length; i++) {
      if (Number(r1.result[i-1].shortage) < Number(r1.result[i].shortage)) {
        sortedOk = false;
        break;
      }
    }
    if (sortedOk) { passed++; c.check('3.3 排序: 按 shortage 降序', true); }
    else { failed++; c.check('3.3 排序: 按 shortage 降序', false, '顺序错乱'); }
  } else {
    console.log('  ⚠️ 列表为空，跳过业务逻辑断言');
  }

  // ============================================================
  // 4. 不存在的端点应返回 404
  //    ⚠️ JeecgBoot 全局异常处理：HTTP 永远 200，业务码 code=404
  // ============================================================
  console.log(`\n--- 不存在的端点应返回 code=404 ---`);
  for (const ep of ['add', 'edit', 'delete', 'exportXls', 'queryById', 'queryAll']) {
    const method = ep === 'add' ? 'POST' : (ep === 'edit' ? 'PUT' : 'GET');
    const url = `${ENDPOINT}/${ep}${ep === 'delete' ? '?id=test' : ''}`;
    const opts = { method, headers: { 'X-Access-Token': c.token } };
    const r = await fetch(BASE + url, opts);
    const json = await r.json().catch(() => ({}));
    const ok = json.code === 404 || (r.status === 404);
    if (ok) { passed++; c.check(`4.${ep} 404 (端点不存在)`, true, `HTTP=${r.status} code=${json.code}`); }
    else { failed++; c.check(`4.${ep} 404 (端点不存在)`, false, `HTTP=${r.status} code=${json.code}`); }
  }

  // ============================================================
  // 5. SQL 注入 / 特殊字符（无 query 参数，但测试不崩）
  // ============================================================
  console.log(`\n--- 特殊字符 / 参数鲁棒性 ---`);
  const r5 = await c.api('GET', `${ENDPOINT}/list?keyword=测试`);
  if (r5.code === 200) { passed++; c.check('5.1 附加参数不崩', true, `length=${r5.result?.length || 0}`); }
  else { failed++; c.check('5.1 附加参数不崩', false, `code=${r5.code}`); }

  // ============================================================
  // 6. 鉴权验证（无 token 应 401）
  // ============================================================
  console.log(`\n--- 鉴权 ---`);
  const r6 = await fetch(BASE + ENDPOINT + '/list', { method: 'GET' });
  const r6j = await r6.json().catch(() => ({}));
  if (r6.status === 401 || r6j.code === 401) {
    passed++; c.check('6.1 无 token 401', true, `status=${r6.status} code=${r6j.code}`);
  } else {
    failed++; c.check('6.1 无 token 401', false, `status=${r6.status} code=${r6j.code}`);
  }

  return c.summary('inventoryAlert');
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(2); });
