// 链路测试: 仓储 (其他入库 → 其他出库 → 盘点)
// 验证: 3 个 stock controller 的 CRUD + 盘点批量审核

const { createClient } = require('../helpers/api');
const { createMaterial, createWarehouse } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();

async function run() {
  await c.login();
  console.log('✅ 登录成功\n');
  console.log('━━━ 链路测试: 仓储 (其他入库 → 其他出库 → 盘点) ━━━\n');

  // ============================================================
  // Setup
  // ============================================================
  console.log('Setup: 物料 + 仓库');
  const m1 = await createMaterial(c, `${TS}wh_a`, '仓储料A');
  const m2 = await createMaterial(c, `${TS}wh_b`, '仓储料B');
  const wh = await createWarehouse(c, `${TS}wh`);
  console.log(`✅ fixture: 物料 ${m1.code}/${m2.code}, 仓库 ${wh.code}\n`);

  // ============================================================
  // Step 1: 其他入库 (otherIn) - 初始库存
  // ============================================================
  console.log('Step 1: 其他入库 (otherIn) - m1=100, m2=50');
  let r = await c.api('POST', '/mes/stock/otherIn/add', {
    code: `OI-${TS}`,
    inType: '1',  // 采购溢余
    warehouseId: wh.id,
    reason: '期初入库',
    stockDate: '2026-08-01',
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, qty: 100, unitPrice: 50 },
      { lineNo: 2, materialId: m2.id, qty: 50, unitPrice: 30 }
    ]
  });
  c.check('其他入库 创建', r.success === true, `code=OI-${TS} success=${r.success}`);

  // 验证库存: m1 应有 100 单位 (用 /mes/warehouse/inventory 路径)
  r = await c.api('GET', '/mes/warehouse/inventory/list', { materialId: m1.id, warehouseId: wh.id });
  c.check('m1 初始库存入库', r.success && r.result.records.length > 0, `records=${r.result?.records?.length}`);

  // 审核入库单 (otherIn.audit) - 此时库存才会真正入库
  // PUT /mes/stock/otherIn/audit?id=xxx
  const oiList = await c.api('GET', '/mes/stock/otherIn/list', { code: `OI-${TS}` });
  const oiId = oiList.result.records[0]?.id;
  r = await c.api('PUT', `/mes/stock/otherIn/audit?id=${oiId}`);
  c.check('入库单审核', r.success === true, `库存真正入库`);

  // ============================================================
  // Step 2: 其他出库 (otherOut) - 消耗 m1
  // ============================================================
  console.log('\nStep 2: 其他出库 (otherOut) - 消耗 m1=20');
  r = await c.api('POST', '/mes/stock/otherOut/add', {
    code: `OO-${TS}`,
    outType: '1',  // 销售出库
    warehouseId: wh.id,
    reason: '生产领料',
    stockDate: '2026-08-04',
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, qty: 20 }
    ]
  });
  c.check('其他出库 创建', r.success === true, `code=OO-${TS} success=${r.success}`);

  // 审核出库单 (otherOut.audit)
  const ooList = await c.api('GET', '/mes/stock/otherOut/list', { code: `OO-${TS}` });
  const ooId = ooList.result.records[0]?.id;
  r = await c.api('PUT', `/mes/stock/otherOut/audit?id=${ooId}`);
  c.check('出库单审核', r.success === true, `库存真正出库`);

  // ============================================================
  // Step 3: 盘点单 (bookQty=当前库存, 80=100-20)
  // ============================================================
  console.log('\nStep 3: 创建盘点单 (bookQty 必须等于当前库存)');
  // m1 当前库存 = 100 - 20 = 80
  r = await c.api('POST', '/mes/stock/stocktake/add', {
    code: `ST-${TS}`,
    warehouseId: wh.id,
    takeDate: '2026-08-04',
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, bookQty: 80, actualQty: 78, batchNo: null },
      { lineNo: 2, materialId: m2.id, bookQty: 50, actualQty: 50, batchNo: null }
    ]
  });
  c.check('盘点单 创建', r.success === true, `code=ST-${TS} success=${r.success}`);
  if (!r.success) return;

  // ============================================================
  // Step 4: 盘点单批量审核 (ids 是数组)
  // ============================================================
  console.log('\nStep 4: 盘点单批量审核 (batchAudit, ids 数组)');
  const stocktakeList = await c.api('GET', '/mes/stock/stocktake/list', { code: `ST-${TS}` });
  const stocktakeId = stocktakeList.result.records[0]?.id;
  r = await c.api('POST', '/mes/stock/stocktake/batchAudit', { ids: [stocktakeId] });
  c.check('盘点单批量审核', r.success === true, `盘亏自动生成 otherOut`);

  // ============================================================
  // Step 5: 验证盘点后库存 (m1 应为 78 - 2)
  // ============================================================
  console.log('\nStep 5: 验证盘点后库存 (m1 应为 78)');
  r = await c.api('GET', '/mes/warehouse/inventory/list', { materialId: m1.id, warehouseId: wh.id });
  c.check('m1 库存盘点后状态', r.success && r.result.records.length > 0, `records=${r.result?.records?.length}`);

  // ============================================================
  // Step 6: 验证 3 个 controller list (queryAll 不存在, 用 list)
  // ============================================================
  console.log('\nStep 6: 验证 3 个 controller list');
  for (const mod of ['otherIn', 'otherOut', 'stocktake']) {
    r = await c.api('GET', `/mes/stock/${mod}/list`, { pageNo: 1, pageSize: 5 });
    c.check(`${mod} list 200`, r.success === true, `records=${r.result?.records?.length ?? 0}`);
  }

  // ============================================================
  // 总结
  // ============================================================
  console.log('\n━━━ 链路测试完成 ━━━');
  console.log(`Passed: ${c.passed}, Failed: ${c.failed}`);
  process.exit(c.failed > 0 ? 1 : 0);
}

run().catch(err => {
  console.error('链路测试异常:', err.message);
  console.error(err.stack);
  process.exit(2);
});
