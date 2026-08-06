// MES 采购模块 E2E 测试 (token注入模式)
import { test, expect } from './helpers/diagnostic-test';

const BASE_URL = BASE;

import { loginViaApi, BASE } from './helpers/auth';

// ====== 采购申请 ======
test.describe('采购申请', () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test('E2E-01: 页面加载 + 列表渲染', async ({ page }) => {
    const responses: number[] = [];
    page.on('response', (r) => {
      if (r.url().includes('/mes/') && !r.url().includes('/websocket/')) {
        responses.push(r.status());
      }
    });
    await page.goto(`${BASE_URL}/project/mes/purchase/apply`);
    await page.waitForTimeout(3000);
    // 验证页面有内容 + 后端 API 不报 500/404（避免 .toContain('500') 太严匹配到 CSS/链接文本）
    const hasContent = await page.locator('body').innerText();
    expect(hasContent.length, '页面 body 不应为空').toBeGreaterThan(0);
    const serverErrors = responses.filter((s) => s === 500 || s === 404);
    expect(serverErrors, `后端不应返回 500/404，实际: ${JSON.stringify(responses)}`).toEqual([]);
  });

  test('E2E-02: 新增按钮可点击 (R001)', async ({ page }) => {
    await page.goto(`${BASE_URL}/project/mes/purchase/apply`);
    await page.waitForTimeout(3000);
    const addBtn = page.locator('button:has-text("新增")').first();
    if (await addBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
      await addBtn.click();
      await page.waitForTimeout(1500);
      // 验证弹窗出现
      const drawer = page.locator('.ant-drawer').first();
      const visible = await drawer.isVisible({ timeout: 3000 }).catch(() => false);
      await page.locator('.ant-drawer button:has-text("取")').last().click().catch(() => {});
      expect(visible).toBeTruthy();
    }
  });

  test('E2E-03: SQL注入搜索 (R005)', async ({ page }) => {
    await page.goto(`${BASE_URL}/project/mes/purchase/apply`);
    await page.waitForTimeout(3000);
    const searchInput = page.locator('input').first();
    if (await searchInput.isVisible({ timeout: 2000 }).catch(() => false)) {
      await searchInput.fill("' OR '1'='1");
      await searchInput.press('Enter');
      await page.waitForTimeout(2000);
      const bodyText = await page.locator('body').innerText();
      expect(bodyText).not.toContain('SQLException');
      expect(bodyText).not.toContain('500');
    }
  });
});

// ====== 采购订单 ======
test.describe('采购订单', () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test('E2E-04: 页面加载', async ({ page }) => {
    await page.goto(`${BASE_URL}/project/mes/purchase/order`);
    await page.waitForSelector('.ant-table', { timeout: 15000 });
  });
});

// ====== 采购入库 ======
test.describe('采购入库', () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test('E2E-05: 页面加载', async ({ page }) => {
    await page.goto(`${BASE_URL}/project/mes/purchase/receipt`);
    await page.waitForSelector('.ant-table', { timeout: 15000 });
  });
});

// ====== 库存台账 ======
test.describe('库存台账', () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test('E2E-06: 页面加载自检', async ({ page }) => {
    await page.goto(`${BASE_URL}/project/mes/warehouse/ledger`);
    await page.waitForTimeout(3000);
    const bodyText = await page.locator('body').innerText();
    expect(bodyText).not.toContain('500');
    expect(bodyText).not.toContain('404');
  });
});
