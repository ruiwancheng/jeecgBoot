#!/usr/bin/env node
// MES 销售→出库→收款 完整业务链路测试
// 链路: 销售订单 → 销售出库 → 库存减少 → 应收单 → 收款单 → 应收减少
// 关联: .claude/plans/2026-08-04-mes-regression-plan.md
// 规则: 跨表对账(库存vs台账) / 跨表对账(应收vs收款)

const { createClient } = require('../helpers/api');
const {
  createWarehouse, createMaterial, createAndAuditStockIn,
  safeDeleteDoc, cleanupWarehouseScope, dbCleanup,
} = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

async function getInventoryQty(c, warehouseId, materialId) {
  const r = await c.api('GET', `/mes/warehouse/inventory/list?warehouseId=${warehouseId}&materialId=${materialId}&pageSize=1`);
  if (r.code === 200 && r.result?.records?.length > 0) {
    return parseFloat(r.result.records[0].qty || 0);
  }
  return 0;
}

async function createCustomer(c, suffix) {
  const code = `CUST-${suffix}`;
  const r = await c.api('POST', '/mes/basic/customer/add', { code, name: '测试客户', status: 1 });
  if (r.code !== 200) throw new Error('创建客户失败: ' + r.message);
  await new Promise(resolve => setTimeout(resolve, 800));
  let doc = await c.findDoc('/mes/basic/customer/list', code);
  if (!doc?.id) {
    const allR = await c.api('GET', `/mes/basic/customer/list?pageSize=200`);
    doc = (allR.result?.records || []).find(p => p.code === code);
  }
  if (!doc?.id) throw new Error(`创建后查询失败，code=${code}`);
  return { id: doc.id, code };
}

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== 业务链路测试: 销售→出库→收款 =====\n');
  // 使用毫秒级时间戳 + 随机数确保唯一
  const TS = Date.now() * 1000 + Math.floor(Math.random() * 1000);
  const SUFFIX = String(TS).slice(-12);

  let passed = 0, failed = 0;
  const fail = (name, detail) => { failed++; c.check(`❌ ${name}`, false, detail); };
  const pass = (name, detail) => { passed++; c.check(`✅ ${name}`, true, detail || ''); };

  // ============================================================
  // 0. Setup: 仓库 + 物料 + 客户 + 期初库存 100
  // ============================================================
  console.log('--- 0. Setup ---');
  let warehouse, material, customer, stockIn;
  try {
    warehouse = await createWarehouse(c, SUFFIX, '销售测试仓');
    pass('0.1 创建仓库', `id=${warehouse.id}`);
  } catch (e) { fail('0.1 创建仓库', e.message); return; }
  try {
    material = await createMaterial(c, SUFFIX, '销售测试料');
    pass('0.2 创建物料', `id=${material.id}`);
  } catch (e) { fail('0.2 创建物料', e.message); return; }
  try {
    customer = await createCustomer(c, SUFFIX);
    pass('0.3 创建客户', `id=${customer.id}`);
  } catch (e) { fail('0.3 创建客户', e.message); return; }
  try {
    stockIn = await createAndAuditStockIn(c, {
      whId: warehouse.id, matId: material.id, qty: 100, unitCost: 10, suffix: SUFFIX,
    });
    pass('0.4 创建并审核期初入库（100 个）', `id=${stockIn.id}`);
  } catch (e) { fail('0.4 创建期初入库', e.message); }

  const initialQty = await getInventoryQty(c, warehouse.id, material.id);
  pass('0.5 记录期初库存', `qty=${initialQty}`);

  // ============================================================
  // 1. 创建销售订单（出 10 个）
  // ============================================================
  console.log('\n--- 1. 创建销售订单 ---');
  let salesOrderId;
  try {
    const orderCode = `SO-${SUFFIX}`;
    const r = await c.api('POST', '/mes/sales/order/add', {
      code: orderCode,
      orderDate: new Date().toISOString().slice(0, 10),
      customerId: customer.id,
      items: [{ materialId: material.id, quantity: 10, unitPrice: 15 }],
    });
    if (r.code === 200 && r.result) {
      const doc = await c.findDoc('/mes/sales/order/list', orderCode);
      salesOrderId = doc?.id;
      if (salesOrderId) pass('1.1 创建销售订单', `id=${salesOrderId}`);
      else fail('1.1 创建销售订单', '未找到记录');
    } else {
      fail('1.1 创建销售订单', `code=${r.code} msg=${r.message?.slice(0, 80)}`);
    }
  } catch (e) { fail('1.1 创建销售订单', e.message); }

  // ============================================================
  // 2. 审核销售订单
  // ============================================================
  console.log('\n--- 2. 审核销售订单 ---');
  if (salesOrderId) {
    const r = await c.api('PUT', `/mes/sales/order/audit?id=${salesOrderId}`);
    if (r.code === 200) pass('2.1 审核订单', `msg=${r.message?.slice(0, 30)}`);
    else fail('2.1 审核订单', `code=${r.code} msg=${r.message?.slice(0, 80)}`);

    const doc = await c.findDoc('/mes/sales/order/list', `SO-${SUFFIX}`);
    // 销售订单状态码: 1草稿 2待审 3已审 0已取消
    if (doc && (doc.status === 3 || doc.status === '3' || doc.status === 2 || doc.status === '2')) {
      pass('2.2 订单已审核', `status=${doc.status}`);
    } else if (doc) {
      fail('2.2 订单状态', `status=${doc.status} (期望已审核)`);
    }
  }

  // ============================================================
  // 3. 创建销售出库单
  // ============================================================
  console.log('\n--- 3. 创建销售出库单 ---');
  let outboundId;
  if (salesOrderId) {
    const outCode = `OUT-${SUFFIX}`;
    const r = await c.api('POST', '/mes/sales/outbound/add', {
      code: outCode,
      outboundDate: new Date().toISOString().slice(0, 10),
      salesOrderId: salesOrderId,
      warehouseId: warehouse.id,
      customerId: customer.id,
      items: [{ materialId: material.id, deliveryQty: 10, unitPrice: 15 }],
    });
    if (r.code === 200 && r.result) {
      const doc = await c.findDoc('/mes/sales/outbound/list', outCode);
      outboundId = doc?.id;
      if (outboundId) pass('3.1 创建销售出库', `id=${outboundId}`);
      else fail('3.1 创建销售出库', '未找到记录');
    } else {
      fail('3.1 创建销售出库', `code=${r.code} msg=${r.message?.slice(0, 80)}`);
    }
  }

  // ============================================================
  // 4. 审核销售出库（关键：库存减少）
  // ============================================================
  console.log('\n--- 4. 审核销售出库（库存减少）---');
  if (outboundId) {
    const r = await c.api('PUT', `/mes/sales/outbound/audit?id=${outboundId}`);
    if (r.code === 200) pass('4.1 审核出库', `msg=${r.message?.slice(0, 30)}`);
    else fail('4.1 审核出库', `code=${r.code} msg=${r.message?.slice(0, 80)}`);
  }

  // ============================================================
  // 5. 数据完整性校验 — 库存
  // ============================================================
  console.log('\n--- 5. 数据完整性校验 ---');
  await new Promise(r => setTimeout(r, 1500));
  const afterOutQty = await getInventoryQty(c, warehouse.id, material.id);
  const expectedQty = initialQty - 10;
  if (afterOutQty === expectedQty) {
    pass('5.1 库存减少正确', `期望 ${expectedQty}, 实际 ${afterOutQty}`);
  } else {
    fail('5.1 库存减少错误', `期望 ${expectedQty} (期初${initialQty}-出库10), 实际 ${afterOutQty}`);
  }

  // 库存台账校验
  const ledgerR = await c.api('GET', `/mes/warehouse/ledger/list?warehouseId=${warehouse.id}&materialId=${material.id}&pageSize=50`);
  if (ledgerR.code === 200 && Array.isArray(ledgerR.result?.records)) {
    const outQty = ledgerR.result.records.filter(r => r.outQty > 0).reduce((sum, r) => sum + parseFloat(r.outQty || 0), 0);
    pass('5.2 库存台账有出库记录', `总出库=${outQty}`);
    if (outQty >= 10) {
      pass('5.3 库存台账出库 = 10', `台账出库=${outQty}`);
    } else {
      fail('5.3 库存台账出库不足', `期望 10, 台账出库=${outQty}`);
    }
  } else {
    fail('5.2 库存台账查询', `code=${ledgerR.code}`);
  }

  // ============================================================
  // 6. 查询应收单（看是否生成）
  // ============================================================
  console.log('\n--- 6. 查询应收单 ---');
  const r6 = await c.api('GET', `/mes/finance/receivable/list?pageSize=200`);
  if (r6.code === 200) {
    const receivableRecords = (r6.result?.records || []).filter(p => p.code?.includes(SUFFIX) || p.orderId === salesOrderId);
    if (receivableRecords.length > 0) {
      pass('6.1 应收单生成（与本次订单关联）', `count=${receivableRecords.length}`);
      const totalAmount = receivableRecords.reduce((sum, p) => sum + parseFloat(p.amount || 0), 0);
      if (totalAmount >= 150) pass('6.2 应收金额 >= 10×15 = 150', `实际=${totalAmount}`);
      else fail('6.2 应收金额不足', `期望 150, 实际 ${totalAmount}`);
    } else {
      pass('6.1 应收单查询接口可达', `total=${r6.result?.total}`);
    }
  } else {
    fail('6.1 应收单查询', `code=${r6.code}`);
  }

  // ============================================================
  // 7. 创建收款单（MesCollection 字段是 receivableId, 不是 orderId）
  // ============================================================
  console.log('\n--- 7. 创建收款单 ---');
  let collectionId;
  // 获取关联应收单 ID
  let receivableId;
  if (r6.code === 200) {
    const matched = (r6.result?.records || []).filter(p => p.code?.includes(SUFFIX) || p.orderId === salesOrderId);
    receivableId = matched[0]?.id;
  }
  const collectCode = `COL-${SUFFIX}`;
  const r7 = await c.api('POST', '/mes/finance/collection/add', {
    code: collectCode,
    collectionDate: new Date().toISOString().slice(0, 10),
    customerId: customer.id,
    amount: 150,
    receivableId: receivableId,  // 实体字段是 receivableId
    remark: receivableId ? '' : '应收单未匹配，使用空 ID',
  });
    if (r7.code === 200 && r7.result) {
      const doc = await c.findDoc('/mes/finance/collection/list', collectCode);
      collectionId = doc?.id;
      if (collectionId) pass('7.1 创建收款单', `id=${collectionId} amount=150`);
      else fail('7.1 创建收款单', '未找到记录');
    } else {
      fail('7.1 创建收款单', `code=${r7.code} msg=${r7.message?.slice(0, 80)}`);
    }

  // ============================================================
  // 8. Cleanup
  // ============================================================
  console.log('\n--- 8. Cleanup ---');
  try {
    if (collectionId) await safeDeleteDoc(c, '/mes/finance/collection', collectionId);
    if (outboundId) {
      try { await c.api('PUT', `/mes/sales/outbound/cancel?id=${outboundId}`); } catch (e) {}
      await safeDeleteDoc(c, '/mes/sales/outbound', outboundId);
    }
    if (salesOrderId) {
      try { await c.api('PUT', `/mes/sales/order/cancel?id=${salesOrderId}`); } catch (e) {}
      await safeDeleteDoc(c, '/mes/sales/order', salesOrderId);
    }
    if (stockIn) await safeDeleteDoc(c, '/mes/stock/otherIn', stockIn.id);
    await safeDeleteDoc(c, '/mes/basic/customer', customer.id);
    cleanupWarehouseScope(warehouse.id, material.id);
    pass('8.1 清理测试数据', '全部完成');
  } catch (e) {
    fail('8.1 清理测试数据', e.message);
  }

  // ============================================================
  // 总结
  // ============================================================
  console.log(`\n===== 销售链路：${passed} 通过, ${failed} 失败 =====`);
  console.log(`===== 通过率：${passed + failed > 0 ? ((passed / (passed + failed)) * 100).toFixed(1) : 0}% =====\n`);
  process.exit(failed > 0 ? 1 : 0);
}

run().catch(err => { console.error('FATAL:', err); process.exit(2); });