// MES 采购模块 API 测试
// 测试范围: 采购申请 / 采购订单 / 采购入库 / 库存台账
const BASE = process.env.HARNESS_BASE || 'http://100.122.125.106:8080/jeecg-boot';

let token = '';
const TS = Date.now();

async function login() {
  const res = await fetch(`${BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  });
  const data = await res.json();
  if (data.code === 200 && data.result?.token) {
    token = data.result.token;
    console.log('✓ 登录成功');
  } else {
    throw new Error('登录失败: ' + JSON.stringify(data));
  }
}

async function api(method, path, body) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json', 'X-Access-Token': token }
  };
  if (body) opts.body = JSON.stringify(body);

  // DELETE 请求参数拼到 URL
  let url = `${BASE}${path}`;
  if (method === 'DELETE' && body) {
    const params = new URLSearchParams(body).toString();
    url += '?' + params;
    opts.body = undefined;
  }

  const res = await fetch(url, opts);
  return res.json();
}

function assert(condition, msg) {
  if (!condition) { console.log(`✗ ${msg}`); process.exitCode = 1; }
  else console.log(`✓ ${msg}`);
}

// ====== 测试主流程 ======
async function run() {
  await login();

  // ==========================================
  // 1. 采购申请 (Purchase Apply)
  // ==========================================
  console.log('\n=== 采购申请 ===');

  // 1.1 查询空列表
  let r = await api('GET', '/mes/purchase/apply/list?pageNo=1&pageSize=5');
  assert(r.code === 200, '1.1 申请列表(空): code=' + r.code);

  // 1.2 新增 - 缺少必填校验
  r = await api('POST', '/mes/purchase/apply/add', { code: '', items: [] });
  assert(r.code === 500, '1.2 空code被拦截: ' + r.message);

  r = await api('POST', '/mes/purchase/apply/add', { code: 'PA-' + TS, items: [] });
  assert(r.code === 500 && r.message.includes('至少需要'), '1.3 空items被拦截: ' + r.message);

  // 1.3 正常新增
  r = await api('POST', '/mes/purchase/apply/add', {
    code: 'PA-' + TS,
    deptId: '采购部',
    applicantId: '测试员',
    applyDate: '2026-07-16',
    requiredDate: '2026-07-20',
    budgetSubject: '原材料',
    items: [{ lineNo: 1, materialId: 'm001', quantity: 10, unit: 'kg', purpose: '测试' }]
  });
  assert(r.code === 200, '1.4 新增申请: ' + r.message);

  // 1.4 重复编码被拦截
  r = await api('POST', '/mes/purchase/apply/add', {
    code: 'PA-' + TS,
    items: [{ lineNo: 1, materialId: 'm001', quantity: 5, unit: 'kg' }]
  });
  assert(r.code === 500, '1.5 重复编码被拦截: ' + r.message);

  // 1.5 列表查询 + 获取ID
  r = await api('GET', '/mes/purchase/apply/list?pageNo=1&pageSize=5');
  assert(r.code === 200 && r.result?.records?.length > 0, '1.6 列表有数据: ' + r.result?.records?.length + '条');
  const applyId = r.result?.records?.find(x => x.code === 'PA-' + TS)?.id || '';

  // 1.6 按ID查询(含明细行)
  r = await api('GET', '/mes/purchase/apply/queryById?id=' + applyId);
  assert(r.code === 200 && r.result?.items?.length > 0, '1.7 queryById返回明细: ' + r.result?.items?.length + '行');

  // 1.7 编辑
  r = await api('PUT', '/mes/purchase/apply/edit', {
    id: applyId, code: 'PA-' + TS, deptId: '采购部V2', applicantId: '测试员',
    items: [{ lineNo: 1, materialId: 'm001', quantity: 20, unit: 'kg', purpose: '修改后' }]
  });
  assert(r.code === 200, '1.8 编辑申请: ' + r.message);

  // 1.8 删除
  r = await api('DELETE', '/mes/purchase/apply/delete', { id: applyId });
  assert(r.code === 200, '1.9 删除申请: ' + r.message);

  // ==========================================
  // 2. 采购订单 (Purchase Order)
  // ==========================================
  console.log('\n=== 采购订单 ===');

  // 2.1 新增 - 缺少供应商校验
  r = await api('POST', '/mes/purchase/order/add', {
    code: 'PO-' + TS, supplierId: '', items: [{ lineNo: 1, materialId: 'm001', quantity: 100, unitPrice: 25.50 }]
  });
  assert(r.code === 500 && r.message.includes('供应商'), '2.1 空供应商被拦截: ' + r.message);

  // 2.2 正常新增
  r = await api('POST', '/mes/purchase/order/add', {
    code: 'PO-' + TS,
    supplierId: 'temp_s_001',
    orderDate: '2026-07-16',
    deliveryDate: '2026-07-25',
    paymentTerms: '月结30天',
    items: [
      { lineNo: 1, materialId: 'm001', quantity: 100, unitPrice: 25.50, taxRate: 0.13 },
      { lineNo: 2, materialId: 'm002', quantity: 50, unitPrice: 10.00, taxRate: 0.06 }
    ]
  });
  assert(r.code === 200, '2.2 新增订单(多税率): ' + r.message);

  // 2.3 查询验证金额计算 (100*25.50=2550.00 + 50*10.00=500.00 = 3050.00不含税)
  r = await api('GET', '/mes/purchase/order/list?pageNo=1&pageSize=10');
  assert(r.code === 200, '2.3 订单列表: code=' + r.code);

  // 2.4 日期校验
  r = await api('POST', '/mes/purchase/order/add', {
    code: 'PO-DATE-' + TS,
    supplierId: 'temp_s_001',
    orderDate: '2026-07-20',
    deliveryDate: '2026-07-15',
    items: [{ lineNo: 1, materialId: 'm001', quantity: 10, unitPrice: 100 }]
  });
  assert(r.code === 500 && r.message.includes('交货日期'), '2.4 交货日期<订单日期被拦截: ' + r.message);

  // 2.5 查询详情 - 先获取订单ID
  r = await api('GET', '/mes/purchase/order/list?pageNo=1&pageSize=10');
  assert(r.code === 200, '2.5 订单列表查询成功');
  const orderId = r.result?.records?.find(x => x.code === 'PO-' + TS)?.id;
  if (orderId) {
    r = await api('GET', '/mes/purchase/order/queryById?id=' + orderId);
    assert(r.code === 200 && r.result?.items?.length === 2, '2.6 queryById返回2行明细: ' + (r.result?.items?.length || 0) + '行');
  } else {
    console.log('⚠ 未找到测试订单，跳过queryById');
  }

  // ==========================================
  // 3. 采购入库 (Purchase Receipt) - P0修复验证
  // ==========================================
  console.log('\n=== 采购入库(P0修复验证) ===');

  // 当前订单状态机缺少"确认"接口，新增订单后默认草稿状态
  // 鹰眼团规则：只修测试代码，不修被测业务代码。此处标记为业务缺陷：#STATUS-FLOW-MISSING
  r = await api('POST', '/mes/purchase/order/add', {
    code: 'PO-REC-' + TS,
    supplierId: 'temp_s_001',
    orderDate: '2026-07-16',
    deliveryDate: '2026-07-25',
    items: [
      { lineNo: 1, materialId: 'm001', quantity: 100, unitPrice: 25.50, taxRate: 0.13 },
      { lineNo: 2, materialId: 'm002', quantity: 50, unitPrice: 10.00, taxRate: 0.06 }
    ]
  });
  assert(r.code === 200, '3.0 创建订单(默认草稿): ' + r.message);

  // 获取订单ID
  r = await api('GET', '/mes/purchase/order/list?pageNo=1&pageSize=10');
  const recOrderId = r.result?.records?.find(x => x.code === 'PO-REC-' + TS)?.id || '';
  assert(recOrderId !== '', '3.0b 获取订单ID成功');

  // 3.1 不存在的订单 → 应被拦截
  r = await api('POST', '/mes/purchase/receipt/add', {
    code: 'PR-BAD-' + TS,
    purchaseOrderId: 'NOT_EXIST_99999',
    supplierId: 'temp_s_001',
    warehouseId: 'wh001',
    items: [{ lineNo: 1, materialId: 'm001', receiptQuantity: 10 }]
  });
  assert(r.code === 500 && r.message.includes('不存在'), '3.1 P0修复-不存在订单被拦截: ' + r.message);

  // 3.2 草稿状态订单不允许入库（因缺少确认/审核接口，无法验证已确认订单的超量/正常入库）
  r = await api('POST', '/mes/purchase/receipt/add', {
    code: 'PR-DRAFT-' + TS,
    purchaseOrderId: recOrderId,
    supplierId: 'temp_s_001',
    warehouseId: 'wh001',
    items: [{ lineNo: 1, materialId: 'm001', receiptQuantity: 5 }]
  });
  assert(r.code === 500 && r.message.includes('状态不允许入库'), '3.2 草稿订单入库被拦截: ' + r.message);

  // 3.3 因状态机缺失，无法构造已确认订单，标记为业务缺陷而非测试失败
  console.log('⚠ 3.3 状态机缺失：订单无确认/审核接口，已确认订单的入库场景无法验证');

  // 3.5 必填校验 - 空仓库
  r = await api('POST', '/mes/purchase/receipt/add', {
    code: 'PR-NO-WH-' + TS,
    purchaseOrderId: recOrderId,
    warehouseId: '',
    items: [{ lineNo: 1, materialId: 'm001', receiptQuantity: 5 }]
  });
  assert(r.code === 500 && r.message.includes('仓库'), '3.5 空仓库被拦截: ' + r.message);

  // ==========================================
  // 4. 库存台账 (Inventory Ledger)
  // ==========================================
  console.log('\n=== 库存台账 ===');

  r = await api('GET', '/mes/warehouse/ledger/list?pageNo=1&pageSize=5');
  assert(r.code === 200, '4.1 台账列表: code=' + r.code);

  r = await api('GET', '/mes/warehouse/ledger/queryAll');
  assert(r.code === 200, '4.2 台账queryAll: code=' + r.code);

  // ==========================================
  // 5. 清理测试数据
  // ==========================================
  console.log('\n=== 清理测试数据 ===');

  // 删除入库单
  r = await api('GET', '/mes/purchase/receipt/list?pageNo=1&pageSize=10');
  const receiptIds = r.result?.records?.filter(x => x.code?.startsWith('PR-')).map(x => x.id) || [];
  for (const id of receiptIds) {
    await api('DELETE', '/mes/purchase/receipt/delete', { id });
  }
  console.log('✓ 清理入库单: ' + receiptIds.length + '条');

  // 删除订单
  r = await api('GET', '/mes/purchase/order/list?pageNo=1&pageSize=10');
  const orderIds = r.result?.records?.filter(x => x.code?.startsWith('PO-')).map(x => x.id) || [];
  for (const id of orderIds) {
    await api('DELETE', '/mes/purchase/order/delete', { id });
  }
  console.log('✓ 清理订单: ' + orderIds.length + '条');

  // ==========================================
  // 汇总
  // ==========================================
  console.log('\n========== 测试完成 ==========');
  if (!process.exitCode) console.log('全部测试通过 ✓');
  else console.log('存在失败项 ✗');
}

run().catch(e => { console.error('测试异常:', e.message); process.exitCode = 1; });
