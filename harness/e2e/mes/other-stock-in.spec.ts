import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi, BASE, API_BASE } from './helpers/auth';

let accessToken: string;

async function cleanupDoc(code: string) {
  try {
    const listRes = await fetch(`${API_BASE}/mes/stock/otherIn/list?pageNo=1&pageSize=5&code=${code}`, {
      headers: { 'X-Access-Token': accessToken },
    });
    const list = await listRes.json();
    const doc = list.result?.records?.[0];
    if (doc) {
      await fetch(`${API_BASE}/mes/stock/otherIn/unaudit?id=${doc.id}`, { method: 'PUT', headers: { 'X-Access-Token': accessToken } });
      await fetch(`${API_BASE}/mes/stock/otherIn/delete?id=${doc.id}`, { method: 'DELETE', headers: { 'X-Access-Token': accessToken } });
    }
  } catch (e) { console.log('cleanup skip', e); }
}

test.describe('其它入库', () => {
  test.beforeEach(async ({ page }) => { accessToken = await loginViaApi(page, '/project/mes/stock/other-in'); });

  test('新增入库单-物料选中后自动预填移动平均成本', async ({ page }) => {
    const code = `E2E_OST_${Date.now()}`;

    // 1. 页面加载
    await page.waitForSelector('.ant-table', { timeout: 10000 });
    console.log('✅ 其它入库列表加载');

    // 2. 点新增
    await page.locator('button:has-text("新增")').first().click();
    await page.waitForTimeout(1000);
    await expect(page.locator('.ant-drawer-title')).toContainText('新增入库单');
    console.log('✅ 新增入库单抽屉打开');

    // 3. 填主表（所有操作都限定在抽屉内，避免误触列表页搜索区）
    const drawer = page.locator('.ant-drawer:has-text("新增入库单")').first();
    await drawer.locator('input[placeholder="QT-IN-YYYYMMDD-0001"]').fill(code);
    // 入库类型：点开抽屉内 select，选可见下拉的第一项
    await drawer.locator('.ant-select').filter({ hasText: '请选择入库类型' }).first().locator('.ant-select-selector').click();
    await page.waitForSelector('.ant-select-dropdown:visible .ant-select-item-option', { timeout: 5000 });
    await page.waitForTimeout(400);
    // 首项可能是“全部”（空值），选第二项
    await page.locator('.ant-select-dropdown:visible .ant-select-item-option').nth(1).click({ force: true });

    // 仓库：同法
    await drawer.locator('.ant-select').filter({ hasText: '请选择仓库' }).first().locator('.ant-select-selector').click();
    await page.waitForSelector('.ant-select-dropdown:visible .ant-select-item-option', { timeout: 5000 });
    await page.waitForTimeout(400);
    await page.locator('.ant-select-dropdown:visible .ant-select-item-option').first().click({ force: true });
    await page.waitForTimeout(300);

    // 原因
    await drawer.locator('textarea[placeholder="手工填写入库原因"]').fill('E2E 成本联动验证');

    // 4. 明细行（抽屉打开时已默认带一行，直接在第一行选物料）
    const matInput = drawer.locator('input[placeholder="点击选择物料"]').first();
    await matInput.click();
    await page.waitForTimeout(1500);
    const modal = page.locator('.ant-modal').filter({ hasText: '选择物料' }).first();
    await expect(modal).toBeVisible();
    // 2026-08-05 物料动态化（TS-2）：通过 API 查第一个 movingAvgCost > 0 的物料，避免硬编码 MAT-A000027 在环境不存在
    //   历史依据：hermes/eagle-eye/issues/mes-2026-08-04-business-bugs.md #7
    const matListRes = await fetch(`${API_BASE}/mes/basic/material/list?pageNo=1&pageSize=20`, { headers: { 'X-Access-Token': accessToken } });
    const matList = await matListRes.json();
    const mat = (matList.result?.records || []).find((m: any) => Number(m.movingAvgCost) > 0);
    expect(mat, '环境须有 movingAvgCost>0 的物料（其它入库成本预填依赖此数据）').toBeTruthy();
    const expectedCost = Number(mat.movingAvgCost);
    console.log(`✅ 动态选中物料: ${mat.code} movingAvgCost=${expectedCost}`);
    // 弹窗里搜这个物料编码
    await modal.getByPlaceholder('搜索编码/名称/规格').fill(mat.code);
    await modal.getByRole('button', { name: '搜 索' }).click();
    await modal.locator('.ant-table-row', { hasText: mat.code }).first().waitFor({ timeout: 8000 });
    await modal.locator('.ant-table-row', { hasText: mat.code }).first().locator('.ant-radio-wrapper').click();
    await page.waitForTimeout(300);
    await modal.getByRole('button', { name: '确 认' }).click();
    await page.waitForTimeout(800);
    console.log('✅ 已选物料');

    // 6. 验证成本单价被预填为移动平均
    const costInput = drawer.locator('input[placeholder="手工录入"]').first();
    const costValue = await costInput.inputValue();
    expect(Number(costValue)).toBe(expectedCost);
    console.log(`✅ 成本单价自动预填: ${costValue}（= 物料移动平均 ${expectedCost}）`);

    // 7. 保存后用 API 验证单据真实落库（比 toast 可靠）
    await drawer.getByRole('button', { name: '确 认' }).click();
    await page.waitForTimeout(2500);
    const listRes = await fetch(`${API_BASE}/mes/stock/otherIn/list?pageNo=1&pageSize=5&code=${code}`, {
      headers: { 'X-Access-Token': accessToken },
    });
    const list = await listRes.json();
    const saved = list.result?.records?.[0];
    expect(saved).toBeTruthy();
    expect(saved.totalAmount).toBe(expectedCost);
    console.log(`✅ 单据落库: ${saved.code} totalAmount=${saved.totalAmount}`);

    // 8. 清理
    await cleanupDoc(code);
  });
});
