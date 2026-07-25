#!/usr/bin/env node
// MES 销售订单 API 测试 — /gen-tests 生成（2026-07-21）
// 推导来源：MesSalesOrderController 13 端点 + gen-tests-rules.json 自定义规则（R001空值/R002越权/R003边界）
// 状态机：草稿1 →审核→ 已审核2 →下达→ 已下达3；关闭5/取消6 仅草稿可发起；非草稿禁删
// Usage: node harness/tests/mes/sales-order.test.mjs

const BASE = 'http://100.122.125.106:8080/jeecg-boot';
const ADMIN = { username: 'admin', password: '123456' };
let token = '', customerId = '', materialId = '';
let passed = 0, failed = 0;
const ts = Date.now();

function req(method, path, data, noToken) {
  let url = `${BASE}${path}`;
  if (method === 'DELETE' && data) url += '?' + new URLSearchParams(data).toString();
  const headers = { 'Content-Type': 'application/json' };
  if (!noToken) headers['X-Access-Token'] = token;
  const opts = { method, headers };
  if ((method === 'POST' || method === 'PUT') && data !== undefined) opts.body = JSON.stringify(data);
  return fetch(url, opts).then(r => r.json()).catch(e => ({ code: -1, message: 'NETWORK_ERROR ' + e.message }));
}
const get = (p, params) => req('GET', p + (params ? '?' + new URLSearchParams(params) : ''));
const post = (p, d) => req('POST', p, d);
const put = (p, d) => req('PUT', p, d);
const del = (p, params) => req('DELETE', p, params);

function check(name, cond, evidence) {
  if (cond) { passed++; console.log(`✓ ${name} — ${evidence}`); }
  else { failed++; console.log(`✗ ${name} — ${evidence}`); }
}
const okRes = r => r?.code === 200 || r?.success === true;
async function findByCode(code) {
  const r = await get('/mes/sales/order/list', { pageNo: 1, pageSize: 5, code });
  return r?.result?.records?.[0];
}
async function addOrder(code, items) {
  const r = await post('/mes/sales/order/add', {
    code, customerId, orderDate: '2026-07-21', deliveryDate: '2026-08-01',
    items: items || [{ materialId, quantity: 2, unitPrice: 50, taxRate: 0.13 }],
  });
  return okRes(r) ? await findByCode(code) : null;
}

// 0. 登录 + 基础数据
const login = await post('/sys/login', ADMIN);
token = login?.result?.token || '';
check('登录', !!token, token ? 'OK' : JSON.stringify(login));
if (!token) process.exit(1);
customerId = (await get('/mes/basic/customer/list', { pageSize: 1 }))?.result?.records?.[0]?.id;
materialId = (await get('/mes/basic/material/list', { pageSize: 1 }))?.result?.records?.[0]?.id;
check('基础数据就绪', !!(customerId && materialId), `customer=${!!customerId} material=${!!materialId}`);

// ========== 1. 新增 POST /add ==========
const CODE1 = `GT-SO1-${ts}`;
const o1 = await addOrder(CODE1);
check('新增订单', !!o1, o1 ? `id=${o1.id}` : '创建失败');

// 明细金额/税额后端重算（qty2×price50=100, 税13）
const q1 = await get('/mes/sales/order/queryById', { id: o1.id });
const it1 = q1?.result?.items?.[0];
check('明细金额后端重算', it1?.amount === 100, `amount=${it1?.amount}`);
check('明细税额=金额×税率', Math.abs((it1?.taxAmount ?? -1) - 13) < 0.01, `taxAmount=${it1?.taxAmount}`);
check('订单总额汇总', q1?.result?.totalAmount === 100, `totalAmount=${q1?.result?.totalAmount}`);

// 缺税率 → 默认 0.13
const CODE2 = `GT-SO2-${ts}`;
const o2 = await addOrder(CODE2, [{ materialId, quantity: 1, unitPrice: 10 }]);
const q2 = o2 && await get('/mes/sales/order/queryById', { id: o2.id });
check('税率缺省默认0.13', q2?.result?.items?.[0]?.taxRate === 0.13, `taxRate=${q2?.result?.items?.[0]?.taxRate}`);

// 必填校验：缺订单日期 / 缺交货日期
const noDate = await post('/mes/sales/order/add', { code: `GT-X1-${ts}`, customerId, deliveryDate: '2026-08-01', items: [{ materialId, quantity: 1, unitPrice: 1 }] });
check('缺订单日期拒绝', !okRes(noDate) && /订单日期/.test(noDate?.message || ''), noDate?.message);
const noDelivery = await post('/mes/sales/order/add', { code: `GT-X2-${ts}`, customerId, orderDate: '2026-07-21', items: [{ materialId, quantity: 1, unitPrice: 1 }] });
check('缺交货日期拒绝', !okRes(noDelivery) && /交货日期/.test(noDelivery?.message || ''), noDelivery?.message);

// 重复编码拒绝
const dup = await post('/mes/sales/order/add', { code: CODE1, customerId, orderDate: '2026-07-21', deliveryDate: '2026-08-01', items: [{ materialId, quantity: 1, unitPrice: 1 }] });
check('重复编码拒绝', !okRes(dup) && /已存在/.test(dup?.message || ''), dup?.message);

// R001: null body
const nullBody = await post('/mes/sales/order/add', null);
check('R001 空body拒绝', !okRes(nullBody), nullBody?.message?.slice(0, 50) || 'error');

// R003: 负数单价
const negPrice = await post('/mes/sales/order/add', { code: `GT-X3-${ts}`, customerId, orderDate: '2026-07-21', deliveryDate: '2026-08-01', items: [{ materialId, quantity: 1, unitPrice: -5 }] });
check('R003 负数单价拒绝', !okRes(negPrice) && /负数/.test(negPrice?.message || ''), negPrice?.message);

// ========== 2. 查询 GET /list /queryById /queryAll ==========
const list = await get('/mes/sales/order/list', { pageNo: 1, pageSize: 10 });
check('列表分页查询', okRes(list) && list.result.records.length > 0, `${list?.result?.total} 条`);
const notFound = await get('/mes/sales/order/queryById', { id: '0' });
check('查询不存在订单提示', !okRes(notFound) || /不存在/.test(notFound?.message || ''), notFound?.message);
const qa = await get('/mes/sales/order/queryAll');
check('queryAll', okRes(qa), `${qa?.result?.length} 条`);

// ========== 3. 编辑 PUT /edit ==========
const ed = await put('/mes/sales/order/edit', { ...q1.result, remark: 'gen-tests编辑' });
check('编辑订单', okRes(ed), ed?.message);
const edDup = await put('/mes/sales/order/edit', { ...q2.result, code: CODE1 });
check('编辑撞他人编码拒绝', !okRes(edDup) && /已存在/.test(edDup?.message || ''), edDup?.message);

// ========== 4. 状态流转（o1：审核→下达→非法操作拦截）==========
const putId = (p, id) => req('PUT', `${p}?id=${id}`);
check('审核(草稿→已审核)', okRes(await putId('/mes/sales/order/audit', o1.id)), 'audit');
const aud2 = await putId('/mes/sales/order/audit', o1.id);
check('重复审核被守卫拦截', !okRes(aud2) && /状态已变更/.test(aud2?.message || ''), aud2?.message);
check('下达(已审核→已下达)', okRes(await putId('/mes/sales/order/release', o1.id)), 'release');
const clo1 = await putId('/mes/sales/order/close', o1.id);
check('下达后关闭被拦截(关闭仅草稿)', !okRes(clo1) && /状态已变更/.test(clo1?.message || ''), clo1?.message);
const can1 = await putId('/mes/sales/order/cancel', o1.id);
check('下达后取消被拦截(取消仅草稿)', !okRes(can1) && /状态已变更/.test(can1?.message || ''), can1?.message);

// 草稿直接关闭/取消
check('草稿关闭成功', okRes(await putId('/mes/sales/order/close', o2.id)), 'close 1→5');
const CODE3 = `GT-SO3-${ts}`;
const o3 = await addOrder(CODE3);
check('草稿取消成功', okRes(await putId('/mes/sales/order/cancel', o3.id)), 'cancel 1→6');

// ========== 5. 删除 DELETE /delete /deleteBatch ==========
const delNonDraft = await del('/mes/sales/order/delete', { id: o1.id });
check('非草稿删除被拦截', !okRes(delNonDraft) && /非草稿/.test(delNonDraft?.message || ''), delNonDraft?.message);
const CODE4 = `GT-SO4-${ts}`;
const o4 = await addOrder(CODE4);
check('草稿删除成功', okRes(await del('/mes/sales/order/delete', { id: o4.id })), 'delete');
const q4 = await get('/mes/sales/order/queryById', { id: o4.id });
check('删除后查不到', !okRes(q4) || /不存在/.test(q4?.message || ''), q4?.message);
const emptyBatch = await del('/mes/sales/order/deleteBatch', { ids: '' });
check('空ids批量删除', okRes(emptyBatch), emptyBatch?.message);
const CODE5 = `GT-SO5-${ts}`;
const o5 = await addOrder(CODE5);
check('批量删除草稿', okRes(await del('/mes/sales/order/deleteBatch', { ids: o5.id })), 'deleteBatch');

// ========== 6. R002 越权 ==========
const noAuth = await req('GET', '/mes/sales/order/list?pageNo=1&pageSize=1', undefined, true);
check('R002 无token访问被拒', !okRes(noAuth), `code=${noAuth?.code}`);

// 汇总（o1已下达/o2已关闭/o3已取消 因业务规则不可删除，残留为测试数据）
console.log(`\n===== 结果: ${passed} 通过 / ${failed} 失败 =====`);
process.exit(failed ? 1 : 0);
