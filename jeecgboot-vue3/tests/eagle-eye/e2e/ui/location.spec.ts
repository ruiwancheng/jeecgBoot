import { test, expect } from '@playwright/test';
import { navigateToModule, type ModuleConfig } from './mes-crud.template';

/**
 * 库位管理 E2E 测试
 * 依赖：仓库数据存在，新增库位时需选择仓库
 */

const config: ModuleConfig = {
  name: '库位管理',
  topMenu: 'MES系统',
  secondMenu: '基础设置',
  thirdMenu: '库位管理',
  targetMenu: '库位管理',
  path: '/project/mes/basic/location',
  addButtonText: '新增库位',
  codeLabel: '库位编码',
  nameLabel: '库位名称',
  searchCodeLabel: '库位编码',
};

const drawer = (page: any) => page.locator('.ant-drawer-body, .ant-modal-body').first();

async function selectFirstWarehouse(page: any) {
  // 左侧仓库列表选择第一个仓库，为新增库位提供 warehouseId
  const tree = page.locator('.ant-tree');
  await tree.locator('.ant-tree-title').first().waitFor();
  await tree.locator('.ant-tree-title').first().click();
  await page.waitForTimeout(300);
}

async function selectWarehouseZoneShelf(page: any) {
  // 回退为仓库-库位两级后，抽屉内无仓库选择器，依赖左侧树传入 warehouseId
  await selectFirstWarehouse(page);
}

async function clearWarehouseSelection(page: any) {
  // 刷新页面后左侧仓库树无选中状态
  await page.reload();
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(500);
}

test.describe(config.name, () => {
  test.beforeEach(async ({ page }) => {
    await navigateToModule(page, config);
    // 库位管理依赖左侧仓库选择，新增前需先选中仓库
    await selectWarehouseZoneShelf(page);
  });

  test('库位完整生命周期：新增、编辑、删除、复活、清理', async ({ page }) => {
    const testCode = `EYE-L-${Date.now()}`;

    // 新增
    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 库位编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '库位名称 :' }).fill('鹰眼测试库位');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    // 查询
    await page.getByRole('textbox', { name: '库位编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText('鹰眼测试库位');

    // 编辑
    await page.getByRole('button', { name: '编辑' }).first().click();
    await drawer(page).getByRole('textbox', { name: '库位名称 :' }).fill('鹰眼测试库位_已编辑');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '编辑成功' }).first()).toBeVisible();

    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText('鹰眼测试库位_已编辑');

    // 删除
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();

    // 借尸还魂
    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody2 = drawer(page);
    await formBody2.getByRole('textbox', { name: '* 库位编码 :' }).fill(testCode);
    await formBody2.getByRole('textbox', { name: '库位名称 :' }).fill('复活后库位');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('textbox', { name: '库位编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText('复活后库位');

    // 清理
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('必填字段校验：库位编码为空', async ({ page }) => {
    await page.getByRole('button', { name: '新增库位' }).click();
    await page.getByRole('button', { name: '确 认' }).click();

    const formBody = drawer(page);
    await expect(formBody.locator('.ant-form-item-has-error').filter({ hasText: '库位编码' })).toBeVisible();
  });

  test('唯一编码重复校验：同仓库下已存在的库位编码应被拦截', async ({ page }) => {
    const testCode = `EYE-L-DUP-${Date.now()}`;

    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 库位编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '库位名称 :' }).fill('鹰眼测试库位');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody2 = drawer(page);
    await formBody2.getByRole('textbox', { name: '* 库位编码 :' }).fill(testCode);
    await formBody2.getByRole('textbox', { name: '库位名称 :' }).fill('重复编码测试');
    await page.getByRole('button', { name: '确 认' }).click();

    await expect(page.locator('.ant-message').filter({ hasText: '该仓库下已存在相同编码的库位' }).first()).toBeVisible({ timeout: 5000 });
    await page.locator('.ant-drawer-close').first().click();

    await page.getByRole('textbox', { name: '库位编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toHaveCount(1);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  // 当前已知缺陷：未选仓库时新增库位未在前端拦截，会触发后端 SQL 异常
  test.fail('未选择仓库时新增库位：应被拦截并提示选择仓库', async ({ page }) => {
    await clearWarehouseSelection(page);

    await page.getByRole('button', { name: '新增库位' }).click();
    // 期望前端提示：未选择仓库
    await expect(page.locator('.ant-message').filter({ hasText: /仓库/ }).first()).toBeVisible({ timeout: 5000 });

    // 进一步确认没有提交到后端导致 SQL 异常
    await expect(page.locator('.ant-message').filter({ hasText: 'Error updating database' })).not.toBeVisible();
  });

  test('超长库位编码输入校验：超过50字符应被截断或拦截', async ({ page }) => {
    const longCode = 'A'.repeat(60);
    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 库位编码 :' }).fill(longCode);
    const value = await formBody.getByRole('textbox', { name: '* 库位编码 :' }).inputValue();
    expect(value.length).toBeLessThanOrEqual(50);
  });

  test('快速重复提交：连续点击确认按钮不应产生重复数据', async ({ page }) => {
    const testCode = `EYE-L-DOUBLE-${Date.now()}`;
    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 库位编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '库位名称 :' }).fill('重复提交测试');
    // 连续快速点击两次确认，第二次可能因按钮 loading 被忽略
    await page.getByRole('button', { name: '确 认' }).click();
    await page.getByRole('button', { name: '确 认' }).click({ force: true }).catch(() => {});
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('textbox', { name: '库位编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toHaveCount(1);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('清空搜索条件后列表应恢复展示全部数据', async ({ page }) => {
    const searchBox = page.getByRole('textbox', { name: '库位编码' }).first();
    await searchBox.fill('NOT_EXISTS');
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-empty-description')).toContainText('暂无数据');

    await page.getByRole('button', { name: '重置' }).click();
    await page.waitForTimeout(500);
    // 重置后应展示当前仓库下的数据（表格可见）
    await expect(page.locator('.ant-table-body').first()).toBeVisible();
  });

  test('左侧仓库切换后右侧列表应正确刷新', async ({ page }) => {
    const tree = page.locator('.ant-tree');
    const nodes = await tree.locator('.ant-tree-title').all();
    if (nodes.length < 2) {
      test.skip();
      return;
    }
    // 先选择第二个仓库
    await nodes[1].click();
    await page.waitForTimeout(500);
    await expect(page.locator('.ant-table-body').first()).toBeVisible();
    // 再切回第一个仓库
    await nodes[0].click();
    await page.waitForTimeout(500);
    await expect(page.locator('.ant-table-body').first()).toBeVisible();
  });

  test('关闭抽屉后再次打开，表单应清空无残留', async ({ page }) => {
    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 库位编码 :' }).fill('RESIDUE_CODE');
    await formBody.getByRole('textbox', { name: '库位名称 :' }).fill('残留数据');
    await page.locator('.ant-drawer-close').first().click();
    await page.waitForTimeout(300);

    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody2 = drawer(page);
    const codeValue = await formBody2.getByRole('textbox', { name: '* 库位编码 :' }).inputValue();
    const nameValue = await formBody2.getByRole('textbox', { name: '库位名称 :' }).inputValue();
    expect(codeValue).toBe('');
    expect(nameValue).toBe('');
  });

  test('特殊字符库位名称保存后应正常显示', async ({ page }) => {
    const testCode = `EYE-L-SPEC-${Date.now()}`;
    const specialName = '库位!@#测试_2026';
    await page.getByRole('button', { name: '新增库位' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 库位编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '库位名称 :' }).fill(specialName);
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('textbox', { name: '库位编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText(specialName);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  // TODO: 跨模块验证（仓库删除时存在关联库位应被拦截），建议后续在仓库管理测试套件中实现
  test.skip('删除存在关联库位的仓库：应提示不能删除', async ({ page }) => {});

});
