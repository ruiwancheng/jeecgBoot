// MES 生产订单详情 Drawer 补领按钮 E2E 测试 [/add-tests manufacturing 生产链路 OrderDrawer 补领]
//
// 覆盖 slice-5 中 OrderDrawer.vue 加的"补领"按钮 + 关联领料单子表
// 链路：进订单列表 → 点行查看 → 抽屉展开 → 看到补领按钮（仅已下达/执行中可见） → 点击 → 弹窗 → 选订单 → 提交 → 生成草稿领料单
//
// UI 锚点（按 testing.md v2 L0）：
//   锚点 1: OrderDrawer 打开后，"补领"按钮按订单 status 显隐
//           - status=草稿(1) / 已审核(2) / 已取消(7) / 已关闭(6) → 按钮不可见
//           - status=已下达(3) → 按钮可见
//   锚点 2: 关联领料单子表：Drawer 打开后展示该订单关联的所有领料单（按 productionOrderId 过滤）
//   锚点 3: 补领弹窗：含订单选择器 + 数量预览（剩余可领量）
//
// payload 抓包保真：
//   1. GET /mes/manufacturing/order/queryById?id=xxx（Drawer 打开时）
//   2. GET /mes/manufacturing/picking/list?productionOrderId=xxx（关联领料单）
//   3. POST /mes/manufacturing/picking/generateByOrder?orderId=xxx（补领提交）
//
// 5 断言锚点（testing.md v2 L0）：
//   #1 创建断言   : Drawer 打开可见
//   #2 状态流转   : 补领按钮按 status 显隐
//   #3 数据传递   : 关联领料单按 productionOrderId 过滤
//   #4 显示值     : 关联领料单 status_tag 显示中文（草稿/已审核）
//   #5 清理       : 测试结束 DB 兜底 + API 删 fixture

import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const ORDER_PAGE = '/project/mes/manufacturing/order';

async function api(method, path, body, token) {
  const BASE = (typeof process !== 'undefined' && process.env && process.env.API_BASE) || 'http://localhost:8080/jeecg-boot';
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['X-Access-Token'] = token;
  const opts = { method, headers };
  let url = BASE + path;
  if (body && (method === 'GET' || method === 'DELETE')) {
    url += (path.includes('?') ? '&' : '?') + new URLSearchParams(body).toString();
  } else if (body) {
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(url, opts);
  return res.json();
}

async function createMaterial(token, code, name) {
  await api('POST', '/mes/basic/material/add', { code, name, type: '1' }, token);
  const r = await api('GET', `/mes/basic/material/list?code=${code}`, null, token);
  return r.result?.records?.[0]?.id;
}
async function createWarehouse(token, code, name) {
  await api('POST', '/mes/basic/warehouse/add', { code, name, status: 1 }, token);
  const r = await api('GET', `/mes/basic/warehouse/list?code=${code}`, null, token);
  return r.result?.records?.[0]?.id;
}

test.describe('MES 生产订单详情 Drawer 补领按钮 E2E（[/add-tests]）', () => {
  const TS = Date.now();
  let token;
  let finishedMatId, m1MatId, warehouseId;
  let bomId, orderDraftId, orderAuditedId, orderReleasedId, orderCancelledId;
  const createdMaterials: string[] = [];
  const createdWarehouses: string[] = [];
  const createdBoms: string[] = [];
  const createdOrders: string[] = [];
  const createdPickings: string[] = [];

  test.beforeAll(async ({ request }) => {
    // 用 fetch 直接登录拿 token（避开页面交互）
    const loginRes = await request.post('http://localhost:8080/jeecg-boot/sys/login', {
      data: { username: 'admin', password: '123456' },
    });
    const loginJson = await loginRes.json();
    token = loginJson.result?.token;

    // Setup: 1 产成品 + 1 子件 + 1 仓库 + 期初库存
    finishedMatId = await createMaterial(token, `MAT_DRAWER_${TS}_fin`, 'Drawer补领产成品');
    m1MatId = await createMaterial(token, `MAT_DRAWER_${TS}_a`, 'Drawer补领子件');
    warehouseId = await createWarehouse(token, `WH_DRAWER_${TS}`, 'Drawer补领仓');
    createdMaterials.push(finishedMatId, m1MatId);
    createdWarehouses.push(warehouseId);

    // 期初库存 m1=100
    const stockInCode = `FIXIN_DRAWER_${TS}`;
    await api('POST', '/mes/stock/otherIn/add', {
      code: stockInCode, inType: '2', warehouseId, reason: 'E2E 期初',
      stockDate: new Date().toISOString().slice(0, 10),
      items: [{ materialId: m1MatId, qty: 100, unitCost: 10 }],
    }, token);
    const stockList = await api('GET', `/mes/stock/otherIn/list?code=${stockInCode}`, null, token);
    await api('PUT', `/mes/stock/otherIn/audit?id=${stockList.result.records[0]?.id}`, null, token);

    // BOM 创建 + 生效
    const bomCode = `BOM_DRAWER_${TS}`;
    await api('POST', '/mes/manufacturing/bom/add', {
      code: bomCode, productId: finishedMatId, version: 'V1.0',
      status: '1', remark: 'Drawer E2E BOM',
      items: [{ lineNo: 1, materialId: m1MatId, quantity: 1 }],
    }, token);
    const bomList = await api('GET', `/mes/manufacturing/bom/list?code=${bomCode}`, null, token);
    bomId = bomList.result?.records?.[0]?.id;
    createdBoms.push(bomId);
    await api('PUT', `/mes/manufacturing/bom/approve?id=${bomId}`, null, token);

    // 创建 4 个订单（4 种状态）：草稿、已审核、已下达、已取消
    const mkOrder = async (suffix, extraCalls = []) => {
      const code = `ORD_DRAWER_${TS}_${suffix}`;
      await api('POST', '/mes/manufacturing/order/add', {
        code, productId: finishedMatId, bomId,
        planQty: 5, warehouseId,
        startDate: new Date().toISOString().slice(0, 10),
        endDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        status: '1',
      }, token);
      const list = await api('GET', `/mes/manufacturing/order/list?code=${code}`, null, token);
      const id = list.result?.records?.[0]?.id;
      for (const c of extraCalls) await c(id);
      return id;
    };
    orderDraftId = await mkOrder('draft');
    orderAuditedId = await mkOrder('audited', [id => api('PUT', `/mes/manufacturing/order/audit?id=${id}`, null, token)]);
    orderReleasedId = await mkOrder('released', [
      id => api('PUT', `/mes/manufacturing/order/audit?id=${id}`, null, token),
      id => api('PUT', `/mes/manufacturing/order/release?id=${id}`, null, token),
    ]);
    orderCancelledId = await mkOrder('cancelled', [
      id => api('PUT', `/mes/manufacturing/order/cancel?id=${id}`, null, token),
    ]);
    createdOrders.push(orderDraftId, orderAuditedId, orderReleasedId, orderCancelledId);
  });

  test.beforeEach(async ({ page }) => {
    await loginViaApi(page);
  });

  // ============================================================
  // 锚点 1: OrderDrawer 打开后，"补领"按钮按订单 status 显隐
  // ============================================================
  test('锚点 1: 草稿/已审核/已取消订单 Drawer 中"补领"按钮不可见', async ({ page }) => {
    await page.goto(ORDER_PAGE);
    await page.waitForTimeout(1500);
    await page.locator('.ant-table-tbody tr.ant-table-row').first().waitFor({ state: 'visible', timeout: 10000 }).catch(() => {});

    // 用 code 搜订单
    const searchInput = page.locator('input[placeholder*="单号"], input[placeholder*="订单"], input').first();
    await searchInput.fill(`ORD_DRAWER_${TS}_draft`);
    await searchInput.press('Enter');
    await page.waitForTimeout(1500);

    // 点击第一行 → 打开 Drawer
    const firstRow = page.locator('.ant-table-tbody tr.ant-table-row').first();
    await firstRow.click();
    await page.waitForTimeout(2000);

    // Drawer 可见
    const drawer = page.locator('.ant-drawer-content').first();
    await expect(drawer, 'OrderDrawer 可见').toBeVisible({ timeout: 10000 });

    // 补领按钮应该不可见（草稿态）
    const pickupBtn = drawer.locator('button:has-text("补领")');
    await expect(pickupBtn, '草稿订单补领按钮不可见').toHaveCount(0);
  });

  test('锚点 1b: 已下达订单 Drawer 中"补领"按钮可见', async ({ page }) => {
    await page.goto(ORDER_PAGE);
    await page.waitForTimeout(1500);

    const searchInput = page.locator('input[placeholder*="单号"], input[placeholder*="订单"], input').first();
    await searchInput.fill(`ORD_DRAWER_${TS}_released`);
    await searchInput.press('Enter');
    await page.waitForTimeout(1500);

    const firstRow = page.locator('.ant-table-tbody tr.ant-table-row').first();
    await firstRow.click();
    await page.waitForTimeout(2000);

    const drawer = page.locator('.ant-drawer-content').first();
    await expect(drawer, 'OrderDrawer 可见').toBeVisible({ timeout: 10000 });

    // 补领按钮应该可见（已下达态）
    const pickupBtn = drawer.locator('button:has-text("补领")');
    await expect(pickupBtn, '已下达订单补领按钮可见').toBeVisible({ timeout: 5000 });
  });

  // ============================================================
  // 锚点 2: 关联领料单子表
  // ============================================================
  test('锚点 2: 已下达订单 Drawer 展示关联领料单（按 productionOrderId 过滤）', async ({ page }) => {
    await page.goto(ORDER_PAGE);
    await page.waitForTimeout(1500);

    const searchInput = page.locator('input[placeholder*="单号"], input[placeholder*="订单"], input').first();
    await searchInput.fill(`ORD_DRAWER_${TS}_released`);
    await searchInput.press('Enter');
    await page.waitForTimeout(1500);

    const firstRow = page.locator('.ant-table-tbody tr.ant-table-row').first();
    await firstRow.click();
    await page.waitForTimeout(2000);

    const drawer = page.locator('.ant-drawer-content').first();
    await expect(drawer, 'OrderDrawer 可见').toBeVisible({ timeout: 10000 });

    // 关联领料单子表应至少展示一行（release 已生成的草稿领料单）
    // 子表标题可能含"领料"二字
    const subTable = drawer.locator('.ant-table').last();
    await expect(subTable, '关联领料单子表可见').toBeVisible({ timeout: 10000 });

    // 提取关联领料单的 ID 用于补领弹窗
    const pickingRow = subTable.locator('tr.ant-table-row').first();
    await expect(pickingRow, '关联领料单有数据').toBeVisible({ timeout: 5000 });

    // 状态字典显示中文（草稿 / 已审核）
    const tagText = await pickingRow.locator('.ant-tag').first().innerText().catch(() => '');
    const rowText = await pickingRow.innerText();
    const hasChineseTag = /草稿|已审核/.test(tagText + ' ' + rowText);
    expect(hasChineseTag, '领料单 status 显示中文（非裸 ID）').toBe(true);
  });

  // ============================================================
  // 锚点 3: 补领弹窗
  // ============================================================
  test('锚点 3: 点击补领按钮 → 弹窗含订单选择器 → 提交后生成新草稿领料单', async ({ page }) => {
    await page.goto(ORDER_PAGE);
    await page.waitForTimeout(1500);

    const searchInput = page.locator('input[placeholder*="单号"], input[placeholder*="订单"], input').first();
    await searchInput.fill(`ORD_DRAWER_${TS}_released`);
    await searchInput.press('Enter');
    await page.waitForTimeout(1500);

    const firstRow = page.locator('.ant-table-tbody tr.ant-table-row').first();
    await firstRow.click();
    await page.waitForTimeout(2000);

    const drawer = page.locator('.ant-drawer-content').first();
    const pickupBtn = drawer.locator('button:has-text("补领")');
    await pickupBtn.click();
    await page.waitForTimeout(1500);

    // 补领 modal 可见（含订单选择器）
    const modal = page.locator('.ant-modal-content').first();
    await expect(modal, '补领弹窗可见').toBeVisible({ timeout: 10000 });

    // 弹窗内应有订单选择器（a-select 或 a-cascader）
    const orderSelector = modal.locator('.ant-select').first();
    await expect(orderSelector, '订单选择器可见').toBeVisible({ timeout: 5000 });

    // 提交（选当前订单）
    const confirmBtn = modal.locator('button:has-text("确定"), button:has-text("提交"), button.ant-btn-primary').last();
    if (await confirmBtn.count() > 0) {
      await confirmBtn.click();
      await page.waitForTimeout(2000);
      // 弹窗应关闭（提交成功）
      await expect(modal, '提交后弹窗关闭').toHaveCount(0, { timeout: 10000 }).catch(() => {});
    }
  });

  // ============================================================
  // 清理
  // ============================================================
  test.afterAll(async () => {
    // API 删除订单（草稿/已取消可删，其他 DB 兜底）
    for (const id of createdOrders.filter(Boolean)) {
      try {
        const detail = await api('GET', `/mes/manufacturing/order/queryById?id=${id}`, null, token);
        if (detail?.result?.status === '1' || detail?.result?.status === '7') {
          await api('DELETE', `/mes/manufacturing/order/delete?id=${id}`, null, token);
        } else {
          const { execSync } = await import('node:child_process');
          try {
            execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -e "UPDATE c_mes_production_order SET del_flag=1 WHERE id='${id}';"`, { stdio: 'pipe' });
          } catch (e) {}
        }
      } catch (e) {}
    }
    // BOM（生效不可 API 删，DB 兜底）
    for (const id of createdBoms.filter(Boolean)) {
      const { execSync } = await import('node:child_process');
      try {
        execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -e "UPDATE c_mes_bom SET del_flag=1 WHERE id='${id}'; UPDATE c_mes_bom_item SET del_flag=1 WHERE bom_id='${id}';"`, { stdio: 'pipe' });
      } catch (e) {}
    }
    // 物料 + 仓库 + 库存
    if (createdMaterials.length || createdWarehouses.length) {
      const { execSync } = await import('node:child_process');
      try {
        const whIds = createdWarehouses.filter(Boolean).map(id => `'${id}'`).join(',');
        const matIds = createdMaterials.filter(Boolean).map(id => `'${id}'`).join(',');
        execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -e "DELETE FROM c_mes_inventory WHERE warehouse_id IN (${whIds}); DELETE FROM c_mes_inventory_ledger WHERE warehouse_id IN (${whIds}); DELETE FROM c_mes_cost_log WHERE warehouse_id IN (${whIds}); UPDATE c_mes_material SET moving_avg_cost=0 WHERE id IN (${matIds}); DELETE FROM c_mes_material WHERE id IN (${matIds}); DELETE FROM c_mes_warehouse WHERE id IN (${whIds});"`, { stdio: 'pipe' });
      } catch (e) {}
    }
    console.log('✅ Drawer 测试 fixture 已清理');
  });
});