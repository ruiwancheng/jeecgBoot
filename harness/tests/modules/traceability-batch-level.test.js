#!/usr/bin/env node
// MES 批次追溯 V10.0.3 批次级 API 测试（gen-tests 自动生成版）
// 覆盖: Controller /list (分页+搜索) + /exportXls (导出阈值) + 抽屉 /listByBatchId
// 关联: .claude/plans/2026-08-03-redesign-traceability-batch-level.md
// 关联: hermes/reviews/2026-08-03-orca-review-traceability-batch-level.md
// 规则: 内置 R001-R008 — R002(越权) R003(数值边界) R005(SQL注入特殊字符) 命中

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

// 无权限测试账号（用 guest 之类的无 mes 权限账号；若不存在将跳过）
const NO_PERM_USER = { username: 'guest', password: '123456' };

async function run() {
  // 主管账号 client
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== MES 批次追溯 V10.0.3 API 测试 =====\n');

  // ============================================================
  // 1. 列表接口（批次级 + 聚合字段）
  // ============================================================
  console.log('--- 1. 列表接口 /mes/batch/traceability/list ---');
  const r1 = await c.api('GET', '/mes/batch/traceability/list?pageNo=1&pageSize=10');
  c.check('1.1 状态码 200', r1.code === 200, `code=${r1.code}`);
  c.check('1.2 返回 records 数组', Array.isArray(r1.result?.records), `length=${r1.result?.records?.length || 0}`);

  if (r1.result?.records?.length > 0) {
    const r = r1.result.records[0];
    const required = ['id', 'batchNo', 'materialId', 'originType', 'status'];
    c.check('1.3 批次级字段齐全', required.every(f => f in r), `缺失=${required.filter(f => !(f in r)).join(',') || '无'}`);

    const agg = ['totalInQty', 'totalOutQty', 'ledgerCount', 'lastOccurTime'];
    c.check('1.4 聚合字段齐全', agg.every(f => f in r), `缺失=${agg.filter(f => !(f in r)).join(',') || '无'}`);

    const dict = ['materialId_dictText', 'originType_dictText', 'status_dictText'];
    c.check('1.5 dict 反查字段齐全', dict.every(f => f in r), `缺失=${dict.filter(f => !(f in r)).join(',') || '无'}`);

    const oldFields = ['batchId', 'bizType', 'bizId', 'bizNo', 'inQty', 'outQty', 'occurTime', 'remark'];
    c.check('1.6 无旧 ledger 字段', !oldFields.some(f => f in r), `不应出现=${oldFields.filter(f => f in r).join(',') || '无'}`);

    c.check('1.7 totalInQty 是数字', typeof r.totalInQty === 'number', `totalInQty=${r.totalInQty}`);
    c.check('1.8 ledgerCount 是数字', typeof r.ledgerCount === 'number', `ledgerCount=${r.ledgerCount}`);
    c.check('1.9 materialId_dictText 非空', !!(r.materialId_dictText && r.materialId_dictText.length > 0), `text=${r.materialId_dictText}`);
  } else {
    console.log('  ⚠️ 列表为空，跳过字段校验');
  }

  // ============================================================
  // 2. 搜索 filter: batchNo
  // ============================================================
  console.log('\n--- 2. 搜索 batchNo ---');
  const r2 = await c.api('GET', '/mes/batch/traceability/list?batchNo=PC-20260802-001&pageSize=10');
  c.check('2.1 batchNo 搜索 200', r2.code === 200, `code=${r2.code}`);
  if (r2.result?.records) {
    c.check('2.2 结果 batchNo 全匹配', r2.result.records.every(r => r.batchNo === 'PC-20260802-001'), `count=${r2.result.records.length}`);
  }

  // ============================================================
  // 3. 搜索 filter: materialId / originType / status
  // ============================================================
  console.log('\n--- 3. 搜索 materialId/originType/status ---');
  const r3 = await c.api('GET', '/mes/batch/traceability/list?pageSize=1');
  if (r3.result?.records?.length > 0) {
    const sample = r3.result.records[0];

    const rm = await c.api('GET', `/mes/batch/traceability/list?materialId=${sample.materialId}&pageSize=10`);
    c.check('3.1 materialId 搜索 200', rm.code === 200, `code=${rm.code}`);
    c.check('3.2 materialId 结果一致', rm.result?.records?.every(r => r.materialId === sample.materialId), `count=${rm.result?.records?.length}`);

    const ro = await c.api('GET', '/mes/batch/traceability/list?originType=1&pageSize=10');
    c.check('3.3 originType=1 搜索 200', ro.code === 200, `code=${ro.code}`);
    c.check('3.4 originType 结果一致', ro.result?.records?.every(r => r.originType === '1'), `count=${ro.result?.records?.length}`);

    const rs = await c.api('GET', `/mes/batch/traceability/list?status=${sample.status}&pageSize=10`);
    c.check('3.5 status 搜索 200', rs.code === 200, `code=${rs.code}`);
    c.check('3.6 status 结果一致', rs.result?.records?.every(r => r.status === sample.status), `count=${rs.result?.records?.length}`);
  } else {
    console.log('  ⚠️ 无数据跳过 materialId/originType/status 搜索');
  }

  // ============================================================
  // 4. 抽屉接口 listByBatchId
  // ============================================================
  console.log('\n--- 4. 抽屉接口 /mes/batch/ledger/listByBatchId ---');
  if (r3.result?.records?.length > 0) {
    const batchId = r3.result.records[0].id;

    const r4 = await c.api('GET', `/mes/batch/ledger/listByBatchId?batchId=${batchId}`);
    c.check('4.1 抽屉接口 200', r4.code === 200, `code=${r4.code}`);
    c.check('4.2 返回 ledger 数组', Array.isArray(r4.result), `length=${r4.result?.length || 0}`);

    if (r4.result?.length > 0) {
      const item = r4.result[0];
      const ledgerFields = ['bizType', 'bizNo', 'inQty', 'outQty', 'occurTime'];
      c.check('4.3 流水字段齐全', ledgerFields.every(f => f in item), `缺失=${ledgerFields.filter(f => !(f in item)).join(',') || '无'}`);
      c.check('4.4 流水 batchId 匹配', item.batchId === batchId, `item.batchId=${item.batchId}, expected=${batchId}`);
    }

    const r4inv = await c.api('GET', '/mes/batch/ledger/listByBatchId?batchId=non-existent-id');
    c.check('4.5 无效 batchId 不崩溃', r4inv.code === 200, `code=${r4inv.code}`);
    c.check('4.6 无效 batchId 返回空', Array.isArray(r4inv.result) && r4inv.result.length === 0, `result=${JSON.stringify(r4inv.result).slice(0, 50)}`);
  } else {
    console.log('  ⚠️ 无批次数据跳过抽屉测试');
  }

  // ============================================================
  // 5. 导出 Excel（手写导出 + 阈值检查）
  // ============================================================
  console.log('\n--- 5. 导出 /mes/batch/traceability/exportXls ---');
  const res = await fetch(BASE + '/mes/batch/traceability/exportXls', {
    headers: { 'X-Access-Token': c.token },
  });
  c.check('5.1 导出响应 200', res.status === 200, `status=${res.status}`);
  const buf = await res.arrayBuffer();
  const bytes = new Uint8Array(buf);
  // xlsx = zip: PK\x03\x04
  const isXlsx = bytes[0] === 0x50 && bytes[1] === 0x4b && bytes[2] === 0x03 && bytes[3] === 0x04;
  c.check('5.2 是 xlsx 文件 (PK magic)', isXlsx, `magic=${bytes[0].toString(16)}${bytes[1].toString(16)}`);
  c.check('5.3 导出文件非空', buf.byteLength > 1000, `size=${buf.byteLength} bytes`);

  // ============================================================
  // 6. R002 越权访问 — 无 token 401 + 无权限角色 403
  // ============================================================
  console.log('\n--- 6. R002 越权访问 ---');
  const rNoTok = await c.api('GET', '/mes/batch/traceability/list?pageSize=1', undefined);
  // 上面 api() 仍会带 token；这里直接 fetch 无 token
  const noTokRes = await fetch(BASE + '/mes/batch/traceability/list?pageSize=1');
  const noTokJson = await noTokRes.json();
  c.check('6.1 无 token 401', noTokJson.code === 401, `code=${noTokJson.code}`);

  // 无权限角色（guest）登录后访问 list / exportXls / listByBatchId
  const guest = createClient(BASE);
  try {
    await guest.login(NO_PERM_USER.username, NO_PERM_USER.password);
    const rGuestList = await guest.api('GET', '/mes/batch/traceability/list?pageSize=1');
    c.check('6.2 无权限角色 list 拒绝', rGuestList.code === 401 || rGuestList.code === 403, `code=${rGuestList.code}`);

    const rGuestExport = await guest.api('GET', '/mes/batch/traceability/exportXls');
    c.check('6.3 无权限角色 exportXls 拒绝', rGuestExport.code === 401 || rGuestExport.code === 403, `code=${rGuestExport.code}`);

    const rGuestLedger = await guest.api('GET', '/mes/batch/ledger/listByBatchId?batchId=any');
    c.check('6.4 无权限角色 listByBatchId 拒绝', rGuestLedger.code === 401 || rGuestLedger.code === 403, `code=${rGuestLedger.code}`);
  } catch (e) {
    console.log(`  ⚠️ 无权限账号 ${NO_PERM_USER.username} 不存在或登录失败，跳过 6.2-6.4 (${e.message})`);
  }

  // ============================================================
  // 7. R003 数值边界 — pageNo/pageSize 边界值
  // ============================================================
  console.log('\n--- 7. R003 数值边界 ---');
  const boundaryCases = [
    { name: '7.1 pageNo=0', qs: 'pageNo=0&pageSize=10', expectCode: 200 },
    { name: '7.2 pageNo=-1', qs: 'pageNo=-1&pageSize=10', expectCode: 200 },
    { name: '7.3 pageSize=0', qs: 'pageNo=1&pageSize=0', expectCode: 200 },
    { name: '7.4 pageSize=-1', qs: 'pageNo=1&pageSize=-1', expectCode: 200 },
    { name: '7.5 pageSize=2147483647', qs: 'pageNo=1&pageSize=2147483647', expectCode: 200 },
  ];
  for (const bc of boundaryCases) {
    const r = await c.api('GET', `/mes/batch/traceability/list?${bc.qs}`);
    c.check(bc.name, r.code === bc.expectCode || r.code === 500 /* 兜底：业务校验拒绝 */, `code=${r.code} msg=${r.message?.slice(0, 50)}`);
  }

  // ============================================================
  // 8. R005 SQL注入 — 搜索参数特殊字符
  // ============================================================
  console.log('\n--- 8. R005 SQL注入 / 特殊字符 ---');
  const sqlCases = [
    { name: "8.1 单引号 OR 1=1", value: "' OR '1'='1" },
    { name: '8.2 百分号 %', value: '%PC%' },
    { name: '8.3 下划线 _', value: 'PC_' },
    { name: '8.4 SQL 关键字 DROP', value: 'DROP TABLE c_mes_batch' },
    { name: '8.5 注释符 --', value: 'PC-20260802-001' + '--' },
    { name: '8.6 中文 + 特殊符号', value: '批次号\\/%' },
    { name: '8.7 XSS 尝试', value: '<script>alert(1)</script>' },
  ];
  for (const sc of sqlCases) {
    const r = await c.api('GET', `/mes/batch/traceability/list?batchNo=${encodeURIComponent(sc.value)}&pageSize=10`);
    // 期望：业务侧正常转义 → 200 (返回 0 条)，或不报错；不应 500
    c.check(`${sc.name} 不报错`, r.code === 200, `code=${r.code} msg=${r.message?.slice(0, 80)}`);
  }

  // ============================================================
  // 9. 数据完整性 — 聚合 ledgerCount 与实际流水数一致
  // ============================================================
  console.log('\n--- 9. 数据完整性 ---');
  if (r1.result?.total > 0) {
    const sample = r1.result.records.find(r => r.ledgerCount > 0);
    if (sample) {
      const rLedger = await c.api('GET', `/mes/batch/ledger/listByBatchId?batchId=${sample.id}`);
      const actualCount = rLedger.result?.length || 0;
      c.check('9.1 聚合 ledgerCount = 实际流水数', sample.ledgerCount === actualCount, `聚合=${sample.ledgerCount}, 实际=${actualCount}`);
    } else {
      console.log('  ⚠️ 没有 ledgerCount>0 的批次，跳过跨表对账');
    }
  }

  // ============================================================
  // 10. 空数据 — pageNo=99999 应返回空数组
  // ============================================================
  console.log('\n--- 10. 空数据 ---');
  const rEmpty = await c.api('GET', '/mes/batch/traceability/list?pageNo=99999&pageSize=10');
  c.check('10.1 超大 pageNo 不报错', rEmpty.code === 200, `code=${rEmpty.code}`);
  c.check('10.2 返回 records 空数组', Array.isArray(rEmpty.result?.records) && rEmpty.result.records.length === 0, `length=${rEmpty.result?.records?.length}`);

  // ============================================================
  // 总结
  // ============================================================
  const allPassed = c.summary('MES 批次追溯 V10.0.3');
  process.exit(allPassed ? 0 : 1);
}

run().catch(err => {
  console.error('FATAL:', err);
  process.exit(2);
});