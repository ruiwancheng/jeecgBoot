import { test, expect } from '@playwright/test';
import { loginViaApi, BASE } from './helpers/auth';

test.describe('物料选择窗口', () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test('销售订单-批量添加物料', async ({ page }) => {
    // 1. 打开销售订单页面
    await page.goto(`${BASE}/project/mes/sales/order`);
    await page.waitForTimeout(2000);
    console.log('✅ 页面加载');

    // 2. 点击新增
    await page.click('button:has-text("新增订单")');
    await page.waitForTimeout(1500);

    // 3. 验证两个按钮
    const addLineBtn = page.locator('button:has-text("添加行")');
    const addMaterialBtn = page.locator('button:has-text("添加物料")');
    expect(await addLineBtn.isVisible()).toBeTruthy();
    expect(await addMaterialBtn.isVisible()).toBeTruthy();
    console.log('✅ 添加行 + 添加物料 按钮');

    // 4. 打开物料选择弹窗
    await addMaterialBtn.click();
    await page.waitForTimeout(2000);

    // 5. 验证弹窗（multiple 模式）
    const modal = page.locator('.ant-modal').filter({ hasText: '选择物料' }).first();
    expect(await modal.isVisible()).toBeTruthy();
    console.log('✅ 选择物料弹窗');

    // 6. 勾选第一个物料（multiple 模式是 checkbox）
    await modal.locator('.ant-checkbox-wrapper').first().click();
    await page.waitForTimeout(500);
    console.log('✅ 已勾选物料');

    // 7. 确认（ant 按钮两汉字间有空格：确 认）
    await modal.getByRole('button', { name: '确 认' }).click();
    await page.waitForTimeout(1000);

    // 8. 截图验证
    await page.screenshot({ path: '/tmp/material-done.png', fullPage: true });
    console.log('📸 /tmp/material-done.png');
  });
});
