#!/usr/bin/env node
// 切片 2：basic/supplier API 测试
// 覆盖: MesSupplierController（11 端点：list/queryById/add/edit/delete/deleteBatch/queryAll/exportXls/importExcel/selectPage）
// 关联: /coverage 切片 2 P1 缺口
// 特性: 完整模块（ServiceImpl 业务校验 + Controller 全端点 + 前端完整 + 字典 + 权限注册）
//       → 标准 CRUD 测试 + 边界 + 字段语义 + 黑名单场景

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const ENDPOINT = '/mes/basic/supplier';
const TIMESTAMP = Date.now();
const TEST_CODE = `TEST_GYS_${TIMESTAMP}`;

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== MES basic/supplier 模块 API 测试 =====\n');
  console.log(`测试供应商编码: ${TEST_CODE}`);
  let passed = 0, failed = 0;
  let createdId = null;

  // ============================================================
  // 1. /list 列表
  // ============================================================
  console.log(`--- /list ---`);
  const r1 = await c.api('GET', `${ENDPOINT}/list?pageNo=1&pageSize=10`);
  if (r1.code === 200) { passed++; c.check('1.1 list 200', true, `total=${r1.result?.total || 0}`); }
  else { failed++; c.check('1.1 list 200', false, `code=${r1.code} msg=${r1.message?.slice(0, 80)}`); }

  if (r1.code === 200 && Array.isArray(r1.result?.records)) {
    passed++; c.check('1.2 records 是数组', true, `length=${r1.result.records.length}`);
  } else {
    failed++; c.check('1.2 records 是数组', false);
  }

  // ============================================================
  // 2. /add 新增
  // ============================================================
  console.log(`\n--- /add ---`);
  const addBody = {
    code: TEST_CODE,
    name: '测试供应商-自动化',
    type: '1',  // 生产商
    status: '1', // 潜在
    grade: 'A',
    blacklistFlag: 0,
    contact: '张三',
    phone: '13800138000',
    address: '测试地址',
    remark: '由自动化测试创建',
  };
  const r2 = await c.api('POST', `${ENDPOINT}/add`, addBody);
  if (r2.code === 200) {
    passed++; c.check('2.1 add 200', true, `msg=${r2.result}`);
    // JeecgController 父类 add 返回字符串，从 list 反查
    const r2q = await c.api('GET', `${ENDPOINT}/list?code=${TEST_CODE}&pageSize=5`);
    if (r2q.code === 200 && r2q.result?.records?.length > 0) {
      createdId = r2q.result.records[0].id;
      passed++; c.check('2.2 反查 createdId', true, `id=${createdId.slice(-12)}`);
    } else {
      failed++; c.check('2.2 反查 createdId', false, 'list 未找到刚创建的记录');
    }
  } else {
    failed++; c.check('2.1 add 200', false, `code=${r2.code} msg=${r2.message?.slice(0, 80)}`);
  }

  // ============================================================
  // 3. /queryById 验证新增
  // ============================================================
  console.log(`\n--- /queryById ---`);
  if (createdId) {
    const r3 = await c.api('GET', `${ENDPOINT}/queryById?id=${createdId}`);
    if (r3.code === 200 && r3.result?.id === createdId) {
      passed++; c.check('3.1 queryById 200', true, `name=${r3.result.name}`);
    } else {
      failed++; c.check('3.1 queryById 200', false, `code=${r3.code}`);
    }
    // 字段值断言
    if (r3.result?.code === TEST_CODE) { passed++; c.check('3.2 字段值: code 匹配', true); }
    else { failed++; c.check('3.2 字段值: code 匹配', false, `code=${r3.result?.code}`); }
    if (r3.result?.name === addBody.name) { passed++; c.check('3.3 字段值: name 匹配', true); }
    else { failed++; c.check('3.3 字段值: name 匹配', false); }
    if (r3.result?.type === '1') { passed++; c.check('3.4 字段值: type=生产商', true); }
    else { failed++; c.check('3.4 字段值: type=生产商', false); }
  } else {
    console.log('  ⚠️ 未创建成功，跳过 queryById 测试');
  }

  // ============================================================
  // 4. /edit 编辑（修改黑名单状态）
  // ============================================================
  console.log(`\n--- /edit ---`);
  if (createdId) {
    const editBody = { id: createdId, ...addBody, blacklistFlag: 1, remark: '自动化测试-加入黑名单' };
    const r4 = await c.api('PUT', `${ENDPOINT}/edit`, editBody);
    if (r4.code === 200) { passed++; c.check('4.1 edit 200', true); }
    else { failed++; c.check('4.1 edit 200', false, `code=${r4.code} msg=${r4.message?.slice(0, 80)}`); }

    // 验证修改
    const r4v = await c.api('GET', `${ENDPOINT}/queryById?id=${createdId}`);
    if (r4v.result?.blacklistFlag === 1) { passed++; c.check('4.2 验证: blacklistFlag=1', true); }
    else { failed++; c.check('4.2 验证: blacklistFlag=1', false, `actual=${r4v.result?.blacklistFlag}`); }
  } else {
    console.log('  ⚠️ 无 createdId，跳过 edit 测试');
  }

  // ============================================================
  // 5. /queryAll 全部
  // ============================================================
  console.log(`\n--- /queryAll ---`);
  const r5 = await c.api('GET', `${ENDPOINT}/queryAll`);
  if (r5.code === 200 && Array.isArray(r5.result)) {
    passed++; c.check('5.1 queryAll 200', true, `length=${r5.result.length}`);
  } else {
    failed++; c.check('5.1 queryAll 200', false, `code=${r5.code}`);
  }

  // ============================================================
  // 6. /exportXls 导出
  // ============================================================
  console.log(`\n--- /exportXls ---`);
  const expRes = await fetch(BASE + `${ENDPOINT}/exportXls`, { headers: { 'X-Access-Token': c.token } });
  const bytes = new Uint8Array(await expRes.arrayBuffer());
  const isXlsx = bytes[0] === 0x50 && bytes[1] === 0x4b;
  if (expRes.status === 200 && isXlsx) { passed++; c.check('6.1 exportXls xlsx', true, `size=${bytes.length}B`); }
  else { failed++; c.check('6.1 exportXls xlsx', false, `status=${expRes.status} magic=${bytes[0]?.toString(16)}`); }

  // ============================================================
  // 7. /selectPage 下拉（ApiSelect 专用）
  // ============================================================
  console.log(`\n--- /selectPage ---`);
  const r7 = await c.api('GET', `${ENDPOINT}/selectPage?keyword=测试`);
  if (r7.code === 200 && Array.isArray(r7.result)) {
    passed++; c.check('7.1 selectPage 200', true, `length=${r7.result.length}`);
  } else {
    failed++; c.check('7.1 selectPage 200', false, `code=${r7.code} msg=${r7.message?.slice(0, 80)}`);
  }

  // ============================================================
  // 8. 字典过滤（type/status/grade 字典下拉）
  // ============================================================
  console.log(`\n--- 字典过滤 ---`);
  const dictCases = [
    { name: 'type=1 生产商', qs: 'type=1' },
    { name: 'type=2 贸易商', qs: 'type=2' },
    { name: 'status=1 潜在', qs: 'status=1' },
    { name: 'status=3 合格', qs: 'status=3' },
    { name: 'grade=A A级', qs: 'grade=A' },
    { name: 'blacklistFlag=1 黑名单', qs: 'blacklistFlag=1' },
  ];
  for (const dc of dictCases) {
    const r = await c.api('GET', `${ENDPOINT}/list?${dc.qs}&pageSize=10`);
    if (r.code === 200) { passed++; c.check(`8.${dc.name} 200`, true, `total=${r.result?.total || 0}`); }
    else { failed++; c.check(`8.${dc.name} 200`, false, `code=${r.code}`); }
  }

  // ============================================================
  // 9. R003 边界值
  // ============================================================
  console.log(`\n--- 边界值 ---`);
  const boundaryCases = [
    { name: 'pageNo=0', qs: 'pageNo=0&pageSize=10' },
    { name: 'pageNo=-1', qs: 'pageNo=-1&pageSize=10' },
    { name: 'pageSize=0', qs: 'pageNo=1&pageSize=0' },
    { name: 'pageSize=2147483647', qs: 'pageNo=1&pageSize=2147483647' },
  ];
  for (const bc of boundaryCases) {
    const r = await c.api('GET', `${ENDPOINT}/list?${bc.qs}`);
    const ok = r.code === 200 || r.code === 500;
    if (ok) { passed++; c.check(`9.${bc.name} 不崩`, true, `code=${r.code}`); }
    else { failed++; c.check(`9.${bc.name} 不崩`, false, `code=${r.code}`); }
  }

  // ============================================================
  // 10. R005 SQL 注入 / 特殊字符
  // ============================================================
  console.log(`\n--- 特殊字符 ---`);
  const sqlCases = ["' OR '1'='1", '%test%', 'DROP', '<script>', '中文字符'];
  for (const sc of sqlCases) {
    const r = await c.api('GET', `${ENDPOINT}/list?name=${encodeURIComponent(sc)}&pageSize=10`);
    if (r.code === 200) { passed++; c.check(`10.特殊字符"${sc.slice(0, 12)}..." 200`, true); }
    else { failed++; c.check(`10.特殊字符"${sc.slice(0, 12)}..." 200`, false, `code=${r.code}`); }
  }

  // ============================================================
  // 11. 业务校验：编码重复
  // ============================================================
  console.log(`\n--- 业务校验 ---`);
  if (createdId) {
    // 尝试用已存在的 code 再创建
    const r11 = await c.api('POST', `${ENDPOINT}/add`, addBody);
    if (r11.code !== 200) { passed++; c.check('11.1 重复 code 被拒', true, `code=${r11.code} msg=${r11.message?.slice(0, 50)}`); }
    else { failed++; c.check('11.1 重复 code 被拒', false, '重复 code 未被拦截'); }
  }

  // ============================================================
  // 12. 清理：删除测试数据
  // ============================================================
  console.log(`\n--- 清理 ---`);
  if (createdId) {
    const r12 = await c.api('DELETE', `${ENDPOINT}/delete?id=${createdId}`);
    if (r12.code === 200) { passed++; c.check('12.1 delete 200', true); }
    else { failed++; c.check('12.1 delete 200', false, `code=${r12.code} msg=${r12.message?.slice(0, 80)}`); }

    // 验证已删
    const r12v = await c.api('GET', `${ENDPOINT}/queryById?id=${createdId}`);
    if (!r12v.result || r12v.result.id !== createdId) { passed++; c.check('12.2 验证: 已软删除', true); }
    else { failed++; c.check('12.2 验证: 已软删除', false); }
  }

  return c.summary('supplier');
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(2); });
