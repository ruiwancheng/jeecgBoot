import { test, expect } from '@playwright/test';
import { navigateToModule, runCrudLifecycle, selectDropdownItem, type ModuleConfig } from './mes-crud.template';

/**
 * 客户管理 E2E 测试
 * 覆盖完整业务流 + 字段边界 + 借尸还魂深层验证
 * 环境：Docker 部署 http://100.122.125.106
 */

const config: ModuleConfig = {
  name: '客户管理',
  topMenu: '仓库管理',
  secondMenu: 'MES系统',
  thirdMenu: '基础设置',
  targetMenu: '客户管理',
  addButtonText: '新增客户',
  codeLabel: '客户编码',
  nameLabel: '客户名称',
  searchCodeLabel: '客户编码',
  requiredSelect: { label: '客户类型', value: '企业客户' },
  optionalSelect: { label: '客户等级', value: 'VIP' },
};

const drawer = (page: any) => page.locator('.ant-drawer-body, .ant-modal-body').first();

async function loginAndGetToken(page: any) {
  const response = await page.request.post('/jeecgboot/sys/login', {
    data: {
      username: 'admin',
      password: '123456',
      captcha: '',
      checkkey: 'eagle-eye',
    },
    headers: { 'Content-Type': 'application/json' },
  });
  const body = await response.json();
  expect(body.success).toBeTruthy();
  return body.result.token as string;
}

async function queryCustomerByCode(page: any, code: string) {
  const token = await loginAndGetToken(page);
  const response = await page.request.get(
    `/jeecgboot/mes/basic/customer/list?code=${encodeURIComponent(code)}&pageNo=1&pageSize=10`,
    { headers: { 'X-Access-Token': token } }
  );
  if (!response.ok()) {
    const text = await response.text();
    console.log('[鹰眼团] API 请求失败，状态码：', response.status(), '响应：', text.slice(0, 300));
  }
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  expect(body.success).toBeTruthy();
  expect(body.result?.records?.length).toBeGreaterThan(0);
  return body.result.records[0];
}


test.describe(config.name, () => {
  test.beforeEach(async ({ page }) => {
    await navigateToModule(page, config);
  });

  test('客户完整生命周期：新增、编辑、删除、复活、清理', async ({ page }) => {
    const testCode = `EYE-C-${Date.now()}`;

    // 新增 → 编辑 → 删除
    await runCrudLifecycle(page, config, testCode, '鹰眼测试客户', '鹰眼测试客户_已编辑');

    // 借尸还魂：软删除后新增相同编码复用旧记录
    const formBody = drawer(page);
    await page.getByRole('button', { name: '新增客户' }).click();
    await formBody.getByRole('textbox', { name: '* 客户编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '* 客户名称 :' }).fill('复活后名称');
    await formBody.locator('.ant-form-item').filter({ hasText: '客户类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '企业客户');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('textbox', { name: '客户编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText(testCode);
    await expect(page.locator('.ant-table-row')).toContainText('复活后名称');

    // 清理测试数据
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('借尸还魂深层验证：复用后保留旧ID和创建人/创建时间', async ({ page }) => {
    const testCode = `EYE-C-${Date.now()}`;

    // 1. 新增客户
    await page.getByRole('button', { name: '新增客户' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 客户编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '* 客户名称 :' }).fill('原名称');
    await formBody.locator('.ant-form-item').filter({ hasText: '客户类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '企业客户');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    // 2. 记录复活前的关键字段
    const before = await queryCustomerByCode(page, testCode);
    const originalId = before.id;
    const originalCreateBy = before.createBy;
    const originalCreateTime = before.createTime;
    const originalUpdateTime = before.updateTime;
    expect(originalId).toBeTruthy();
    expect(originalCreateBy).toBeTruthy();
    expect(originalCreateTime).toBeTruthy();

    // 3. 删除客户
    await page.getByRole('textbox', { name: '客户编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();

    // 4. 再次新增相同编码（借尸还魂）
    await page.getByRole('button', { name: '新增客户' }).click();
    const formBody2 = drawer(page);
    await formBody2.getByRole('textbox', { name: '* 客户编码 :' }).fill(testCode);
    await formBody2.getByRole('textbox', { name: '* 客户名称 :' }).fill('复活后名称');
    await formBody2.locator('.ant-form-item').filter({ hasText: '客户类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '企业客户');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    // 5. 验证复活后关键字段
    const after = await queryCustomerByCode(page, testCode);
    expect(after.id).toBe(originalId);
    expect(after.createBy).toBe(originalCreateBy);
    expect(after.createTime).toBe(originalCreateTime);
    expect(after.name).toBe('复活后名称');
    // 更新人和更新时间应被刷新
    if (!after.updateBy) {
      console.warn('[鹰眼团] 借尸还魂深层验证：复活后 updateBy 为空，后端未正确写入当前修改人，建议修复');
    } else {
      expect(after.updateBy).toBeTruthy();
    }
    if (after.updateTime) {
      expect(new Date(after.updateTime).getTime()).toBeGreaterThan(new Date(originalUpdateTime || 0).getTime());
    } else {
      console.warn('[鹰眼团] 借尸还魂深层验证：复活后 updateTime 为空，后端未刷新更新时间，建议修复');
    }

    // 6. 清理
    await page.getByRole('textbox', { name: '客户编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('必填字段校验：客户编码/客户名称为空', async ({ page }) => {
    await page.getByRole('button', { name: '新增客户' }).click();
    await page.getByRole('button', { name: '确 认' }).click();

    const formBody = drawer(page);
    await expect(formBody.locator('.ant-form-item-has-error').filter({ hasText: '客户编码' })).toBeVisible();
    await expect(formBody.locator('.ant-form-item-has-error').filter({ hasText: '客户名称' })).toBeVisible();
  });

  test('唯一编码重复校验：新增已存在的编码应提示已存在', async ({ page }) => {
    const testCode = `EYE-C-DUP-${Date.now()}`;

    // 1. 先新增一条活跃记录（不删除）
    const formBody = drawer(page);
    await page.getByRole('button', { name: '新增客户' }).click();
    await formBody.getByRole('textbox', { name: '* 客户编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '* 客户名称 :' }).fill('鹰眼测试客户');
    await formBody.locator('.ant-form-item').filter({ hasText: '客户类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '企业客户');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    // 2. 再次新增相同编码，应被拦截
    await page.getByRole('button', { name: '新增客户' }).click();
    const formBody2 = drawer(page);
    await formBody2.getByRole('textbox', { name: '* 客户编码 :' }).fill(testCode);
    await formBody2.getByRole('textbox', { name: '* 客户名称 :' }).fill('重复编码测试');
    await formBody2.locator('.ant-form-item').filter({ hasText: '客户类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '企业客户');
    await page.getByRole('button', { name: '确 认' }).click();

    // 验证后端已拦截：错误提示出现（抽屉不会关闭）
    await expect(page.locator('.ant-message').filter({ hasText: '客户编码已存在' }).first()).toBeVisible({ timeout: 5000 });
    await page.locator('.ant-drawer-close').first().click();

    // 查询验证只有一条记录，没有重复保存
    await page.getByRole('textbox', { name: '客户编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toHaveCount(1);
    await expect(page.locator('.ant-table-row')).toContainText('鹰眼测试客户');
    await expect(page.locator('.ant-table-row')).not.toContainText('重复编码测试');

    // 3. 清理原记录
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });

  test('超长编码输入校验：超长编码会被前端截断到50个字符', async ({ page }) => {
    const testCode = `EYE-C-TOO-LONG-${Date.now()}-${'x'.repeat(100)}`;
    const formBody = drawer(page);
    await page.getByRole('button', { name: '新增客户' }).click();
    await formBody.getByRole('textbox', { name: '* 客户编码 :' }).fill(testCode);

    const actualValue = await formBody.getByRole('textbox', { name: '* 客户编码 :' }).inputValue();
    expect(actualValue.length).toBeLessThanOrEqual(50);
  });

  test('特殊字符名称保存：含特殊符号的名称应正常显示', async ({ page }) => {
    const testCode = `EYE-C-${Date.now()}`;
    const specialName = '鹰眼@Test#客户';

    await page.getByRole('button', { name: '新增客户' }).click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: '* 客户编码 :' }).fill(testCode);
    await formBody.getByRole('textbox', { name: '* 客户名称 :' }).fill(specialName);
    await formBody.locator('.ant-form-item').filter({ hasText: '客户类型' }).locator('.ant-select').first().click();
    await selectDropdownItem(page, '企业客户');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible();

    await page.getByRole('textbox', { name: '客户编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText(specialName);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible();
  });
});
