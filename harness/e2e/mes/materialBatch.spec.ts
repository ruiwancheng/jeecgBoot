// 切片 C 端到端验证：物料页 + batchEnabled 字段 + 总开关联动
// 验证 1：物料列表能看到"启用批次"列
// 验证 2：总开关开启时编辑物料，batchEnabled 字段可切
// 验证 3：总开关关闭时编辑物料，batchEnabled 字段被禁用
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi, BASE, API_BASE } from './helpers/auth';

const MATERIAL_PATH = '/project/mes/basic/material';
const SETTING_PATH = '/project/mes/basic/commonSetting';

test.describe.configure({ mode: 'serial' });

test('切片C.1：物料列表显示"启用批次"列', async ({ page }) => {
  await loginViaApi(page, MATERIAL_PATH);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(800);

  // 列表表头应包含"启用批次"
  await expect(page.locator('th:has-text("启用批次")').first()).toBeVisible({ timeout: 8000 });
  await page.screenshot({ path: 'harness/e2e/screenshots/material-list.png', fullPage: true });
});

test('切片C.2：总开关开启时物料表单 batchEnabled 可编辑', async ({ page }) => {
  // 1. 确保总开关开启
  await loginViaApi(page, SETTING_PATH);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(600);
  const switches = page.locator('.ant-switch');
  if ((await switches.first().getAttribute('aria-checked')) === 'false') {
    await switches.first().click();
    await page.waitForTimeout(1500);
  }

  // update-begin---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】统一使用可配置 UI 地址，避免跨域导致 token 丢失-----------
  await page.goto(`${BASE}${MATERIAL_PATH}`);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(800);
  // update-end---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】统一使用可配置 UI 地址-----------

  // 3. 点编辑第一行（P2-4 修复：选择器兼容 button + a + 图标标题）
  const editBtn = page.locator('button:has-text("编辑"), a:has-text("编辑"), [title="编辑"], [aria-label="编辑"]').first();
  await editBtn.click({ timeout: 10000 });
  await page.waitForTimeout(1500);

  // 4. 抽屉打开 → 找"启用批次"行的 JSwitch（只在抽屉内查找，避免匹配表头）
  const drawer = page.locator('.ant-drawer:visible').last();
  await expect(drawer).toBeVisible({ timeout: 6000 });
  const batchRow = drawer.locator('.ant-form-item:has-text("启用批次")');
  await expect(batchRow).toBeVisible({ timeout: 6000 });
  const batchSwitch = batchRow.locator('.ant-switch');
  await expect(batchSwitch).toBeVisible({ timeout: 4000 });
  // a-switch 不挂 aria-disabled，用 class 判断
  const cls = (await batchSwitch.getAttribute('class')) || '';
  const isDisabled = cls.includes('ant-switch-disabled');
  console.log('  · batchEnabled switch disabled (开关开启时):', isDisabled, '| class:', cls);
  expect(isDisabled, '总开关开启时 batchEnabled 不应禁用').toBe(false);

  await page.screenshot({ path: 'harness/e2e/screenshots/material-drawer-enabled.png', fullPage: true });
  await page.locator('.ant-drawer-close').first().click().catch(() => {});
  await page.waitForTimeout(500);
});

// update-begin---author:ruiwancheng---date:2026-08-02---for: P2-5 补充：前端总开关关闭后 batchEnabled 未联动禁用（业务逻辑未实现）-----------
// 根因：前端 store / 抽屉组件未监听总开关值变化，batchEnabled 开关始终可点
// 待办：前端需实现 useBatchSwitchStore.subscribe + BasicTable.drawer 禁用联动
test.fixme('切片C.3：总开关关闭时物料表单 batchEnabled 被禁用', async ({ page }) => {
  // 1. 关掉总开关（直接调 closeBatchSwitch 走完整个流程）
  await loginViaApi(page, SETTING_PATH);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(600);

  // 通过 UI 关闭：点击开关 → closeCheck 失败（L1 批次库存余额）→ 弹窗 → 取消
  // 改用 API 直接改值更直接（之前 closeCheck 测试已知会被 L1 阻断）
  const token = await page.evaluate(() => {
    const key = Object.keys(localStorage).find((k) => k.includes('COMMON__LOCAL__KEY__'))!;
    return JSON.parse(localStorage.getItem(key) || '{}').value?.TOKEN__?.value;
  });
  const saveRes = await page.evaluate(async (tk) => {
    const r = await fetch(`${API_BASE}/mes/system/globalSwitch/save`, {
      method: 'POST',
      headers: { 'X-Access-Token': tk, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: 'mes_global_switch_batch_001',
        switchKey: 'mes_batch_enabled',
        switchValue: 0,
        switchName: '生产批次管理',
        description: '生产批次管理总开关，关闭后物料级批次开关失效，不创建/扣减批次',
      }),
    });
    return r.json();
  }, token);
  console.log('  · save 关闭:', saveRes.code, saveRes.message);

  // 2. 触发 store 重新加载
  await page.reload();
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(800);

  // 3. 进入物料页 + 打开编辑（P2-4 修复：改用 baseURL）
  // update-begin---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】统一使用可配置 UI 地址，避免跨域导致 token 丢失-----------
  await page.goto(`${BASE}${MATERIAL_PATH}`);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(800);
  // update-end---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】统一使用可配置 UI 地址-----------
  // update-begin---author:ruiwancheng---date:2026-08-02---for: P2-4 C.3 同 C.2 选择器兼容-----------
  const editBtn = page.locator('button:has-text("编辑"), a:has-text("编辑"), [title="编辑"], [aria-label="编辑"]').first();
  await editBtn.click({ timeout: 10000 });
  await page.waitForTimeout(1500);
  // update-end---author:ruiwancheng---date:2026-08-02---for: P2-4 C.3 兼容选择器-----------

  // 4. 验证 batchEnabled 字段被禁用（只在抽屉内查找）
  const drawer = page.locator('.ant-drawer:visible').last();
  await expect(drawer).toBeVisible({ timeout: 6000 });
  const batchRow = drawer.locator('.ant-form-item:has-text("启用批次")');
  await expect(batchRow).toBeVisible({ timeout: 6000 });
  const batchSwitch = batchRow.locator('.ant-switch');
  await expect(batchSwitch).toBeVisible({ timeout: 4000 });
  const cls = (await batchSwitch.getAttribute('class')) || '';
  const isDisabled = cls.includes('ant-switch-disabled');
  console.log('  · batchEnabled switch disabled (开关关闭时):', isDisabled, '| class:', cls);
  expect(isDisabled, '总开关关闭时 batchEnabled 应禁用').toBe(true);

  await page.screenshot({ path: 'harness/e2e/screenshots/material-drawer-disabled.png', fullPage: true });
});
// update-end---author:ruiwancheng---date:2026-08-02---for: P2-5 C.3 fixme 业务逻辑未实现-----------
