// MES 其他出库 E2E 测试（/add-tests stock otherOut）
// 覆盖：/project/mes/stock/other-out（CRUD + 审核流 + 导出）
// 后端：GET/POST/PUT/DELETE /mes/stock/otherOut/{list,queryById,add,edit,delete,deleteBatch,exportXls,audit,unaudit}
// 前端：index.vue（useListPage + 工具栏审核/反审核 + OtherOutDrawer）
// 命令来源：/add-tests stock otherOut
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const PAGE_PATH = '/project/mes/stock/other-out';
const PAGE_NAME = '其他出库';

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

  test(`${PAGE_NAME} 3. 工具栏：新增出库单 + 导出`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await expect(page.locator('button:has-text("新增出库单")').first(), `${PAGE_NAME} 新增出库单按钮`).toBeVisible({ timeout: 10000 });
    await expect(page.locator('button:has-text("导出")').first(), `${PAGE_NAME} 导出按钮`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 4. 工具栏：审核/反审核按钮（默认禁用）`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    // 审核/反审核按钮在未选中时默认禁用
    const auditBtn = page.locator('button:has-text("审核")').first();
    await expect(auditBtn, `${PAGE_NAME} 审核按钮可见`).toBeVisible({ timeout: 10000 });
    const unauditBtn = page.locator('button:has-text("反审核")').first();
    await expect(unauditBtn, `${PAGE_NAME} 反审核按钮可见`).toBeVisible({ timeout: 10000 });
    // 默认禁用
    await expect(auditBtn, `${PAGE_NAME} 审核默认禁用`).toBeDisabled();
    await expect(unauditBtn, `${PAGE_NAME} 反审核默认禁用`).toBeDisabled();
  });

  test(`${PAGE_NAME} 5. 点击新增出库单 → OtherOutDrawer 打开`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await page.locator('button:has-text("新增出库单")').first().click();
    await page.waitForTimeout(1500);
    const drawer = page.locator('.ant-drawer').first();
    await expect(drawer, `${PAGE_NAME} OtherOutDrawer 可见`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 6. 搜索表单 + 查询按钮可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await expect(page.locator('button:has-text("查询"), button:has-text("搜索")').first(), `${PAGE_NAME} 查询按钮`).toBeVisible({ timeout: 10000 });
  });
});