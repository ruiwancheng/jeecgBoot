// 微链路测试: 采购申请 → 采购订单
// 验证: 申请审核后状态正确、可被订单加载、非审核申请不可加载
// 不重复单端点已有的输入校验

const BASE = 'http://100.122.125.106:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const res = await fetch(`${BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  });
  token = (await res.json()).result.token;
}

async function api(method, path, body) {
  const opts = { method, headers: { 'Content-Type': 'application/json', 'X-Access-Token': token } };
  if (body) opts.body = JSON.stringify(body);
  let url = `${BASE}${path}`;
  if (method === 'DELETE' && body) url += '?' + new URLSearchParams(body).toString(), opts.body = undefined;
  return (await fetch(url, opts)).json();
}

function assert(condition, msg) {
  console.log((condition ? '  ✓' : '  ✗') + ' ' + msg);
  if (!condition) process.exitCode = 1;
}

async function run() {
  await login();
  console.log('✓ 登录成功\n');

  console.log('━━━ 链路测试: 采购申请 → 采购订单 ━━━\n');

  // Step 1: 创建申请
  console.log('Step 1: 创建申请');
  let r = await api('POST', '/mes/purchase/apply/add', {
    code: 'CHAIN-A-' + TS,
    deptId: '采购部',
    applicantId: '测试员',
    applyDate: '2026-07-22',
    requiredDate: '2026-07-30',
    budgetSubject: '原材料',
    items: [
      { lineNo: 1, materialId: 'm001', quantity: 50, unit: 'kg', purpose: '链路测试' },
      { lineNo: 2, materialId: 'm002', quantity: 30, unit: 'kg', purpose: '链路测试' }
    ]
  });
  assert(r.code === 200, '创建申请: ' + r.message);

  r = await api('GET', '/mes/purchase/apply/list?pageNo=1&pageSize=5');
  const apply = r.result?.records?.find(x => x.code === 'CHAIN-A-' + TS);
  assert(apply != null, '申请已出现在列表');
  assert(apply.status === '1', '[链路] 新申请状态=草稿(1)');
  const applyId = apply.id;

  // Step 2: 草稿申请不可加载到订单
  console.log('\nStep 2: 草稿申请不可用于生成订单');
  r = await api('GET', '/mes/purchase/order/loadApplyItemsForOrder?applyId=' + applyId);
  assert(r.code === 500, '[链路] 草稿申请被拦截: ' + (r.message || '').substring(0, 40));

  // Step 3: 审核申请
  console.log('\nStep 3: 审核申请');
  r = await api('PUT', '/mes/purchase/apply/audit?id=' + applyId);
  assert(r.code === 200, '审核: ' + r.message);

  r = await api('GET', '/mes/purchase/apply/queryById?id=' + applyId);
  assert(r.result?.status === '2', '[链路] 审核后状态=已审核(2)，实际=' + r.result?.status);

  // Step 4: 已审核申请可加载到订单
  console.log('\nStep 4: 已审核申请加载到订单');
  r = await api('GET', '/mes/purchase/order/loadApplyItemsForOrder?applyId=' + applyId);
  assert(r.code === 200, '加载明细: code=' + r.code);
  assert(r.result?.length === 2, '[链路] 返回2行明细(与申请行数一致)');
  assert(r.result[0].materialId === 'm001', '[链路] 第1行物料=m001');
  assert(r.result[0].applyQty === 50, '[链路] 第1行数量=50');
  assert(r.result[1].materialId === 'm002', '[链路] 第2行物料=m002');
  assert(r.result[1].applyQty === 30, '[链路] 第2行数量=30');

  // Step 5: 用加载的明细创建订单
  console.log('\nStep 5: 用申请明细创建订单');
  r = await api('POST', '/mes/purchase/order/add', {
    code: 'CHAIN-AO-' + TS,
    supplierId: 'temp_s_001',
    orderDate: '2026-07-22',
    deliveryDate: '2026-07-30',
    items: [
      { lineNo: 1, materialId: 'm001', quantity: 50, unitPrice: 25.50, taxRate: 0.13 },
      { lineNo: 2, materialId: 'm002', quantity: 30, unitPrice: 10.00, taxRate: 0.06 }
    ]
  });
  assert(r.code === 200, '从申请明细创建订单: ' + r.message);

  r = await api('GET', '/mes/purchase/order/list?pageNo=1&pageSize=5');
  const order = r.result?.records?.find(x => x.code === 'CHAIN-AO-' + TS);
  assert(order != null, '订单已创建');
  const orderId = order.id;

  // Step 6: 审核订单 → 验证申请状态不变
  console.log('\nStep 6: 审核订单');
  r = await api('PUT', '/mes/purchase/order/audit?id=' + orderId);
  assert(r.code === 200, '审核订单: ' + r.message);

  // 验证订单状态
  r = await api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  assert(r.result?.status === '3', '[链路] 订单状态=已确认(3)');

  // 验证申请状态未被订单审核影响
  r = await api('GET', '/mes/purchase/apply/queryById?id=' + applyId);
  assert(r.result?.status === '2', '[链路] 申请状态仍为已审核(2)，未被联动修改');

  // Step 7: 订单反审核
  console.log('\nStep 7: 订单反审核');
  r = await api('PUT', '/mes/purchase/order/unaudit?id=' + orderId);
  assert(r.code === 200, '反审核: ' + r.message);

  r = await api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  assert(r.result?.status === '1', '[链路] 反审核后订单状态=草稿(1)');

  // 清理
  console.log('\n━━━ 清理 ━━━');
  await api('DELETE', '/mes/purchase/order/delete', { id: orderId });
  await api('DELETE', '/mes/purchase/apply/delete', { id: applyId });
  console.log('  清理完成');

  console.log('\n========== ' + (process.exitCode ? '链路测试失败 ✗' : '链路测试通过 ✓') + ' ==========');
}

run().catch(e => { console.error('异常:', e.message); process.exitCode = 1; });
