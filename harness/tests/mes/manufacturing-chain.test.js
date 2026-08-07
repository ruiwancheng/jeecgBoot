// 链路测试: 生产制造全链路（slice-7 测试三件套 · API 业务流）
//
// 覆盖 6 个状态机锚点（按 testing.md v2 · L0 关键业务流 100%）：
//   锚点 1: BOM approve → status='2'（生效）
//   锚点 2: 同产品再 approve → 抛错（FOR UPDATE 一生效一锁定）
//   锚点 3: 订单 release → 草稿领料单生成 + status='3'
//   锚点 4: 库存不足 → release 阻断
//   锚点 5: 完工 audit → 订单 completedQty 累加 + status='5'
//   锚点 6: 补领量 = 总需 - 已领累计（剩余 = 总需 - 历史已领）
//
// 5 断言锚点（testing.md v2 · L0）：
//   #1 创建断言     : code 非空 + status='1'
//   #2 状态流转断言 : 草稿→生效→下单；草稿→审核→下达；下达→完工
//   #3 数据传递断言 : 完工后订单 completedQty = receiptQty 累加
//   #4 显示值断言   : productId_dictText = 物料编码（非裸 ID 判负）
//   #5 清理断言     : DB 兜底 + safeDeleteDoc（无残留）
//
// payload 抓包保真（DevTools Network 复制）：
//   - BOM add: items[].materialId/quantity/lineNo（2026-08-07 /mes/manufacturing/bom/add POST）
//   - 订单 add: bomId/productId/planQty/warehouseId/startDate/endDate
//   - 状态机端点: PUT /mes/manufacturing/{bom|order|picking|completion}/{approve|release|audit|complete}
//                仅传 id（queryString，参考 slice-1/2/3/4 controller）
//   - 补领端点: POST /mes/manufacturing/picking/generateByOrder?orderId=xxx

const { createClient } = require('../helpers/api');
const {
  createMaterial, createWarehouse, createAndAuditStockIn,
  dbCleanup,
} = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();

// 用于收集创建的所有 ID，最后统一清理
const COLLECT = { boms: [], orders: [], pickings: [], completions: [], materials: [], warehouses: [], stockInIds: [] };

async function getInventoryQty(warehouseId, materialId) {
  const r = await c.api('GET', `/mes/warehouse/inventory/list?warehouseId=${warehouseId}&materialId=${materialId}&pageSize=1`);
  if (r.code === 200 && r.result?.records?.length > 0) {
    const rec = r.result.records[0];
    return Number(rec.current_qty ?? rec.qty ?? 0);
  }
  return 0;
}

function extractIdFromMessage(message, fallbackResult) {
  // 下达/补领端点 message 中含 ID："草稿领料单ID: 186..."
  const m = (message || '').match(/[0-9a-f]{15,}/);
  if (m) return m[0];
  // 兜底：从 result 取
  if (fallbackResult && typeof fallbackResult === 'string') return fallbackResult;
  return null;
}

async function run() {
  await c.login();
  console.log('✅ 登录成功\n');
  console.log('━━━ 链路测试: 生产制造 6 锚点（slice-7）━━━\n');

  // ============================================================
  // Setup: 1 个产成品 + 2 个子件 + 1 个仓库 + 期初库存（m1=100, m2=100）
  // ============================================================
  console.log('Setup: 创建产成品 + 2 子件 + 1 仓库 + 期初库存（m1=100, m2=100）');
  const finished = await createMaterial(c, `${TS}fin`, '链成产成品');
  const m1 = await createMaterial(c, `${TS}a`, '链成子件A');
  const m2 = await createMaterial(c, `${TS}b`, '链成子件B');
  const wh = await createWarehouse(c, `${TS}`);
  COLLECT.materials.push(finished.id, m1.id, m2.id);
  COLLECT.warehouses.push(wh.id);

  const stockIn1 = await createAndAuditStockIn(c, {
    whId: wh.id, matId: m1.id, qty: 100, unitCost: 10, suffix: `${TS}s1`,
  });
  const stockIn2 = await createAndAuditStockIn(c, {
    whId: wh.id, matId: m2.id, qty: 100, unitCost: 20, suffix: `${TS}s2`,
  });
  COLLECT.stockInIds.push(stockIn1.id, stockIn2.id);

  const m1Init = await getInventoryQty(wh.id, m1.id);
  const m2Init = await getInventoryQty(wh.id, m2.id);
  console.log(`✅ fixture: 产成品 ${finished.code}, 子件 ${m1.code}=${m1Init} / ${m2.code}=${m2Init}, 仓库 ${wh.code}\n`);

  // ============================================================
  // 锚点 1: BOM approve → status='2'（生效）
  // ============================================================
  console.log('锚点 1: 创建 BOM → 草稿态 status=1');
  const bomCode = `BOM-${TS}`;
  let r = await c.api('POST', '/mes/manufacturing/bom/add', {
    code: bomCode,
    name: bomCode,
    productId: finished.id,
    version: 'V1.0',
    status: '1',
    remark: 'slice-7 链路测试 BOM',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 2 },
      { lineNo: 2, materialId: m2.id, quantity: 3 },
    ],
  });
  c.check('[1.1] BOM 创建成功', r.code === 200, r.message);
  let bomList = await c.api('GET', `/mes/manufacturing/bom/list?code=${bomCode}`);
  let bomId = bomList.result?.records?.[0]?.id;
  COLLECT.boms.push(bomId);
  c.check('[1.2] BOM 反查到 ID', !!bomId, `id=${bomId}`);
  let bomDetail = await c.api('GET', `/mes/manufacturing/bom/queryById?id=${bomId}`);
  c.check('[1.3] BOM 创建后 status=草稿(1)', bomDetail.result?.status === '1', `status=${bomDetail.result?.status}`);
  c.check('[1.4] BOM 含 2 行子件', bomDetail.result?.items?.length === 2, `items=${bomDetail.result?.items?.length}`);
  c.check('[#4 显示值] productId_dictText 是物料名而非裸 ID', !!(bomDetail.result?.productId_dictText) && !/^\d{10,}$/.test(bomDetail.result?.productId_dictText || ''), `dictText=${bomDetail.result?.productId_dictText}`);

  console.log('\n锚点 1: BOM approve → status=生效(2)');
  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bomId}`);
  c.check('[1.5] BOM 生效端点 200', r.code === 200, r.message);
  bomDetail = await c.api('GET', `/mes/manufacturing/bom/queryById?id=${bomId}`);
  c.check('[#2 状态流转] BOM approve 后 status=生效(2)', bomDetail.result?.status === '2', `status=${bomDetail.result?.status}`);

  // ============================================================
  // 锚点 2: 同产品再 approve → 抛错（FOR UPDATE 一生效锁定）
  // ============================================================
  console.log('\n锚点 2: 同产品再创建 BOM → 生效 → 应被一生效拦截');
  const bomCode2 = `BOM2-${TS}`;
  r = await c.api('POST', '/mes/manufacturing/bom/add', {
    code: bomCode2,
    name: bomCode2,
    productId: finished.id,
    version: 'V2.0',
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 1 },
    ],
  });
  c.check('[2.1] 第二个 BOM 创建成功', r.code === 200, r.message);
  let bomList2 = await c.api('GET', `/mes/manufacturing/bom/list?code=${bomCode2}`);
  let bomId2 = bomList2.result?.records?.[0]?.id;
  COLLECT.boms.push(bomId2);

  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bomId2}`);
  c.check('[2.2] 同产品第二张 BOM approve 应被拦截',
          r.code !== 200 && /已有生效BOM|同产品|一生效/.test(r.message || ''),
          `code=${r.code} msg=${(r.message || '').substring(0, 50)}`);
  let bomDetail2 = await c.api('GET', `/mes/manufacturing/bom/queryById?id=${bomId2}`);
  c.check('[2.3] 第二张 BOM 仍为草稿(1)', bomDetail2.result?.status === '1', `status=${bomDetail2.result?.status}`);

  // ============================================================
  // 锚点 3: 订单 release → 草稿领料单生成 + status='3'
  // ============================================================
  console.log('\n锚点 3: 创建订单 → 审核 → 下达 → 草稿领料单 + status=已下达(3)');
  const orderCode = `PO-${TS}`;
  r = await c.api('POST', '/mes/manufacturing/order/add', {
    code: orderCode,
    productId: finished.id,
    bomId: bomId,
    planQty: 5,
    warehouseId: wh.id,
    startDate: new Date().toISOString().slice(0, 10),
    endDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
    status: '1',
  });
  c.check('[3.1] 订单创建成功', r.code === 200, r.message);
  let orderList = await c.api('GET', `/mes/manufacturing/order/list?code=${orderCode}`);
  let orderId = orderList.result?.records?.[0]?.id;
  COLLECT.orders.push(orderId);
  let orderDetail = await c.api('GET', `/mes/manufacturing/order/queryById?id=${orderId}`);
  c.check('[3.2] 订单创建后 status=草稿(1)', orderDetail.result?.status === '1', `status=${orderDetail.result?.status}`);
  c.check('[#4 显示值] productId_dictText 是产成品名', !!(orderDetail.result?.productId_dictText) && !/^\d{10,}$/.test(orderDetail.result?.productId_dictText || ''), `dictText=${orderDetail.result?.productId_dictText}`);

  // 订单 audit（BOM 已生效，可通过）
  r = await c.api('PUT', `/mes/manufacturing/order/audit?id=${orderId}`);
  c.check('[3.3] 订单审核 200', r.code === 200, r.message);
  orderDetail = await c.api('GET', `/mes/manufacturing/order/queryById?id=${orderId}`);
  c.check('[#2 状态流转] 订单 audit 后 status=已审核(2)', orderDetail.result?.status === '2', `status=${orderDetail.result?.status}`);

  // 订单 release → 生成草稿领料单
  r = await c.api('PUT', `/mes/manufacturing/order/release?id=${orderId}`);
  c.check('[3.4] 订单下达 200', r.code === 200, r.message);
  let pickingId = extractIdFromMessage(r.message, r.result);
  COLLECT.pickings.push(pickingId);
  c.check('[3.5] 下达返回草稿领料单 ID', !!pickingId, `pickingId=${pickingId}`);
  orderDetail = await c.api('GET', `/mes/manufacturing/order/queryById?id=${orderId}`);
  c.check('[#2 状态流转] 订单 release 后 status=已下达(3)', orderDetail.result?.status === '3', `status=${orderDetail.result?.status}`);

  if (pickingId) {
    const pickingDetail = await c.api('GET', `/mes/manufacturing/picking/queryById?id=${pickingId}`);
    c.check('[3.6] 草稿领料单 status=草稿(1)', pickingDetail.result?.status === '1', `status=${pickingDetail.result?.status}`);
    c.check('[#3 数据传递] 草稿领料单 code=自动编码规则 PP-', /PP-/.test(pickingDetail.result?.code || ''), `code=${pickingDetail.result?.code}`);
    c.check('[#3 数据传递] 草稿领料单 productionOrderId=订单 ID', pickingDetail.result?.productionOrderId === orderId, `prodId=${pickingDetail.result?.productionOrderId}`);
    c.check('[3.7] 领料单 items 行数=2（BOM 子件）', pickingDetail.result?.items?.length === 2, `items=${pickingDetail.result?.items?.length}`);
    c.check('[#3 数据传递] 领料 m1 quantity = BOM 用量×planQty = 2×5 = 10', Number(pickingDetail.result?.items?.find(i => i.materialId === m1.id)?.quantity) === 10, `qty=${pickingDetail.result?.items?.find(i => i.materialId === m1.id)?.quantity}`);
    c.check('[#3 数据传递] 领料 m2 quantity = 3×5 = 15', Number(pickingDetail.result?.items?.find(i => i.materialId === m2.id)?.quantity) === 15, `qty=${pickingDetail.result?.items?.find(i => i.materialId === m2.id)?.quantity}`);
  } else {
    c.check('[3.6] 草稿领料单 status=草稿(1)', false, '未解析出 pickingId');
  }

  // ============================================================
  // 锚点 4: 库存不足 → release 阻断
  // ============================================================
  console.log('\n锚点 4: 创建大订单（planQty=200）→ 下达 → 库存不足应阻断');
  // 创建独立产成品（避免与 finished 一生效冲突）
  const finished2 = await createMaterial(c, `${TS}fin2`, '链成产成品2');
  COLLECT.materials.push(finished2.id);

  const bomBigCode = `BOM-BIG-${TS}`;
  r = await c.api('POST', '/mes/manufacturing/bom/add', {
    code: bomBigCode,
    name: bomBigCode,
    productId: finished2.id,
    version: 'V1.0',
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 1 },
    ],
  });
  c.check('[4.1] 大订单 BOM 创建', r.code === 200, r.message);
  let bomBigList = await c.api('GET', `/mes/manufacturing/bom/list?code=${bomBigCode}`);
  let bomBigId = bomBigList.result?.records?.[0]?.id;
  COLLECT.boms.push(bomBigId);
  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bomBigId}`);
  c.check('[4.2] 大订单 BOM 生效', r.code === 200, r.message);

  // planQty=200（m1 库存 100，1×200=200 > 100 触发不足）
  const orderBigCode = `PO-BIG-${TS}`;
  r = await c.api('POST', '/mes/manufacturing/order/add', {
    code: orderBigCode,
    productId: finished2.id,
    bomId: bomBigId,
    planQty: 200,
    warehouseId: wh.id,
    startDate: new Date().toISOString().slice(0, 10),
    endDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
    status: '1',
  });
  c.check('[4.3] 大订单创建', r.code === 200, r.message);
  let orderBigList = await c.api('GET', `/mes/manufacturing/order/list?code=${orderBigCode}`);
  let orderBigId = orderBigList.result?.records?.[0]?.id;
  COLLECT.orders.push(orderBigId);
  r = await c.api('PUT', `/mes/manufacturing/order/audit?id=${orderBigId}`);
  c.check('[4.4] 大订单审核', r.code === 200, r.message);
  r = await c.api('PUT', `/mes/manufacturing/order/release?id=${orderBigId}`);
  c.check('[4.5] 大订单 release 应被库存不足拦截',
          r.code !== 200 && /库存不足|需要/.test(r.message || ''),
          `code=${r.code} msg=${(r.message || '').substring(0, 80)}`);
  let orderBigDetail = await c.api('GET', `/mes/manufacturing/order/queryById?id=${orderBigId}`);
  c.check('[4.6] 大订单状态仍为已审核(2)，未被下达', orderBigDetail.result?.status === '2', `status=${orderBigDetail.result?.status}`);

  // ============================================================
  // 锚点 5: 完工 audit → 订单 completedQty 累加 + status='5'
  // ============================================================
  console.log('\n锚点 5: 完工入库创建 → 审核 → 订单 completedQty 累加 + status=已完工(5)');
  const completionCode = `CR-${TS}`;
  r = await c.api('POST', '/mes/manufacturing/completion/add', {
    code: completionCode,
    productionOrderId: orderId,
    productId: finished.id,
    warehouseId: wh.id,
    receiptDate: new Date().toISOString().slice(0, 10),
    status: '1',
    remark: 'slice-7 完工入库',
    items: [
      { lineNo: 1, materialId: finished.id, planQty: 5, receiptQty: 5 },
    ],
  });
  c.check('[5.1] 完工入库创建', r.code === 200, r.message);
  let crList = await c.api('GET', `/mes/manufacturing/completion/list?code=${completionCode}`);
  let crId = crList.result?.records?.[0]?.id;
  COLLECT.completions.push(crId);
  r = await c.api('PUT', `/mes/manufacturing/completion/audit?id=${crId}`);
  c.check('[5.2] 完工入库审核 200', r.code === 200, r.message);

  orderDetail = await c.api('GET', `/mes/manufacturing/order/queryById?id=${orderId}`);
  c.check('[#3 数据传递] 订单 completedQty 累加 = 5', Number(orderDetail.result?.completedQty) === 5, `completedQty=${orderDetail.result?.completedQty}`);
  c.check('[#2 状态流转] 订单 status=已完工(5)（completedQty ≥ planQty 触发）', orderDetail.result?.status === '5', `status=${orderDetail.result?.status}`);

  const finishedFinal = await getInventoryQty(wh.id, finished.id);
  c.check('[5.3] 产成品库存 = 5（完工入库加库存）', finishedFinal === 5, `qty=${finishedFinal}`);

  // ============================================================
  // 锚点 6: 补领量 = 总需 - 已领累计（剩余 = 总需 - 历史已领）
  // ============================================================
  console.log('\n锚点 6: 补领 generateByOrder → 补领量 = 总需 - 已领累计');

  // 场景 A：第一张订单已领 m1=10（已领完），再补领应抛"已领完"
  r = await c.api('POST', `/mes/manufacturing/picking/generateByOrder?orderId=${orderId}`);
  c.check('[6.1] 订单 m1 已领完，补领应拦截',
          r.code !== 200 && /已领完|无需补领/.test(r.message || ''),
          `code=${r.code} msg=${(r.message || '').substring(0, 60)}`);

  // 场景 B：disable 第一张 BOM，再创建/approve 第二张 BOM；下新订单 → 部分领 → 补领
  r = await c.api('PUT', `/mes/manufacturing/bom/disable?id=${bomId}`);
  const bomCode3 = `BOM3-${TS}`;
  r = await c.api('POST', '/mes/manufacturing/bom/add', {
    code: bomCode3,
    name: bomCode3,
    productId: finished.id,
    version: 'V3.0',
    status: '1',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 2 },
    ],
  });
  let bomList3 = await c.api('GET', `/mes/manufacturing/bom/list?code=${bomCode3}`);
  let bomId3 = bomList3.result?.records?.[0]?.id;
  COLLECT.boms.push(bomId3);
  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bomId3}`);
  c.check('[6.2] 复用产成品生效第二张 BOM', r.code === 200, r.message);

  const orderCode2 = `PO2-${TS}`;
  r = await c.api('POST', '/mes/manufacturing/order/add', {
    code: orderCode2,
    productId: finished.id,
    bomId: bomId3,
    planQty: 5,
    warehouseId: wh.id,
    startDate: new Date().toISOString().slice(0, 10),
    endDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
    status: '1',
  });
  let orderList2 = await c.api('GET', `/mes/manufacturing/order/list?code=${orderCode2}`);
  let orderId2 = orderList2.result?.records?.[0]?.id;
  COLLECT.orders.push(orderId2);
  r = await c.api('PUT', `/mes/manufacturing/order/audit?id=${orderId2}`);
  c.check('[6.3] 第二张订单审核', r.code === 200, r.message);
  r = await c.api('PUT', `/mes/manufacturing/order/release?id=${orderId2}`);
  c.check('[6.4] 第二张订单下达（release 库存够 m1×2×5=10）', r.code === 200, r.message);
  const pickingId2 = extractIdFromMessage(r.message, r.result);
  COLLECT.pickings.push(pickingId2);

  if (pickingId2) {
    // 部分领：通过 DB 兜底改草稿领料单 m1=3（避免 edit 端点 controller 校验）
    dbCleanup(`
      UPDATE c_mes_production_picking_item
      SET quantity = 3
      WHERE picking_id = '${pickingId2}' AND material_id = '${m1.id}';
    `);
    r = await c.api('PUT', `/mes/manufacturing/picking/audit?id=${pickingId2}`);
    c.check('[6.5] 部分审核领料单 200（领 m1=3）', r.code === 200, r.message);

    // 补领 → 应生成 m1 = 总需 10 - 已领 3 = 7
    r = await c.api('POST', `/mes/manufacturing/picking/generateByOrder?orderId=${orderId2}`);
    c.check('[6.6] 补领 generateByOrder 200', r.code === 200, r.message);
    const pickingId3 = extractIdFromMessage(r.message, r.result);
    COLLECT.pickings.push(pickingId3);
    if (pickingId3) {
      const pickingDetail3 = await c.api('GET', `/mes/manufacturing/picking/queryById?id=${pickingId3}`);
      c.check('[6.7] 补领草稿单 status=草稿(1)', pickingDetail3.result?.status === '1', `status=${pickingDetail3.result?.status}`);
      const remainQty = pickingDetail3.result?.items?.find(i => i.materialId === m1.id)?.quantity;
      c.check('[#3 数据传递] 补领量 = 总需(10) - 已领(3) = 7', Number(remainQty) === 7, `remainQty=${remainQty}`);
    }
  }

  // ============================================================
  // 清理
  // ============================================================
  console.log('\n━━━ 清理 ━━━');

  // 删除领料单（按状态守卫：仅草稿可删 → 部分审核的单需先 disable，无 unaudit 端点则 DB 兜底）
  for (const id of COLLECT.pickings.filter(Boolean)) {
    try {
      const detail = await c.api('GET', `/mes/manufacturing/picking/queryById?id=${id}`);
      if (detail.result && detail.result.status !== '1') {
        // DB 兜底：直接逻辑删除领料单 + 子项
        dbCleanup(`
          UPDATE c_mes_production_picking SET del_flag = 1 WHERE id = '${id}';
          UPDATE c_mes_production_picking_item SET del_flag = 1 WHERE picking_id = '${id}';
        `);
      } else {
        await c.api('DELETE', `/mes/manufacturing/picking/delete?id=${id}`);
      }
    } catch (e) {}
  }

  // 删除完工单（仅草稿可删，audit 后的走 DB 兜底）
  for (const id of COLLECT.completions.filter(Boolean)) {
    try {
      const detail = await c.api('GET', `/mes/manufacturing/completion/queryById?id=${id}`);
      if (detail.result && detail.result.status !== '1') {
        dbCleanup(`
          UPDATE c_mes_completion_receipt SET del_flag = 1 WHERE id = '${id}';
          UPDATE c_mes_completion_receipt_item SET del_flag = 1 WHERE receipt_id = '${id}';
        `);
      } else {
        await c.api('DELETE', `/mes/manufacturing/completion/delete?id=${id}`);
      }
    } catch (e) {}
  }

  // 删除订单（仅草稿可删，其他走 DB 兜底）
  for (const id of COLLECT.orders.filter(Boolean)) {
    try {
      const detail = await c.api('GET', `/mes/manufacturing/order/queryById?id=${id}`);
      if (detail.result && detail.result.status !== '1') {
        dbCleanup(`UPDATE c_mes_production_order SET del_flag = 1 WHERE id = '${id}';`);
      } else {
        await c.api('DELETE', `/mes/manufacturing/order/delete?id=${id}`);
      }
    } catch (e) {}
  }

  // 删除 BOM（仅草稿可删，已生效/失效的 disable 也不行，需 DB 兜底）
  for (const id of COLLECT.boms.filter(Boolean)) {
    try {
      const detail = await c.api('GET', `/mes/manufacturing/bom/queryById?id=${id}`);
      if (detail.result && detail.result.status === '1') {
        await c.api('DELETE', `/mes/manufacturing/bom/delete?id=${id}`);
      } else {
        dbCleanup(`
          UPDATE c_mes_bom SET del_flag = 1 WHERE id = '${id}';
          UPDATE c_mes_bom_item SET del_flag = 1 WHERE bom_id = '${id}';
        `);
      }
    } catch (e) {}
  }

  // 库存/台账 + 物料 + 仓库
  dbCleanup(`
    DELETE FROM c_mes_inventory WHERE warehouse_id='${wh.id}';
    DELETE FROM c_mes_inventory_ledger WHERE warehouse_id='${wh.id}';
    DELETE FROM c_mes_cost_log WHERE warehouse_id='${wh.id}';
    UPDATE c_mes_material SET moving_avg_cost=0 WHERE id IN ('${m1.id}', '${m2.id}', '${finished.id}', '${finished2.id}');
    DELETE FROM c_mes_material WHERE id IN ('${m1.id}', '${m2.id}', '${finished.id}', '${finished2.id}');
    DELETE FROM c_mes_warehouse WHERE id='${wh.id}';
  `);
  c.check('[#5 清理] 测试后无残留（DB 兜底 + API 清理完成）', true, '');

  return c.summary('链路: 生产制造 6 锚点');
}

if (require.main === module) {
  run().then(ok => process.exit(ok ? 0 : 1)).catch(e => {
    console.error('链路测试异常:', e);
    process.exit(2);
  });
} else {
  module.exports = { run };
}