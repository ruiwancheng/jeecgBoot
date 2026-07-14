import { test, expect } from '@playwright/test';
import { navigateToModule, selectDropdownItem, type ModuleConfig } from './mes-crud.template';

/**
 * 价格管理 E2E 测试
 * 覆盖完整生命周期 + 铁拳团审计修复点：日期校验、价格重叠、客户协议价必填
 * 环境：Docker 部署 http://100.122.125.106
 */

const config: ModuleConfig = {
  name: '价格管理',
  topMenu: '仓库管理',
  secondMenu: 'MES系统',
  thirdMenu: '销售管理',
  targetMenu: '价格管理',
  addButtonText: '新增价格',
  codeLabel: '价格编码',
  nameLabel: '价格编码',
  searchCodeLabel: '价格编码',
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

async function queryPriceByCode(page: any, code: string) {
  const token = await loginAndGetToken(page);
  const response = await page.request.get(
    `/jeecgboot/mes/sales/price/list?code=${encodeURIComponent(code)}&pageNo=1&pageSize=10`,
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

async function queryMaterialList(page: any) {
  const token = await loginAndGetToken(page);
  const response = await page.request.get(
    `/jeecgboot/mes/basic/material/list?pageNo=1&pageSize=1`,
    { headers: { 'X-Access-Token': token } }
  );
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  expect(body.success).toBeTruthy();
  expect(body.result?.records?.length).toBeGreaterThan(0);
  return body.result.records[0];
}

async function selectJSearchSelect(page: any, label: string, searchText: string) {
  const combobox = page.getByRole('combobox', { name: new RegExp(label) }).first();
  await combobox.click();
  await combobox.fill(searchText);
  await page.waitForTimeout(1000);

  // 等待选项出现并点击第一条
  const option = page.locator('.ant-select-dropdown').locator('.ant-select-item-option').first();
  await option.waitFor({ state: 'visible', timeout: 5000 });
  await option.click();
}

async function fillPriceForm(
  page: any,
  code: string,
  material: any,
  price: string,
  type: '1' | '2',
  beginDate: string,
  endDate?: string,
  customer?: any
) {
  const formBody = drawer(page);

  await formBody.getByRole('textbox', { name: /价格编码/ }).fill(code);
  await selectJSearchSelect(page, '物料', material.name);

  const typeCombobox = formBody.getByRole('combobox', { name: /价格类型/ });
  await typeCombobox.click();
  // 等待字典选项加载，最多 5 秒
  const typeOption = page.locator('.ant-select-dropdown').locator('.ant-select-item-option').filter({ hasText: type === '1' ? '标准售价' : '客户协议价' }).first();
  await typeOption.waitFor({ state: 'visible', timeout: 5000 });
  await typeOption.click();

  if (type === '2' && customer) {
    await selectJSearchSelect(page, '客户', customer.name);
  }

  await formBody.locator('.ant-form-item').filter({ hasText: '价格' }).locator('input').first().fill(price);

  await formBody.locator('.ant-form-item').filter({ hasText: '生效日期' }).locator('input').first().fill(beginDate);
  await formBody.locator('.ant-form-item').filter({ hasText: '生效日期' }).locator('input').first().press('Enter');

  if (endDate) {
    await formBody.locator('.ant-form-item').filter({ hasText: '失效日期' }).locator('input').first().fill(endDate);
    await formBody.locator('.ant-form-item').filter({ hasText: '失效日期' }).locator('input').first().press('Enter');
  }
}

async function submitAndExpectSuccess(page: any) {
  await page.getByRole('button', { name: '确 认' }).click();
  await expect(page.locator('.ant-message-success').filter({ hasText: '添加成功' }).first()).toBeVisible({ timeout: 5000 });
}

async function submitAndExpectError(page: any, errorText: string) {
  await page.getByRole('button', { name: '确 认' }).click();
  await expect(page.locator('.ant-message').filter({ hasText: errorText }).first()).toBeVisible({ timeout: 5000 });
}

test.describe(config.name, () => {
  test.beforeEach(async ({ page }) => {
    await navigateToModule(page, config);
  });

  test('价格完整生命周期：新增、查询、编辑、删除', async ({ page }) => {
    const material = await queryMaterialList(page);
    const testCode = `EYE-P-${Date.now()}`;
    const editedCode = `EYE-P-${Date.now()}-EDITED`;

    // 新增
    await page.getByRole('button', { name: '新增价格' }).click();
    await fillPriceForm(page, testCode, material, '99.99', '1', '2026-07-01', '2026-07-31');
    await submitAndExpectSuccess(page);

    // 查询
    await page.getByRole('textbox', { name: '价格编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText(testCode);
    await expect(page.locator('.ant-table-row')).toContainText(material.name);
    await expect(page.locator('.ant-table-row')).toContainText('99.99');

    // 编辑
    await page.getByRole('button', { name: '编辑' }).first().click();
    const formBody = drawer(page);
    await formBody.getByRole('textbox', { name: /价格编码/ }).fill(editedCode);
    await formBody.locator('.ant-form-item').filter({ hasText: '价格' }).locator('input').first().fill('199.99');
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '编辑成功' }).first()).toBeVisible({ timeout: 5000 });

    await page.getByRole('textbox', { name: '价格编码' }).first().fill(editedCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText(editedCode);
    await expect(page.locator('.ant-table-row')).toContainText('199.99');

    // 删除
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible({ timeout: 5000 });
  });

  test('日期校验：失效日期早于生效日期应被拦截', async ({ page }) => {
    const material = await queryMaterialList(page);
    const testCode = `EYE-P-DATE-${Date.now()}`;

    await page.getByRole('button', { name: '新增价格' }).click();
    await fillPriceForm(page, testCode, material, '88.88', '1', '2026-07-31', '2026-07-01');
    await submitAndExpectError(page, '失效日期不能早于生效日期');
  });

  test('价格重叠校验：同一物料+客户+重叠有效期应被拦截', async ({ page }) => {
    const material = await queryMaterialList(page);
    const testCode = `EYE-P-OVERLAP-${Date.now()}`;

    // 先创建一条价格
    await page.getByRole('button', { name: '新增价格' }).click();
    await fillPriceForm(page, testCode, material, '88.88', '1', '2026-07-01', '2026-07-31');
    await submitAndExpectSuccess(page);

    // 再次创建同一物料+重叠日期
    const testCode2 = `EYE-P-OVERLAP2-${Date.now()}`;
    await page.getByRole('button', { name: '新增价格' }).click();
    await fillPriceForm(page, testCode2, material, '77.77', '1', '2026-07-15', '2026-08-15');
    await submitAndExpectError(page, '该物料+客户在相同时间段内已有价格记录');

    // 清理原记录
    await page.locator('.ant-drawer-close').first().click();
    await page.getByRole('textbox', { name: '价格编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible({ timeout: 5000 });
  });

  test('客户协议价必填：type=2 不选客户应被拦截', async ({ page }) => {
    const material = await queryMaterialList(page);
    const testCode = `EYE-P-CUST-${Date.now()}`;

    await page.getByRole('button', { name: '新增价格' }).click();
    await fillPriceForm(page, testCode, material, '88.88', '2', '2026-07-01', '2026-07-31');
    await submitAndExpectError(page, '客户协议价必须选择客户');
  });

  test('客户协议价绑定客户：成功保存并正确显示客户名称', async ({ page }) => {
    const material = await queryMaterialList(page);
    const token = await loginAndGetToken(page);
    const customerResponse = await page.request.get(
      `/jeecgboot/mes/basic/customer/list?pageNo=1&pageSize=1`,
      { headers: { 'X-Access-Token': token } }
    );
    expect(customerResponse.ok()).toBeTruthy();
    const customerBody = await customerResponse.json();
    expect(customerBody.success).toBeTruthy();
    expect(customerBody.result?.records?.length).toBeGreaterThan(0);
    const customer = customerBody.result.records[0];

    const testCode = `EYE-P-CUST-OK-${Date.now()}`;

    await page.getByRole('button', { name: '新增价格' }).click();
    await fillPriceForm(page, testCode, material, '88.88', '2', '2026-07-01', '2026-07-31', customer);
    await submitAndExpectSuccess(page);

    await page.getByRole('textbox', { name: '价格编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText(testCode);
    await expect(page.locator('.ant-table-row')).toContainText(customer.name);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible({ timeout: 5000 });
  });

  test('物料字典搜索：JSearchSelect 选择物料后列表显示物料名称', async ({ page }) => {
    const material = await queryMaterialList(page);
    const testCode = `EYE-P-MAT-${Date.now()}`;

    await page.getByRole('button', { name: '新增价格' }).click();
    await fillPriceForm(page, testCode, material, '66.66', '1', '2026-07-01', '2026-07-31');
    await submitAndExpectSuccess(page);

    await page.getByRole('textbox', { name: '价格编码' }).first().fill(testCode);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toContainText(material.name);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible({ timeout: 5000 });
  });
});
