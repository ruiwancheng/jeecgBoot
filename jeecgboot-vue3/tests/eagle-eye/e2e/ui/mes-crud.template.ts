import { test, expect, type Locator, type Page } from '@playwright/test';

/**
 * 鹰眼团 MES 基础资料 UI 测试模板
 * 适用于：仓库管理、库位管理、客户管理 等标准单表 CRUD 页面
 * 使用方式：复制本模板，替换菜单路径、按钮名称、表单字段即可
 */

export interface ModuleConfig {
  /** 模块名称，如“客户管理”“仓库管理” */
  name: string;
  /** 顶部一级菜单文本 */
  topMenu: string;
  /** 二级菜单文本 */
  secondMenu: string;
  /** 三级菜单文本 */
  thirdMenu: string;
  /** 列表页面目标菜单文本（精确匹配） */
  targetMenu: string;
  /** 列表页面路由路径（直接导航，可选） */
  path?: string;
  /** 新增按钮文本 */
  addButtonText: string;
  /** 唯一编码字段在表单中的 label */
  codeLabel: string;
  /** 名称字段在表单中的 label */
  nameLabel: string;
  /** 列表查询区编码字段 placeholder 或 label */
  searchCodeLabel: string;
  /** 表单中必填下拉字段配置（没有可留空） */
  requiredSelect?: { label: string; value: string };
  /** 表单中可选下拉字段配置（没有可留空） */
  optionalSelect?: { label: string; value: string };
}

export async function navigateToModule(page: Page, config: ModuleConfig) {
  await page.goto('/login');
  const loginButton = page.getByRole('button', { name: '登 录' });
  await expect(loginButton).toBeVisible();

  const userInput = page.getByRole('textbox', { name: '账号' });
  if ((await userInput.inputValue().catch(() => '')) === '') {
    await userInput.fill('admin');
  }
  const pwdInput = page.getByRole('textbox', { name: '密码' });
  if ((await pwdInput.inputValue().catch(() => '')) === '') {
    await pwdInput.fill('123456');
  }

  await loginButton.click();
  await page.waitForURL((url) => !url.pathname.includes('/login'), { timeout: 30000 });

  if (config.path) {
    await page.goto(config.path);
  } else {
    await page.getByRole('listitem').filter({ hasText: config.topMenu }).first().click();
    await page.getByText(config.secondMenu).click();
    await page.getByText(config.thirdMenu).click();
    if (config.thirdMenu !== config.targetMenu) {
      await page.getByRole('listitem').filter({ hasText: config.targetMenu }).last().click();
    }
  }
  await expect(page.getByRole('button', { name: config.addButtonText })).toBeVisible();
}

export function drawer(page: Page) {
  return page.locator('.ant-drawer-body, .ant-modal-body').first();
}

export async function selectDropdownItem(page: Page, text: string) {
  const option = page.locator('.ant-select-dropdown').locator('.ant-select-item-option').filter({ hasText: text }).first();
  await option.waitFor({ state: 'visible', timeout: 5000 });
  await option.click();
}

export async function fillAddForm(
  page: Page,
  config: ModuleConfig,
  code: string,
  name: string
) {
  await page.getByRole('button', { name: config.addButtonText }).click();
  const formBody = drawer(page);
  await expect(formBody.getByRole('textbox', { name: new RegExp(`\\*?\\s*${config.codeLabel} :`) })).toBeVisible();

  await formBody.getByRole('textbox', { name: new RegExp(`\\*?\\s*${config.codeLabel} :`) }).fill(code);
  await formBody.getByRole('textbox', { name: new RegExp(`\\*?\\s*${config.nameLabel} :`) }).fill(name);

  if (config.requiredSelect) {
    await formBody
      .locator('.ant-form-item')
      .filter({ hasText: config.requiredSelect.label })
      .locator('.ant-select')
      .first()
      .click();
    await selectDropdownItem(page, config.requiredSelect.value);
  }

  if (config.optionalSelect) {
    await formBody
      .locator('.ant-form-item')
      .filter({ hasText: config.optionalSelect.label })
      .locator('.ant-select')
      .first()
      .click();
    await selectDropdownItem(page, config.optionalSelect.value);
  }

  await page.getByRole('button', { name: '确 认' }).click();
  await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();
}

export async function searchAndVerify(page: Page, config: ModuleConfig, code: string, ...expectedTexts: string[]) {
  await page.getByRole('textbox', { name: config.searchCodeLabel }).first().fill(code);
  await page.getByRole('button', { name: '查询' }).click();
  const targetRow = page.locator('.ant-table-row').filter({ hasText: code });
  for (const text of expectedTexts) {
    await expect(targetRow).toContainText(text);
  }
}

export async function deleteAndVerify(page: Page, config: ModuleConfig, code: string) {
  await page.getByRole('button', { name: '删除' }).first().click();
  await page.getByRole('button', { name: '确 认' }).click();
  await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();

  await page.getByRole('button', { name: '重置' }).click();
  await page.getByRole('textbox', { name: config.searchCodeLabel }).first().fill(code);
  await page.getByRole('button', { name: '查询' }).click();
  await expect(page.locator('.ant-empty-description')).toContainText('暂无数据');
}

export async function editAndVerify(
  page: Page,
  config: ModuleConfig,
  code: string,
  newName: string,
  verificationTexts: string[]
) {
  await page.getByRole('textbox', { name: config.searchCodeLabel }).first().fill(code);
  await page.getByRole('button', { name: '查询' }).click();
  await page.getByRole('button', { name: '编辑' }).first().click();

  await drawer(page).getByRole('textbox', { name: new RegExp(`\\*?\\s*${config.nameLabel} :`) }).fill(newName);
  await page.getByRole('button', { name: '确 认' }).click();
  await expect(page.locator('.ant-message-success').filter({ hasText: '编辑成功' }).first()).toBeVisible();

  await page.getByRole('button', { name: '查询' }).click();
  for (const text of verificationTexts) {
    const targetRow = page.locator('.ant-table-row').filter({ hasText: code });
    await expect(targetRow).toContainText(text);
  }
}

export async function runCrudLifecycle(page: Page, config: ModuleConfig, code: string, name: string, editedName: string) {
  await fillAddForm(page, config, code, name);
  await searchAndVerify(page, config, code, code, name);
  await editAndVerify(page, config, code, editedName, [editedName]);
  await deleteAndVerify(page, config, code);
}

/**
 * 使用示例（在 *.spec.ts 文件中）：
 *
 * import { test } from '@playwright/test';
 * import { navigateToModule, runCrudLifecycle, ModuleConfig } from './mes-crud.template';
 *
 * const config: ModuleConfig = {
 *   name: '客户管理',
 *   topMenu: '仓库管理',
 *   secondMenu: 'MES系统',
 *   thirdMenu: '基础设置',
 *   targetMenu: '客户管理',
 *   addButtonText: '新增客户',
 *   codeLabel: '客户编码',
 *   nameLabel: '客户名称',
 *   searchCodeLabel: '客户编码',
 *   requiredSelect: { label: '客户类型', value: '企业客户' },
 *   optionalSelect: { label: '客户等级', value: 'VIP' },
 * };
 *
 * test.describe(config.name, () => {
 *   test('完整生命周期', async ({ page }) => {
 *     await navigateToModule(page, config);
 *     const code = `EYE-C-${Date.now()}`;
 *     await runCrudLifecycle(page, config, code, '测试客户', '测试客户_已编辑');
 *   });
 * });
 */
