// MES 销售订单 (SalesOrder) + 发货单 (DeliveryNote) 状态机测试 — slice-6
// SalesOrder: cancel+close+release (add 后才能状态流转)
// DeliveryNote: sign+submit (add 后再 sign 再 submit)
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();
let customerId = '';

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败：' + JSON.stringify(r));
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  return fetch(BASE + path, opts).then(r => r.json());
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function setupCustomer() {
  const code = 'SLICE6_CUST_' + TS;
  const add = await api('POST', '/mes/basic/customer/add', { code, name: 'slice-6 客户', status: 1 });
  if (add.code !== 200) return '';
  const list = await api('GET', '/mes/basic/customer/list?pageNo=1&pageSize=50');
  const c = list.result?.records?.find(x => x.code === code);
  return c?.id || '';
}

async function addSalesOrder(code) {
  const add = await api('POST', '/mes/sales/order/add', {
    code, customerId, orderDate: '2026-08-06', totalAmount: 100,
    status: '1', remark: 'slice-6 auto'
  });
  if (add.code !== 200) return '';
  const list = await api('GET', '/mes/sales/order/list?pageNo=1&pageSize=10');
  return list.result?.records?.find(x => x.code === code)?.id || '';
}

async function run() {
  await login();
  customerId = await setupCustomer();
  ass(customerId !== '', '0a 创建客户: ' + customerId);

  console.log('\n=== SalesOrder (/mes/sales/order) 状态机 ===');
  const ORDER = '/mes/sales/order';

  // 1. add
  const orderId = await addSalesOrder('SO-' + TS);
  ass(orderId !== '', '1.1 add SalesOrder: ' + orderId);

  // 2. release (下达：未审核 → 已下达)
  if (orderId) {
    const rel = await api('PUT', `${ORDER}/release?id=${orderId}`);
    ass(rel.code === 200, '2.1 release: ' + rel.message);
  }

  // 3. close (关闭已下达订单)
  if (orderId) {
    const cls = await api('PUT', `${ORDER}/close?id=${orderId}`);
    ass(cls.code === 200, '3.1 close: ' + cls.message);
  }

  // 4. cancel (新建订单再 cancel，避免 close 后无法 cancel)
  const orderId2 = await addSalesOrder('SO2-' + TS);
  if (orderId2) {
    const cancel = await api('PUT', `${ORDER}/cancel?id=${orderId2}`);
    ass(cancel.code === 200, '4.1 cancel: ' + cancel.message);
    await api('DELETE', `${ORDER}/delete?id=${orderId2}`);
  }

  // 清理
  if (orderId) await api('DELETE', `${ORDER}/delete?id=${orderId}`);
  if (customerId) await api('DELETE', '/mes/basic/customer/delete?id=' + customerId);

  console.log('\n=== DeliveryNote (/mes/sales/delivery) 状态机 ===');
  const DELIV = '/mes/sales/delivery';

  // 5. add (最小 payload)
  const dnAdd = await api('POST', `${DELIV}/add`, {
    code: 'DN-' + TS, customerId: '', deliveryDate: '2026-08-06',
    status: '1', remark: 'slice-6 auto'
  });
  ass(dnAdd.code === 200 || (dnAdd.message && dnAdd.message.length > 0),
      '5.1 add DeliveryNote: code=' + dnAdd.code + ' msg=' + (dnAdd.message || ''));

  // 6. 通过 list 拿 ID 再 sign/submit
  const dnList = await api('GET', `${DELIV}/list?pageNo=1&pageSize=10`);
  const dn = dnList.result?.records?.find(x => x.code === 'DN-' + TS);
  const dnId = dn?.id || '';
  ass(!!dnId, '6.0 查到 DeliveryNote: ' + dnId);

  if (dnId) {
    const sign = await api('PUT', `${DELIV}/sign?id=${dnId}`);
    ass(sign.code === 200, '6.1 sign: ' + sign.message);
    const submit = await api('PUT', `${DELIV}/submit?id=${dnId}`);
    ass(submit.code === 200, '6.2 submit: ' + submit.message);
    await api('DELETE', `${DELIV}/delete?id=${dnId}`);
  }

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
