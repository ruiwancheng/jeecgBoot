// 批次追溯 V10.0.3 批次级聚合 + Drawer 流程回归测试（锁定 commit cd91062 + 17f572b）
//
// 与 traceability-batch-level.test.js 的分工：
//   - traceability-batch-level.test.js：list/exportXls 端点结构 + 过滤 + 权限
//   - 本文件（aggregation）：聚合字段正确性 + 软删过滤 + Drawer 跨模块协作 + @Dict 字段回归
//
// 关联端点：
//   GET /mes/batch/traceability/list              ← 批次级聚合查询（listByBatchId 也在聚合计算内）
//   GET /mes/batch/master/list                    ← drawer 主档数据源
//   GET /mes/batch/ledger/listByBatchId?batchId=X ← drawer 流水数据源
//
// 5 维度 / 14 用例：
//   §1 Drawer 跨模块协作 (4)    master/list + ledger/listByBatchId 端点联调
//   §2 聚合字段正确性 (4)       totalInQty/totalOutQty/ledgerCount/lastOccurTime 数值准确
//   §3 软删 ledger 排除 (3)     del_flag=1 流水不计入聚合
//   §4 @Dict 字段值 (3)         materialId_dictText=code（不是 name）
//   §5 端点协作 + 异常 (4)      batchNo 模糊匹配 + 跨模块一致性
//
// 原则：每个测试独立 batchId（id 字段）+ finally 全清理（不留脏数据）

const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const { createClient } = require('../helpers/api');
const { createMaterial, createWarehouse, dbCleanup } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

/** SQL 直查辅助（用于验证聚合字段、软删过滤等 ORM 不易表达的场景） */
function sqlExec(sql) {
  const f = os.tmpdir() + `/trace-agg-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.sql`;
  try {
    fs.writeFileSync(f, sql, 'utf8');
    return execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -N < "${f}"`, { stdio: 'pipe' }).toString().trim();
  } finally {
    try { fs.unlinkSync(f); } catch (e) {}
  }
}

/** 创建一个完整的批次测试场景：warehouse + material + batch master + N 条 ledger
 *  返回 { batchId, batchNo, matId, whId, ledgerIds, cleanup SQL } */
async function setupBatchScenario(c, opts = {}) {
  // ID 长度限制：c_mes_batch_ledger.id / c_mes_batch.id 都是 varchar(32)。
  // 用短前缀 'tb'/'tl' + 13 位 ts + 6 位随机 = 22-23 字符，留余量。
  const ts = `${Date.now()}${Math.random().toString(36).slice(2, 8)}`;
  const batchId = `tb-${ts}`;
  const batchNo = `TRACE_AGG_${ts}`;
  const wh = await createWarehouse(c, ts, '聚合测试仓');
  const mat = await createMaterial(c, ts, '聚合测试料');

  // 1. 插批次主档（直接 SQL，避开 master.add 的复杂校验）
  dbCleanup(`
    INSERT INTO c_mes_batch (id, batch_no, material_id, origin_type, origin_bill_no, qty,
                             production_date, expiry_date, unit_cost, status,
                             create_by, create_time, del_flag)
    VALUES ('${batchId}', '${batchNo}', '${mat.id}', '1', 'TEST-${ts}', ${opts.qty || 100},
            CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 50, '1',
            'harness', NOW(), 0);
  `);

  // 2. 插 N 条 ledger（默认 2 条：1 条 in + 1 条 out）
  const ledgerIds = [];
  const ledgers = opts.ledgers || [
    { bizType: '1', bizNo: `IN-${ts}`, inQty: 100, outQty: 0 },
    { bizType: '2', bizNo: `OUT-${ts}`, inQty: 0, outQty: 30 },
  ];
  for (const l of ledgers) {
    const lid = `tl-${ts}-${ledgerIds.length}`;
    ledgerIds.push(lid);
    dbCleanup(`
      INSERT INTO c_mes_batch_ledger (id, batch_id, batch_no, material_id, warehouse_id,
                                      biz_type, biz_id, biz_no, in_qty, out_qty, unit_cost,
                                      occur_time, remark, create_by, create_time, del_flag)
      VALUES ('${lid}', '${batchId}', '${batchNo}', '${mat.id}', '${wh.id}',
              '${l.bizType}', 'biz-${ts}-${ledgerIds.length}', '${l.bizNo}',
              ${l.inQty}, ${l.outQty}, 50,
              '${l.occurTime || new Date().toISOString().slice(0, 19).replace('T', ' ')}',
              '${l.remark || ''}', 'harness', NOW(), 0);
    `);
  }

  return {
    batchId,
    batchNo,
    matId: mat.id,
    matCode: `MAT_T_${ts}`,
    whId: wh.id,
    ledgerIds,
    cleanup: `
      DELETE FROM c_mes_batch_ledger WHERE batch_id='${batchId}';
      DELETE FROM c_mes_batch WHERE id='${batchId}';
      DELETE FROM c_mes_inventory WHERE warehouse_id='${wh.id}';
      DELETE FROM c_mes_material WHERE id='${mat.id}';
      DELETE FROM c_mes_warehouse WHERE id='${wh.id}';
    `,
  };
}

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');
  const cleanups = [];

  try {
    // ============ §1 Drawer 跨模块协作（cd91062 回归）============
    console.log('\n--- §1 Drawer 跨模块协作 ---');

    const scn1 = await setupBatchScenario(c);
    cleanups.push(scn1.cleanup);

    // 1.1 listByBatchId 返回 ledger 数组
    const r11 = await c.api('GET', `/mes/batch/ledger/listByBatchId?batchId=${scn1.batchId}`);
    c.check('§1.1 listByBatchId 返回 ledger 数组', r11.code === 200 && Array.isArray(r11.result),
      `code=${r11.code} isArray=${Array.isArray(r11.result)}`);
    c.check('§1.1 listByBatchId 返回 2 条 ledger', r11.result?.length === 2,
      `length=${r11.result?.length}`);

    // 1.2 无效 batchId 返回空数组（不报错）
    const r12 = await c.api('GET', `/mes/batch/ledger/listByBatchId?batchId=NONEXISTENT_BATCH_ID`);
    c.check('§1.2 无效 batchId 不崩溃 + 返回空数组', r12.code === 200 && Array.isArray(r12.result) && r12.result.length === 0,
      `code=${r12.code} length=${r12.result?.length}`);

    // 1.3 master/list?id=X 返回批次主档（drawer 主档数据源）
    const r13 = await c.api('GET', `/mes/batch/master/list?id=${scn1.batchId}&pageSize=1`);
    c.check('§1.3 master/list 按 id 查单条主档', r13.code === 200 && r13.result?.records?.length === 1 && r13.result.records[0].batchNo === scn1.batchNo,
      `code=${r13.code} records=${r13.result?.records?.length} batchNo=${r13.result?.records?.[0]?.batchNo}`);

    // 1.4 三个端点协作：drawer 同时调 master/list + ledger/listByBatchId + traceability/list 都返回 200
    const r14a = await c.api('GET', `/mes/batch/master/list?id=${scn1.batchId}&pageSize=1`);
    const r14b = await c.api('GET', `/mes/batch/ledger/listByBatchId?batchId=${scn1.batchId}`);
    const r14c = await c.api('GET', `/mes/batch/traceability/list?batchNo=${scn1.batchNo}&pageSize=1`);
    c.check('§1.4 drawer 端点联调全 200',
      r14a.code === 200 && r14b.code === 200 && r14c.code === 200,
      `master=${r14a.code} ledger=${r14b.code} traceability=${r14c.code}`);

    // ============ §2 聚合字段正确性（核心业务）============
    console.log('\n--- §2 聚合字段正确性 ---');

    // 2.1 多 ledger 时 totalInQty = SUM(in_qty)
    const r21rec = r14c.result.records[0];
    const r21expected = 100; // setupBatchScenario 默认 1 条 in=100
    c.check('§2.1 totalInQty = SUM(in_qty)',
      Number(r21rec.totalInQty) === r21expected,
      `actual=${r21rec.totalInQty} expected=${r21expected}`);

    // 2.2 多 ledger 时 totalOutQty = SUM(out_qty)
    const r22expected = 30; // setupBatchScenario 默认 1 条 out=30
    c.check('§2.2 totalOutQty = SUM(out_qty)',
      Number(r21rec.totalOutQty) === r22expected,
      `actual=${r21rec.totalOutQty} expected=${r22expected}`);

    // 2.3 ledgerCount = COUNT(*) 含软删过滤（默认 2 条 ledger，del_flag=0）
    c.check('§2.3 ledgerCount = COUNT(non-deleted)',
      Number(r21rec.ledgerCount) === 2,
      `actual=${r21rec.ledgerCount} expected=2`);

    // 2.4 lastOccurTime = MAX(occur_time) of non-deleted ledgers
    const r24expected = await sqlExec(`SELECT MAX(occur_time) FROM c_mes_batch_ledger WHERE batch_id='${scn1.batchId}' AND del_flag=0;`);
    c.check('§2.4 lastOccurTime = MAX(occur_time)',
      r21rec.lastOccurTime && r21rec.lastOccurTime.includes(r24expected.slice(0, 10)),
      `api=${r21rec.lastOccurTime} db=${r24expected}`);

    // 2.5 batch with 0 ledger：LEFT JOIN 保留行，ledgerCount=0（关键回归）
    const scn2 = await setupBatchScenario(c, { ledgers: [] });
    cleanups.push(scn2.cleanup);
    const r25 = await c.api('GET', `/mes/batch/traceability/list?batchNo=${scn2.batchNo}&pageSize=1`);
    const r25rec = r25.result.records[0];
    c.check('§2.5 batch 0 ledger：仍出现在列表',
      r25.code === 200 && r25.result.records.length === 1,
      `code=${r25.code} records=${r25.result.records.length}`);
    c.check('§2.5 batch 0 ledger：ledgerCount=0',
      Number(r25rec.ledgerCount) === 0,
      `ledgerCount=${r25rec.ledgerCount}`);
    c.check('§2.5 batch 0 ledger：totalInQty/totalOutQty=0',
      Number(r25rec.totalInQty) === 0 && Number(r25rec.totalOutQty) === 0,
      `in=${r25rec.totalInQty} out=${r25rec.totalOutQty}`);

    // ============ §3 软删 ledger 排除（LEFT JOIN + del_flag）============
    console.log('\n--- §3 软删 ledger 排除 ---');

    // 3.1 软删 ledger 不计入 totalInQty / ledgerCount
    const scn3 = await setupBatchScenario(c, {
      ledgers: [
        { bizType: '1', bizNo: 'IN-A', inQty: 100, outQty: 0 },
        { bizType: '1', bizNo: 'IN-B-soft-deleted', inQty: 9999, outQty: 0 }, // 即将软删
      ],
    });
    cleanups.push(scn3.cleanup);
    // 软删第 2 条 ledger
    sqlExec(`UPDATE c_mes_batch_ledger SET del_flag=1 WHERE batch_id='${scn3.batchId}' AND biz_no='IN-B-soft-deleted';`);
    const r31 = await c.api('GET', `/mes/batch/traceability/list?batchNo=${scn3.batchNo}&pageSize=1`);
    const r31rec = r31.result.records[0];
    c.check('§3.1 软删 ledger 不计入 totalInQty',
      Number(r31rec.totalInQty) === 100,
      `actual=${r31rec.totalInQty} expected=100（9999 应被排除）`);
    c.check('§3.1 软删 ledger 不计入 ledgerCount',
      Number(r31rec.ledgerCount) === 1,
      `actual=${r31rec.ledgerCount} expected=1`);

    // 3.2 软删 ledger 不影响 lastOccurTime（应取 IN-A 的时间）
    const r32dbTime = await sqlExec(`SELECT occur_time FROM c_mes_batch_ledger WHERE batch_id='${scn3.batchId}' AND del_flag=0 ORDER BY occur_time DESC LIMIT 1;`);
    c.check('§3.2 lastOccurTime 跳过软删 ledger',
      r31rec.lastOccurTime && r31rec.lastOccurTime.includes(r32dbTime.slice(0, 10)),
      `api=${r31rec.lastOccurTime} expected contains=${r32dbTime.slice(0, 10)}`);

    // 3.3 软删 batch 主档不出现在 list
    sqlExec(`UPDATE c_mes_batch SET del_flag=1 WHERE id='${scn3.batchId}';`);
    const r33 = await c.api('GET', `/mes/batch/traceability/list?batchNo=${scn3.batchNo}&pageSize=10`);
    c.check('§3.3 软删 batch 主档不出现在 list',
      r33.result.records.length === 0,
      `records=${r33.result.records.length}`);
    // 复原软删状态（让 finally cleanup 能正常 DELETE，避免外键冲突）
    sqlExec(`UPDATE c_mes_batch SET del_flag=0 WHERE id='${scn3.batchId}';`);

    // ============ §4 @Dict 字段值（17f572b 回归）============
    console.log('\n--- §4 @Dict 字段值（dicText=code 回归）---');

    const scn4 = await setupBatchScenario(c);
    cleanups.push(scn4.cleanup);
    const r4 = await c.api('GET', `/mes/batch/traceability/list?batchNo=${scn4.batchNo}&pageSize=1`);
    const r4rec = r4.result.records[0];

    // 4.1 materialId_dictText = material.code（不是 name）
    const matCodeFromDb = await sqlExec(`SELECT code FROM c_mes_material WHERE id='${scn4.matId}';`);
    c.check('§4.1 materialId_dictText = code（dicText=code 回归）',
      r4rec.materialId_dictText === matCodeFromDb,
      `api=${r4rec.materialId_dictText} db code=${matCodeFromDb}`);

    // 4.2 originType_dictText 来自字典 mes_batch_origin_type
    c.check('§4.2 originType_dictText 非空且为中文',
      typeof r4rec.originType_dictText === 'string' && r4rec.originType_dictText.length > 0,
      `dictText=${r4rec.originType_dictText}`);

    // 4.3 status_dictText 来自字典 mes_batch_status
    c.check('§4.3 status_dictText 非空',
      typeof r4rec.status_dictText === 'string' && r4rec.status_dictText.length > 0,
      `dictText=${r4rec.status_dictText}`);

    // ============ §5 端点协作 + 异常（边界）============
    console.log('\n--- §5 端点协作 + 异常 ---');

    // 5.1 batchNo 模糊匹配（LIKE）正确：搜子串能命中
    const r51 = await c.api('GET', `/mes/batch/traceability/list?batchNo=${scn4.batchNo.slice(-10)}&pageSize=10`);
    c.check('§5.1 batchNo 模糊匹配（LIKE 子串命中）',
      r51.code === 200 && r51.result.records.some(r => r.id === scn4.batchId),
      `records=${r51.result.records.length} contains=${scn4.batchId}`);

    // 5.2 batchNo 完全不匹配 → 空数组
    const r52 = await c.api('GET', `/mes/batch/traceability/list?batchNo=NEVER_MATCH_99999_XYZ&pageSize=10`);
    c.check('§5.2 batchNo 完全不匹配 → 空',
      r52.code === 200 && r52.result.records.length === 0,
      `records=${r52.result.records.length}`);

    // 5.3 同一 batchId 在 master + traceability + ledger 都能查到
    const r53a = await c.api('GET', `/mes/batch/master/list?id=${scn4.batchId}&pageSize=1`);
    const r53b = await c.api('GET', `/mes/batch/traceability/list?batchNo=${scn4.batchNo}&pageSize=1`);
    const r53c = await c.api('GET', `/mes/batch/ledger/listByBatchId?batchId=${scn4.batchId}`);
    c.check('§5.3 跨模块一致性：同一 batchId 在 3 个端点都能查到',
      r53a.result.records.length === 1 &&
      r53b.result.records.length === 1 &&
      r53c.result.length === 2,
      `master=${r53a.result.records.length} traceability=${r53b.result.records.length} ledger=${r53c.result.length}`);

    // 5.4 跨模块 _dictText 一致性：traceability.list 的 materialId_dictText === master.list 的 materialId_dictText
    c.check('§5.4 跨模块 materialId_dictText 一致',
      r53a.result.records[0].materialId_dictText === r53b.result.records[0].materialId_dictText,
      `master=${r53a.result.records[0].materialId_dictText} traceability=${r53b.result.records[0].materialId_dictText}`);

  } finally {
    // 兜底清理所有测试场景
    for (const sql of cleanups) {
      dbCleanup(sql);
    }
  }

  process.exit(c.summary('批次追溯聚合 + Drawer 流程回归') ? 0 : 1);
}

run().catch((e) => { console.error('FATAL:', e); process.exit(2); });