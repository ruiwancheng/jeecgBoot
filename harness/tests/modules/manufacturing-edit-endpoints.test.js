// 生产链路 /edit + /generatePicking 测试补齐 — slice-8
// 覆盖 5 端点：
//   1. PUT /mes/manufacturing/bom/edit       — MesBom（含 items）
//   2. PUT /mes/manufacturing/order/edit     — MesProductionOrder
//   3. PUT /mes/manufacturing/picking/edit   — MesProductionPicking（含 items）
//   4. PUT /mes/manufacturing/completion/edit — MesCompletionReceipt（含 items）
//   5. POST /mes/manufacturing/order/generatePicking — 仅已下达(status=3)订单可调用
//
// 模式：edit 走 queryById→edit→queryById 验证回写；generatePicking 走状态机守卫验证
// 每个端点 2-3 断言，generatePicking 4 断言，总共 12-15 断言

const { createClient } = require('../helpers/api');
const {
  createMaterial, createWarehouse, createAndAuditStockIn,
  dbCleanup,
} = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();

// 收集测试数据用于清理
const COLLECT = {
  boms: [], orders: [], pickings: [], completions: [],
  materials: [], warehouses: [],
};

/** 反查 BOM 明细 */
async function getBomDetail(id) {
  const r = await c.api('GET', `/mes/manufacturing/bom/queryById?id=${id}`);
  return r.result;
}

/** 反查订单明细 */
async function getOrderDetail(id) {
  const r = await c.api('GET', `/mes/manufacturing/order/queryById?id=${id}`);
  return r.result;
}

/** 反查领料单明细 */
async function getPickingDetail(id) {
  const r = await c.api('GET', `/mes/manufacturing/picking/queryById?id=${id}`);
  return r.result;
}

/** 反查完工入库明细 */
async function getCompletionDetail(id) {
  const r = await c.api('GET', `/mes/manufacturing/completion/queryById?id=${id}`);
  return r.result;
}

/** 创建 BOM（草稿） */
async function createDraftBom({ code, productId, childMatId }) {
  const add = await c.api('POST', '/mes/manufacturing/bom/add', {
    code, productId, version: 'V1-' + TS, status: '1', remark: 'slice-8',
    items: [{ lineNo: 1, materialId: childMatId, quantity: 1, lossRate: 0 }],
  });
  if (add.code !== 200) throw new Error(`BOM add 失败: ${add.message}`);
  const doc = await c.findDoc('/mes/manufacturing/bom/list', code);
  return { id: doc?.id, code };
}

/** 创建订单（草稿） */
async function createDraftOrder({ code, bomId, productId, warehouseId, planQty = 10 }) {
  const add = await c.api('POST', '/mes/manufacturing/order/add', {
    code, bomId, productId, warehouseId,
    planQty, startDate: '2026-08-08', endDate: '2026-09-08',
    status: '1', remark: 'slice-8',
  });
  if (add.code !== 200) throw new Error(`订单 add 失败: ${add.message}`);
  const doc = await c.findDoc('/mes/manufacturing/order/list', code);
  return { id: doc?.id, code };
}

/** 创建领料单（草稿） */
async function createDraftPicking({ code, orderId, warehouseId, productId }) {
  const add = await c.api('POST', '/mes/manufacturing/picking/add', {
    code, productionOrderId: orderId, warehouseId, status: '1', remark: 'slice-8',
    items: [{ lineNo: 1, materialId: productId, quantity: 1 }],
  });
  if (add.code !== 200) throw new Error(`领料 add 失败: ${add.message}`);
  const doc = await c.findDoc('/mes/manufacturing/picking/list', code);
  return { id: doc?.id, code };
}

/** 创建完工入库单（草稿） */
async function createDraftCompletion({ code, orderId, productId, warehouseId }) {
  const add = await c.api('POST', '/mes/manufacturing/completion/add', {
    code, productionOrderId: orderId, productId, warehouseId, status: '1', remark: 'slice-8',
    items: [{ lineNo: 1, materialId: productId, planQty: 10, receiptQty: 5 }],
  });
  if (add.code !== 200) throw new Error(`完工入库 add 失败: ${add.message}`);
  const doc = await c.findDoc('/mes/manufacturing/completion/list', code);
  return { id: doc?.id, code };
}

(async () => {
  await c.login('admin', '123456');
  console.log(`✅ 登录成功\n`);

  // ============================================================
  // Setup: 1 产成品 + 1 子件 + 1 仓库 + 期初库存
  // ============================================================
  console.log('━━━ Setup: 1 产成品 + 1 子件 + 1 仓库 + 期初库存 ━━━');
  const finished = await createMaterial(c, `${TS}f`, '切片8产成品');
  COLLECT.materials.push(finished.id);
  const child = await createMaterial(c, `${TS}c`, '切片8子件');
  COLLECT.materials.push(child.id);
  const wh = await createWarehouse(c, `${TS}`, '切片8仓');
  COLLECT.warehouses.push(wh.id);
  await createAndAuditStockIn(c, { whId: wh.id, matId: child.id, qty: 100, unitCost: 10, suffix: `${TS}s` });
  console.log(`✅ fixture: ${finished.code} / ${child.code} / ${wh.code}\n`);

  // ============================================================
  // 端点 1: PUT /mes/manufacturing/bom/edit — MesBom（含 items）
  // ============================================================
  console.log('━━━ 端点 1: PUT /mes/manufacturing/bom/edit ━━━');
  const bom1 = await createDraftBom({
    code: `BOM_E_${TS}`, productId: finished.id, childMatId: child.id,
  });
  COLLECT.boms.push(bom1.id);

  // 1.1 edit 更新 remark + items 子项 quantity → 应 200
  const bom1Detail = await getBomDetail(bom1.id);
  const bomEdit = await c.api('PUT', '/mes/manufacturing/bom/edit', {
    id: bom1.id,
    code: bom1Detail.code,
    productId: bom1Detail.productId,
    version: bom1Detail.version,
    status: bom1Detail.status,
    remark: 'EDITED-' + TS,
    items: [{ lineNo: 1, materialId: child.id, quantity: 99, lossRate: 5 }],
  });
  c.check('[1.1] BOM edit OK', bomEdit.code === 200, `code=${bomEdit.code} msg=${bomEdit.message}`);

  // 1.2 queryById 验证 remark 已更新
  const bom1After = await getBomDetail(bom1.id);
  c.check('[1.2] BOM remark 持久化生效',
    bom1After?.remark === 'EDITED-' + TS, `actual=${bom1After?.remark}`);

  // 1.3 queryById 验证 items 子项 quantity 已更新
  const item1 = bom1After?.items?.[0];
  c.check('[1.3] BOM items 子项 quantity 持久化生效',
    item1 && Number(item1.quantity) === 99, `actual=${item1?.quantity}`);

  // 1.4 approve BOM（订单 audit 守卫要求 BOM 已生效）
  const bomApprove = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bom1.id}`);
  c.check('[1.4] BOM approve OK', bomApprove.code === 200, `code=${bomApprove.code} msg=${bomApprove.message}`);

  // ============================================================
  // 端点 2: PUT /mes/manufacturing/order/edit — MesProductionOrder
  // ============================================================
  console.log('\n━━━ 端点 2: PUT /mes/manufacturing/order/edit ━━━');
  const order2 = await createDraftOrder({
    code: `ORD_E_${TS}`, bomId: bom1.id, productId: finished.id, warehouseId: wh.id, planQty: 50,
  });
  COLLECT.orders.push(order2.id);

  // 2.1 edit 更新 planQty + remark → 应 200
  const order2Detail = await getOrderDetail(order2.id);
  const orderEdit = await c.api('PUT', '/mes/manufacturing/order/edit', {
    id: order2.id,
    code: order2Detail.code,
    productId: order2Detail.productId,
    bomId: order2Detail.bomId,
    warehouseId: order2Detail.warehouseId,
    planQty: 222,
    status: order2Detail.status,
    remark: 'EDITED-' + TS,
  });
  c.check('[2.1] Order edit OK', orderEdit.code === 200, `code=${orderEdit.code} msg=${orderEdit.message}`);

  // 2.2 queryById 验证 planQty 已更新
  const order2After = await getOrderDetail(order2.id);
  c.check('[2.2] Order planQty 持久化生效',
    Number(order2After?.planQty) === 222, `actual=${order2After?.planQty}`);

  // 2.3 queryById 验证 remark 已更新
  c.check('[2.3] Order remark 持久化生效',
    order2After?.remark === 'EDITED-' + TS, `actual=${order2After?.remark}`);

  // ============================================================
  // 端点 3: PUT /mes/manufacturing/picking/edit — MesProductionPicking（含 items）
  // ============================================================
  console.log('\n━━━ 端点 3: PUT /mes/manufacturing/picking/edit ━━━');
  const pick3 = await createDraftPicking({
    code: `PK_E_${TS}`, orderId: order2.id, warehouseId: wh.id, productId: child.id,
  });
  COLLECT.pickings.push(pick3.id);

  // 3.1 edit 更新 remark + items.quantity → 应 200
  const pick3Detail = await getPickingDetail(pick3.id);
  const pickEdit = await c.api('PUT', '/mes/manufacturing/picking/edit', {
    id: pick3.id,
    code: pick3Detail.code,
    productionOrderId: pick3Detail.productionOrderId,
    warehouseId: pick3Detail.warehouseId,
    status: pick3Detail.status,
    remark: 'EDITED-' + TS,
    items: [{ lineNo: 1, materialId: child.id, quantity: 77 }],
  });
  c.check('[3.1] Picking edit OK', pickEdit.code === 200, `code=${pickEdit.code} msg=${pickEdit.message}`);

  // 3.2 queryById 验证 remark 已更新
  const pick3After = await getPickingDetail(pick3.id);
  c.check('[3.2] Picking remark 持久化生效',
    pick3After?.remark === 'EDITED-' + TS, `actual=${pick3After?.remark}`);

  // 3.3 queryById 验证 items 子项 quantity 已更新
  const pickItem3 = pick3After?.items?.[0];
  c.check('[3.3] Picking items 子项 quantity 持久化生效',
    pickItem3 && Number(pickItem3.quantity) === 77, `actual=${pickItem3?.quantity}`);

  // ============================================================
  // 端点 4: PUT /mes/manufacturing/completion/edit — MesCompletionReceipt（含 items）
  // ============================================================
  console.log('\n━━━ 端点 4: PUT /mes/manufacturing/completion/edit ━━━');
  const cpl4 = await createDraftCompletion({
    code: `CR_E_${TS}`, orderId: order2.id, productId: finished.id, warehouseId: wh.id,
  });
  COLLECT.completions.push(cpl4.id);

  // 4.1 edit 更新 remark + items.receiptQty → 应 200
  const cpl4Detail = await getCompletionDetail(cpl4.id);
  const cplEdit = await c.api('PUT', '/mes/manufacturing/completion/edit', {
    id: cpl4.id,
    code: cpl4Detail.code,
    productionOrderId: cpl4Detail.productionOrderId,
    productId: cpl4Detail.productId,
    warehouseId: cpl4Detail.warehouseId,
    status: cpl4Detail.status,
    remark: 'EDITED-' + TS,
    items: [{ lineNo: 1, materialId: finished.id, planQty: 10, receiptQty: 8 }],
  });
  c.check('[4.1] Completion edit OK', cplEdit.code === 200, `code=${cplEdit.code} msg=${cplEdit.message}`);

  // 4.2 queryById 验证 remark 已更新
  const cpl4After = await getCompletionDetail(cpl4.id);
  c.check('[4.2] Completion remark 持久化生效',
    cpl4After?.remark === 'EDITED-' + TS, `actual=${cpl4After?.remark}`);

  // 4.3 queryById 验证 items 子项 receiptQty 已更新
  const cplItem4 = cpl4After?.items?.[0];
  c.check('[4.3] Completion items 子项 receiptQty 持久化生效',
    cplItem4 && Number(cplItem4.receiptQty) === 8, `actual=${cplItem4?.receiptQty}`);

  // ============================================================
  // 端点 5: POST /mes/manufacturing/order/generatePicking — 状态机守卫
  //   5a. 草稿订单(status=1) → 拒绝（"只有已下达订单可生成"）
  //   5b. 审核订单(status=2) → 拒绝（同样状态机）
  //   5c. 已取消订单(status=7) → 拒绝
  //   5d. 已下达订单(status=3) → OK，生成草稿领料单
  // ============================================================
  console.log('\n━━━ 端点 5: POST /mes/manufacturing/order/generatePicking ━━━');

  // 5a. 草稿订单生成 → 拒绝
  let r = await c.api('POST', `/mes/manufacturing/order/generatePicking?id=${order2.id}`);
  c.check('[5a] 草稿订单 generatePicking 拒绝',
    r.code === 500 && /已下达/.test(r.message || ''),
    `code=${r.code} msg=${r.message}`);

  // 5b. 创建新订单 + audit（status=2），再尝试 generatePicking → 拒绝
  const order5b = await createDraftOrder({
    code: `ORD_GP_${TS}_b`, bomId: bom1.id, productId: finished.id, warehouseId: wh.id, planQty: 5,
  });
  COLLECT.orders.push(order5b.id);
  const audit5b = await c.api('PUT', `/mes/manufacturing/order/audit?id=${order5b.id}`);
  c.check('[5b.前置] 新订单 audit OK', audit5b.code === 200, `code=${audit5b.code} msg=${audit5b.message}`);
  r = await c.api('POST', `/mes/manufacturing/order/generatePicking?id=${order5b.id}`);
  c.check('[5b] 已审核订单 generatePicking 拒绝',
    r.code === 500 && /已下达/.test(r.message || ''),
    `code=${r.code} msg=${r.message}`);

  // 5c. 用刚 cancel 的已取消订单试 → 拒绝
  // 复用已下达 → cancel 的路径：先 release 再 cancel 会失败（cancel 仅 1/2），
  // 这里直接用 audit 后 cancel 产生已取消订单
  const order5c = await createDraftOrder({
    code: `ORD_GP_${TS}_c`, bomId: bom1.id, productId: finished.id, warehouseId: wh.id, planQty: 5,
  });
  COLLECT.orders.push(order5c.id);
  await c.api('PUT', `/mes/manufacturing/order/audit?id=${order5c.id}`);
  await c.api('PUT', `/mes/manufacturing/order/cancel?id=${order5c.id}`);
  r = await c.api('POST', `/mes/manufacturing/order/generatePicking?id=${order5c.id}`);
  c.check('[5c] 已取消订单 generatePicking 拒绝',
    r.code === 500 && /已下达/.test(r.message || ''),
    `code=${r.code} msg=${r.message}`);

  // 5d. 已下达订单(status=3) → generatePicking OK，生成草稿领料单
  // 注：BOM items quantity=99（[1.3]步骤设置），期初库存 100
  //     选用 planQty=1 使 release 校验 99*1=99 ≤ 100 通过
  const order5d = await createDraftOrder({
    code: `ORD_GP_${TS}_d`, bomId: bom1.id, productId: finished.id, warehouseId: wh.id, planQty: 1,
  });
  COLLECT.orders.push(order5d.id);
  await c.api('PUT', `/mes/manufacturing/order/audit?id=${order5d.id}`);
  const rel5d = await c.api('PUT', `/mes/manufacturing/order/release?id=${order5d.id}`);
  c.check('[5d.前置] order5d release OK', rel5d.code === 200, `code=${rel5d.code} msg=${rel5d.message}`);
  r = await c.api('POST', `/mes/manufacturing/order/generatePicking?id=${order5d.id}`);
  c.check('[5d] 已下达订单 generatePicking OK',
    r.code === 200, `code=${r.code} msg=${r.message} result=${r.result}`);
  // 5d.1 从 result 字符串提取 pickingId，反查验证草稿领料单生成
  if (r.code === 200) {
    // 后端返回 "草稿领料单生成成功，ID: xxxx"，提取 ID
    const m = String(r.result || '').match(/ID:\s*(\w+)/);
    const generatedPickingId = m?.[1] || '';
    c.check('[5d.1] generatePicking 返回 pickingId', !!generatedPickingId, `result=${r.result}`);
    if (generatedPickingId) {
      const pickDetail = await getPickingDetail(generatedPickingId);
      c.check('[5d.2] 生成草稿领料单(status=1, 关联订单)',
        pickDetail?.status === '1' && pickDetail?.productionOrderId === order5d.id,
        `status=${pickDetail?.status} productionOrderId=${pickDetail?.productionOrderId}`);
      COLLECT.pickings.push(generatedPickingId);
    }
  }

  // ============================================================
  // 清理
  // ============================================================
  console.log('\n━━━ 清理 ━━━');

  // 领料单（草稿可删）
  for (const id of COLLECT.pickings.filter(Boolean)) {
    try { await c.api('DELETE', `/mes/manufacturing/picking/delete?id=${id}`); } catch (e) {}
  }

  // 完工入库单（草稿可删）
  for (const id of COLLECT.completions.filter(Boolean)) {
    try { await c.api('DELETE', `/mes/manufacturing/completion/delete?id=${id}`); } catch (e) {}
  }

  // 订单（非草稿走 DB 兜底）
  for (const id of COLLECT.orders.filter(Boolean)) {
    try {
      const detail = await getOrderDetail(id);
      if (detail && detail.status === '1') {
        await c.api('DELETE', `/mes/manufacturing/order/delete?id=${id}`);
      } else {
        dbCleanup(`UPDATE c_mes_production_order SET del_flag=1 WHERE id='${id}';`);
      }
    } catch (e) {}
  }

  // BOM（草稿可删）
  for (const id of COLLECT.boms.filter(Boolean)) {
    try {
      const detail = await getBomDetail(id);
      if (detail && detail.status === '1') {
        await c.api('DELETE', `/mes/manufacturing/bom/delete?id=${id}`);
        await c.api('DELETE', `/mes/manufacturing/bom/deleteBatch?ids=${id}`);
      } else {
        // 已生效/失效 BOM：软删主表（c_mes_bom_item 无 del_flag，走物理删除）
        dbCleanup(`UPDATE c_mes_bom SET del_flag=1 WHERE id='${id}'; DELETE FROM c_mes_bom_item WHERE bom_id='${id}';`);
      }
    } catch (e) {}
  }

  // 物料 + 仓库 + 库存
  const matIds = COLLECT.materials.filter(Boolean).map(id => `'${id}'`).join(',');
  const whIds = COLLECT.warehouses.filter(Boolean).map(id => `'${id}'`).join(',');
  if (matIds || whIds) {
    dbCleanup(`
      DELETE FROM c_mes_inventory WHERE warehouse_id IN (${whIds});
      DELETE FROM c_mes_inventory_ledger WHERE warehouse_id IN (${whIds});
      UPDATE c_mes_material SET moving_avg_cost=0 WHERE id IN (${matIds});
      DELETE FROM c_mes_material WHERE id IN (${matIds});
      DELETE FROM c_mes_warehouse WHERE id IN (${whIds});
    `);
  }
  console.log('✅ 测试 fixture 已清理');

  // 总结
  c.summary('生产链路 /edit + /generatePicking');
  process.exit(c.failed > 0 ? 1 : 0);
})().catch(e => {
  console.error('❌ 测试异常:', e);
  process.exit(2);
});
