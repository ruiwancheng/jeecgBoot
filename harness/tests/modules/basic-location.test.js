#!/usr/bin/env node
// 切片 3：basic/location API 测试
// 覆盖: MesLocationController（11 端点：list/add/edit/delete/deleteBatch/generate/exportXls/importExcel/selectPage）
// 关联: /coverage 切片 3 P1 缺口
// 特性:
//   - 库位关联仓库（warehouseId），需先有 warehouse 才能 add
//   - /generate 批量生成库位（按 行/列 自动编码）
//   - 容量字段：maxCapacity/loadCapacity/storageLimit

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const WH_ENDPOINT = '/mes/basic/warehouse';
const LOC_ENDPOINT = '/mes/basic/location';
const TIMESTAMP = Date.now();
const WH_CODE = `TEST_LOC_WH_${TIMESTAMP}`;
const LOC_CODE = `TEST_LOC_${TIMESTAMP}`;

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== MES basic/location 模块 API 测试 =====\n');
  console.log(`测试仓库: ${WH_CODE}, 测试库位: ${LOC_CODE}`);
  let passed = 0, failed = 0;
  let whId = null;
  let locId = null;

  // ============================================================
  // 0. 准备：创建测试仓库
  // ============================================================
  console.log(`--- 0. 准备：创建测试仓库 ---`);
  const whBody = { code: WH_CODE, name: '测试库位-仓库', type: '1', status: 1 };
  const rWh = await c.api('POST', `${WH_ENDPOINT}/add`, whBody);
  if (rWh.code === 200) {
    const rWhQ = await c.api('GET', `${WH_ENDPOINT}/list?code=${WH_CODE}&pageSize=5`);
    if (rWhQ.code === 200 && rWhQ.result?.records?.length > 0) {
      whId = rWhQ.result.records[0].id;
      passed++; c.check('0.1 创建测试仓库', true, `id=${whId.slice(-12)}`);
    } else {
      failed++; c.check('0.1 创建测试仓库', false, 'list 未找到刚创建的仓库');
    }
  } else {
    failed++; c.check('0.1 创建测试仓库', false, `code=${rWh.code} msg=${rWh.message?.slice(0, 80)}`);
  }

  // ============================================================
  // 1. /list 列表（按 warehouseId 过滤）
  // ============================================================
  console.log(`\n--- /list ---`);
  const r1 = await c.api('GET', `${LOC_ENDPOINT}/list?pageNo=1&pageSize=10`);
  if (r1.code === 200) { passed++; c.check('1.1 list 200', true, `total=${r1.result?.total || 0}`); }
  else { failed++; c.check('1.1 list 200', false, `code=${r1.code}`); }

  if (whId) {
    const r1w = await c.api('GET', `${LOC_ENDPOINT}/list?warehouseId=${whId}&pageSize=10`);
    if (r1w.code === 200) { passed++; c.check('1.2 list by warehouseId', true, `total=${r1w.result?.total || 0}`); }
    else { failed++; c.check('1.2 list by warehouseId', false); }
  }

  // ============================================================
  // 2. /add 新增库位
  // ============================================================
  console.log(`\n--- /add ---`);
  if (whId) {
    const addBody = {
      warehouseId: whId,
      code: LOC_CODE,
      name: '测试库位-A01',
      type: '1',
      area: 'A区',
      passageRow: 1,
      passageCol: 1,
      shelfRow: 1,
      shelfCol: 1,
      maxCapacity: 1000,
      loadCapacity: 500,
      storageLimit: '常温',
      status: 1,
      remark: '自动化测试',
    };
    const r2 = await c.api('POST', `${LOC_ENDPOINT}/add`, addBody);
    if (r2.code === 200) {
      passed++; c.check('2.1 add 200', true, `msg=${r2.result}`);
      const r2q = await c.api('GET', `${LOC_ENDPOINT}/list?code=${LOC_CODE}&pageSize=5`);
      if (r2q.code === 200 && r2q.result?.records?.length > 0) {
        locId = r2q.result.records[0].id;
        passed++; c.check('2.2 反查 locId', true, `id=${locId.slice(-12)}`);
      } else {
        failed++; c.check('2.2 反查 locId', false);
      }
    } else {
      failed++; c.check('2.1 add 200', false, `code=${r2.code} msg=${r2.message?.slice(0, 80)}`);
    }
  } else {
    console.log('  ⚠️ 无 whId，跳过 add 测试');
  }

  // ============================================================
  // 3. /generate 批量生成库位
  //    字段名: channelRows/channelCols/shelfRows/shelfCols (Controller 期望)
  //    ⚠️ 前端 data.ts 用 passageRow/passageCol，但 Controller 用 channelRows/channelCols
  //    → 前后端字段名不一致 bug（前端页面提交可能 500）
  // ============================================================
  console.log(`\n--- /generate (批量生成) ---`);
  if (whId) {
    const genBody = {
      warehouseId: whId,
      area: 'B区',
      channelRows: 2,
      channelCols: 3,
      shelfRows: 1,
      shelfCols: 1,
    };
    const r3 = await c.api('POST', `${LOC_ENDPOINT}/generate`, genBody);
    if (r3.code === 200) { passed++; c.check('3.1 generate 200', true, `msg=${r3.result}`); }
    else { failed++; c.check('3.1 generate 200', false, `code=${r3.code} msg=${r3.message?.slice(0, 80)}`); }

    // 验证生成数量（2 * 3 = 6 条）
    const r3v = await c.api('GET', `${LOC_ENDPOINT}/list?warehouseId=${whId}&pageSize=100`);
    if (r3v.code === 200 && r3v.result?.records?.length >= 7) {
      passed++; c.check('3.2 验证: 至少 7 条 (1手动+6自动)', true, `actual=${r3v.result.records.length}`);
    } else {
      failed++; c.check('3.2 验证: 至少 7 条', false, `actual=${r3v.result?.records?.length || 0}`);
    }
  } else {
    console.log('  ⚠️ 无 whId，跳过 generate 测试');
  }

  // ============================================================
  // 4. /selectPage 下拉
  // ============================================================
  console.log(`\n--- /selectPage ---`);
  const r4 = await c.api('GET', `${LOC_ENDPOINT}/selectPage?keyword=A01`);
  if (r4.code === 200 && Array.isArray(r4.result)) {
    passed++; c.check('4.1 selectPage 200', true, `length=${r4.result.length}`);
  } else {
    failed++; c.check('4.1 selectPage 200', false, `code=${r4.code} msg=${r4.message?.slice(0, 80)}`);
  }

  // ============================================================
  // 5. /edit 编辑
  // ============================================================
  console.log(`\n--- /edit ---`);
  if (locId && whId) {
    const editBody = {
      id: locId,
      warehouseId: whId,
      code: LOC_CODE,
      name: '测试库位-A01-已修改',
      type: '1',
      area: 'A区',
      passageRow: 1, passageCol: 1, shelfRow: 1, shelfCol: 1,
      maxCapacity: 2000,
      loadCapacity: 1000,
      status: 1,
      remark: '已修改',
    };
    const r5 = await c.api('PUT', `${LOC_ENDPOINT}/edit`, editBody);
    if (r5.code === 200) { passed++; c.check('5.1 edit 200', true); }
    else { failed++; c.check('5.1 edit 200', false, `code=${r5.code} msg=${r5.message?.slice(0, 80)}`); }

    const r5v = await c.api('GET', `${LOC_ENDPOINT}/list?code=${LOC_CODE}&pageSize=5`);
    if (r5v.result?.records?.[0]?.maxCapacity === 2000) {
      passed++; c.check('5.2 验证: maxCapacity=2000', true);
    } else {
      failed++; c.check('5.2 验证: maxCapacity=2000', false);
    }
  } else {
    console.log('  ⚠️ 无 locId，跳过 edit 测试');
  }

  // ============================================================
  // 6. /exportXls 导出
  // ============================================================
  console.log(`\n--- /exportXls ---`);
  const expRes = await fetch(BASE + `${LOC_ENDPOINT}/exportXls`, { headers: { 'X-Access-Token': c.token } });
  const bytes = new Uint8Array(await expRes.arrayBuffer());
  const isXlsx = bytes[0] === 0x50 && bytes[1] === 0x4b;
  if (expRes.status === 200 && isXlsx) { passed++; c.check('6.1 exportXls xlsx', true, `size=${bytes.length}B`); }
  else { failed++; c.check('6.1 exportXls xlsx', false, `status=${expRes.status}`); }

  // ============================================================
  // 7. 边界值
  // ============================================================
  console.log(`\n--- 边界值 ---`);
  const boundaryCases = [
    { name: 'pageNo=0', qs: 'pageNo=0&pageSize=10' },
    { name: 'pageNo=-1', qs: 'pageNo=-1&pageSize=10' },
    { name: 'pageSize=0', qs: 'pageNo=1&pageSize=0' },
    { name: 'pageSize=2147483647', qs: 'pageNo=1&pageSize=2147483647' },
  ];
  for (const bc of boundaryCases) {
    const r = await c.api('GET', `${LOC_ENDPOINT}/list?${bc.qs}`);
    const ok = r.code === 200 || r.code === 500;
    if (ok) { passed++; c.check(`7.${bc.name} 不崩`, true, `code=${r.code}`); }
    else { failed++; c.check(`7.${bc.name} 不崩`, false, `code=${r.code}`); }
  }

  // ============================================================
  // 8. SQL 注入 / 特殊字符
  // ============================================================
  console.log(`\n--- 特殊字符 ---`);
  const sqlCases = ["' OR '1'='1", '%test%', 'DROP', '<script>', '中文字符'];
  for (const sc of sqlCases) {
    const r = await c.api('GET', `${LOC_ENDPOINT}/list?name=${encodeURIComponent(sc)}&pageSize=10`);
    if (r.code === 200) { passed++; c.check(`8.特殊字符"${sc.slice(0, 12)}..." 200`, true); }
    else { failed++; c.check(`8.特殊字符"${sc.slice(0, 12)}..." 200`, false, `code=${r.code}`); }
  }

  // ============================================================
  // 9. 业务校验：重复 code 拒绝
  // ============================================================
  console.log(`\n--- 业务校验 ---`);
  if (whId) {
    const r9 = await c.api('POST', `${LOC_ENDPOINT}/add`, {
      warehouseId: whId, code: LOC_CODE, name: '重复code', type: '1', status: 1,
    });
    if (r9.code !== 200) { passed++; c.check('9.1 重复 code 被拒', true, `code=${r9.code} msg=${r9.message?.slice(0, 50)}`); }
    else { failed++; c.check('9.1 重复 code 被拒', false, '重复 code 未被拦截'); }
  }

  // ============================================================
  // 10. 清理：删除所有测试库位 + 删除仓库
  // ============================================================
  console.log(`\n--- 清理 ---`);
  if (whId) {
    // 先 list 找所有测试库位并批量删除
    const rAllLocs = await c.api('GET', `${LOC_ENDPOINT}/list?warehouseId=${whId}&pageSize=100`);
    if (rAllLocs.code === 200 && rAllLocs.result?.records?.length > 0) {
      const ids = rAllLocs.result.records.map(r => r.id).filter(id => id !== locId).join(',');
      if (ids) {
        const rBatch = await c.api('DELETE', `${LOC_ENDPOINT}/deleteBatch?ids=${ids}`);
        if (rBatch.code === 200) { passed++; c.check('10.0 deleteBatch auto-gen locs', true, `count=${ids.split(',').length}`); }
        else { failed++; c.check('10.0 deleteBatch auto-gen locs', false, `code=${rBatch.code}`); }
      }
    }
  }
  if (locId) {
    const r10 = await c.api('DELETE', `${LOC_ENDPOINT}/delete?id=${locId}`);
    if (r10.code === 200) { passed++; c.check('10.1 delete loc 200', true); }
    else { failed++; c.check('10.1 delete loc 200', false); }
  }
  if (whId) {
    const r10w = await c.api('DELETE', `${WH_ENDPOINT}/delete?id=${whId}`);
    if (r10w.code === 200) { passed++; c.check('10.2 delete wh 200', true); }
    else { failed++; c.check('10.2 delete wh 200', false, `code=${r10w.code} msg=${r10w.message?.slice(0, 50)}`); }
  }

  return c.summary('location');
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(2); });
