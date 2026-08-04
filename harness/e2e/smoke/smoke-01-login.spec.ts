// Smoke Test 1: 登录
// 验证：登录接口返回 Token（HTTP 200 + code=200 + token 非空）
// 来源：test-e2e skill 冒烟测试集
import { test, expect } from '@playwright/test';

const API_BASE = process.env.E2E_API_BASE || 'http://localhost:8080/jeecg-boot';

test('冒烟 1: 登录接口返回 Token', async ({ request }) => {
  const res = await request.post(`${API_BASE}/sys/login`, {
    data: { username: 'admin', password: '123456' },
    headers: { 'Content-Type': 'application/json' },
  });
  expect(res.status(), 'HTTP 状态码').toBe(200);

  const body = await res.json();
  expect(body.code, '业务 code').toBe(200);
  expect(body.result?.token, 'token 非空').toBeTruthy();
  expect(body.result.token.length, 'token 长度 > 50').toBeGreaterThan(50);
  console.log(`  · token 前缀: ${body.result.token.substring(0, 20)}...`);
});