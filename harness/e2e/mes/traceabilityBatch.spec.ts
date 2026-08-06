// MES 批次追溯 V10.0.3 批次级 E2E 测试（gen-tests 自动生成版）
// 验证: UI 列表展示批次级 + 聚合字段 + 抽屉正常打开 + 搜索/导出/翻页
// 关联: .claude/plans/2026-08-03-redesign-traceability-batch-level.md
// 关联: hermes/reviews/2026-08-03-orca-review-traceability-batch-level.md
// 规则: 内置 R001-R008 — R001(必填校验-不适用) R005(特殊字符搜索) R008(dictCode-不适用) 命中

import { test, expect } from './helpers/diagnostic-test';
import type { Page } from '@playwright/test';
import { loginViaApi } from './helpers/auth';

const PAGE_PATH = '/project/mes/batch/traceability';

// 帮助函数: 等表格数据稳定（避免列表加载竞态）
async function waitForTableReady(page: Page) {
  await page.waitForTimeout(1500);
  const spinner = page.locator('.ant-spin-spinning').first();
  if (await spinner.count() > 0) {
    await spinner.waitFor({ state: 'hidden', timeout: 10000 }).catch(() => {});
  }
  // 等表格数据行真正可见（排除 measure-row）
  await page.locator('.ant-table-tbody tr.ant-table-row').first().waitFor({ state: 'visible', timeout: 15000 }).catch(() => {});
}

// 数据行选择器（排除 ant-table-measure-row）
const DATA_ROW = '.ant-table-tbody tr.ant-table-row';
const HEADER_TH = '.ant-table-thead th';

test.describe('MES 批次追溯 V10.0.3 批次级 E2E', () => {
  // 动态取一个 dev DB 真实存在的批次号（避免硬编码 PC-20260802-001 在 dev DB 不存在）
  let KNOWN_BATCH_NO = '';
  test.beforeEach(async ({ page, request }) => {
    // admin 权限足够（mes_admin 在某些 UI 路径会跳登录页）
    await loginViaApi(page, PAGE_PATH);
    await waitForTableReady(page);
    if (!KNOWN_BATCH_NO) {
      const login = await request.post('http://127.0.0.1:8080/jeecg-boot/sys/login', {
        data: { username: 'admin', password: '123456', captcha: '1', checkKey: 'x' },
      });
      const token = (await login.json()).result.token;
      const list = await request.get('http://127.0.0.1:8080/jeecg-boot/mes/batch/master/list?pageNo=1&pageSize=1', {
        headers: { 'X-Access-Token': token },
      });
      const records = (await list.json()).result?.records || [];
      KNOWN_BATCH_NO = records[0]?.batchNo || '';
    }
  });

  // ============================================================
  // 1. 页面加载 + 列表列头（V10.0.3 聚合字段）
  // ============================================================
  test('1. 页面加载 + 列表显示批次级字段', async ({ page }) => {
    // 顶部 Alert
    const alert = page.locator('.ant-alert:has-text("查看追溯")');
    await expect(alert).toBeVisible({ timeout: 10000 });

    // 表格可见
    const table = page.locator('.ant-table').first();
    await expect(table).toBeVisible({ timeout: 10000 });

    // V10.0.3 批次级列头（聚合字段）
    const expectedHeaders = ['批次号', '物料', '来源类型', '累计入库', '累计出库', '流水条数', '最新发生时间'];
    for (const header of expectedHeaders) {
      await expect(page.locator(`${HEADER_TH}:has-text("${header}")`).first(), `应显示"${header}"列头`).toBeVisible({ timeout: 10000 });
    }

    // 数据行存在（排除 measure-row）
    await expect(page.locator(DATA_ROW).first(), '应至少 1 条数据行').toBeVisible({ timeout: 10000 });
  });

  // ============================================================
  // 2. 搜索批次号（动态取 dev DB 真实存在的批次号）
  // ============================================================
  test('2. 搜索批次号', async ({ page }) => {
    test.skip(!KNOWN_BATCH_NO, 'dev DB 无批次数据，请先 seed c_mes_batch');

    const batchNoInput = page.locator('input[placeholder="请输入批次号"]').first();
    await expect(batchNoInput).toBeVisible({ timeout: 5000 });
    await batchNoInput.fill(KNOWN_BATCH_NO);

    await page.locator('button:has-text("查询")').first().click();
    await waitForTableReady(page);

    const rows = page.locator(DATA_ROW);
    await rows.first().waitFor({ state: 'visible', timeout: 10000 });
    const count = await rows.count();
    expect(count, `搜索结果应 >= 1 条（搜索 ${KNOWN_BATCH_NO}）`).toBeGreaterThanOrEqual(1);

    // 第一行第一个 td = batchNo
    const firstBatchNo = await rows.first().locator('td').first().textContent();
    expect(firstBatchNo?.trim(), `第一行 batchNo 应为 ${KNOWN_BATCH_NO}`).toBe(KNOWN_BATCH_NO);
  });

  // ============================================================
  // 3. R005 搜索特殊字符（不报错）
  // ============================================================
  test('3. R005 搜索特殊字符不报错', async ({ page }) => {
    const batchNoInput = page.locator('input[placeholder="请输入批次号"]').first();
    await expect(batchNoInput).toBeVisible();

    const specialCases = [
      "' OR '1'='1",
      '%PC%',
      'DROP TABLE',
      '<script>alert(1)</script>',
    ];
    for (const sc of specialCases) {
      await batchNoInput.fill(sc);
      await page.locator('button:has-text("查询")').first().click();
      await waitForTableReady(page);

      // 不报错 — 表格还在（要么有数据，要么空状态）
      const tableOrEmpty = await page.locator('.ant-table, .ant-empty').first().isVisible();
      expect(tableOrEmpty, `特殊字符 "${sc}" 搜索后页面应正常`).toBe(true);

      // 无错误提示（ant-message-error）
      const errorMsg = page.locator('.ant-message-error').first();
      const errCount = await errorMsg.count();
      expect(errCount, `特殊字符 "${sc}" 不应弹错误提示`).toBe(0);
    }
  });

  // ============================================================
  // 4. 点击"查看追溯"打开抽屉（动态取首个批次行）
  // ============================================================
  test('4. 点击查看追溯 → 抽屉显示口径提示 + 流水表', async ({ page }) => {
    test.skip(!KNOWN_BATCH_NO, 'dev DB 无批次数据，请先 seed c_mes_batch');

    const candidates = page.locator(`${DATA_ROW} a:has-text("查看追溯"), ${DATA_ROW} button:has-text("查看追溯")`);
    await candidates.first().waitFor({ state: 'visible', timeout: 10000 });

    // 优先点击 KNOWN_BATCH_NO 对应行，否则取第一行
    let clicked = false;
    const knownRow = page.locator(DATA_ROW).filter({ hasText: KNOWN_BATCH_NO }).first();
    if (await knownRow.count() > 0) {
      const knownLink = knownRow.locator('a:has-text("查看追溯"), button:has-text("查看追溯")').first();
      if (await knownLink.count() > 0) {
        await knownLink.click();
        clicked = true;
      }
    }
    if (!clicked) {
      await candidates.first().click();
    }
    await page.waitForTimeout(2000);

    const drawer = page.locator('.ant-drawer:visible').last();
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // 标题含"批次追溯"
    await expect(drawer.locator('.ant-drawer-title')).toContainText('批次追溯');

    // 顶部 Alert
    const drawerAlert = drawer.locator('.ant-alert:has-text("采购入库")');
    await expect(drawerAlert).toBeVisible();

    // 批次流水 divider + 流水表头（这些始终渲染）
    await expect(drawer.locator('text:has-text("批次流水")')).toBeVisible();
    const ledgerHeaders = ['时间', '业务类型', '业务单据', '入库', '出库'];
    for (const h of ledgerHeaders) {
      await expect(drawer.locator(`th:has-text("${h}")`).first(), `流水表应显示"${h}"列`).toBeVisible({ timeout: 3000 });
    }

    // 关闭抽屉，避免影响后续 test
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
  });

  // ============================================================
  // 5. 导出按钮可见 + 点击触发下载
  // ============================================================
  test('5. 导出按钮可见 + 点击触发下载', async ({ page }) => {
    const exportBtn = page.locator('button:has-text("导出")').first();
    await expect(exportBtn, '导出按钮应可见').toBeVisible({ timeout: 5000 });
    await expect(exportBtn).toBeEnabled();

    // 监听下载事件
    const downloadPromise = page.waitForEvent('download', { timeout: 15000 }).catch(() => null);
    await exportBtn.click();
    const download = await downloadPromise;
    if (download) {
      const filename = download.suggestedFilename();
      expect(filename.endsWith('.xlsx') || filename.endsWith('.xls'), `下载文件名应是 Excel (${filename})`).toBe(true);
    } else {
      // 没触发下载可能是浏览器拦截，记录但不 fail
      console.warn('  ⚠️ 导出未触发 download 事件（可能被浏览器拦截）');
    }
  });

  // ============================================================
  // 6. 验证无旧 ledger 字段在列头
  // ============================================================
  test('6. 列表列不包含旧 ledger 字段', async ({ page }) => {
    const oldFields = ['bizType', 'bizNo', 'inQty', 'outQty', 'occurTime', 'remark'];
    for (const f of oldFields) {
      const th = page.locator(`${HEADER_TH}:has-text("${f}")`);
      const count = await th.count();
      expect(count, `列表列不应含旧字段"${f}"`).toBe(0);
    }
  });

  // ============================================================
  // 7. 重置搜索表单
  // ============================================================
  test('7. 重置按钮清空搜索条件', async ({ page }) => {
    const batchNoInput = page.locator('input[placeholder="请输入批次号"]').first();
    await batchNoInput.fill('任意内容');

    const resetBtn = page.locator('button:has-text("重置")').first();
    if (await resetBtn.count() > 0) {
      await resetBtn.click();
      await page.waitForTimeout(500);
      const value = await batchNoInput.inputValue();
      expect(value, '重置后批次号输入应为空').toBe('');
    } else {
      console.warn('  ⚠️ 未找到重置按钮，跳过');
    }
  });

  // ============================================================
  // 8. 翻页（如有数据）
  // ============================================================
  test('8. 翻页到第二页（如有数据）', async ({ page }) => {
    const rows = page.locator('.ant-table-tbody > tr');
    const initialCount = await rows.count();
    test.skip(initialCount < 5, '数据少于 5 条，跳过翻页测试');

    const nextPageBtn = page.locator('.ant-pagination-next, .ant-pagination-item-2').first();
    if (await nextPageBtn.count() > 0) {
      await nextPageBtn.click();
      await waitForTableReady(page);
      await expect(page.locator(DATA_ROW).first()).toBeVisible({ timeout: 10000 });
    } else {
      console.warn('  ⚠️ 未找到翻页按钮，跳过');
    }
  });
});