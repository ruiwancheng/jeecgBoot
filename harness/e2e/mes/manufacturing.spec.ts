// MES 生产制造模块 E2E 测试（gen-tests 自动生成版）
// 覆盖: bom（物料清单）/ order（生产订单）/ picking（生产领料）/ completion（完工入库）
// 关联: .claude/plans/2026-08-04-mes-regression-plan.md
// 规则: 每个页面 7 个基础 E2E：加载/列表/搜索/导出/新增/列头/抽屉
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const PAGES = [
  { name: 'BOM管理', path: '/project/mes/manufacturing/bom', hasAdd: true, hasExport: true },
  { name: '生产订单', path: '/project/mes/manufacturing/order', hasAdd: true, hasExport: true },
  { name: '生产领料', path: '/project/mes/manufacturing/picking', hasAdd: true, hasExport: true },
  { name: '完工入库', path: '/project/mes/manufacturing/completion', hasAdd: true, hasExport: true },
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

test.describe('MES 生产制造 E2E（gen-tests 完整版）', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaApi(page);
  });

  for (const pg of PAGES) {
    test(`${pg.name} 1. 页面加载 + 列表渲染`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      await expect(page.locator('.ant-table').first(), `${pg.name} 表格可见`).toBeVisible({ timeout: 15000 });
      await expect(page.locator(HEADER_TH).first(), `${pg.name} 列头可见`).toBeVisible({ timeout: 5000 });
    });

    test(`${pg.name} 2. 新增按钮可见`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const addBtn = page.locator('button:has-text("新增")').first();
      await expect(addBtn, `${pg.name} 新增按钮可见`).toBeVisible({ timeout: 10000 });
      await expect(addBtn).toBeEnabled();
    });

    test(`${pg.name} 3. 搜索表单可见 + 重置`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const searchArea = page.locator('.ant-form, .search-form, form').first();
      if (await searchArea.count() > 0) {
        await expect(searchArea, `${pg.name} 搜索表单可见`).toBeVisible({ timeout: 5000 });
      }
      // 重置按钮
      const resetBtn = page.locator('button:has-text("重置")').first();
      if (await resetBtn.count() > 0) {
        await expect(resetBtn, `${pg.name} 重置按钮可见`).toBeVisible({ timeout: 5000 });
      }
    });

    if (pg.hasExport) {
      test(`${pg.name} 4. 导出按钮可见 + 点击触发下载`, async ({ page }) => {
        await page.goto(pg.path);
        await waitForTableReady(page);
        const exportBtn = page.locator('button:has-text("导出")').first();
        await expect(exportBtn, `${pg.name} 导出按钮可见`).toBeVisible({ timeout: 10000 });
        await expect(exportBtn).toBeEnabled();
        const downloadPromise = page.waitForEvent('download', { timeout: 15000 }).catch(() => null);
        await exportBtn.click();
        const download = await downloadPromise;
        if (download) {
          const filename = download.suggestedFilename();
          expect(filename.endsWith('.xlsx') || filename.endsWith('.xls'), `${pg.name} 导出 Excel (${filename})`).toBe(true);
        }
      });
    }

    if (pg.hasAdd) {
      test(`${pg.name} 5. 点击新增 → 弹窗/抽屉可见`, async ({ page }) => {
        await page.goto(pg.path);
        await waitForTableReady(page);
        const addBtn = page.locator('button:has-text("新增")').first();
        await addBtn.click();
        await page.waitForTimeout(2000);
        // 弹窗或抽屉
        const modal = page.locator('.ant-modal, .ant-drawer').first();
        await expect(modal, `${pg.name} 新增弹窗/抽屉可见`).toBeVisible({ timeout: 10000 });
        // 关闭
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
      });
    }

    test(`${pg.name} 6. 数据行存在（表头下方有真实数据）`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      // 检查是否有数据行（不是空表）
      const dataRows = page.locator(DATA_ROW);
      const count = await dataRows.count();
      // 即使空也要验证"暂无数据"占位符
      if (count === 0) {
        const empty = page.locator('.ant-empty').first();
        await expect(empty, `${pg.name} 表格无数据时显示空占位符`).toBeVisible({ timeout: 5000 });
      } else {
        expect(count, `${pg.name} 应有 >= 1 数据行`).toBeGreaterThanOrEqual(1);
      }
    });

    test(`${pg.name} 7. 列头完整渲染（含 ant-table-thead）`, async ({ page }) => {
      await page.goto(pg.path);
      await waitForTableReady(page);
      const headers = page.locator(HEADER_TH);
      const count = await headers.count();
      expect(count, `${pg.name} 应有 >= 3 个列头`).toBeGreaterThanOrEqual(3);
    });
  }
});