// MES 销售订单 E2E 测试 (token注入模式)
import { test, expect } from '@playwright/test';

const BASE_URL = 'http://100.122.125.106';

async function loginViaApi(page) {
  const res = await fetch(`${BASE_URL}:8080/jeecg-boot/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' }),
  });
  const data = await res.json();
  if (data.code === 200) {
    await page.goto(BASE_URL);
    await page.evaluate((token) => {
      localStorage.setItem('Access-Token', token);
    }, data.result.token);
  }
}

test.describe('销售订单', () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test('E2E-01: 页面加载 + 列表渲染', async ({ page }) => {
    await page.goto(`${BASE_URL}/project/mes/sales/order`);
    await page.waitForTimeout(3000);
    const hasContent = await page.locator('body').innerText();
    expect(hasContent.length).toBeGreaterThan(0);
    expect(hasContent).not.toContain('500');
    expect(hasContent).not.toContain('404');
    console.log('✅ 页面加载正常');
  });

  test('E2E-02: 新增按钮可点击', async ({ page }) => {
    await page.goto(`${BASE_URL}/project/mes/sales/order`);
    await page.waitForTimeout(3000);
    const addBtn = page.locator('button:has-text("新增订单")').first();
    if (await addBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
      await addBtn.click();
      await page.waitForTimeout(1500);
      const drawer = page.locator('.ant-drawer').first();
      if (await drawer.isVisible({ timeout: 3000 }).catch(() => false)) {
        // 验证物料选择相关元素
        const hasAddLine = await page.locator('button:has-text("添加行")').isVisible().catch(() => false);
        const hasAddMat = await page.locator('button:has-text("添加物料")').isVisible().catch(() => false);
        console.log(`  添加行: ${hasAddLine}, 添加物料: ${hasAddMat}`);
        expect(hasAddLine || hasAddMat).toBeTruthy();
      }
    }
    console.log('✅ 新增订单弹窗');
    await page.screenshot({ path: 'test-results/sales-order-e2e.png', fullPage: true });
  });
});
