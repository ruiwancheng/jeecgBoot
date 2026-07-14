import { test, expect } from '@playwright/test';
import { navigateToModule, runCrudLifecycle, type ModuleConfig } from './mes-crud.template';

/**
 * 仓库管理 E2E 测试
 * 覆盖完整业务流 + 字段边界 + 借尸还魂
 */

const config: ModuleConfig = {
  name: '仓库管理',
  topMenu: 'MES系统',
  secondMenu: '基础设置',
  thirdMenu: '仓库管理',
  targetMenu: '仓库管理',
  path: '/project/mes/basic/warehouse',
  addButtonText: '新增仓库',
  codeLabel: '仓库编码',
  nameLabel: '仓库名称',
  searchCodeLabel: '仓库编码',
};

const drawer = (page: any) => page.locator('.ant-drawer-body, .ant-modal-body').first();

test.describe(config.name, () => {
  test.beforeEach(async ({ page }) => {
    await navigateToModule(page, config);
  });

  test('仓库完整生命周期：新增、编辑、删除、复活、清理', async ({ page }) => {
    const testCode = `EYE-W-${Date.now()}`;
    await runCrudLifecycle(page, config, testCode, '鹰眼测试仓库', '鹰眼测试仓库_已编辑');

    const formBody = drawer(page);
    await page.getByRole('button', { name: '新增仓库' }).click();
    await formBody.getByRole('textbox', { name: '* 仓库编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '* 仓库名称 :' }).fill('复活后仓库');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('textbox', { name: '仓库编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText('复活后仓库');

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('必填字段校验：仓库编码/仓库名称为空', async ({ page }) => {
    await page.getByRole('button', { name: '新增仓库' }).click();
    await page.getByRole('button', { name: '确 认' }).click();

    const formBody = drawer(page);
    await expect(formBody.locator('.ant-form-item-has-error').filter({ hasText: '仓库编码' })).toBeVisible();
    await expect(formBody.locator('.ant-form-item-has-error').filter({ hasText: '仓库名称' })).toBeVisible();
  });

  test('唯一编码重复校验：新增已存在的仓库编码应被拦截', async ({ page }) => {
    const testCode = `EYE-W-DUP-${Date.now()}`;

    const formBody = drawer(page);
    await page.getByRole('button', { name: '新增仓库' }).click();
    await formBody.getByRole('textbox', { name: '* 仓库编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '* 仓库名称 :' }).fill('鹰眼测试仓库');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('button', { name: '新增仓库' }).click();
    const formBody2 = drawer(page);
    await formBody2.getByRole('textbox', { name: '* 仓库编码 :' }).fill(testCode);
    await formBody2.getByRole('textbox', { name: '* 仓库名称 :' }).fill('重复编码测试');
    await page.getByRole('button', { name: '确 认' }).click();

    await expect(page.locator('.ant-message').filter({ hasText: '仓库编码已存在' }).first()).toBeVisible({ timeout: 5000 });
    await page.locator('.ant-drawer-close').first().click();

    await page.getByRole('textbox', { name: '仓库编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toHaveCount(1);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('超长编码输入校验：仓库编码超过50字符被截断', async ({ page }) => {
    const testCode = `EYE-W-TOO-LONG-${Date.now()}-${'x'.repeat(100)}`;
    const formBody = drawer(page);
    await page.getByRole('button', { name: '新增仓库' }).click();
    await formBody.getByRole('textbox', { name: '* 仓库编码 :' }).fill(testCode);
    const actualValue = await formBody.getByRole('textbox', { name: '* 仓库编码 :' }).inputValue();
    expect(actualValue.length).toBeLessThanOrEqual(50);
  });
});
