import { test, expect } from '@playwright/test';
test('销售订单-物料选择窗口验证', async ({ page }) => {
  // 1. 登录
  await page.goto('http://100.122.125.106');
  await page.fill('input[placeholder*="用户名"]', 'admin');
  await page.fill('input[placeholder*="密码"]', '123456');
  await page.click('button:has-text("登 录")');
  await page.waitForTimeout(2000);

  // 2. 导航到销售订单
  await page.goto('http://100.122.125.106/mes/sales/order');
  await page.waitForTimeout(2000);

  // 3. 点击新增
  await page.click('button:has-text("新增")');
  await page.waitForTimeout(1500);

  // 4. 验证关键元素
  const addLineBtn = page.locator('button:has-text("添加行")');
  const addMaterialBtn = page.locator('button:has-text("添加物料")');

  console.log('添加行按钮:', await addLineBtn.isVisible());
  console.log('添加物料按钮:', await addMaterialBtn.isVisible());

  // 5. 截图
  await page.screenshot({ path: '/tmp/sales-order-drawer.png', fullPage: true });
  console.log('截图已保存: /tmp/sales-order-drawer.png');
});
