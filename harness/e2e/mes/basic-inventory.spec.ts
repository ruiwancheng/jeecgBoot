// MES 库存总览 E2E 测试（gen-tests 完整版）
// 覆盖：/project/mes/warehouse/inventory（MesInventoryController）
// 后端：GET /mes/basic/inventory/list（只读 dashboard）
// 路由：router 静态注册在 warehouse 父节点下，URL 路径是 /project/mes/warehouse/inventory
//      （Vue 物理文件在 basic/inventory/，但路由 menu 在 warehouse 下）
//
// 重要：此页面是只读 inventory overview dashboard，不是 CRUD 页面
// - 后端 controller 只有 GET /list，无 add/edit/delete/export
// - 前端 useListPage 调用未传 exportConfig/importConfig，未启用 actionColumn
// - 菜单仅 mes:inventory:list 权限
// 因此"导出/新增/抽屉"测试应跳过，不应作为失败项
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const PAGE_PATH = '/project/mes/warehouse/inventory';
const PAGE_NAME = '库存总览';
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

test.describe(`MES ${PAGE_NAME} E2E（只读 dashboard）`, () => {
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

  test(`${PAGE_NAME} 4. 仓库筛选下拉可见`, async ({ page }) => {
    // 只读 dashboard 通过仓库下拉筛选（ApiSelect 真实接口）
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const selects = await page.locator('.ant-select').count();
    expect(selects, '库存筛选 select').toBeGreaterThanOrEqual(1);
  });

  test(`${PAGE_NAME} 5. 数据行或空状态可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const count = await page.locator(DATA_ROW).count();
    if (count === 0) {
      await expect(page.locator('.ant-empty').first(), `${PAGE_NAME} 空状态`).toBeVisible({ timeout: 5000 });
    } else {
      expect(count).toBeGreaterThanOrEqual(1);
    }
  });

  test(`${PAGE_NAME} 6. 库存金额合计可见（页面特性）`, async ({ page }) => {
    // 库存总览特有：模板顶部显示"库存金额合计：<金额>"
    await page.goto(PAGE_PATH);
    await waitForTableReady(page);
    const total = page.locator('text=库存金额合计').first();
    await expect(total, '库存金额合计标签').toBeVisible({ timeout: 5000 });
  });
});
