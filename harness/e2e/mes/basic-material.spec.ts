// MES 物料管理 E2E 测试（gen-tests 自动生成版）
// 覆盖：/project/mes/basic/material（MesMaterialController）
// 后端：GET/POST/PUT/DELETE /mes/basic/material/{list,queryById,add,edit,delete,deleteBatch,queryAll,exportXls}
// 路由：router/routes/modules/mes.ts 静态注册 basic/material
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const PAGE_PATH = '/project/mes/basic/material';
const PAGE_NAME = '物料管理';
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
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test(`${PAGE_NAME} 1. 路由可达性 + 页面渲染`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(3000);
    const url = page.url();
    expect(url.includes(PAGE_PATH), `${PAGE_NAME} URL 应停留在 ${PAGE_PATH}，实际 ${url}`).toBe(true);
    expect(url.includes('/login'), `${PAGE_NAME} 不应跳登录页`).toBe(false);
  });

  test(`${PAGE_NAME} 2. 表格 + 列头可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    await expect(page.locator('.ant-table').first(), `${PAGE_NAME} 表格可见`).toBeVisible({ timeout: 15000 });
    const count = await page.locator(HEADER_TH).count();
    expect(count, `${PAGE_NAME} 列头数`).toBeGreaterThanOrEqual(3);
  });

  test(`${PAGE_NAME} 3. 搜索表单 + 查询按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    await expect(page.locator('button:has-text("查询"), button:has-text("搜索")').first(), `${PAGE_NAME} 查询按钮`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 4. 导出按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    await expect(page.locator('button:has-text("导出")').first(), `${PAGE_NAME} 导出按钮`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 5. 新增按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    await expect(page.locator('button:has-text("新增")').first(), `${PAGE_NAME} 新增按钮`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 6. 数据行或空状态可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const count = await page.locator(DATA_ROW).count();
    if (count === 0) {
      await expect(page.locator('.ant-empty').first(), `${PAGE_NAME} 空状态`).toBeVisible({ timeout: 5000 });
    } else {
      expect(count).toBeGreaterThanOrEqual(1);
    }
  });

  test(`${PAGE_NAME} 7. 点击新增 → 抽屉可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    await page.locator('button:has-text("新增")').first().click();
    await page.waitForTimeout(2000);
    await expect(page.locator('.ant-drawer, .ant-modal').first(), `${PAGE_NAME} 新增抽屉`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 8. 物料分类/编码搜索字段可见`, async ({ page }) => {
    // 物料通常按编码/名称/分类搜索
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const inputs = await page.locator('.ant-input, .ant-select').count();
    expect(inputs, `${PAGE_NAME} 搜索字段数`).toBeGreaterThanOrEqual(1);
  });
});
