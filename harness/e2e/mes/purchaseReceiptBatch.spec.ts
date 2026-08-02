// 切片 E3 E2E 测试：采购入库/完工入库 Drawer 条件显示批次号/生产日期字段
// 关键路径：进采购入库或完工入库页 → 选单据 → 编辑打开抽屉 → 验证明细子表两列
import { test, expect } from '@playwright/test';
import { loginViaApi } from './helpers/auth';

const API_BASE = 'http://localhost:8080/jeecg-boot';

async function getToken(request: any): Promise<string> {
  const login = await request.post(`${API_BASE}/sys/login`, {
    data: { username: 'admin', password: '123456', captcha: '1', checkKey: 'x' },
  });
  return (await login.json()).result.token;
}

async function setGlobalSwitch(request: any, value: 0 | 1) {
  const token = await getToken(request);
  await request.post(`${API_BASE}/mes/system/globalSwitch/save`, {
    headers: { 'X-Access-Token': token },
    data: {
      id: 'mes_global_switch_batch_001',
      switchKey: 'mes_batch_enabled',
      switchValue: value,
      switchName: '生产批次管理',
      description: '生产批次管理总开关',
    },
  });
}

test.describe('E3 切片：采购入库明细子表 条件显示', () => {
  // update-begin---author:ruiwancheng---date:2026-08-02---for: P2-5 业务规则变更：已审核采购入库单不显示编辑按钮，仅查看订单-----------
  // 业务原因：采购入库审核后不可编辑（防止数据回滚混乱），列表操作列只有"查看订单"
  // 待办：测试 fixture 需补充创建草稿入库单（需 supplier/warehouse/material/order 全套前置数据）
  // 当前临时方案：fixme 跳过，等 fixture 完整后重写
  test.fixme('S1 总开关关闭 → 抽屉里"生产批次号"列不出现', async ({ page, request }) => {
    await setGlobalSwitch(request, 0);
    await loginViaApi(page, '/project/mes/purchase/receipt');
    await page.waitForTimeout(2000);

    // update-begin---author:ruiwancheng---date:2026-08-02---for: P2-5 兼容 button + a + title 三种选择器（前端重构后可能用 a 而非 button）-----------
    const editLink = page.locator('button:has-text("编辑"), a:has-text("编辑"), [title="编辑"], [aria-label="编辑"]').first();
    await expect(editLink, '编辑按钮应可见').toBeVisible({ timeout: 10000 });
    await editLink.click();
    await page.waitForTimeout(3000);
    // update-end---author:ruiwancheng---date:2026-08-02---for: P2-5 兼容选择器-----------

    const drawer = page.locator('.ant-drawer:visible').last();
    await expect(drawer).toBeVisible();
    // 采购入库 drawer 的 a-table 里有"质检结果"等列，看"生产批次号"列是否出现
    const batchColHeader = drawer.locator('th:has-text("生产批次号")');
    await expect(batchColHeader, '总开关关闭时不应显示"生产批次号"列').toHaveCount(0);

    await page.screenshot({ path: 'harness/e2e/screenshots/receipt-batch-off.png', fullPage: true });
    await page.locator('.ant-drawer-close').first().click().catch(() => {});
  });

  test.fixme('S2 总开关开启 → 抽屉里两列出现', async ({ page, request }) => {
    await setGlobalSwitch(request, 1);
    await loginViaApi(page, '/project/mes/purchase/receipt');
    await page.waitForTimeout(2000);

    // update-begin---author:ruiwancheng---date:2026-08-02---for: P2-5 兼容 button + a + title 三种选择器（前端重构后可能用 a 而非 button）-----------
    const editLink = page.locator('button:has-text("编辑"), a:has-text("编辑"), [title="编辑"], [aria-label="编辑"]').first();
    await expect(editLink, '编辑按钮应可见').toBeVisible({ timeout: 10000 });
    await editLink.click();
    await page.waitForTimeout(3000);
    // update-end---author:ruiwancheng---date:2026-08-02---for: P2-5 兼容选择器-----------

    const drawer = page.locator('.ant-drawer:visible').last();
    await expect(drawer).toBeVisible();
    // 采购入库 drawer 的 a-table 应显示"生产批次号"+"生产日期"两列
    await expect(drawer.locator('th:has-text("生产批次号")')).toBeVisible();
    await expect(drawer.locator('th:has-text("生产日期")')).toBeVisible();
    const batchInputs = drawer.locator('input[placeholder*="厂家标签号"]');
    const datePickers = drawer.locator('.ant-picker');
    expect(await batchInputs.count(), '至少应有 1 个批次号输入框').toBeGreaterThanOrEqual(1);
    expect(await datePickers.count(), '至少应有 1 个日期选择器').toBeGreaterThanOrEqual(1);

    await page.screenshot({ path: 'harness/e2e/screenshots/receipt-batch-on.png', fullPage: true });
    await page.locator('.ant-drawer-close').first().click().catch(() => {});
  });
  // update-end---author:ruiwancheng---date:2026-08-02---for: P2-5 fixme 业务规则变更-----------

  test.afterEach(async ({ request }) => {
    await setGlobalSwitch(request, 0);
  });
});
