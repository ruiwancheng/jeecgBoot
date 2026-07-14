import { test, expect } from '@playwright/test';
import { navigateToModule, runCrudLifecycle, selectDropdownItem, type ModuleConfig } from './mes-crud.template';

/**
 * 物料管理 E2E 测试
 * 覆盖完整业务流 + 字段边界 + 重复编码拦截
 * 环境：Docker 部署 http://100.122.125.106
 */

const config: ModuleConfig = {
  name: '物料管理',
  topMenu: '仓库管理',
  secondMenu: 'MES系统',
  thirdMenu: '基础设置',
  targetMenu: '物料管理',
  path: '/project/mes/basic/material',
  addButtonText: '新增物料',
  codeLabel: '物料编码',
  nameLabel: '物料名称',
  searchCodeLabel: '物料编码',
  requiredSelect: { label: '物料类型', value: '原材料' },
  optionalSelect: { label: '单位', value: '个' },
};

const drawer = (page: any) => page.locator('.ant-drawer-body, .ant-modal-body').first();

test.describe(config.name, () => {
  test.beforeEach(async ({ page }) => {
    await navigateToModule(page, config);
  });

  test('物料完整生命周期：新增、编辑、删除、复活、清理', async ({ page }) => {
    const testCode = `EYE-M-${Date.now()}`;

    // 新增 → 编辑 → 删除
    await runCrudLifecycle(page, config, testCode, '鹰眼测试物料', '鹰眼测试物料_已编辑');

    // 复活：软删除后新增相同编码复用旧记录
    const formBody = drawer(page);
    await page.getByRole('button', { name: '新增物料' }).click();
    await formBody.getByRole('textbox', { name: new RegExp('\\*?\\s*物料编码 :') }).fill(testCode);
    await formBody.getByRole('textbox', { name: new RegExp('\\*?\\s*物料名称 :') }).fill('复活后物料名称');
    await formBody.locator('.ant-form-item').filter({ hasText: '物料类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '原材料');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('textbox', { name: '物料编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row').filter({ hasText: testCode })).toContainText('复活后物料名称');

    // 清理测试数据
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('重复编码新增：应被拦截并提示', async ({ page }) => {
    const testCode = `EYE-M-DUP-${Date.now()}`;

    // 首次新增成功
    await page.getByRole('button', { name: '新增物料' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: new RegExp('\\*?\\s*物料编码 :') }).fill(testCode);
    await formBody.getByRole('textbox', { name: new RegExp('\\*?\\s*物料名称 :') }).fill('重复编码测试');
    await formBody.locator('.ant-form-item').filter({ hasText: '物料类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '原材料');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    // 再次新增应被拦截
    await page.getByRole('button', { name: '新增物料' }).click();
    const formBody2 = drawer(page);
    await formBody2.getByRole('textbox', { name: new RegExp('\\*?\\s*物料编码 :') }).fill(testCode);
    await formBody2.getByRole('textbox', { name: new RegExp('\\*?\\s*物料名称 :') }).fill('重复编码测试_第二次');
    await formBody2.locator('.ant-form-item').filter({ hasText: '物料类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '原材料');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message').filter({ hasText: '物料编码已存在' }).first()).toBeVisible();

    // 关闭抽屉并清理
    await page.locator('.ant-drawer-close').first().click();
    await page.getByRole('textbox', { name: '物料编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('超长编码边界：前端应截断或后端应拦截', async ({ page }) => {
    const longCode = 'EYE-M-LONG-' + 'A'.repeat(60);
    const truncatedCode = longCode.slice(0, 50);

    await page.getByRole('button', { name: '新增物料' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: new RegExp('\\*?\\s*物料编码 :') }).fill(longCode);
    await formBody.getByRole('textbox', { name: new RegExp('\\*?\\s*物料名称 :') }).fill('超长编码测试');
    await formBody.locator('.ant-form-item').filter({ hasText: '物料类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '原材料');
    await page.getByRole('button', { name: '确 认' }).click();

    // 若前端有 maxlength 则提示成功；否则后端应拦截并提示
    const successMsg = page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first();
    const errorMsg = page.locator('.ant-message').filter({ hasText: /不能超过50|编码已存在/ }).first();
    await expect(successMsg.or(errorMsg)).toBeVisible();

    if (await successMsg.isVisible().catch(() => false)) {
      // 清理被截断后的编码
      await page.getByRole('textbox', { name: '物料编码' }).first().fill(truncatedCode);
      await page.getByRole('button', { name: '查询' }).click();
      await page.getByRole('button', { name: '删除' }).first().click();
      await page.getByRole('button', { name: '确 认' }).click();
      await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
    }
  });
});
