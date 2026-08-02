// Smoke Test 3: 角色列表 + 权限树
// 验证：角色列表接口返回数据 + 权限树加载无致命错误（前端 UI 通过 system/role 路径访问）
// 来源：test-e2e skill 冒烟测试集
import { test, expect } from '@playwright/test';

const API_BASE = process.env.E2E_API_BASE || 'http://100.122.125.106:8080/jeecg-boot';

test('冒烟 3: 角色列表加载 + 权限树渲染', async () => {
  // 1. 登录拿 token（用 fetch 而非 Playwright request）
  const loginRes = await fetch(`${API_BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' }),
  });
  expect(loginRes.status, 'login HTTP').toBe(200);
  const { result: { token } } = await loginRes.json();
  expect(token, 'token 非空').toBeTruthy();

  // 2. API 验证：角色列表
  const roleRes = await fetch(`${API_BASE}/sys/role/list?pageNo=1&pageSize=10`, {
    headers: { 'X-Access-Token': token },
  });
  expect(roleRes.status, 'role-list HTTP').toBe(200);
  const body = await roleRes.json();
  // JeecgBoot 接口语义: success=true 且 code=0 表示业务成功
  expect(body.success, 'role-list success').toBe(true);
  expect(body.code, 'role-list code').toBe(0);
  expect(body.result?.total, '角色总数 > 0').toBeGreaterThan(0);
  console.log(`  · role total: ${body.result.total}`);

  // 3. 权限树 API 验证：/sys/permission/list（菜单/权限）
  const permRes = await fetch(`${API_BASE}/sys/permission/list?pageNo=1&pageSize=100`, {
    headers: { 'X-Access-Token': token },
  });
  expect(permRes.status, 'permission-list HTTP').toBe(200);
  const permBody = await permRes.json();
  expect(permBody.success, 'permission-list success').toBe(true);
  expect(permBody.code, 'permission-list code').toBe(0);
  expect(permBody.result?.length, '权限节点 > 0').toBeGreaterThan(0);
  console.log(`  · permission nodes: ${permBody.result.length}`);
});