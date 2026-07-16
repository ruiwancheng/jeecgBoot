import { test, expect } from '@playwright/test';
import { navigateToModule, type ModuleConfig } from './mes-crud.template';

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

async function loginAndGetToken(page: any) {
  const response = await page.request.post('/jeecgboot/sys/login', {
    data: { username: 'admin', password: '123456', captcha: '', checkkey: 'eagle-eye' },
    headers: { 'Content-Type': 'application/json' },
  });
  const body = await response.json();
  expect(body.success).toBeTruthy();
  return body.result.token as string;
}

async function queryMaterialList(page: any) {
  const token = await loginAndGetToken(page);
  const response = await page.request.get('/jeecgboot/mes/basic/material/list?pageNo=1&pageSize=1', {
    headers: { 'X-Access-Token': token },
  });
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  if (!body.success) {
    console.log('[鹰眼团] createPrice 失败:', JSON.stringify(body));
  }
  expect(body.success).toBeTruthy();
  expect(body.result?.records?.length).toBeGreaterThan(0);
  return body.result.records[0];
}

async function queryCustomerList(page: any) {
  const token = await loginAndGetToken(page);
  const response = await page.request.get('/jeecgboot/mes/basic/customer/list?pageNo=1&pageSize=1', {
    headers: { 'X-Access-Token': token },
  });
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  if (!body.success) {
    console.log('[鹰眼团] createPrice 失败:', JSON.stringify(body));
  }
  expect(body.success).toBeTruthy();
  expect(body.result?.records?.length).toBeGreaterThan(0);
  return body.result.records[0];
}

async function queryPriceByCode(page: any, code: string) {
  const token = await loginAndGetToken(page);
  const response = await page.request.get(
    `/jeecgboot/mes/sales/price/list?code=${encodeURIComponent(code)}&pageNo=1&pageSize=10`,
    { headers: { 'X-Access-Token': token } }
  );
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  return body.result?.records || [];
}

async function createPrice(page: any, record: any) {
  const token = await loginAndGetToken(page);
  const response = await page.request.post('/jeecgboot/mes/sales/price/add', {
    data: record,
    headers: { 'Content-Type': 'application/json', 'X-Access-Token': token },
  });
  if (!response.ok()) {
    const text = await response.text();
    console.log('[鹰眼团] 新增价格 API 失败，状态码：', response.status(), '响应：', text.slice(0, 300));
  }
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  if (!body.success) {
    console.log('[鹰眼团] createPrice 失败:', JSON.stringify(body));
  }
  expect(body.success).toBeTruthy();
  return body.result;
}

async function apiDeletePrice(page: any, id: string) {
  const token = await loginAndGetToken(page);
  await page.request.delete('/jeecgboot/mes/sales/price/delete', {
    params: { id },
    headers: { 'X-Access-Token': token },
  });
}

async function cleanupTestPrices(page: any) {
  const records = await queryPriceByCode(page, 'EYE-P-');
  for (const r of records) {
    if (r.id) await apiDeletePrice(page, r.id);
  }
}

async function queryMaterialPriceList(page: any, materialId: string) {
  const token = await loginAndGetToken(page);
  const response = await page.request.get(
    `/jeecgboot/mes/sales/price/list?materialId=${encodeURIComponent(materialId)}&pageNo=1&pageSize=100`,
    { headers: { 'X-Access-Token': token } }
  );
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  return body.result?.records || [];
}

async function createUniquePrice(page: any, overrides: any = {}) {
  const material = await queryMaterialList(page);
  const code = `EYE-P-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

  // 找该物料当前最晚的结束日期，往后推 1 天开始，避免重叠
  const existing = await queryMaterialPriceList(page, material.id);
  let startDay = new Date('2026-07-01');
  for (const r of existing) {
    if (r.endDate) {
      const d = new Date(r.endDate);
      if (d >= startDay) startDay = new Date(d.getTime() + 24 * 60 * 60 * 1000);
    }
  }
  const endDay = new Date(startDay.getTime() + 9 * 24 * 60 * 60 * 1000);
  const fmt = (d: Date) => d.toISOString().slice(0, 10);

  await createPrice(page, {
    code,
    materialId: material.id,
    type: '1',
    price: 99.99,
    beginDate: fmt(startDay),
    endDate: fmt(endDay),
    status: 1,
    ...overrides,
  });
  return { code, material };
}

async function searchAndExpectRow(page: any, code: string, expectTexts: string[]) {
  await page.getByRole('textbox', { name: '价格编码' }).first().fill(code);
  await page.getByRole('button', { name: '查询' }).click();
  const row = page.locator('.ant-table-row').filter({ hasText: code }).first();
  await expect(row).toBeVisible({ timeout: 10000 });
  for (const text of expectTexts) {
    await expect(row).toContainText(text);
  }
}

async function getSearchConditionLabels(page: any) {
  return await page.evaluate(() => {
    const labels = Array.from(document.querySelectorAll('.jeecg-basic-form .ant-form-item-label, .ant-form-item-label'));
    return labels.map((el) => el.textContent?.trim()).filter(Boolean);
  });
}

test.describe(config.name, () => {
  test.beforeEach(async ({ page }) => {
    await navigateToModule(page, config);
    await cleanupTestPrices(page);
  });

  test('列表展示：标准售价记录显示物料名称和价格', async ({ page }) => {
    const { code, material } = await createUniquePrice(page, { price: 99.99 });
    await searchAndExpectRow(page, code, [code, material.name, '99.99', '标准售价']);
  });

  test('新增价格按钮可打开新增抽屉', async ({ page }) => {
    await page.getByRole('button', { name: '新增价格' }).click();
    await expect(page.getByText('新增价格').first()).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.ant-form-item').filter({ hasText: '价格编码' }).first()).toBeVisible();
    await expect(page.locator('.ant-form-item').filter({ hasText: '物料' }).first()).toBeVisible();
    await expect(page.locator('.ant-form-item').filter({ hasText: '价格' }).first()).toBeVisible();
  });

  test('价格类型字典下拉显示正确选项', async ({ page }) => {
    await page.getByRole('button', { name: '新增价格' }).click();
    await page.waitForTimeout(500);
    const drawer = page.locator('.ant-drawer-body, .ant-modal-body').first();
    await expect(drawer.locator('.ant-form-item').filter({ hasText: '价格类型' }).first()).toBeVisible({ timeout: 5000 });
    const typeFormItem = drawer.locator('.ant-form-item').filter({ hasText: '价格类型' }).first();
    await typeFormItem.locator('.ant-select-selector').first().click();
    await page.waitForTimeout(500);
    const dropdown = page.locator('.ant-select-dropdown').first();
    await expect(dropdown.locator('.ant-select-item-option').filter({ hasText: '标准售价' }).first()).toBeVisible();
    await expect(dropdown.locator('.ant-select-item-option').filter({ hasText: '客户协议价' }).first()).toBeVisible();
  });

  test('客户协议价记录显示客户名称', async ({ page }) => {
    const material = await queryMaterialList(page);
    const customer = await queryCustomerList(page);
    const code = `EYE-P-CUST-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
    const existing = await queryMaterialPriceList(page, material.id);
    let startDay = new Date('2026-07-01');
    for (const r of existing) {
      if (r.endDate) {
        const d = new Date(r.endDate);
        if (d >= startDay) startDay = new Date(d.getTime() + 24 * 60 * 60 * 1000);
      }
    }
    const endDay = new Date(startDay.getTime() + 9 * 24 * 60 * 60 * 1000);
    const fmt = (d: Date) => d.toISOString().slice(0, 10);
    await createPrice(page, {
      code,
      materialId: material.id,
      customerId: customer.id,
      type: '2',
      price: 88.88,
      beginDate: fmt(startDay),
      endDate: fmt(endDay),
      status: 1,
    });
    await searchAndExpectRow(page, code, [code, material.name, customer.name, '客户协议价', '88.88']);
  });

  test('删除价格后列表不再显示', async ({ page }) => {
    const { code } = await createUniquePrice(page);
    await searchAndExpectRow(page, code, [code]);

    await page.getByRole('button', { name: '删除' }).first().click();
    await page.getByRole('button', { name: '确 认' }).click();
    await expect(page.locator('.ant-message-success').filter({ hasText: '删除成功' }).first()).toBeVisible({ timeout: 5000 });

    await page.waitForTimeout(1500);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row')).toHaveCount(0);
  });

  test('搜索条件：按价格编码搜索能过滤结果', async ({ page }) => {
    const { code } = await createUniquePrice(page);
    await page.getByRole('textbox', { name: '价格编码' }).first().fill(code);
    await page.getByRole('button', { name: '查询' }).click();
    await expect(page.locator('.ant-table-row').filter({ hasText: code }).first()).toBeVisible({ timeout: 10000 });
  });

  test('搜索条件：按价格类型搜索能过滤标准售价', async ({ page }) => {
    const { code } = await createUniquePrice(page, { type: '1', price: 77.77 });
    const token = await loginAndGetToken(page);
    const response = await page.request.get(
      `/jeecgboot/mes/sales/price/list?code=${encodeURIComponent(code)}&type=1&pageNo=1&pageSize=10`,
      { headers: { 'X-Access-Token': token } }
    );
    expect(response.ok()).toBeTruthy();
    const body = await response.json();
    expect(body.success).toBeTruthy();
    expect(body.result?.records?.length).toBeGreaterThan(0);
    const record = body.result.records[0];
    expect(record.code).toBe(code);
    expect(record.type).toBe('1');
    expect(record.type_dictText).toBe('标准售价');
  });

  test('搜索条件：按状态搜索能过滤启用记录', async ({ page }) => {
    const { code } = await createUniquePrice(page, { status: 1 });
    const token = await loginAndGetToken(page);
    const response = await page.request.get(
      `/jeecgboot/mes/sales/price/list?code=${encodeURIComponent(code)}&status=1&pageNo=1&pageSize=10`,
      { headers: { 'X-Access-Token': token } }
    );
    expect(response.ok()).toBeTruthy();
    const body = await response.json();
    expect(body.success).toBeTruthy();
    expect(body.result?.records?.length).toBeGreaterThan(0);
    const record = body.result.records[0];
    expect(record.code).toBe(code);
    expect(record.status).toBe(1);
    expect(record.status_dictText).toBe('是');
  });

  test('搜索条件：搜索面板包含所有条件字段', async ({ page }) => {
    const labels = await getSearchConditionLabels(page);
    expect(labels).toContain('价格编码');
    expect(labels).toContain('价格类型');
    expect(labels).toContain('状态');
  });
});
