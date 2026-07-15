import { test, expect } from '@playwright/test';

const BASE = 'http://100.122.125.106';
const TEST_CODE = `E2E-SUP-${Date.now()}`;

test.describe('供应商管理 E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE}/login`, { waitUntil: 'networkidle' });
    await page.waitForSelector('.ant-form', { timeout: 15000 });

    const accountInput = page.getByRole('textbox', { name: '账号' });
    const passwordInput = page.getByRole('textbox', { name: '密码' });
    await accountInput.clear();
    await accountInput.fill('admin');
    await passwordInput.clear();
    await passwordInput.fill('123456');

    await page.getByRole('button', { name: '登 录' }).click();
    await page.waitForURL('**/dashboard**', { timeout: 20000 }).catch(() => {});
    await page.waitForTimeout(2000);
  });

  test('供应商管理 - 页面加载和按钮可见', async ({ page }) => {
    await page.goto(`${BASE}/project/mes/basic/supplier`);
    await page.waitForSelector('.ant-table', { timeout: 10000 });

    // 验证表格渲染
    await expect(page.locator('.ant-table')).toBeVisible();

    // 验证操作按钮（j-upload-button 双重按钮结构，用 first() 避免歧义）
    await expect(page.getByRole('button', { name: '新增供应商' })).toBeVisible({ timeout: 5000 });
    await expect(page.getByRole('button', { name: '导出' })).toBeVisible({ timeout: 5000 });
    await expect(page.getByRole('button', { name: '导入' }).first()).toBeVisible({ timeout: 5000 });

    // 验证表头
    await expect(page.getByRole('columnheader', { name: '供应商编码' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: '供应商名称' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: '供应商类型' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: '供应商状态' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: '供应商等级' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: '黑名单' })).toBeVisible();
  });

  test('供应商管理 - 完整的CRUD流程', async ({ page }) => {
    await page.goto(`${BASE}/project/mes/basic/supplier`);
    await page.waitForSelector('.ant-table', { timeout: 10000 });

    // === 新增供应商 ===
    await page.getByRole('button', { name: '新增供应商' }).click();
    await page.waitForSelector('.ant-drawer-body', { timeout: 5000 });
    const drawer = page.locator('.ant-drawer-body');

    // 填写基础信息（type是必填字段）
    await drawer.locator('#form_item_code').fill(TEST_CODE);
    await drawer.locator('#form_item_name').fill('E2E测试供应商');

    // 选择供应商类型（必填）
    await drawer.locator('#form_item_type').locator('.ant-select').click();
    await page.locator('.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item').first().click();
    await page.waitForTimeout(500);

    await drawer.locator('#form_item_contact').fill('王五');
    await drawer.locator('#form_item_phone').fill('13700001111');
    await drawer.locator('#form_item_address').fill('广州市天河区');

    // 保存
    await page.locator('.ant-drawer .ant-btn-primary').last().click();
    await page.waitForTimeout(2500);

    // 验证列表中出现
    const row = page.locator(`.ant-table-tbody tr:has-text("${TEST_CODE}")`).first();
    await expect(row).toBeVisible({ timeout: 5000 });

    // === 编辑供应商 ===
    await row.getByRole('button', { name: '编辑' }).click();
    await page.waitForSelector('.ant-drawer-body', { timeout: 5000 });
    const editDrawer = page.locator('.ant-drawer-body');

    // 修改名称
    const nameInput = editDrawer.locator('#form_item_name');
    await nameInput.clear();
    await nameInput.fill('E2E测试供应商-已编辑');
    await page.locator('.ant-drawer .ant-btn-primary').last().click();
    await page.waitForTimeout(2000);

    // 验证编辑后行仍在
    const editedRow = page.locator(`.ant-table-tbody tr:has-text("${TEST_CODE}")`).first();
    await expect(editedRow).toBeVisible({ timeout: 5000 });

    // === 删除供应商 ===
    await editedRow.getByRole('button', { name: '删除' }).click();
    await page.waitForTimeout(500);
    const confirmBtn = page.locator('.ant-popconfirm .ant-btn-primary').first();
    if (await confirmBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await confirmBtn.click();
      await page.waitForTimeout(1500);
    }
    // 验证已删除
    await expect(page.locator(`.ant-table-tbody tr:has-text("${TEST_CODE}")`)).toHaveCount(0, { timeout: 5000 });
  });

  test('供应商管理 - 搜索表单验证', async ({ page }) => {
    await page.goto(`${BASE}/project/mes/basic/supplier`);
    await page.waitForSelector('.ant-table', { timeout: 10000 });

    // 验证搜索区域存在
    await expect(page.locator('.ant-form')).toBeVisible({ timeout: 5000 });

    // 验证搜索字段（使用 role 选择器，搜索表单不用 #form_item_ ID）
    const codeInput = page.getByRole('textbox', { name: '供应商编码' });
    const nameInput = page.getByRole('textbox', { name: '供应商名称' });
    await expect(codeInput).toBeVisible({ timeout: 3000 });
    await expect(nameInput).toBeVisible({ timeout: 3000 });

    // 验证查询/重置按钮
    await expect(page.getByRole('button', { name: '查询' })).toBeVisible({ timeout: 3000 });
    await expect(page.getByRole('button', { name: '重置' })).toBeVisible({ timeout: 3000 });
  });
});
