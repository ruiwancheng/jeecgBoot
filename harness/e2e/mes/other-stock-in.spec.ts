import { test, expect } from '@playwright/test';

const BASE = 'http://100.122.125.106';
let accessToken: string;

async function loginViaApi(page: any) {
  const res = await fetch(`${BASE}:8080/jeecg-boot/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'mes_admin', password: '123456' }),
  });
  const data = await res.json();
  expect(data.code).toBe(200);
  accessToken = data.result.token;
  await page.goto('/');
  // JeecgBoot 缓存结构: localStorage[<prefix>COMMON__LOCAL__KEY__] = { value: { TOKEN__: token, ... }, time, expire }
  await page.evaluate((token: string) => {
    const keys = Object.keys(localStorage);
    const cacheKey = keys.find(k => k.includes('COMMON__LOCAL__KEY__'))
      || 'JEECGBOOT_PRO__PRODUCTION__3.9.2__COMMON__LOCAL__KEY__';
    let cache: any = {};
    try { cache = JSON.parse(localStorage.getItem(cacheKey) || '{}'); } catch { cache = {}; }
    if (!cache.value) cache.value = {};
    // 每个 key 也是 {value, time, expire} 包装结构（Persistent.getLocal 读 .value）
    cache.value['TOKEN__'] = { value: token, time: Date.now(), expire: Date.now() + 7 * 24 * 3600 * 1000 };
    cache.time = Date.now();
    cache.expire = Date.now() + 7 * 24 * 3600 * 1000;
    localStorage.setItem(cacheKey, JSON.stringify(cache));
  }, accessToken);
  await page.goto('/project/mes/stock/other-in');
  await page.waitForTimeout(2000);
  // 偶发竞态：若被重定向回登录页，重注入再跳一次
  if (page.url().includes('/login')) {
    await page.evaluate((token: string) => {
      const key = Object.keys(localStorage).find(k => k.includes('COMMON__LOCAL__KEY__'));
      if (!key) return;
      const cache = JSON.parse(localStorage.getItem(key) || '{}');
      if (!cache.value) cache.value = {};
      cache.value['TOKEN__'] = { value: token, time: Date.now(), expire: Date.now() + 7 * 24 * 3600 * 1000 };
      localStorage.setItem(key, JSON.stringify(cache));
    }, accessToken);
    await page.goto('/project/mes/stock/other-in');
    await page.waitForTimeout(2500);
  }
}

async function cleanupDoc(code: string) {
  try {
    const listRes = await fetch(`${BASE}:8080/jeecg-boot/mes/stock/otherIn/list?pageNo=1&pageSize=5&code=${code}`, {
      headers: { 'X-Access-Token': accessToken },
    });
    const list = await listRes.json();
    const doc = list.result?.records?.[0];
    if (doc) {
      await fetch(`${BASE}:8080/jeecg-boot/mes/stock/otherIn/unaudit?id=${doc.id}`, { method: 'PUT', headers: { 'X-Access-Token': accessToken } });
      await fetch(`${BASE}:8080/jeecg-boot/mes/stock/otherIn/delete?id=${doc.id}`, { method: 'DELETE', headers: { 'X-Access-Token': accessToken } });
    }
  } catch (e) { console.log('cleanup skip', e); }
}

test.describe('其它入库', () => {
  test.beforeEach(async ({ page }) => { await loginViaApi(page); });

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
    // 搜索有成本的物料 MAT-A000027（avg=50）
    await modal.getByPlaceholder('搜索编码/名称/规格').fill('MAT-A000027');
    await modal.getByRole('button', { name: '搜 索' }).click();
    // 等搜索结果行出现再选中
    await modal.locator('.ant-table-row', { hasText: 'MAT-A000027' }).first().waitFor({ timeout: 8000 });
    await modal.locator('.ant-table-row', { hasText: 'MAT-A000027' }).first().locator('.ant-radio-wrapper').click();
    await page.waitForTimeout(300);
    await modal.getByRole('button', { name: '确 认' }).click();
    await page.waitForTimeout(800);
    console.log('✅ 已选物料');

    // 6. 验证成本单价被预填为移动平均 50
    const costInput = drawer.locator('input[placeholder="手工录入"]').first();
    const costValue = await costInput.inputValue();
    expect(Number(costValue)).toBe(50);
    console.log(`✅ 成本单价自动预填: ${costValue}（= 物料移动平均 50）`);

    // 7. 保存后用 API 验证单据真实落库（比 toast 可靠）
    await drawer.getByRole('button', { name: '确 认' }).click();
    await page.waitForTimeout(2500);
    const listRes = await fetch(`${BASE}:8080/jeecg-boot/mes/stock/otherIn/list?pageNo=1&pageSize=5&code=${code}`, {
      headers: { 'X-Access-Token': accessToken },
    });
    const list = await listRes.json();
    const saved = list.result?.records?.[0];
    expect(saved).toBeTruthy();
    expect(saved.totalAmount).toBe(50);
    console.log(`✅ 单据落库: ${saved.code} totalAmount=${saved.totalAmount}`);

    // 8. 清理
    await cleanupDoc(code);
  });
});
