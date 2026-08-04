import { test, expect } from './helpers/diagnostic-test';

const BASE = 'http://localhost:3100';

test.describe('MES 基础设置 E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(BASE + '/user/login');
    await page.waitForLoadState('networkidle');

    // 截图调试
    await page.screenshot({ path: '/tmp/login-debug.png' });

    // 直接用 Ant Design 表单中第一个 input 填账号，第二个填密码
    const inputs = page.locator('input:visible');
    const count = await inputs.count();
    if (count >= 2) {
      await inputs.nth(0).fill('mes_admin');
      await inputs.nth(1).fill('123456');
    }
    // 点登录按钮
    const btn = page.locator('button:has-text("登")').first();
    await btn.click();
    await page.waitForURL('**/dashboard/**', { timeout: 15000 }).catch(() => {});
    await page.waitForTimeout(2000);
  });

  test('仓库管理 — 页面加载 + 表格可见', async ({ page }) => {
    await page.goto(BASE + '/project/mes/basic/warehouse');
    await page.waitForTimeout(3000);

    await expect(page.locator('.ant-table')).toBeVisible({ timeout: 10000 });
    await expect(page.locator('button:has-text("新增")').first()).toBeVisible({ timeout: 5000 });
  });

  test('库位管理 — 左树右表 + 批量生成按钮', async ({ page }) => {
    await page.goto(BASE + '/project/mes/basic/location');
    await page.waitForTimeout(3000);

    await expect(page.locator('.ant-tree').first()).toBeVisible({ timeout: 10000 });
    await expect(page.locator('.ant-table').first()).toBeVisible({ timeout: 5000 });
    await expect(page.locator('button:has-text("批量生成")')).toBeVisible({ timeout: 5000 });
  });
});
