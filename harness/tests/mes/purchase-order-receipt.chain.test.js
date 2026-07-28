// 链路测试: 采购订单 → 采购入库（真实 fixture 版，修复假ID破窗）
// 验证: 订单审核流转、部分/全部收货状态、超量拦截、台账记录
const { createClient } = require('../helpers/api');
const { createSupplier, createMaterial, createWarehouse, safeDeleteDoc, cleanupWarehouseScope } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();

async function run() {
  await c.login();
  console.log('✅ 登录成功\n');
  console.log('━━━ 链路测试: 采购订单 → 采购入库 ━━━\n');

  // Setup
  const sup = await createSupplier(c, TS);
  const wh = await createWarehouse(c, TS);
  const m1 = await createMaterial(c, `${TS}a`, '链路料A');
  const m2 = await createMaterial(c, `${TS}b`, '链路料B');
  console.log(`✅ fixture: 供应商/仓库/物料×2 就绪\n`);

  let orderId = null;
  const receiptIds = [];

  // Step 1: 创建订单
  console.log('Step 1: 创建订单');
  let r = await c.api('POST', '/mes/purchase/order/add', {
    code: 'CHAIN-RO-' + TS,
    supplierId: sup.id,
    orderDate: '2026-07-29',
    deliveryDate: '2026-07-30',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 100, unitPrice: 25.50, taxRate: 0.13 },
      { lineNo: 2, materialId: m2.id, quantity: 50, unitPrice: 10.00, taxRate: 0.06 },
    ],
  });
  c.check('创建订单', r.code === 200, r.message);
  const order = await c.findDoc('/mes/purchase/order/list', 'CHAIN-RO-' + TS);
  c.check('订单已出现在列表', !!order);
  c.check('[链路] 新订单状态=草稿(1)', order?.status === '1', `实际=${order?.status}`);
  orderId = order.id;

  // Step 2: 草稿订单入库应被拦截
  console.log('\nStep 2: 草稿订单入库应被拦截');
  r = await c.api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R1-' + TS,
    purchaseOrderId: orderId,
    supplierId: sup.id,
    warehouseId: wh.id,
    items: [{ lineNo: 1, materialId: m1.id, receiptQuantity: 10 }],
  });
  c.check('[链路] 草稿订单入库被拦截', r.code === 500 && (r.message || '').includes('状态不允许入库'), (r.message || '').substring(0, 40));

  // Step 3: 审核订单
  console.log('\nStep 3: 审核订单');
  r = await c.api('PUT', '/mes/purchase/order/audit?id=' + orderId);
  c.check('审核订单', r.code === 200, r.message);
  r = await c.api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  c.check('[链路] 审核后订单状态=已确认(3)', r.result?.status === '3', `实际=${r.result?.status}`);

  // Step 4: 部分收货（30+20）
  console.log('\nStep 4: 部分收货');
  r = await c.api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R2-' + TS,
    purchaseOrderId: orderId,
    supplierId: sup.id,
    warehouseId: wh.id,
    items: [
      { lineNo: 1, materialId: m1.id, receiptQuantity: 30 },
      { lineNo: 2, materialId: m2.id, receiptQuantity: 20 },
    ],
  });
  c.check('创建入库单', r.code === 200, r.message);
  const receipt = await c.findDoc('/mes/purchase/receipt/list', 'CHAIN-R2-' + TS);
  c.check('入库单已出现在列表', !!receipt);
  receiptIds.push(receipt.id);
  r = await c.api('PUT', '/mes/purchase/receipt/audit?id=' + receipt.id);
  c.check('审核入库单', r.code === 200, r.message);

  r = await c.api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  c.check('[链路] 部分收货后订单状态=部分到货(4)', r.result?.status === '4', `实际=${r.result?.status}`);
  const item1 = r.result?.items?.find(i => i.materialId === m1.id);
  c.check('[链路] m1已收货30', Number(item1?.receivedQty) === 30, `实际=${item1?.receivedQty}`);

  // Step 5: 超量入库应被拦截（30已收+80=110>100）
  console.log('\nStep 5: 超量入库应被拦截');
  r = await c.api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R3-' + TS,
    purchaseOrderId: orderId,
    supplierId: sup.id,
    warehouseId: wh.id,
    items: [{ lineNo: 1, materialId: m1.id, receiptQuantity: 80 }],
  });
  c.check('[链路] 超量被拦截(累计110>100)', r.code === 500 && (r.message || '').includes('超过采购数量'), (r.message || '').substring(0, 50));

  // Step 6: 补足剩余（70+30）
  console.log('\nStep 6: 补足剩余数量');
  r = await c.api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R4-' + TS,
    purchaseOrderId: orderId,
    supplierId: sup.id,
    warehouseId: wh.id,
    items: [
      { lineNo: 1, materialId: m1.id, receiptQuantity: 70 },
      { lineNo: 2, materialId: m2.id, receiptQuantity: 30 },
    ],
  });
  c.check('补足入库', r.code === 200, r.message);
  const receipt2 = await c.findDoc('/mes/purchase/receipt/list', 'CHAIN-R4-' + TS);
  if (receipt2) {
    receiptIds.push(receipt2.id);
    r = await c.api('PUT', '/mes/purchase/receipt/audit?id=' + receipt2.id);
    c.check('审核补足入库', r.code === 200, r.message);
  }

  r = await c.api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  c.check('[链路] 全部到货后订单状态=已到货(5)', r.result?.status === '5', `实际=${r.result?.status}`);

  // Step 7: 台账记录
  console.log('\nStep 7: 验证库存台账');
  r = await c.api('GET', `/mes/warehouse/ledger/list?pageNo=1&pageSize=50&warehouseId=${wh.id}`);
  const entries = (r.result?.records || []).filter(e => e.bizId === 'CHAIN-R2-' + TS || e.bizId === 'CHAIN-R4-' + TS);
  c.check('[链路] 台账有2笔入库记录', entries.length >= 2, `实际=${entries.length}`);

  // 清理
  console.log('\n━━━ 清理 ━━━');
  for (const rid of receiptIds) await safeDeleteDoc(c, '/mes/purchase/receipt', rid);
  await safeDeleteDoc(c, '/mes/purchase/order', orderId);
  await c.api('DELETE', `/mes/basic/supplier/delete?id=${sup.id}`);
  const dbOk = cleanupWarehouseScope(wh.id, null) && cleanupWarehouseScope(wh.id, m1.id);
  await c.api('DELETE', `/mes/basic/material/delete?id=${m1.id}`);
  await c.api('DELETE', `/mes/basic/material/delete?id=${m2.id}`);
  if (!dbOk) await c.api('DELETE', `/mes/basic/warehouse/delete?id=${wh.id}`);
  console.log('✅ 清理完成');

  return c.summary('链路: 订单→入库');
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(1); });
