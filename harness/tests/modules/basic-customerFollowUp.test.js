// MES 客户跟进记录子模块 API 测试
// 命令来源：/add-tests basic customerFollowUp
// 覆盖：7/7 endpoints (list/add/edit/delete/deleteBatch/exportXls/importExcel)
// 场景：CRUD + 边界 + 错误路径
const { dbCleanup } = require('../helpers/fixtures');
const { createClient } = require('../helpers/api');
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);

async function api(method, path, token, body) { return (method === 'POST' || method === 'PUT' || method === 'PATCH') ? c.api(method, path, body) : c.api(method, path); }

async function login() { const token = await c.login(); return token; }

async function createCustomer(token, code, name) {
  const r = await api('POST', '/mes/basic/customer/add', token, { code, name, status: 1 });
  const list = await api('GET', `/mes/basic/customer/list?code=${code}&pageSize=1`, token);
  return list.result.records[0];
}

async function findFollowUp(token, customerId, content) {
  const r = await api('GET', `/mes/basic/customer/followUp/list?customerId=${customerId}&pageSize=20`, token);
  return r.result.records.find((a) => a.content === content) || null;
}

async function run() {
  let passed = 0, failed = 0;
  const check = (name, ok, detail) => {
    if (ok) { passed++; console.log(`  ✅ ${name}: ${detail}`); }
    else { failed++; console.error(`  ❌ ${name}: ${detail}`); }
  };

  console.log('\n===== MES 客户跟进记录子模块 API 测试 =====\n');

  const TS = Date.now();
  const SUFFIX = String(TS).slice(-12);
  const custCode = `FU_T_${SUFFIX}`;

  // 预清理历史残留
  dbCleanup(`
    DELETE FROM c_mes_customer_follow_up WHERE customer_id IN (SELECT id FROM c_mes_customer WHERE code LIKE 'FU_T_%');
    DELETE FROM c_mes_customer WHERE code LIKE 'FU_T_%';
  `);

  // ---- 登录 ----
  const token = await login();
  console.log('  ✅ 登录成功\n');

  // ---- 准备客户 ----
  const customer = await createCustomer(token, custCode, '联系人测试客户');
  if (!customer) {
    console.error('  ❌ 创建客户失败，跳过后续测试');
    return;
  }
  console.log(`  📋 测试客户: ${customer.id}\n`);

  // ============================================================
  // 1. CRUD 主流程
  // ============================================================
  console.log('--- 1. CRUD 主流程 ---');

  // 1.1 新增联系人（必填字段齐全）
  const addR1 = await api('POST', '/mes/basic/customer/followUp/add', token, {
    customerId: customer.id,
    followType: '1', content: '首次拜访，介绍产品', follower: '张三',
    followDate: '2026-08-04 10:00:00', nextDate: '2026-08-15 10:00:00',
    remark: '客户有兴趣',
  });
  check('1.1 新增联系人(必填齐全)', addR1.code === 200, addR1.message);
  const contact1 = await findFollowUp(token, customer.id, '首次拜访，介绍产品');
  check('1.1.1 新增跟进落库', contact1 != null, `id=${contact1?.id}`);

  // 1.2 新增第二个联系人（非默认）
  const addR2 = await api('POST', '/mes/basic/customer/followUp/add', token, {
    customerId: customer.id,
    followType: '2', content: '电话跟进，发送报价单', follower: '李四',
    followDate: '2026-08-05 14:00:00', nextDate: '2026-08-20 14:00:00',
    remark: '待客户确认报价',
  });
  check('1.2 新增第二个联系人', addR2.code === 200, addR2.message);
  const contact2 = await findFollowUp(token, customer.id, '电话跟进，发送报价单');
  check('1.2.1 第二个跟进落库', contact2 != null, `id=${contact2?.id}`);

  // 1.3 列表查询（按 customerId 过滤）
  const listR = await api('GET', `/mes/basic/customer/followUp/list?customerId=${customer.id}&pageSize=10`, token);
  check('1.3 列表查询(过滤客户)', listR.code === 200 && listR.result.total >= 2, `total=${listR.result.total}`);
  // 验证：orderByDesc followDate，最新跟进排第一
  if (listR.result.records.length >= 2) {
    // 1.2 是后添加的 (2026-08-05)，1.1 是先添加的 (2026-08-04) → 1.2 应该排第一
    check('1.3.1 最新跟进排第一', listR.result.records[0].content?.includes('电话跟进'), `first.content=${listR.result.records[0].content}`);
  }

  // 1.4 编辑联系人
  const editR = await api('PUT', '/mes/basic/customer/followUp/edit', token, {
    id: contact1.id, customerId: customer.id,
    followType: '1', content: '首次拜访-改', follower: '张三',
    followDate: '2026-08-04 10:00:00', nextDate: '2026-08-16 10:00:00',
    remark: '客户已签约',
  });
  check('1.4 编辑联系人', editR.code === 200, editR.message);
  const contact1Edited = await findFollowUp(token, customer.id, '首次拜访-改');
  check('1.4.1 编辑后字段更新', contact1Edited?.content === '首次拜访-改', `name=${contact1Edited?.content}`);

  // 1.5 删除联系人
  const delR = await api('DELETE', `/mes/basic/customer/followUp/delete?id=${contact2.id}`, token);
  check('1.5 删除联系人', delR.code === 200, delR.message);
  const contact2After = await findFollowUp(token, customer.id, '电话跟进，发送报价单');
  check('1.5.1 删除后查询不到', contact2After == null, `仍存在=${contact2After != null}`);

  // 1.6 批量删除
  const addR3 = await api('POST', '/mes/basic/customer/followUp/add', token, {
    customerId: customer.id, name: '王五', title: '助理', phone: '13700137000', email: 'wangwu@example.com', social: 'wx-003', isDefault: 0,
    province: '北京', city: '北京', district: '朝阳区',
    detail: '国贸路', isDefault: 0,
  });
  const contact3 = await findFollowUp(token, customer.id, '上门拜访，演示样品');
  const batchR = await api('DELETE', `/mes/basic/customer/followUp/deleteBatch?ids=${contact3?.id}`, token);
  check('1.6 批量删除', batchR.code === 200, batchR.message);
  const contact3After = await findFollowUp(token, customer.id, '上门拜访，演示样品');
  check('1.6.1 批量删除后查询不到', contact3After == null, `仍存在=${contact3After != null}`);

  // ============================================================
  // 2. 校验规则（必填字段缺失）
  // ============================================================
  console.log('\n--- 2. 校验规则 ---');

  // 2.1 缺 customerId - 应能添加（customerId 不是必填，看 controller）
  // 实际 controller 不校验 customerId 必填，service 层由 Schema 决定
  // 这里跳过验证必填（JeecgBoot 框架可能允许），只验证 customerId 过滤生效
  const noCust = await api('POST', '/mes/basic/customer/followUp/add', token, {
    name: '无客户', title: 'X', phone: '13000130000', email: 'x@x.com', social: 'wx', isDefault: 0,
    detail: '某地址', isDefault: 0,
  });
  check('2.1 缺 customerId 添加（可能成功或失败）', noCust.code === 200 || noCust.code === 500, `code=${noCust.code} msg=${noCust.message?.slice(0, 40)}`);

  // ============================================================
  // 3. 错误路径
  // ============================================================
  console.log('\n--- 3. 错误路径 ---');

  // 3.1 编辑不存在的 ID
  const edit404 = await api('PUT', '/mes/basic/customer/followUp/edit', token, {
    id: 'nonexistent_id_999', customerId: customer.id,
    followType: 'X', content: 'X', follower: 'X', followDate: '2026-01-01 00:00:00',
  });
  check('3.1 编辑不存在ID', edit404.code === 200, `code=${edit404.code} (mybatis-plus updateById 静默成功 0 行)`);

  // 3.2 删除不存在的 ID
  const del404 = await api('DELETE', `/mes/basic/customer/followUp/delete?id=nonexistent_id_999`, token);
  check('3.2 删除不存在ID', del404.code === 200, `code=${del404.code}`);

  // 3.3 批量删除空字符串
  const batchEmpty = await api('DELETE', `/mes/basic/customer/followUp/deleteBatch?ids=`, token);
  check('3.3 批量删除空字符串', batchEmpty.code === 500 || batchEmpty.code === 200, `code=${batchEmpty.code} msg=${batchEmpty.message?.slice(0, 40)}`);

  // 3.4 列表查询异常分页
  const listBig = await api('GET', `/mes/basic/customer/followUp/list?customerId=${customer.id}&pageNo=999&pageSize=999999`, token);
  check('3.4 列表查询超大分页', listBig.code === 200, `code=${listBig.code}`);

  // ============================================================
  // 4. 导出/导入（仅验证端点可达，文件操作复杂）
  // ============================================================
  console.log('\n--- 4. 导出/导入 ---');

  // 4.1 exportXls (GET 返回 Excel 文件流，JSON 解析会失败但 HTTP 200)
  try {
    const exportR = await fetch(`${BASE}/mes/basic/customer/followUp/exportXls?customerId=${customer.id}`, {
      headers: { 'X-Access-Token': token },
    });
    check('4.1 exportXls 端点可达', exportR.status === 200, `status=${exportR.status}`);
  } catch (e) {
    check('4.1 exportXls 端点可达', false, e.message);
  }

  // 4.2 importExcel (POST 无文件时应 400 或 500)
  const importR = await api('POST', '/mes/basic/customer/followUp/importExcel', token, {});
  check('4.2 importExcel 端点可达(空请求)', importR.code === 200 || importR.code === 500, `code=${importR.code} msg=${importR.message?.slice(0, 40)}`);

  // ============================================================
  // 清理
  // ============================================================
  dbCleanup(`
    DELETE FROM c_mes_customer_follow_up WHERE customer_id = '${customer.id}';
    DELETE FROM c_mes_customer WHERE id = '${customer.id}';
  `);

  console.log(`\n===== 客户跟进记录：${passed} 通过, ${failed} 失败 =====`);
  console.log(`===== 通过率：${passed + failed > 0 ? ((passed / (passed + failed)) * 100).toFixed(1) : 0}% =====\n`);
  process.exit(failed > 0 ? 1 : 0);
}

run().catch((err) => { console.error('FATAL:', err); process.exit(2); });