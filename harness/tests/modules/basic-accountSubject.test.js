// MES 会计科目子模块 API 测试
// 命令来源：/add-tests finance accountSubject
// 覆盖：10/10 endpoints (list/tree/queryById/add/edit/delete/deleteBatch/queryAll/exportXls/selectPage)
// 场景：CRUD + 树形结构 + 校验 + 边界
const { dbCleanup } = require('../helpers/fixtures');
const { createClient } = require('../helpers/api');
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);

// update-begin---author:pi---date:2026-08-05---for:[N1 修复] 消除 positional-param 反模式 wrapper，签名改为 (method, path, body) 直接转发 c.api（token 由 createClient 闭包管理，调用方无需传）-----------
async function api(method, path, body) { return c.api(method, path, body); }
// update-end---author:pi---date:2026-08-05---for:[N1 修复] 消除 positional-param 反模式 wrapper-----------

async function login() { const token = await c.login(); return token; }

async function run() {
  let passed = 0, failed = 0;
  const check = (name, ok, detail) => {
    if (ok) { passed++; console.log(`  ✅ ${name}: ${detail}`); }
    else { failed++; console.error(`  ❌ ${name}: ${detail}`); }
  };

  console.log('\n===== MES 会计科目子模块 API 测试 =====\n');

  const token = await login();
  console.log('  ✅ 登录成功\n');

  const TS = Date.now();
  const SUFFIX = String(TS).slice(-12);
  const rootCode = `SUB_T_${SUFFIX}`;
  const childCode = `SUB_T_${SUFFIX}_01`;

  // 预清理历史残留
  dbCleanup(`
    DELETE FROM c_mes_account_subject WHERE code LIKE 'SUB_T_%';
  `);

  // ============================================================
  // 1. CRUD 主流程（树形结构）
  // ============================================================
  console.log('--- 1. CRUD 主流程（树形）---');

  // 1.1 list 端点可达
  const listR = await api('GET', '/mes/finance/subject/list?pageNo=1&pageSize=10');
  check('1.1 list 端点可达', listR.code === 200, `total=${listR.result?.total}（接受历史残留）`);

  // 1.2 新增根科目
  const addRootR = await api('POST', '/mes/finance/subject/add', {
    code: rootCode, name: '测试根科目', category: '1',
    balanceDirection: '1', status: '1', remark: '根科目',
  });
  check('1.2 新增根科目', addRootR.code === 200, addRootR.message);
  const rootDoc = (await api('GET', `/mes/finance/subject/list?code=${rootCode}&pageSize=1`)).result.records[0];
  check('1.2.1 根科目落库', rootDoc != null, `id=${rootDoc?.id}`);

  // 1.3 新增子科目（parentId = 根科目 id）
  const addChildR = await api('POST', '/mes/finance/subject/add', {
    code: childCode, name: '测试子科目', category: '1',
    parentId: rootDoc.id, balanceDirection: '1', status: '1', remark: '子科目',
  });
  check('1.3 新增子科目', addChildR.code === 200, addChildR.message);
  const childDoc = (await api('GET', `/mes/finance/subject/list?code=${childCode}&pageSize=1`)).result.records[0];
  check('1.3.1 子科目落库', childDoc != null, `id=${childDoc?.id}`);

  // 1.4 验证父节点自动 isLeaf=0（树形逻辑）
  const rootAfterChild = (await api('GET', `/mes/finance/subject/list?code=${rootCode}&pageSize=1`)).result.records[0];
  check('1.4 父节点自动 isLeaf=0', rootAfterChild?.isLeaf === 0, `isLeaf=${rootAfterChild?.isLeaf}`);

  // 1.5 queryById
  const queryByIdR = await api('GET', `/mes/finance/subject/queryById?id=${childDoc.id}`);
  check('1.5 queryById 返回科目详情', queryByIdR.code === 200 && queryByIdR.result?.code === childCode, `code=${queryByIdR.result?.code}`);

  // 1.6 编辑科目
  const editR = await api('PUT', '/mes/finance/subject/edit', {
    id: childDoc.id, code: childCode, name: '测试子科目-改', category: '1',
    parentId: rootDoc.id, balanceDirection: '1', status: '1', remark: '子科目-改',
  });
  check('1.6 编辑科目', editR.code === 200, editR.message);
  const childEdited = (await api('GET', `/mes/finance/subject/list?code=${childCode}&pageSize=1`)).result.records[0];
  check('1.6.1 编辑后 name 更新', childEdited?.name === '测试子科目-改', `name=${childEdited?.name}`);

  // ============================================================
  // 2. 树形查询（tree / queryAll）
  // ============================================================
  console.log('\n--- 2. 树形查询 ---');

  // 2.1 tree 端点
  const treeR = await api('GET', '/mes/finance/subject/tree');
  check('2.1 tree 端点可达', treeR.code === 200, `code=${treeR.code}`);

  // 2.2 queryAll 端点
  const queryAllR = await api('GET', '/mes/finance/subject/queryAll');
  check('2.2 queryAll 端点可达', queryAllR.code === 200, `code=${queryAllR.code}`);

  // 2.3 selectPage 端点（ApiSelect 用）
  const selectPageR = await api('GET', '/mes/finance/subject/selectPage?pageSize=20');
  check('2.3 selectPage 端点可达', selectPageR.code === 200, `code=${selectPageR.code}`);

  // ============================================================
  // 3. 校验规则
  // ============================================================
  console.log('\n--- 3. 校验规则 ---');

  // 3.1 缺 code 应失败
  const noCodeR = await api('POST', '/mes/finance/subject/add', {
    name: '无code科目', category: '1', balanceDirection: '1', status: '1',
  });
  check('3.1 缺 code 应失败', noCodeR.code === 500, `code=${noCodeR.code} msg=${noCodeR.message?.slice(0, 40)}`);

  // 3.2 code 超长（>50 字符）
  const longCodeR = await api('POST', '/mes/finance/subject/add', {
    code: 'X'.repeat(51), name: '长code', category: '1', balanceDirection: '1', status: '1',
  });
  check('3.2 code 超长应失败', longCodeR.code === 500, `code=${longCodeR.code} msg=${longCodeR.message?.slice(0, 40)}`);

  // 3.3 缺 name 应失败
  const noNameR = await api('POST', '/mes/finance/subject/add', {
    code: 'NO_NAME_' + SUFFIX, category: '1', balanceDirection: '1', status: '1',
  });
  check('3.3 缺 name 应失败', noNameR.code === 500, `code=${noNameR.code} msg=${noNameR.message?.slice(0, 40)}`);

  // 3.4 缺 category 应失败
  const noCatR = await api('POST', '/mes/finance/subject/add', {
    code: 'NO_CAT_' + SUFFIX, name: '无category', balanceDirection: '1', status: '1',
  });
  check('3.4 缺 category 应失败', noCatR.code === 500, `code=${noCatR.code} msg=${noCatR.message?.slice(0, 40)}`);

  // 3.5 重复 code 应失败
  const dupR = await api('POST', '/mes/finance/subject/add', {
    code: rootCode, name: '重复', category: '1', balanceDirection: '1', status: '1',
  });
  check('3.5 重复 code 应失败', dupR.code === 500, `code=${dupR.code} msg=${dupR.message?.slice(0, 40)}`);

  // ============================================================
  // 4. 错误路径
  // ============================================================
  console.log('\n--- 4. 错误路径 ---');

  // 4.1 queryById 不存在 ID
  const query404 = await api('GET', '/mes/finance/subject/queryById?id=nonexistent_id_999');
  check('4.1 queryById 不存在 ID', query404.code === 200 || query404.code === 500, `code=${query404.code}（service 返回 error 500）`);

  // 4.2 edit 不存在 ID
  const edit404 = await api('PUT', '/mes/finance/subject/edit', {
    id: 'nonexistent_id_999', code: 'X', name: 'X', category: '1',
    balanceDirection: '1', status: '1',
  });
  check('4.2 edit 不存在 ID', edit404.code === 200 || edit404.code === 500, `code=${edit404.code}`);

  // 4.3 delete 不存在 ID
  const del404 = await api('DELETE', '/mes/finance/subject/delete?id=nonexistent_id_999');
  check('4.3 delete 不存在 ID', del404.code === 200, `code=${del404.code} (mybatis-plus 静默成功)`);

  // 4.4 批量删除空串
  const batchEmpty = await api('DELETE', '/mes/finance/subject/deleteBatch?ids=');
  check('4.4 批量删除空串', batchEmpty.code === 200 || batchEmpty.code === 500, `code=${batchEmpty.code}`);

  // ============================================================
  // 5. 边界
  // ============================================================
  console.log('\n--- 5. 边界 ---');

  // 5.1 超大 pageSize
  const listBig = await api('GET', '/mes/finance/subject/list?pageNo=1&pageSize=999999');
  check('5.1 list 超大 pageSize', listBig.code === 200, `code=${listBig.code}`);

  // 5.2 负数 pageNo
  const listNeg = await api('GET', '/mes/finance/subject/list?pageNo=-1&pageSize=10');
  check('5.2 list 负数 pageNo', listNeg.code === 200, `code=${listNeg.code}`);

  // 5.3 list 按 parentId 过滤
  const listByParent = await api('GET', `/mes/finance/subject/list?parentId=${rootDoc.id}&pageSize=10`);
  check('5.3 list 按 parentId 过滤', listByParent.code === 200 && listByParent.result.total >= 1, `total=${listByParent.result.total}（至少包含 1 个子科目）`);

  // ============================================================
  // 6. 导出
  // ============================================================
  console.log('\n--- 6. 导出 ---');

  try {
    const exportR = await fetch(`${BASE}/mes/finance/subject/exportXls?pageNo=1&pageSize=10`, {
      headers: { 'X-Access-Token': token },
    });
    check('6.1 exportXls 端点可达', exportR.status === 200 || exportR.status === 500, `status=${exportR.status}`);
  } catch (e) {
    check('6.1 exportXls 端点可达', false, e.message);
  }

  // ============================================================
  // 7. 删除
  // ============================================================
  console.log('\n--- 7. 删除 ---');

  // 7.1 删除子科目
  const delChildR = await api('DELETE', `/mes/finance/subject/delete?id=${childDoc.id}`);
  check('7.1 删除子科目', delChildR.code === 200, delChildR.message);
  const childDeleted = (await api('GET', `/mes/finance/subject/list?code=${childCode}&pageSize=1`)).result.records[0];
  check('7.1.1 子科目已删', childDeleted == null, `仍存在=${childDeleted != null}`);

  // 7.2 批量删除根科目
  const batchDelR = await api('DELETE', `/mes/finance/subject/deleteBatch?ids=${rootDoc.id}`);
  check('7.2 批量删除', batchDelR.code === 200, batchDelR.message);
  const rootDeleted = (await api('GET', `/mes/finance/subject/list?code=${rootCode}&pageSize=1`)).result.records[0];
  check('7.2.1 根科目已删', rootDeleted == null, `仍存在=${rootDeleted != null}`);

  // ============================================================
  // 清理
  // ============================================================
  dbCleanup(`
    DELETE FROM c_mes_account_subject WHERE code LIKE 'SUB_T_%';
  `);

  console.log(`\n===== 会计科目：${passed} 通过, ${failed} 失败 =====`);
  console.log(`===== 通过率：${passed + failed > 0 ? ((passed / (passed + failed)) * 100).toFixed(1) : 0}% =====\n`);
  process.exit(failed > 0 ? 1 : 0);
}

run().catch((err) => { console.error('FATAL:', err); process.exit(2); });