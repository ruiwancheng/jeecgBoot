#!/usr/bin/env node
// 切片 5：warehouse/ledger API 测试
// 覆盖: MesInventoryLedgerController（3 端点：list/queryAll/exportXls）
// 关联: /coverage 切片 5 P1 缺口
// 特性:
//   - 库存台账只读视图（list/queryAll/exportXls）
//   - 业务逻辑：fillCostDiff 实时计算 costDiff = (unitCost - movingAvgCost) × qty
//   - queryAll 阈值 5000 条限制（>5000 抛异常）
//   - 排序：orderByDesc("record_date").orderByAsc("material_id")
//   - 当前测试数据 ~30+ 条，远低于 queryAll 阈值

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const ENDPOINT = '/mes/warehouse/ledger';

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== MES warehouse/ledger 模块 API 测试 =====\n');
  let passed = 0, failed = 0;

  // ============================================================
  // 1. /list 列表（核心端点）
  // ============================================================
  console.log(`--- /list ---`);
  const r1 = await c.api('GET', `${ENDPOINT}/list?pageNo=1&pageSize=10`);
  if (r1.code === 200) { passed++; c.check('1.1 list 200', true, `total=${r1.result?.total || 0}`); }
  else { failed++; c.check('1.1 list 200', false, `code=${r1.code} msg=${r1.message?.slice(0, 80)}`); }

  if (Array.isArray(r1.result?.records)) { passed++; c.check('1.2 records 是数组', true, `length=${r1.result.records.length}`); }
  else { failed++; c.check('1.2 records 是数组', false); }

  // ============================================================
  // 2. /queryAll 全部
  // ============================================================
  console.log(`\n--- /queryAll ---`);
  const r2 = await c.api('GET', `${ENDPOINT}/queryAll`);
  if (r2.code === 200 && Array.isArray(r2.result)) {
    passed++; c.check('2.1 queryAll 200', true, `length=${r2.result.length}`);
  } else {
    failed++; c.check('2.1 queryAll 200', false, `code=${r2.code} msg=${r2.message?.slice(0, 80)}`);
  }

  // ============================================================
  // 3. /exportXls 导出
  // ============================================================
  console.log(`\n--- /exportXls ---`);
  const expRes = await fetch(BASE + `${ENDPOINT}/exportXls`, { headers: { 'X-Access-Token': c.token } });
  const bytes = new Uint8Array(await expRes.arrayBuffer());
  const isXlsx = bytes[0] === 0x50 && bytes[1] === 0x4b;
  if (expRes.status === 200 && isXlsx) { passed++; c.check('3.1 exportXls xlsx', true, `size=${bytes.length}B`); }
  else { failed++; c.check('3.1 exportXls xlsx', false, `status=${expRes.status} magic=${bytes[0]?.toString(16)}`); }

  // ============================================================
  // 4. 字段语义断言
  // ============================================================
  console.log(`\n--- 字段语义 ---`);
  if (r1.code === 200 && r1.result?.records?.length > 0) {
    const sample = r1.result.records[0];

    // 必填字段
    if (sample.id) { passed++; c.check('4.1 字段: id 存在', true, `id=${sample.id.slice(-12)}`); }
    else { failed++; c.check('4.1 字段: id 存在', false); }

    if (sample.materialId) { passed++; c.check('4.2 字段: materialId 存在', true); }
    else { failed++; c.check('4.2 字段: materialId 存在', false); }

    if (sample.warehouseId) { passed++; c.check('4.3 字段: warehouseId 存在', true); }
    else { failed++; c.check('4.3 字段: warehouseId 存在', false); }

    // 业务字段
    if (sample.beginningQty !== undefined) { passed++; c.check('4.4 字段: beginningQty 存在', true, `begin=${sample.beginningQty}`); }
    else { failed++; c.check('4.4 字段: beginningQty 存在', false); }

    if (sample.inQty !== undefined) { passed++; c.check('4.5 字段: inQty 存在', true, `in=${sample.inQty}`); }
    else { failed++; c.check('4.5 字段: inQty 存在', false); }

    if (sample.outQty !== undefined) { passed++; c.check('4.6 字段: outQty 存在', true, `out=${sample.outQty}`); }
    else { failed++; c.check('4.6 字段: outQty 存在', false); }

    if (sample.endingQty !== undefined) { passed++; c.check('4.7 字段: endingQty 存在', true, `end=${sample.endingQty}`); }
    else { failed++; c.check('4.7 字段: endingQty 存在', false); }

    if (sample.unitCost !== undefined) { passed++; c.check('4.8 字段: unitCost 存在', true, `unitCost=${sample.unitCost}`); }
    else { failed++; c.check('4.8 字段: unitCost 存在', false); }

    // 关键：A+ 成本差异实时计算
    if (sample.costDiff !== undefined) { passed++; c.check('4.9 字段: costDiff 存在 (A+ 业务)', true, `costDiff=${sample.costDiff}`); }
    else { failed++; c.check('4.9 字段: costDiff 存在', false, 'A+ 成本差异字段缺失'); }

    if (sample.movingAvgCost !== undefined) { passed++; c.check('4.10 字段: movingAvgCost 存在', true, `avg=${sample.movingAvgCost}`); }
    else { failed++; c.check('4.10 字段: movingAvgCost 存在', false); }

    if (sample.recordDate) { passed++; c.check('4.11 字段: recordDate 存在', true, `date=${sample.recordDate}`); }
    else { failed++; c.check('4.11 字段: recordDate 存在', false); }

    if (sample.bizType) { passed++; c.check('4.12 字段: bizType 存在', true, `bizType=${sample.bizType}`); }
    else { failed++; c.check('4.12 字段: bizType 存在', false); }
  } else {
    console.log('  ⚠️ 列表为空，跳过字段断言');
  }

  // ============================================================
  // 5. 业务逻辑验证：costDiff = (unitCost - movingAvgCost) × qty
  // ============================================================
  console.log(`\n--- 业务逻辑: costDiff 计算 ---`);
  if (r1.code === 200 && r1.result?.records?.length > 0) {
    let logicOk = true;
    for (const r of r1.result.records.slice(0, 10)) {
      if (r.unitCost == null || r.movingAvgCost == null || r.costDiff == null) continue;
      const qty = (Number(r.inQty || 0) + Number(r.outQty || 0));
      const expected = (Number(r.unitCost) - Number(r.movingAvgCost)) * qty;
      // tolerance: ±0.01（四舍五入差异）
      if (Math.abs(Number(r.costDiff) - expected) > 0.01) {
        logicOk = false;
        console.log(`     ❌ costDiff 错: id=${r.id.slice(-12)} unit=${r.unitCost} avg=${r.movingAvgCost} qty=${qty} expected=${expected.toFixed(2)} actual=${r.costDiff}`);
        break;
      }
    }
    if (logicOk) { passed++; c.check('5.1 业务规则: costDiff = (unit-avg) × qty', true, '前 10 条均满足'); }
    else { failed++; c.check('5.1 业务规则: costDiff 计算', false); }
  } else {
    console.log('  ⚠️ 列表为空，跳过业务逻辑');
  }

  // ============================================================
  // 6. 排序：orderByDesc(record_date).orderByAsc(material_id)
  // ============================================================
  console.log(`\n--- 排序 ---`);
  if (r1.code === 200 && r1.result?.records?.length > 1) {
    let sortOk = true;
    for (let i = 1; i < r1.result.records.length; i++) {
      const prev = r1.result.records[i-1];
      const curr = r1.result.records[i];
      if (prev.recordDate < curr.recordDate) {
        sortOk = false;
        console.log(`     ❌ 排序错: prev=${prev.recordDate} > curr=${curr.recordDate}`);
        break;
      }
    }
    if (sortOk) { passed++; c.check('6.1 排序: record_date 降序', true); }
    else { failed++; c.check('6.1 排序: record_date 降序', false); }
  }

  // ============================================================
  // 7. 不存在的端点应返回 404
  //    ⚠️ JeecgBoot 全局异常处理：HTTP 永远 200，业务码 code=404
  // ============================================================
  console.log(`\n--- 不存在的端点应返回 code=404 ---`);
  for (const ep of ['add', 'edit', 'delete', 'queryById', 'importExcel', 'deleteBatch', 'selectPage']) {
    const method = ep === 'add' ? 'POST' : (ep === 'edit' ? 'PUT' : 'GET');
    const url = ep === 'delete' || ep === 'deleteBatch' ? `${ENDPOINT}/${ep}?id=test` : `${ENDPOINT}/${ep}`;
    const opts = { method, headers: { 'X-Access-Token': c.token } };
    const r = await fetch(BASE + url, opts);
    const json = await r.json().catch(() => ({}));
    const ok = json.code === 404 || (r.status === 404);
    if (ok) { passed++; c.check(`7.${ep} 404 (端点不存在)`, true, `HTTP=${r.status} code=${json.code}`); }
    else { failed++; c.check(`7.${ep} 404 (端点不存在)`, false, `HTTP=${r.status} code=${json.code}`); }
  }

  // ============================================================
  // 8. 边界值
  // ============================================================
  console.log(`\n--- 边界值 ---`);
  const boundaryCases = [
    { name: 'pageNo=0', qs: 'pageNo=0&pageSize=10' },
    { name: 'pageNo=-1', qs: 'pageNo=-1&pageSize=10' },
    { name: 'pageSize=0', qs: 'pageNo=1&pageSize=0' },
    { name: 'pageSize=2147483647', qs: 'pageNo=1&pageSize=2147483647' },
  ];
  for (const bc of boundaryCases) {
    const r = await c.api('GET', `${ENDPOINT}/list?${bc.qs}`);
    const ok = r.code === 200 || r.code === 500;
    if (ok) { passed++; c.check(`8.${bc.name} 不崩`, true, `code=${r.code}`); }
    else { failed++; c.check(`8.${bc.name} 不崩`, false, `code=${r.code}`); }
  }

  // ============================================================
  // 9. 字典过滤（materialId/warehouseId/bizType）
  // ============================================================
  console.log(`\n--- 字典过滤 ---`);
  if (r1.code === 200 && r1.result?.records?.length > 0) {
    const sample = r1.result.records[0];
    const filterCases = [
      { name: `materialId=${sample.materialId.slice(-12)}`, qs: `materialId=${sample.materialId}` },
      { name: `warehouseId=${sample.warehouseId.slice(-12)}`, qs: `warehouseId=${sample.warehouseId}` },
      { name: `bizType=${sample.bizType}`, qs: `bizType=${encodeURIComponent(sample.bizType)}` },
    ];
    for (const fc of filterCases) {
      const r = await c.api('GET', `${ENDPOINT}/list?${fc.qs}&pageSize=10`);
      if (r.code === 200) { passed++; c.check(`9.${fc.name} 200`, true, `total=${r.result?.total || 0}`); }
      else { failed++; c.check(`9.${fc.name} 200`, false, `code=${r.code}`); }
    }
  }

  // ============================================================
  // 10. SQL 注入 / 特殊字符
  // ============================================================
  console.log(`\n--- 特殊字符 ---`);
  const sqlCases = ["' OR '1'='1", '%test%', 'DROP', '<script>', '中文字符'];
  for (const sc of sqlCases) {
    const r = await c.api('GET', `${ENDPOINT}/list?bizType=${encodeURIComponent(sc)}&pageSize=10`);
    if (r.code === 200) { passed++; c.check(`10.特殊字符"${sc.slice(0, 12)}..." 200`, true); }
    else { failed++; c.check(`10.特殊字符"${sc.slice(0, 12)}..." 200`, false, `code=${r.code}`); }
  }

  // ============================================================
  // 11. 鉴权
  // ============================================================
  console.log(`\n--- 鉴权 ---`);
  const r11 = await fetch(BASE + ENDPOINT + '/list', { method: 'GET' });
  const r11j = await r11.json().catch(() => ({}));
  if (r11.status === 401 || r11j.code === 401) {
    passed++; c.check('11.1 无 token 401', true, `status=${r11.status} code=${r11j.code}`);
  } else {
    failed++; c.check('11.1 无 token 401', false);
  }

  return c.summary('ledger');
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(2); });
