// MES 财务模块 E2E 测试（gen-tests 自动生成版）
// 覆盖: collection（收款）/ invoice（销项发票）/ payable（应付）/ payment（付款）
//       purchaseInvoice（进项发票）/ receivable（应收）/ subject（科目）/ voucher（凭证）
// 关联: .claude/plans/2026-08-04-mes-regression-plan.md
// 🔴 已知问题: finance 模块 8 个前端页面虽然存在，但 router/routes/modules/mes.ts 中
//    **没有注册 finance 路由**（菜单不可达）。本测试通过直接 URL 访问验证。
//    每个测试期望失败（路由缺失 → 跳登录页），失败即为 P1 bug 暴露。
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const PAGES = [
  { name: '收款管理', path: '/project/mes/finance/collection' },
  { name: '销项发票', path: '/project/mes/finance/invoice' },
  { name: '应付账款', path: '/project/mes/finance/payable' },
  { name: '付款管理', path: '/project/mes/finance/payment' },
  { name: '进项发票', path: '/project/mes/finance/purchaseInvoice' },
  { name: '应收账款', path: '/project/mes/finance/receivable' },
  { name: '会计科目', path: '/project/mes/finance/subject' },
  { name: '凭证管理', path: '/project/mes/finance/voucher' },
];

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

test.describe('MES 财务模块 E2E（gen-tests 完整版）', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaApi(page);
  });

  for (const pg of PAGES) {
    test(`${pg.name} 1. 路由可达性 + 页面渲染`, async ({ page }) => {
      await page.goto(pg.path);
      await page.waitForTimeout(3000);
      // 期望：菜单已注册时停留在 finance 页面，未注册时会跳 /login 或 404
      const url = page.url();
      const isLoginPage = url.includes('/login') || url.includes('/user/login');
      const isFinancePage = url.includes(pg.path);
      expect(isFinancePage, `${pg.name} URL 应停留在 ${pg.path}，实际 ${url}`).toBe(true);
      expect(isLoginPage, `${pg.name} 不应跳登录页`).toBe(false);
    });

    test(`${pg.name} 2. 表格 + 列头可见`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const table = page.locator('.ant-table').first();
      await expect(table, `${pg.name} 表格可见`).toBeVisible({ timeout: 15000 });
      const headers = page.locator(HEADER_TH);
      const count = await headers.count();
      expect(count, `${pg.name} 列头数`).toBeGreaterThanOrEqual(2);
    });

    test(`${pg.name} 3. 搜索表单 + 查询按钮可见`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const searchBtn = page.locator('button:has-text("查询"), button:has-text("搜索")').first();
      await expect(searchBtn, `${pg.name} 查询按钮可见`).toBeVisible({ timeout: 10000 });
    });

    test(`${pg.name} 4. 导出按钮可见`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const exportBtn = page.locator('button:has-text("导出")').first();
      await expect(exportBtn, `${pg.name} 导出按钮可见`).toBeVisible({ timeout: 10000 });
    });

    test(`${pg.name} 5. 新增按钮可见`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const addBtn = page.locator('button:has-text("新增")').first();
      await expect(addBtn, `${pg.name} 新增按钮可见`).toBeVisible({ timeout: 10000 });
    });

    test(`${pg.name} 6. 数据行存在或空状态可见`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const dataRows = page.locator(DATA_ROW);
      const count = await dataRows.count();
      if (count === 0) {
        const empty = page.locator('.ant-empty').first();
        await expect(empty, `${pg.name} 空数据时显示占位符`).toBeVisible({ timeout: 5000 });
      } else {
        expect(count, `${pg.name} 数据行`).toBeGreaterThanOrEqual(1);
      }
    });

    test(`${pg.name} 7. 点击新增 → 弹窗/抽屉可见`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const addBtn = page.locator('button:has-text("新增")').first();
      await addBtn.click();
      await page.waitForTimeout(2000);
      const modal = page.locator('.ant-modal, .ant-drawer').first();
      await expect(modal, `${pg.name} 新增弹窗/抽屉可见`).toBeVisible({ timeout: 10000 });
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);
    });
  }
});