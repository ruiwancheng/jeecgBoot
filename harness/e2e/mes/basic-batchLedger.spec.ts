// MES 批次流水 E2E 测试（/add-tests basic batchLedger）
// 覆盖：/project/mes/batch/ledger（只读 + 导出）
// 后端：GET /mes/batch/ledger/{list,listByBatchId,exportXls}
// 前端：index.vue（useListPage + 导出按钮）
// 命令来源：/add-tests basic batchLedger
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const PAGE_PATH = '/project/mes/batch/ledger';
const PAGE_NAME = '批次流水';

test.describe(`MES ${PAGE_NAME} E2E（/add-tests 完整版）`, () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

  test(`${PAGE_NAME} 1. 路由可达性 + 页面渲染`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(3000);
    const url = page.url();
    expect(url.includes(PAGE_PATH), `${PAGE_NAME} URL 应停留在 ${PAGE_PATH}`).toBe(true);
    expect(url.includes('/login'), `${PAGE_NAME} 不应跳登录页`).toBe(false);
  });

  test(`${PAGE_NAME} 2. 表格 + 列头可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await expect(page.locator('.ant-table').first(), `${PAGE_NAME} 表格可见`).toBeVisible({ timeout: 15000 });
    const headers = await page.locator('.ant-table-thead th').count();
    expect(headers, `${PAGE_NAME} 列头数`).toBeGreaterThanOrEqual(2);
  });

  test(`${PAGE_NAME} 3. 数据行或空状态可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2500);
    const dataRows = await page.locator('.ant-table-tbody tr.ant-table-row').count();
    if (dataRows === 0) {
      await expect(page.locator('.ant-empty').first(), `${PAGE_NAME} 空状态`).toBeVisible({ timeout: 5000 });
    } else {
      expect(dataRows).toBeGreaterThanOrEqual(1);
    }
  });

  test(`${PAGE_NAME} 4. 工具栏：导出按钮（无新增/编辑/删除）`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await expect(page.locator('button:has-text("导出")').first(), `${PAGE_NAME} 导出按钮`).toBeVisible({ timeout: 10000 });
    const addBtnCount = await page.locator('button:has-text("新增")').count();
    expect(addBtnCount, `${PAGE_NAME} 应无新增按钮（只读）`).toBe(0);
  });

  test(`${PAGE_NAME} 5. 搜索表单 + 查询按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await expect(page.locator('button:has-text("查询"), button:has-text("搜索")').first(), `${PAGE_NAME} 查询按钮`).toBeVisible({ timeout: 10000 });
  });
});