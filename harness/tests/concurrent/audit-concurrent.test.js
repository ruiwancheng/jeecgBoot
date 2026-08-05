// MES 并发审核测试 — P0-5
// 验证：并发 audit × N，仅 1 个成功，其余被状态机守卫拒绝
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败: ' + r.message);
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const r = await fetch(BASE + path, opts);
  return r.json();
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();
  console.log('\n=== 并发审核测试 ===');

  // 1. 创建一个销售订单（草稿态）
  const soCode = 'CONCUR-SO-' + TS;
  const soAdd = await api('POST', '/mes/sales/order/add', {
    code: soCode,
    customerId: 'DUMMY_CUST',
    orderDate: '2026-08-06',
    deliveryDate: '2026-08-10',
    items: [{ lineNo: 1, materialId: 'DUMMY_MAT', quantity: 100, unitPrice: 10 }]
  });
  ass(soAdd.code === 200, '1. 创建销售订单: ' + soAdd.message);

  // 取订单 ID
  const soList = await api('GET', '/mes/sales/order/list?pageNo=1&pageSize=50');
  const so = soList.result?.records?.find(x => x.code === soCode);
  const soId = so?.id || '';
  ass(soId !== '', '1b 获取订单ID: ' + soId);
  if (!soId) { console.log('⚠ 创建失败，跳过'); return; }
  console.log('   订单ID: ' + soId + ' 初始status: ' + so?.status);

  // 2. 并发 audit × 5（期望只有 1 个成功，其余被状态机拒绝）
  console.log('\n--- 2. 并发 audit × 5 ---');
  const concurrentCount = 5;
  const results = await Promise.all(
    Array.from({ length: concurrentCount }, () =>
      api('PUT', '/mes/sales/order/audit?id=' + soId)
    )
  );

  const successCodes = results.filter(r => r.code === 200);
  const rejectCodes = results.filter(r => r.code !== 200);

  console.log(`   成功: ${successCodes.length}/${concurrentCount}`);
  console.log(`   拒绝: ${rejectCodes.length}/${concurrentCount}`);
  results.forEach((r, i) => {
    console.log(`   [${i + 1}] code=${r.code} msg=${(r.message || '').slice(0, 50)}`);
  });

  // 断言：恰好 1 个成功（其余被状态机守卫拦截）
  ass(successCodes.length === 1,
    `2. 并发审核仅1个成功: 实际成功=${successCodes.length}`);
  ass(rejectCodes.length === concurrentCount - 1,
    `2. 其余${concurrentCount - 1}个被拒绝: 实际拒绝=${rejectCodes.length}`);

  // 3. 验证最终状态是已审核（status=2）
  const after = await api('GET', '/mes/sales/order/queryById?id=' + soId);
  if (after.code === 200) {
    ass(after.result?.status === '2', '3. 最终状态=已审核: status=' + after.result?.status);
  }

  // 4. 清理
  await api('DELETE', '/mes/sales/order/delete?id=' + soId);
  console.log('✅ 清理完成');

  console.log(process.exitCode ? '❌ 有失败项' : '✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
