// 微链路测试: 采购订单 → 采购入库
// 验证 criticalPath: POST /mes/purchase/receipt/add → 校验订单存在+状态+超量
// 测试维度: 跨步骤状态一致性、数据传递正确性
// 不重复单端点已有的输入校验（空code/空物料等）

const BASE = 'http://localhost:8080/jeecg-boot';
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

  // ==========================================
  // 链路: 订单 → 入库
  // ==========================================
  console.log('━━━ 链路测试: 采购订单 → 采购入库 ━━━\n');

  // Step 1: 创建订单
  console.log('Step 1: 创建订单');
  let r = await api('POST', '/mes/purchase/order/add', {
    code: 'CHAIN-' + TS,
    supplierId: 'temp_s_001',
    orderDate: '2026-07-22',
    deliveryDate: '2026-07-30',
    items: [
      { lineNo: 1, materialId: 'm001', quantity: 100, unitPrice: 25.50, taxRate: 0.13 },
      { lineNo: 2, materialId: 'm002', quantity: 50, unitPrice: 10.00, taxRate: 0.06 }
    ]
  });
  assert(r.code === 200, '创建订单: ' + r.message);

  // 获取订单ID
  r = await api('GET', '/mes/purchase/order/list?pageNo=1&pageSize=5');
  const order = r.result?.records?.find(x => x.code === 'CHAIN-' + TS);
  assert(order != null, '订单已出现在列表中');
  assert(order.status === '1', '[链路] 新订单状态=草稿(1)');
  const orderId = order.id;

  // Step 2: 草稿订单不能入库
  console.log('\nStep 2: 草稿订单入库应被拦截');
  r = await api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R1-' + TS,
    purchaseOrderId: orderId,
    supplierId: 'temp_s_001',
    warehouseId: 'wh001',
    items: [{ lineNo: 1, materialId: 'm001', receiptQuantity: 10 }]
  });
  assert(r.code === 500 && r.message.includes('状态不允许入库'),
    '[链路] 草稿订单入库被拦截: ' + (r.message || '').substring(0, 40));

  // Step 3: 审核订单
  console.log('\nStep 3: 审核订单');
  r = await api('PUT', '/mes/purchase/order/audit?id=' + orderId);
  assert(r.code === 200, '审核订单: ' + r.message);

  // 验证状态变更
  r = await api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  assert(r.code === 200, '查询订单详情');
  assert(r.result?.status === '3', '[链路] 审核后订单状态=已确认(3)，实际=' + r.result?.status);

  // Step 4: 正常入库
  console.log('\nStep 4: 正常入库（部分收货）');
  r = await api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R2-' + TS,
    purchaseOrderId: orderId,
    supplierId: 'temp_s_001',
    warehouseId: 'wh001',
    items: [
      { lineNo: 1, materialId: 'm001', receiptQuantity: 30 },
      { lineNo: 2, materialId: 'm002', receiptQuantity: 20 }
    ]
  });
  assert(r.code === 200, '创建入库单: ' + r.message);

  // 获取入库单并审核
  r = await api('GET', '/mes/purchase/receipt/list?pageNo=1&pageSize=5');
  const receipt = r.result?.records?.find(x => x.code === 'CHAIN-R2-' + TS);
  assert(receipt != null, '入库单已出现在列表中');

  r = await api('PUT', '/mes/purchase/receipt/audit?id=' + receipt.id);
  assert(r.code === 200, '审核入库单: ' + r.message);

  // 验证：订单状态应变为部分到货
  r = await api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  assert(r.result?.status === '4', '[链路] 部分收货后订单状态=部分到货(4)，实际=' + r.result?.status);

  // 验证：物料m001已收货30
  r = await api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  const item1 = r.result?.items?.find(i => i.materialId === 'm001');
  assert(item1?.receivedQty === 30, '[链路] m001已收货30，实际=' + item1?.receivedQty);

  // Step 5: 超量入库应被拦截
  console.log('\nStep 5: 超量入库应被拦截');
  r = await api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R3-' + TS,
    purchaseOrderId: orderId,
    supplierId: 'temp_s_001',
    warehouseId: 'wh001',
    items: [
      { lineNo: 1, materialId: 'm001', receiptQuantity: 80 }  // 30已收 + 80 = 110 > 100
    ]
  });
  assert(r.code === 500 && r.message.includes('超过采购数量'),
    '[链路] 超量入库被拦截(累计110>100): ' + (r.message || '').substring(0, 50));

  // Step 6: 正常补足剩余
  console.log('\nStep 6: 补足剩余数量');
  r = await api('POST', '/mes/purchase/receipt/add', {
    code: 'CHAIN-R4-' + TS,
    purchaseOrderId: orderId,
    supplierId: 'temp_s_001',
    warehouseId: 'wh001',
    items: [
      { lineNo: 1, materialId: 'm001', receiptQuantity: 70 },  // 30+70=100 ✓
      { lineNo: 2, materialId: 'm002', receiptQuantity: 30 }   // 20+30=50 ✓
    ]
  });
  assert(r.code === 200, '补足入库: ' + r.message);

  // 审核第二笔入库
  r = await api('GET', '/mes/purchase/receipt/list?pageNo=1&pageSize=5');
  const receipt2 = r.result?.records?.find(x => x.code === 'CHAIN-R4-' + TS);
  if (receipt2) {
    r = await api('PUT', '/mes/purchase/receipt/audit?id=' + receipt2.id);
    assert(r.code === 200, '审核补足入库: ' + r.message);
  }

  // 验证：全部到货后订单状态
  r = await api('GET', '/mes/purchase/order/queryById?id=' + orderId);
  assert(r.result?.status === '5', '[链路] 全部到货后订单状态=已到货(5)，实际=' + r.result?.status);

  // 验证：库存台账应有记录
  console.log('\nStep 7: 验证库存台账');
  r = await api('GET', '/mes/warehouse/ledger/queryAll');
  assert(r.code === 200, '台账可查询');
  const ledgerEntries = r.result?.filter(e => e.bizId === 'CHAIN-R2-' + TS || e.bizId === 'CHAIN-R4-' + TS);
  assert((ledgerEntries?.length || 0) >= 2, '[链路] 台账有2条入库记录，实际=' + (ledgerEntries?.length || 0));

  // ==========================================
  // 清理
  // ==========================================
  console.log('\n━━━ 清理 ━━━');
  // 删除入库单
  for (const code of ['CHAIN-R1-', 'CHAIN-R2-', 'CHAIN-R3-', 'CHAIN-R4-']) {
    r = await api('GET', '/mes/purchase/receipt/list?pageNo=1&pageSize=10');
    const rec = r.result?.records?.find(x => x.code?.startsWith(code + TS));
    if (rec) {
      await api('PUT', '/mes/purchase/receipt/unaudit?id=' + rec.id).catch(() => {});
      await api('DELETE', '/mes/purchase/receipt/delete', { id: rec.id });
    }
  }
  // 删除订单
  await api('PUT', '/mes/purchase/order/unaudit?id=' + orderId).catch(() => {});
  await api('DELETE', '/mes/purchase/order/delete', { id: orderId });
  console.log('  清理完成');

  console.log('\n========== ' + (process.exitCode ? '链路测试失败 ✗' : '链路测试通过 ✓') + ' ==========');
}

run().catch(e => { console.error('异常:', e.message); process.exitCode = 1; });
