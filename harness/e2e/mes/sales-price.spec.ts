// MES 销售价格管理 E2E 测试（gen-tests 自动生成版）
// 覆盖：/project/mes/sales/price（MesPriceController）
// 后端：GET/POST/PUT/DELETE /mes/sales/price/{list,queryById,add,edit,delete,deleteBatch,queryAll,exportXls,importExcel}
// 路由：router/routes/modules/mes.ts 中 sales 父节点下静态注册，URL 直接访问可用。
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const PAGE_PATH = '/project/mes/sales/price';
const PAGE_NAME = '销售价格管理';
const DATA_ROW = '.ant-table-tbody tr.ant-table-row';
const HEADER_TH = '.ant-table-thead th';

async function waitForTableReady(page) {
  await page.waitForTimeout(1500);
  const spinner = page.locator('.ant-spin-spinning').first();
  if (await spinner.count() > 0) {
    await spinner.waitFor({ state: 'hidden', timeout: 10000 }).catch(() => {});
  }
  await page.locator(DATA_ROW).first().waitFor({ state: 'visible', timeout: 15000 }).catch(() => {});
}

test.describe(`MES ${PAGE_NAME} E2E（gen-tests 完整版）`, () => {
  test.beforeEach(async ({ page }) => {
    await loginViaApi(page);
  });

  test(`${PAGE_NAME} 1. 路由可达性 + 页面渲染`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(3000);
    const url = page.url();
    const isLoginPage = url.includes('/login') || url.includes('/user/login');
    const isPricePage = url.includes(PAGE_PATH);
    expect(isPricePage, `${PAGE_NAME} URL 应停留在 ${PAGE_PATH}，实际 ${url}`).toBe(true);
    expect(isLoginPage, `${PAGE_NAME} 不应跳登录页`).toBe(false);
  });

  test(`${PAGE_NAME} 2. 表格 + 列头可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const table = page.locator('.ant-table').first();
    await expect(table, `${PAGE_NAME} 表格可见`).toBeVisible({ timeout: 15000 });
    const headers = page.locator(HEADER_TH);
    const count = await headers.count();
    expect(count, `${PAGE_NAME} 列头数`).toBeGreaterThanOrEqual(2);
  });

  test(`${PAGE_NAME} 3. 搜索表单 + 查询按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const searchBtn = page.locator('button:has-text("查询"), button:has-text("搜索")').first();
    await expect(searchBtn, `${PAGE_NAME} 查询按钮可见`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 4. 导出按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const exportBtn = page.locator('button:has-text("导出")').first();
    await expect(exportBtn, `${PAGE_NAME} 导出按钮可见`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 5. 导入按钮可见`, async ({ page }) => {
    // 后端有 importExcel 端点，对应前端应有导入按钮
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const importBtn = page.locator('button:has-text("导入")').first();
    await expect(importBtn, `${PAGE_NAME} 导入按钮可见`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 6. 新增按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const addBtn = page.locator('button:has-text("新增")').first();
    await expect(addBtn, `${PAGE_NAME} 新增按钮可见`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 7. 数据行存在或空状态可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const dataRows = page.locator(DATA_ROW);
    const count = await dataRows.count();
    if (count === 0) {
      const empty = page.locator('.ant-empty').first();
      await expect(empty, `${PAGE_NAME} 空数据时显示占位符`).toBeVisible({ timeout: 5000 });
    } else {
      expect(count, `${PAGE_NAME} 数据行`).toBeGreaterThanOrEqual(1);
    }
  });

  test(`${PAGE_NAME} 8. 点击新增 → 弹窗/抽屉可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const addBtn = page.locator('button:has-text("新增")').first();
    await addBtn.click();
    await page.waitForTimeout(2000);
    const drawer = page.locator('.ant-drawer, .ant-modal').first();
    await expect(drawer, `${PAGE_NAME} 新增弹窗/抽屉可见`).toBeVisible({ timeout: 10000 });
  });
});
