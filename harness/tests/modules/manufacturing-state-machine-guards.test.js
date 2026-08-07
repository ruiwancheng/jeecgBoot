// 生产链路状态机守卫补齐测试 [/add-tests manufacturing 生产链路 守卫补齐]
// 覆盖 slice-1/2/3/4 实施后缺失的 5 个状态机守卫：
//   1. BOM disable 状态机（任意→失效，已失效不可再 disable）
//   2. 订单 audit BOM 未生效守卫
//   3. 订单 complete completedQty<planQty 拒绝
//   4. 订单 close 守卫（终态拒绝）
//   5. 订单 cancel 守卫（非草稿/已审核拒绝）
//
// 测试策略：每个守卫 1 个 fixture + 1 个负向断言；fixture 走 ts 后缀唯一编码，避免 DB 脏数据
// 配合 fixtures.dbCleanup 兜底

const { createClient } = require('../helpers/api');
const {
  createMaterial, createWarehouse, createAndAuditStockIn,
  dbCleanup,
} = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();

const COLLECT = { boms: [], orders: [], pickings: [], completions: [], materials: [], warehouses: [] };

async function createBom(c, { code, productId, items, version = 'v1' }) {
  const r = await c.api('POST', '/mes/manufacturing/bom/add', {
    code, productId, version, status: '1', remark: 'guards-test',
    items,
  });
  if (r.code !== 200) throw new Error(`BOM 创建失败 ${code}: ${r.message}`);
  const doc = await c.findDoc('/mes/manufacturing/bom/list', code);
  if (!doc?.id) throw new Error(`BOM 反查失败 ${code}`);
  return { id: doc.id, code };
}

async function createOrder(c, { code, bomId, productId, warehouseId, planQty }) {
  const r = await c.api('POST', '/mes/manufacturing/order/add', {
    code, bomId, productId, warehouseId,
    planQty, startDate: '2026-08-07', endDate: '2026-09-07',
    status: '1', remark: 'guards-test',
  });
  const doc = await c.findDoc('/mes/manufacturing/order/list', code);
  return { id: doc?.id, code };
}

async function getDetail(path, id) {
  const r = await c.api('GET', `${path}?id=${id}`);
  return r.result;
}

(async () => {
  await c.login('admin', '123456');
  console.log(`✅ 登录成功\n`);

  // ============================================================
  // Setup: 创建 fixture（1 仓库 + 1 产成品 + 1 子件 + 期初库存）
  // ============================================================
  console.log('━━━ Setup: 4 产成品（每锚点独立）+ 1 子件 + 1 仓库 + 期初库存 ━━━');
  // 4 个产成品，每个 BOM 锚点用不同 productId（避开 uk_bom_product_version 唯一约束）
  const finished = await createMaterial(c, `${TS}f0`, '守卫补齐产成品0');
  const finished1 = await createMaterial(c, `${TS}f1`, '守卫补齐产成品1');
  const finished2 = await createMaterial(c, `${TS}f2`, '守卫补齐产成品2');
  const finished3 = await createMaterial(c, `${TS}f3`, '守卫补齐产成品3');
  const finished4 = await createMaterial(c, `${TS}f4`, '守卫补齐产成品4');
  const finished5 = await createMaterial(c, `${TS}f5`, '守卫补齐产成品5');
  COLLECT.materials.push(finished.id, finished1.id, finished2.id, finished3.id, finished4.id, finished5.id);
  const child = await createMaterial(c, `${TS}c`, '守卫补齐子件');
  COLLECT.materials.push(child.id);
  const wh = await createWarehouse(c, `${TS}`, '守卫补齐仓');
  COLLECT.warehouses.push(wh.id);
  await createAndAuditStockIn(c, { whId: wh.id, matId: child.id, qty: 100, unitCost: 10, suffix: `${TS}s` });
  console.log(`✅ fixture: ${finished.code} / ${finished1.code} / ${finished2.code} / ${finished3.code} / ${finished4.code} / ${finished5.code} / ${child.code} / ${wh.code}\n`);

  // ============================================================
  // 锚点 1: BOM disable 状态机
  //   1a. 草稿→失效 OK
  //   1b. 失效 BOM 再 disable 拒绝
  //   1c. 失效后 approve 拒绝（"已失效无法生效"）
  // ============================================================
  console.log('━━━ 锚点 1: BOM disable 状态机 ━━━');

  // 1a. 草稿 BOM → disable → status='3'
  const bom1Code = `BOM_D_${TS}_a`;
  const bom1 = await createBom(c, { code: bom1Code, productId: finished1.id, items: [{ lineNo: 1, materialId: child.id, quantity: 1 }] });
  COLLECT.boms.push(bom1.id);
  let r = await c.api('PUT', `/mes/manufacturing/bom/disable?id=${bom1.id}`);
  c.check('[1a] 草稿 BOM disable OK', r.code === 200, `code=${r.code} msg=${r.message}`);
  let bom1Detail = await getDetail('/mes/manufacturing/bom/queryById', bom1.id);
  c.check('[1a.状态] 失效后 status=失效(3)', bom1Detail?.status === '3', `status=${bom1Detail?.status}`);

  // 1b. 失效 BOM 再 disable 拒绝
  r = await c.api('PUT', `/mes/manufacturing/bom/disable?id=${bom1.id}`);
  c.check('[1b] 失效 BOM 再 disable 拒绝', r.code === 500 && /已失效/.test(r.message || ''), `code=${r.code} msg=${r.message}`);

  // 1c. 失效 BOM 再 approve 拒绝（"已失效无法生效"）
  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bom1.id}`);
  c.check('[1c] 失效 BOM approve 拒绝', r.code === 500 && /已失效/.test(r.message || ''), `code=${r.code} msg=${r.message}`);

  // ============================================================
  // 锚点 2: 订单 audit BOM 未生效守卫
  //   2a. 用草稿 BOM 创建订单 → audit 应被拒（"订单BOM未生效"）
  // ============================================================
  console.log('\n━━━ 锚点 2: 订单 audit BOM 未生效守卫 ━━━');
  const bom2 = await createBom(c, { code: `BOM_D_${TS}_b`, productId: finished2.id, items: [{ lineNo: 1, materialId: child.id, quantity: 1 }] });
  COLLECT.boms.push(bom2.id);
  // bom2 是草稿，未 approve
  const order2 = await createOrder(c, { code: `ORD_D_${TS}_b`, bomId: bom2.id, productId: finished.id, warehouseId: wh.id, planQty: 10 });
  COLLECT.orders.push(order2.id);
  r = await c.api('PUT', `/mes/manufacturing/order/audit?id=${order2.id}`);
  c.check('[2a] 草稿 BOM 的订单 audit 拒绝', r.code === 500 && /BOM未生效/.test(r.message || ''), `code=${r.code} msg=${r.message}`);
  let order2Detail = await getDetail('/mes/manufacturing/order/queryById', order2.id);
  c.check('[2a.状态] audit 失败订单 status 仍为草稿(1)', order2Detail?.status === '1', `status=${order2Detail?.status}`);

  // ============================================================
  // 锚点 3: 订单 complete completedQty<planQty 守卫
  //   3a. 创建订单 + approve + release（下达成 status=3）
  //   3b. complete（completedQty=0 < planQty）应被拒
  // ============================================================
  console.log('\n━━━ 锚点 3: 订单 complete completedQty<planQty 守卫 ━━━');
  const bom3 = await createBom(c, { code: `BOM_D_${TS}_c`, productId: finished3.id, items: [{ lineNo: 1, materialId: child.id, quantity: 1 }] });
  COLLECT.boms.push(bom3.id);
  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bom3.id}`);
  c.check('[3.0] bom3 approve OK', r.code === 200, `code=${r.code}`);

  const order3 = await createOrder(c, { code: `ORD_D_${TS}_c`, bomId: bom3.id, productId: finished.id, warehouseId: wh.id, planQty: 5 });
  COLLECT.orders.push(order3.id);
  r = await c.api('PUT', `/mes/manufacturing/order/audit?id=${order3.id}`);
  c.check('[3.1] order3 audit OK', r.code === 200, `code=${r.code}`);
  r = await c.api('PUT', `/mes/manufacturing/order/release?id=${order3.id}`);
  c.check('[3.2] order3 release OK', r.code === 200, `code=${r.code}`);
  let order3Detail = await getDetail('/mes/manufacturing/order/queryById', order3.id);
  c.check('[3.2.状态] release 后 status=已下达(3)', order3Detail?.status === '3', `status=${order3Detail?.status}`);

  // complete 但 completedQty=0 < planQty=5 → 应拒绝
  r = await c.api('PUT', `/mes/manufacturing/order/complete?id=${order3.id}`);
  c.check('[3a] completedQty<planQty 时 complete 拒绝', r.code === 500 && /未达计划数量|已完工数量不足|先通过完工单报工/.test(r.message || ''), `code=${r.code} msg=${r.message}`);

  // ============================================================
  // 锚点 4: 订单 close 守卫（终态拒绝）
  //   4a. 草稿订单 close 应被拒（设计：close 仅非终态可关，但草稿也拒绝？）
  //   实际看代码：close 拒绝 status='5'/'6'/'7'（已终止态）。草稿可关。
  //   4b. 用刚下达的订单 close → status='6' OK
  //   4c. 再 close → 应被拒（终态）
  // ============================================================
  console.log('\n━━━ 锚点 4: 订单 close 守卫 ━━━');
  r = await c.api('PUT', `/mes/manufacturing/order/close?id=${order3.id}`);
  c.check('[4a] 已下达订单 close OK', r.code === 200, `code=${r.code} msg=${r.message}`);
  let order3After = await getDetail('/mes/manufacturing/order/queryById', order3.id);
  c.check('[4a.状态] close 后 status=已关闭(6)', order3After?.status === '6', `status=${order3After?.status}`);

  r = await c.api('PUT', `/mes/manufacturing/order/close?id=${order3.id}`);
  c.check('[4b] 已关闭订单再 close 拒绝', r.code === 500 && /终态|已关闭/.test(r.message || ''), `code=${r.code} msg=${r.message}`);

  // ============================================================
  // 锚点 5: 订单 cancel 守卫（非 1/2 拒绝）
  //   5a. 创建订单 + audit → cancel（status=2）→ status='7' OK
  //   5b. 已取消订单再 cancel 拒绝
  // ============================================================
  console.log('\n━━━ 锚点 5: 订单 cancel 守卫 ━━━');
  const bom5 = await createBom(c, { code: `BOM_D_${TS}_e`, productId: finished4.id, items: [{ lineNo: 1, materialId: child.id, quantity: 1 }] });
  COLLECT.boms.push(bom5.id);
  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bom5.id}`);
  c.check('[5.0] bom5 approve OK', r.code === 200);

  const order5 = await createOrder(c, { code: `ORD_D_${TS}_e`, bomId: bom5.id, productId: finished.id, warehouseId: wh.id, planQty: 5 });
  COLLECT.orders.push(order5.id);
  r = await c.api('PUT', `/mes/manufacturing/order/audit?id=${order5.id}`);
  c.check('[5.1] order5 audit OK', r.code === 200);

  r = await c.api('PUT', `/mes/manufacturing/order/cancel?id=${order5.id}`);
  c.check('[5a] 已审核订单 cancel OK', r.code === 200, `code=${r.code} msg=${r.message}`);
  let order5After = await getDetail('/mes/manufacturing/order/queryById', order5.id);
  c.check('[5a.状态] cancel 后 status=已取消(7)', order5After?.status === '7', `status=${order5After?.status}`);

  r = await c.api('PUT', `/mes/manufacturing/order/cancel?id=${order5.id}`);
  c.check('[5b] 已取消订单再 cancel 拒绝', r.code === 500 && /已取消|终态|草稿/.test(r.message || ''), `code=${r.code} msg=${r.message}`);

  // 5c. 已下达订单 cancel 拒绝（非 1/2）
  const bom5c = await createBom(c, { code: `BOM_D_${TS}_f`, productId: finished5.id, items: [{ lineNo: 1, materialId: child.id, quantity: 1 }] });
  COLLECT.boms.push(bom5c.id);
  r = await c.api('PUT', `/mes/manufacturing/bom/approve?id=${bom5c.id}`);
  console.log(`[5c.诊断] bom5c approve code=${r.code} msg=${r.message}`);
  const order5c = await createOrder(c, { code: `ORD_D_${TS}_f`, bomId: bom5c.id, productId: finished.id, warehouseId: wh.id, planQty: 5 });
  COLLECT.orders.push(order5c.id);
  r = await c.api('PUT', `/mes/manufacturing/order/audit?id=${order5c.id}`);
  console.log(`[5c.诊断] audit code=${r.code} msg=${r.message}`);
  const relR = await c.api('PUT', `/mes/manufacturing/order/release?id=${order5c.id}`);
  const order5cDetail = await getDetail('/mes/manufacturing/order/queryById', order5c.id);
  console.log(`[5c.诊断] release code=${relR.code} msg=${relR.message} order status=${order5cDetail?.status}`);
  r = await c.api('PUT', `/mes/manufacturing/order/cancel?id=${order5c.id}`);
  c.check('[5c] 已下达(3)订单 cancel 拒绝', r.code === 500 && /草稿|已审核|只有/.test(r.message || ''), `code=${r.code} msg=${r.message} release_status=${order5cDetail?.status}`);

  // ============================================================
  // 清理
  // ============================================================
  console.log('\n━━━ 清理 ━━━');

  // 订单（多状态走 DB 兜底）
  for (const id of COLLECT.orders.filter(Boolean)) {
    try {
      const detail = await getDetail('/mes/manufacturing/order/queryById', id);
      if (detail && detail.status === '1') {
        await c.api('DELETE', `/mes/manufacturing/order/delete?id=${id}`);
      } else {
        dbCleanup(`UPDATE c_mes_production_order SET del_flag=1 WHERE id='${id}';`);
      }
    } catch (e) {}
  }

  // BOM（草稿可删，已 disable 走 DB）
  for (const id of COLLECT.boms.filter(Boolean)) {
    try {
      const detail = await getDetail('/mes/manufacturing/bom/queryById', id);
      if (detail && detail.status === '1') {
        await c.api('DELETE', `/mes/manufacturing/bom/delete?id=${id}`);
        await c.api('DELETE', `/mes/manufacturing/bom/deleteBatch?ids=${id}`);
      } else {
        dbCleanup(`UPDATE c_mes_bom SET del_flag=1 WHERE id='${id}'; UPDATE c_mes_bom_item SET del_flag=1 WHERE bom_id='${id}';`);
      }
    } catch (e) {}
  }

  // 物料 + 仓库 + 库存
  if (COLLECT.materials.length || COLLECT.warehouses.length) {
    const whIds = COLLECT.warehouses.filter(Boolean).map(id => `'${id}'`).join(',');
    const matIds = COLLECT.materials.filter(Boolean).map(id => `'${id}'`).join(',');
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
  c.summary('生产链路状态机守卫补齐');
  process.exit(c.failed > 0 ? 1 : 0);
})().catch(e => {
  console.error('❌ 测试异常:', e);
  process.exit(2);
});