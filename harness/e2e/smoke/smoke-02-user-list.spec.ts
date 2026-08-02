// Smoke Test 2: 用户列表
// 验证：登录后能拿到用户列表数据（records 长度 > 0）
// 来源：test-e2e skill 冒烟测试集
import { test, expect } from '@playwright/test';

const API_BASE = process.env.E2E_API_BASE || 'http://100.122.125.106:8080/jeecg-boot';

test('冒烟 2: 用户列表加载 + 数据展示', async () => {
  // 1. 登录拿 token（用 fetch 而非 Playwright request 以避免 baseURL 干扰）
  const loginRes = await fetch(`${API_BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' }),
  });
  expect(loginRes.status, 'login HTTP').toBe(200);
  const { result: { token } } = await loginRes.json();
  expect(token, 'token 非空').toBeTruthy();

  // 2. 拉用户列表
  const userRes = await fetch(`${API_BASE}/sys/user/list?pageNo=1&pageSize=10`, {
    headers: { 'X-Access-Token': token },
  });
  expect(userRes.status, 'user-list HTTP').toBe(200);

  const body = await userRes.json();
  // JeecgBoot 接口语义: success=true 且 code=0 表示业务成功
  expect(body.success, 'user-list success').toBe(true);
  expect(body.code, 'user-list code').toBe(0);
  expect(body.result?.total, '用户总数 > 0').toBeGreaterThan(0);
  expect(body.result.records.length, 'records 长度 > 0').toBeGreaterThan(0);
  console.log(`  · user total: ${body.result.total} / first: ${body.result.records[0].username}`);
});