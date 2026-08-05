// Smoke Test 4: 退出登录
// 验证：登出接口返回成功 + 清除 Token 后重定向到登录页
// 来源：test-e2e skill 冒烟测试集
import { test, expect } from '@playwright/test';

const API_BASE = process.env.E2E_API_BASE || 'http://localhost:8080/jeecg-boot';
const UI_BASE = process.env.E2E_UI_BASE || 'http://localhost:4173';

test('冒烟 4: 登出接口 + 重定向到登录页', async ({ page }) => {
  // 1. 登录拿 token（用 fetch 而非 Playwright request）
  const loginRes = await fetch(`${API_BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' }),
  });
  expect(loginRes.status, 'login HTTP').toBe(200);
  const { result: { token } } = await loginRes.json();

  // 2. 注入 token 进入受保护页面
  await page.goto(`${UI_BASE}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(800);
  await page.evaluate((t: string) => {
    const key = Object.keys(localStorage).find((k) => k.includes('COMMON__LOCAL__KEY__'))
      || 'JEECGBOOT_PRO__DOCKER__3.9.2__COMMON__LOCAL__KEY__';
    const cache: any = { value: { TOKEN__: { value: t, time: Date.now(), expire: Date.now() + 7*24*3600*1000 } }, time: Date.now(), expire: Date.now() + 7*24*3600*1000 };
    localStorage.setItem(key, JSON.stringify(cache));
  }, token);

  // 3. 调用登出 API（用 fetch）
  const logoutRes = await fetch(`${API_BASE}/sys/logout`, {
    method: 'POST',
    headers: { 'X-Access-Token': token },
  });
  expect(logoutRes.status, 'logout HTTP').toBe(200);
  const logoutBody = await logoutRes.json();
  expect(logoutBody.code, '登出业务 code').toBe(200);
  console.log(`  · logout: ${logoutBody.message}`);

  // 4. 清除 localStorage 后访问受保护页面，期望重定向到登录页
  await page.evaluate(() => {
    const key = Object.keys(localStorage).find((k) => k.includes('COMMON__LOCAL__KEY__'));
    if (key) localStorage.removeItem(key);
  });
  await page.goto(`${UI_BASE}/system/role`);
  await page.waitForTimeout(3000);

  const currentUrl = page.url();
  expect(currentUrl, '未登录访问受保护页应重定向到 /login').toContain('/login');
  console.log(`  · redirected to: ${currentUrl}`);
});