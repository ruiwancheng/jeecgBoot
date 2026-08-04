// 链路测试: 采购申请 → 采购订单（真实 fixture 版，修复假ID破窗）
// 验证: 申请审核后状态正确、可被订单加载、非审核申请不可加载、订单审核不联动申请
const { createClient } = require('../helpers/api');
const { createSupplier, createMaterial, safeDeleteDoc, cleanupWarehouseScope } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();
// update-begin---author:ruiwancheng---date:2026-08-02---for: P1修复-日期改为动态避免过期触发交货日期校验-----------
// 业务约束: orderDate <= deliveryDate; 申请审核自动生成订单时 orderDate=今天, deliveryDate=requiredDate
// 故 requiredDate 必须 >= 今天; applyDate <= requiredDate
const TODAY = new Date().toISOString().slice(0, 10);  // 'YYYY-MM-DD'
const TOMORROW = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
// update-end---author:ruiwancheng---date:2026-08-02---for: P1修复-日期改为动态-----------

async function run() {
  await c.login();
  console.log('✅ 登录成功\n');
  console.log('━━━ 链路测试: 采购申请 → 采购订单 ━━━\n');

  // Setup: 真实供应商+物料
  const sup = await createSupplier(c, TS);
  const m1 = await createMaterial(c, `${TS}a`, '链路料A');
  const m2 = await createMaterial(c, `${TS}b`, '链路料B');
  console.log(`✅ fixture: 供应商=${sup.code} 物料=${m1.code}/${m2.code}\n`);

  let applyId = null, orderId = null;

  // Step 1: 创建申请（含供应商+真实物料）
  console.log('Step 1: 创建申请');
  let r = await c.api('POST', '/mes/purchase/apply/add', {
    code: 'CHAIN-A-' + TS,
    supplierId: sup.id,
    deptId: '采购部',
    applicantId: '测试员',
    applyDate: TODAY,
    requiredDate: TOMORROW,
    budgetSubject: '原材料',
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 50, unitPrice: 25.5, unit: 'kg', purpose: '链路测试' },
      { lineNo: 2, materialId: m2.id, quantity: 30, unitPrice: 10, unit: 'kg', purpose: '链路测试' },
    ],
  });
  c.check('创建申请', r.code === 200, r.message);

  const apply = await c.findDoc('/mes/purchase/apply/list', 'CHAIN-A-' + TS);
  c.check('申请已出现在列表', !!apply);
  c.check('[链路] 新申请状态=草稿(1)', apply?.status === '1', `实际=${apply?.status}`);
  applyId = apply.id;

  // Step 2: 草稿申请不可加载到订单
  console.log('\nStep 2: 草稿申请不可用于生成订单');
  r = await c.api('GET', '/mes/purchase/order/loadApplyItemsForOrder?applyId=' + applyId);
  c.check('[链路] 草稿申请被拦截', r.code === 500, (r.message || '').substring(0, 40));

  // Step 3: 审核申请
  console.log('\nStep 3: 审核申请');
  r = await c.api('PUT', '/mes/purchase/apply/audit?id=' + applyId);
  c.check('审核申请', r.code === 200, r.message);
  r = await c.api('GET', '/mes/purchase/apply/queryById?id=' + applyId);
  c.check('[链路] 审核后状态=已审核(3)', r.result?.status === '3', `实际=${r.result?.status}`);

  // Step 4: 已审核申请可加载到订单
  console.log('\nStep 4: 已审核申请加载到订单');
  r = await c.api('GET', '/mes/purchase/order/loadApplyItemsForOrder?applyId=' + applyId);
  c.check('加载明细', r.code === 200, `code=${r.code}`);
  c.check('[链路] 返回2行明细', r.result?.length === 2, `实际=${r.result?.length}`);
  c.check('[链路] 第1行物料=m1', r.result?.[0]?.materialId === m1.id);
  c.check('[链路] 第1行数量=50', Number(r.result?.[0]?.applyQty) === 50, `实际=${r.result?.[0]?.applyQty}`);
  c.check('[链路] 第2行物料=m2', r.result?.[1]?.materialId === m2.id);

  // Step 5: 用加载的明细创建订单
  console.log('\nStep 5: 用申请明细创建订单');
  r = await c.api('POST', '/mes/purchase/order/add', {
    code: 'CHAIN-AO-' + TS,
    supplierId: sup.id,
    orderDate: TODAY,
    deliveryDate: TOMORROW,
    items: [
      { lineNo: 1, materialId: m1.id, quantity: 50, unitPrice: 25.50, taxRate: 0.13 },
      { lineNo: 2, materialId: m2.id, quantity: 30, unitPrice: 10.00, taxRate: 0.06 },
    ],
  });
  c.check('从申请明细创建订单', r.code === 200, r.message);
  const order = await c.findDoc('/mes/purchase/order/list', 'CHAIN-AO-' + TS);
  c.check('订单已创建', !!order);
  orderId = order.id;

  // Step 6: 审核订单 → 申请状态不联动
  console.log('\nStep 6: 审核订单');
  r = await c.api('PUT', '/mes/purchase/order/audit?id=' + orderId);
  c.check('审核订单', r.code === 200, r.message);
  r = await c.api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  c.check('[链路] 订单状态=已确认(3)', r.result?.status === '3', `实际=${r.result?.status}`);
  r = await c.api('GET', '/mes/purchase/apply/queryById?id=' + applyId);
  c.check('[链路] 申请状态仍为已审核(3)，未被订单联动', r.result?.status === '3', `实际=${r.result?.status}`);

  // Step 7: 订单反审核
  console.log('\nStep 7: 订单反审核');
  r = await c.api('PUT', '/mes/purchase/order/unaudit?id=' + orderId);
  c.check('反审核订单', r.code === 200, r.message);
  r = await c.api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  c.check('[链路] 反审核后订单状态=草稿(1)', r.result?.status === '1', `实际=${r.result?.status}`);

  // 清理
  console.log('\n━━━ 清理 ━━━');
  await safeDeleteDoc(c, '/mes/purchase/order', orderId);
  await safeDeleteDoc(c, '/mes/purchase/apply', applyId);
  await c.api('DELETE', `/mes/basic/supplier/delete?id=${sup.id}`);
  await c.api('DELETE', `/mes/basic/material/delete?id=${m1.id}`);
  await c.api('DELETE', `/mes/basic/material/delete?id=${m2.id}`);
  console.log('✅ 清理完成');

  return c.summary('链路: 申请→订单');
}

//update-begin---author:pi---date:2026-08-04---for:【BUG-1】段文件改为可重用模块（独立运行时才 exit，被 require 时不 exit）-----------
if (require.main === module) {
  run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(1); });
} else {
  module.exports = { run };
}
//update-end---author:pi---date:2026-08-04---for:【BUG-1】段文件改为可重用模块（独立运行时才 exit，被 require 时不 exit）-----------
