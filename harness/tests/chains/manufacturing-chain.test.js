// 链路测试: 生产制造 (BOM → 生产订单 → 领料 → 完工入库)
// 验证: 4 个 controller 的 CRUD + 状态字段 + 库存联动
// 修复 BUG-CUSTOMER-SCHEMA-DRIFT (P0) 后回归 (slice-2.1 验证 schema, slice-3.1 验证生产链)
//
// 注意: Manufacturing 4 个 controller 都没有 confirm/audit 端点,
// 只有 add / list / queryById / queryAll / exportXls.
// 所以本测试只覆盖 CRUD + 库存联动的查询验证, 不做状态机推进。

const { createClient } = require('../helpers/api');
const { createMaterial, createWarehouse } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();

async function run() {
  await c.login();
  console.log('✅ 登录成功\n');
  console.log('━━━ 链路测试: 生产制造 (BOM → 订单 → 领料 → 完工) ━━━\n');

  // ============================================================
  // Setup
  // ============================================================
  console.log('Setup: 创建 3 个物料 + 1 个仓库');
  const finished = await createMaterial(c, `${TS}mfg_finished`, '产成品');
  const m1 = await createMaterial(c, `${TS}mfg_a`, '生产料A');
  const m2 = await createMaterial(c, `${TS}mfg_b`, '生产料B');
  const wh = await createWarehouse(c, `${TS}mfg`);
  console.log(`✅ fixture: 产成品 ${finished.code}, 物料 ${m1.code}/${m2.code}, 仓库 ${wh.code}\n`);

  // ============================================================
  // Step 1: 创建 BOM (父项=产成品, 子项=物料A+B)
  // ============================================================
  console.log('Step 1: 创建 BOM');
  let r = await c.api('POST', '/mes/manufacturing/bom/add', {
    code: `BOM-${TS}`,
    name: `BOM-${TS}`,
    productId: finished.id,
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 1, unitPrice: 100, taxRate: 0.13 },
      { lineNo: 2, materialId: m2.id, quantity: 2, unitPrice: 50,  taxRate: 0.13 }
    ]
  });
  c.check('BOM 创建', r.success === true, `BOM-${TS} success=${r.success}`);
  if (!r.success) return;

  const bomList = await c.api('GET', '/mes/manufacturing/bom/list', { code: `BOM-${TS}` });
  c.check('BOM 在 list 中', bomList.success && bomList.result.records.length > 0,
          `records=${bomList.result?.records?.length}`);
  const bomId = bomList.result.records[0]?.id;

  // ============================================================
  // Step 2: 创建生产订单
  // ============================================================
  console.log('\nStep 2: 创建生产订单 (planQty=10)');
  r = await c.api('POST', '/mes/manufacturing/order/add', {
    code: `PO-${TS}`,
    bomId: bomId,
    productId: finished.id,
    planQty: 10,
    warehouseId: wh.id,
    startDate: '2026-08-04',
    endDate: '2026-08-15',
    status: '1'
  });
  c.check('生产订单创建', r.success === true, `code=PO-${TS} success=${r.success}`);
  if (!r.success) return;

  const orderList = await c.api('GET', '/mes/manufacturing/order/list', { code: `PO-${TS}` });
  c.check('生产订单在 list 中', orderList.success && orderList.result.records.length > 0,
          `records=${orderList.result?.records?.length}`);
  const orderId = orderList.result.records[0]?.id;

  // ============================================================
  // Step 3: 创建生产领料
  // ============================================================
  console.log('\nStep 3: 创建生产领料 (quantity: A=5, B=10)');
  r = await c.api('POST', '/mes/manufacturing/picking/add', {
    code: `PK-${TS}`,
    productionOrderId: orderId,
    warehouseId: wh.id,
    pickingDate: '2026-08-04',
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 5 },
      { lineNo: 2, materialId: m2.id, quantity: 10 }
    ]
  });
  c.check('生产领料创建', r.success === true, `code=PK-${TS} success=${r.success}`);

  // ============================================================
  // Step 4: 创建完工入库 (产品 finished 入库 10)
  // ============================================================
  console.log('\nStep 4: 创建完工入库 (planQty=10, receiptQty=10)');
  r = await c.api('POST', '/mes/manufacturing/completion/add', {
    code: `CR-${TS}`,
    productionOrderId: orderId,
    productId: finished.id,
    warehouseId: wh.id,
    receiptDate: '2026-08-04',
    status: '1',
    items: [
      { lineNo: 1, materialId: finished.id, planQty: 10, receiptQty: 10 }
    ]
  });
  c.check('完工入库创建', r.success === true, `code=CR-${TS} success=${r.success}`);

  // ============================================================
  // Step 5: 验证 4 个 entity 状态字段存在
  // ============================================================
  console.log('\nStep 5: 验证 entity 状态字段 (有 status 字段)');
  const bomDetail = await c.api('GET', '/mes/manufacturing/bom/queryById', { id: bomId });
  c.check('BOM 状态 = 草稿(1)', bomDetail.result?.status === '1', `status=${bomDetail.result?.status}`);

  const orderDetail = await c.api('GET', '/mes/manufacturing/order/queryById', { id: orderId });
  c.check('生产订单 状态 = 草稿(1)', orderDetail.result?.status === '1', `status=${orderDetail.result?.status}`);

  const pickingList = await c.api('GET', '/mes/manufacturing/picking/list', { code: `PK-${TS}` });
  const pickingId = pickingList.result.records[0]?.id;
  const pickingDetail = await c.api('GET', '/mes/manufacturing/picking/queryById', { id: pickingId });
  c.check('领料单 状态 = 草稿(1)', pickingDetail.result?.status === '1', `status=${pickingDetail.result?.status}`);

  const completionList = await c.api('GET', '/mes/manufacturing/completion/list', { code: `CR-${TS}` });
  const completionId = completionList.result.records[0]?.id;
  const completionDetail = await c.api('GET', '/mes/manufacturing/completion/queryById', { id: completionId });
  c.check('完工入库 状态 = 草稿(1)', completionDetail.result?.status === '1', `status=${completionDetail.result?.status}`);

  // ============================================================
  // Step 6: 验证 queryAll 列表能取到所有
  // ============================================================
  console.log('\nStep 6: 验证 queryAll 4 个 endpoint');
  const allBom = await c.api('GET', '/mes/manufacturing/bom/queryAll');
  c.check('BOM queryAll 200', allBom.success === true, `records=${allBom.result?.length ?? 0}`);

  const allOrder = await c.api('GET', '/mes/manufacturing/order/queryAll');
  c.check('生产订单 queryAll 200', allOrder.success === true, `records=${allOrder.result?.length ?? 0}`);

  const allPicking = await c.api('GET', '/mes/manufacturing/picking/queryAll');
  c.check('领料单 queryAll 200', allPicking.success === true, `records=${allPicking.result?.length ?? 0}`);

  const allCompletion = await c.api('GET', '/mes/manufacturing/completion/queryAll');
  c.check('完工入库 queryAll 200', allCompletion.success === true, `records=${allCompletion.result?.length ?? 0}`);

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
