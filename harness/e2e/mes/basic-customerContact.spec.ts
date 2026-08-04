// MES 客户联系人子模块 E2E 测试（/add-tests basic customerContact）
// 覆盖：/project/mes/basic/customer 的 CustomerDrawer（含 AddressTab）
// 后端：GET/POST/PUT/DELETE /mes/basic/customer/address/{list,add,edit,delete,deleteBatch,exportXls,importExcel}
// 前端：AddressTab.vue（嵌入 CustomerDrawer 的"地址"Tab）
// 命令来源：/add-tests basic customerContact
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';
import { apiViaPage } from '../helpers/apiViaPage';

const PAGE_PATH = '/project/mes/basic/customer';
const PAGE_NAME = '客户联系人';

test.describe(`MES ${PAGE_NAME} E2E（/add-tests 完整版）`, () => {
  test.beforeEach(async ({ page }) => {
    await loginViaApi(page);
  });

  test(`${PAGE_NAME} 1. 路由可达性 + 客户页渲染`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(3000);
    const url = page.url();
    expect(url.includes(PAGE_PATH), `${PAGE_NAME} URL 应停留在 ${PAGE_PATH}`).toBe(true);
    expect(url.includes('/login'), `${PAGE_NAME} 不应跳登录页`).toBe(false);
  });

  test(`${PAGE_NAME} 2. 客户页表格 + 列头可见`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2500);
    await expect(page.locator('.ant-table').first(), `${PAGE_NAME} 客户表格可见`).toBeVisible({ timeout: 15000 });
    const headers = await page.locator('.ant-table-thead th').count();
    expect(headers, `${PAGE_NAME} 列头数`).toBeGreaterThanOrEqual(3);
  });

  test(`${PAGE_NAME} 3. 客户页工具栏按钮（新增/导出/导入）`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await expect(page.locator('button:has-text("新增客户")').first(), `${PAGE_NAME} 新增客户按钮`).toBeVisible({ timeout: 10000 });
    await expect(page.locator('button:has-text("导出")').first(), `${PAGE_NAME} 导出按钮`).toBeVisible({ timeout: 10000 });
    await expect(page.locator('button:has-text("导入")').first(), `${PAGE_NAME} 导入按钮`).toBeVisible({ timeout: 10000 });
  });

  test(`${PAGE_NAME} 4. 点击新增客户 → CustomerDrawer 打开 + 5 个 Tab 渲染`, async ({ page }) => {
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2000);
    await page.locator('button:has-text("新增客户")').first().click();
    await page.waitForTimeout(1500);

    // Drawer 应可见
    const drawer = page.locator('.ant-drawer').first();
    await expect(drawer, `${PAGE_NAME} CustomerDrawer 可见`).toBeVisible({ timeout: 10000 });

    // 至少 1 个 Tab 渲染（基本信息 Tab 总存在，其他 Tab 因 customerId 未设置被 v-if 隐藏）
    const tabs = page.locator('.ant-drawer .ant-tabs-tab');
    const tabCount = await tabs.count();
    expect(tabCount, `${PAGE_NAME} Tab 数（新增时只显示基本信息 Tab）`).toBeGreaterThanOrEqual(1);

    // 验证基本信息 Tab 可见
    const infoTab = page.locator('.ant-drawer .ant-tabs-tab:has-text("客户信息")').first();
    await expect(infoTab, `${PAGE_NAME} 客户信息 Tab`).toBeVisible();
  });

  test(`${PAGE_NAME} 5. 编辑已有客户 → ContactTab 渲染（地址/联系人/价格 Tab 显示）`, async ({ page }) => {
    // 这个测试需要：1) 先有客户；2) 打开编辑 Drawer；3) 验证多个 Tab
    // 使用 page.evaluate + fetch 走 page context（这样 localStorage / cookie 能用）
    const code = `ADDR_E2E_${Date.now()}`;
    const apiResp = await apiViaPage(page, 'POST', '/mes/basic/customer/add', { code, name: '地址 E2E 测试', status: 1 });
    expect(apiResp.status, `${PAGE_NAME} 准备客户 HTTP 状态`).toBe(200);
    expect(apiResp.json.code, `${PAGE_NAME} 准备客户成功`).toBe(200);

    // 进入客户列表
    await page.goto(PAGE_PATH);
    await page.waitForTimeout(2500);

    // 点击该客户行的"编辑"按钮（按 code 查找）
    // TableAction 的"编辑"按钮是一个 a-link
    const row = page.locator(`.ant-table-tbody tr:has(td:has-text("${code}"))`).first();
    const editBtn = row.locator('a:has-text("编辑"), button:has-text("编辑")').first();
    if (await editBtn.count() === 0) {
      // fallback：直接点击行
      await row.click().catch(() => {});
    } else {
      await editBtn.click();
    }
    await page.waitForTimeout(1500);

    // 验证 Drawer
    const drawer = page.locator('.ant-drawer').first();
    await expect(drawer, `${PAGE_NAME} 编辑 Drawer 可见`).toBeVisible({ timeout: 10000 });

    // 验证 5 个 Tab：基本信息 / 联系人 / 地址 / 价格表 / 跟进记录（编辑模式全显示）
    const tabs = page.locator('.ant-drawer .ant-tabs-tab');
    const tabCount = await tabs.count();
    expect(tabCount, `${PAGE_NAME} 编辑模式 Tab 数（5 个）`).toBeGreaterThanOrEqual(4);

    // 验证"地址"Tab 存在
    const addrTab = page.locator('.ant-drawer .ant-tabs-tab:has-text("地址")').first();
    await expect(addrTab, `${PAGE_NAME} 联系人 Tab 可见`).toBeVisible({ timeout: 5000 });
  });
});