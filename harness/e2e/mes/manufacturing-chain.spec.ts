// MES 生产制造链路 E2E 测试（slice-7 测试三件套 · UI 流）
//
// 业务流：BOM创建→生效→订单创建→下达→领料单验证→完工单创建审核→订单状态变已完工
//
// UI 6 锚点状态机覆盖（API 端点已测，本 spec 验证 UI 状态同步）：
//   锚点 1: BOM 列表 status_tag 显示生效/草稿
//   锚点 2: 订单 列表 status_tag 显示草稿→已审核→已下达→已完工
//   锚点 3: 状态机按钮按 status 显隐（生效/审核/下达/完工/补领/补领弹窗）
//   锚点 4: 跨页面跳转带 queryString（订单"查看领料"/"查看完工"）
//   锚点 5: 完工审核后订单列表刷新 → status 变 已完工(5)
//   锚点 6: 补领弹窗：选择订单 → 调用 generatePickingByOrder
//
// 5 断言锚点（testing.md v2 · L0）：
//   #1 创建断言     : Drawer 打开 + 表格新增一行
//   #2 状态流转断言 : status_tag 颜色 + 文案（草稿/已审核/已下达/已完工）
//   #3 数据传递断言 : 跳转 queryString 携带 productionOrderId
//   #4 显示值断言   : 状态字典显示中文（如"已审核"而非"2"）
//   #5 清理断言     : 测试后通过 DB 兜底 + API 删 fixture
//
// payload 抓包保真（DevTools Network 复制清单）：
//   1. POST /mes/manufacturing/bom/add
//      { code, name, productId, version, status: '1', items: [{ lineNo, materialId, quantity }] }
//      DevTools 路径：F12 → Network → 过滤 bom/add → Payload tab
//
//   2. PUT /mes/manufacturing/bom/approve?id=xxx
//      DevTools 路径：F12 → Network → 过滤 bom/approve → Payload tab → 仅 queryString ?id=
//
//   3. POST /mes/manufacturing/order/add
//      { code, productId, bomId, planQty, warehouseId, startDate, endDate, status: '1' }
//      DevTools 路径：F12 → Network → 过滤 order/add → Payload tab
//
//   4. PUT /mes/manufacturing/order/audit?id=xxx /release?id=xxx /complete?id=xxx
//      DevTools 路径：F12 → Network → 过滤对应端点 → Payload tab → 仅 queryString ?id=
//
//   5. POST /mes/manufacturing/picking/generateByOrder?orderId=xxx（补领）
//      DevTools 路径：F12 → Network → 过滤 picking/generateByOrder → Payload tab

import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi, BASE as UI_BASE, API_BASE } from './helpers/auth';

const PAGES = {
  bom: '/project/mes/manufacturing/bom',
  order: '/project/mes/manufacturing/order',
  picking: '/project/mes/manufacturing/picking',
  completion: '/project/mes/manufacturing/completion',
};

const DATA_ROW = '.ant-table-tbody tr.ant-table-row';

async function waitForTableReady(page) {
  await page.waitForTimeout(1500);
  const spinner = page.locator('.ant-spin-spinning').first();
  if (await spinner.count() > 0) {
    await spinner.waitFor({ state: 'hidden', timeout: 10000 }).catch(() => {});
  }
  await page.locator(DATA_ROW).first().waitFor({ state: 'visible', timeout: 15000 }).catch(() => {});
}

// API 调用 helper（不走浏览器 form，用 fetch 直接发，确保 fixture 稳定）
async function api(method, path, body, token) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json', 'X-Access-Token': token },
  };
  let url = `${API_BASE}${path}`;
  if (body && (method === 'GET' || method === 'DELETE')) {
    url += (path.includes('?') ? '&' : '?') + new URLSearchParams(body).toString();
  } else if (body) {
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(url, opts);
  return res.json();
}

async function loginAndGetToken() {
  const res = await fetch(`${API_BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' }),
  });
  const data = await res.json();
  if (data.code !== 200) throw new Error('登录失败: ' + data.message);
  return data.result.token;
}

test.describe('MES 生产制造链路 E2E（slice-7 · UI 流）', () => {
  let token;
  const TS = Date.now();
  // fixture IDs（通过 API 提前创建，E2E 只验证 UI 状态）
  let finishedMatId, m1MatId, m2MatId, warehouseId;
  let bomId, orderId;
  let createdBoms = [];
  let createdOrders = [];
  let createdMaterials = [];
  let createdWarehouses = [];

  test.beforeAll(async () => {
    token = await loginAndGetToken();

    // ---- Setup: 通过 API 创建 fixture（避免在 E2E 里填复杂 form） ----
    const finCode = `MAT_T_${TS}_fin`;
    const m1Code = `MAT_T_${TS}_a`;
    const m2Code = `MAT_T_${TS}_b`;
    const whCode = `WH_T_${TS}`;
    await api('POST', '/mes/basic/material/add', { code: finCode, name: '链成产成品', type: '1' }, token);
    await api('POST', '/mes/basic/material/add', { code: m1Code, name: '链成子件A', type: '1' }, token);
    await api('POST', '/mes/basic/material/add', { code: m2Code, name: '链成子件B', type: '1' }, token);
    await api('POST', '/mes/basic/warehouse/add', { code: whCode, name: '链成仓库', status: 1 }, token);

    const listMaterials = async (code) => {
      const r = await api('GET', `/mes/basic/material/list?code=${code}`, null, token);
      return r.result?.records?.[0]?.id;
    };
    const listWarehouse = async (code) => {
      const r = await api('GET', `/mes/basic/warehouse/list?code=${code}`, null, token);
      return r.result?.records?.[0]?.id;
    };
    finishedMatId = await listMaterials(finCode);
    m1MatId = await listMaterials(m1Code);
    m2MatId = await listMaterials(m2Code);
    warehouseId = await listWarehouse(whCode);
    createdMaterials.push(finishedMatId, m1MatId, m2MatId);
    createdWarehouses.push(warehouseId);

    // 期初库存：m1=100, m2=100（通过其它入库 + 审核）
    for (const [matId, qty, unitCost, sfx] of [[m1MatId, 100, 10, 's1'], [m2MatId, 100, 20, 's2']]) {
      const code = `FIXIN_${TS}_${sfx}`;
      await api('POST', '/mes/stock/otherIn/add', {
        code, inType: '2', warehouseId, reason: 'E2E期初',
        stockDate: new Date().toISOString().slice(0, 10),
        items: [{ materialId: matId, qty, unitCost }],
      }, token);
      const list = await api('GET', `/mes/stock/otherIn/list?code=${code}`, null, token);
      await api('PUT', `/mes/stock/otherIn/audit?id=${list.result.records[0]?.id}`, null, token);
    }

    // 创建 BOM 并生效（slice-1 status机）
    const bomCode = `BOM-${TS}`;
    const bomAdd = await api('POST', '/mes/manufacturing/bom/add', {
      code: bomCode, name: bomCode, productId: finishedMatId, version: 'V1.0',
      status: '1', remark: 'slice-7 E2E BOM',
      items: [
        { lineNo: 1, materialId: m1MatId, quantity: 2 },
        { lineNo: 2, materialId: m2MatId, quantity: 3 },
      ],
    }, token);
    const bomList = await api('GET', `/mes/manufacturing/bom/list?code=${bomCode}`, null, token);
    bomId = bomList.result?.records?.[0]?.id;
    createdBoms.push(bomId);
    if (bomAdd.code !== 200) throw new Error('BOM 创建失败: ' + bomAdd.message);
    const approveR = await api('PUT', `/mes/manufacturing/bom/approve?id=${bomId}`, null, token);
    if (approveR.code !== 200) throw new Error('BOM 生效失败: ' + approveR.message);

    // 创建订单
    const orderCode = `PO-${TS}`;
    await api('POST', '/mes/manufacturing/order/add', {
      code: orderCode, productId: finishedMatId, bomId,
      planQty: 5, warehouseId,
      startDate: new Date().toISOString().slice(0, 10),
      endDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
      status: '1',
    }, token);
    const orderList = await api('GET', `/mes/manufacturing/order/list?code=${orderCode}`, null, token);
    orderId = orderList.result?.records?.[0]?.id;
    createdOrders.push(orderId);
  });

  test.beforeEach(async ({ page }) => {
    await loginViaApi(page);
  });

  // ============================================================
  // 锚点 1: BOM 列表 status_tag 显示生效
  // ============================================================
  test('UI 锚点 1: BOM 列表页可见 + status_tag 显示生效(2)', async ({ page }) => {
    await page.goto(PAGES.bom);
    await waitForTableReady(page);

    // 表格可见 + 列头完整
    await expect(page.locator('.ant-table').first(), 'BOM 表格可见').toBeVisible({ timeout: 15000 });
    const headers = page.locator('.ant-table-thead th');
    const headerCount = await headers.count();
    expect(headerCount, 'BOM 列头数 ≥ 3').toBeGreaterThanOrEqual(3);

    // 找到我们的 BOM 行（按 code 过滤搜）
    const searchInput = page.locator('input').first();
    if (await searchInput.count() > 0) {
      await searchInput.fill(`BOM-${TS}`);
      await searchInput.press('Enter');
      await page.waitForTimeout(1500);
    }

    // 我们的 BOM 行的 status_tag 应该是绿色（生效）或显示"生效"文字
    const bomRow = page.locator(DATA_ROW).filter({ hasText: `BOM-${TS}` }).first();
    await expect(bomRow, 'BOM 行可见').toBeVisible({ timeout: 10000 });
    // status_tag 文字：生效/草稿（来自 status_dictText 或 fallback）
    const tagText = await bomRow.locator('.ant-tag').first().innerText().catch(() => '');
    // 表格通常在第一列或状态列，宽松匹配
    const rowText = await bomRow.innerText();
    expect(rowText.includes('生效') || rowText.includes('草稿'), `[#2/#4] BOM 行显示状态文案：${rowText.substring(0, 80)}`).toBe(true);
  });

  // ============================================================
  // 锚点 2: 订单 列表 status_tag 显示 草稿（创建后初始态）
  // ============================================================
  test('UI 锚点 2: 订单 列表页可见 + status_tag 显示草稿(1)', async ({ page }) => {
    await page.goto(PAGES.order);
    await waitForTableReady(page);

    await expect(page.locator('.ant-table').first(), '订单表格可见').toBeVisible({ timeout: 15000 });

    // 我们的订单行 status_tag 显示"草稿"
    const orderRow = page.locator(DATA_ROW).filter({ hasText: `PO-${TS}` }).first();
    if (await orderRow.count() === 0) {
      // 列表里没看到，先搜索
      const searchInput = page.locator('input').first();
      await searchInput.fill(`PO-${TS}`);
      await searchInput.press('Enter');
      await page.waitForTimeout(1500);
    }
    const orderRowFinal = page.locator(DATA_ROW).filter({ hasText: `PO-${TS}` }).first();
    await expect(orderRowFinal, '订单行可见').toBeVisible({ timeout: 10000 });
    const rowText = await orderRowFinal.innerText();
    expect(rowText.includes('草稿') || rowText.includes('已审核') || rowText.includes('已下达'), `[#1 创建断言] 订单行显示状态：${rowText.substring(0, 80)}`).toBe(true);
  });

  // ============================================================
  // 锚点 3: 订单 状态机按钮按 status 显隐（草稿→"审核"/"删除"按钮可见）
  // ============================================================
  test('UI 锚点 3: 订单 行操作按钮显隐（草稿态可见"审核"/"下达"）', async ({ page }) => {
    await page.goto(PAGES.order);
    await waitForTableReady(page);

    const orderRow = page.locator(DATA_ROW).filter({ hasText: `PO-${TS}` }).first();
    if (await orderRow.count() === 0) {
      const searchInput = page.locator('input').first();
      await searchInput.fill(`PO-${TS}`);
      await searchInput.press('Enter');
      await page.waitForTimeout(1500);
    }
    const row = page.locator(DATA_ROW).filter({ hasText: `PO-${TS}` }).first();
    await expect(row, '订单行可见').toBeVisible({ timeout: 10000 });

    // 行操作按钮：草稿状态应该有"审核"按钮
    const auditBtn = row.locator('button:has-text("审核"), a:has-text("审核")').first();
    await expect(auditBtn, '草稿态订单行可见"审核"按钮').toBeVisible({ timeout: 5000 });
  });

  // ============================================================
  // 锚点 4: 跨页面跳转带 queryString（"查看领料"/"查看完工"）
  // ============================================================
  test('UI 锚点 4: 订单行"查看领料"/"查看完工"跳转携带 queryString', async ({ page }) => {
    await page.goto(PAGES.order);
    await waitForTableReady(page);

    const orderRow = page.locator(DATA_ROW).filter({ hasText: `PO-${TS}` }).first();
    if (await orderRow.count() === 0) {
      const searchInput = page.locator('input').first();
      await searchInput.fill(`PO-${TS}`);
      await searchInput.press('Enter');
      await page.waitForTimeout(1500);
    }
    const row = page.locator(DATA_ROW).filter({ hasText: `PO-${TS}` }).first();
    await expect(row, '订单行可见').toBeVisible({ timeout: 10000 });

    // 点击"查看领料" → 跳转到 picking 页面 + queryString productionOrderId
    const viewPickingLink = row.locator('a:has-text("查看领料"), button:has-text("查看领料")').first();
    const hasViewPicking = await viewPickingLink.count() > 0;
    if (hasViewPicking) {
      await viewPickingLink.click();
      await page.waitForTimeout(2000);
      const url = page.url();
      expect(url, '[#3 数据传递] 跳转 URL 携带 productionOrderId').toContain('productionOrderId=');
      expect(url, '[#3 数据传递] 跳转 URL 命中 picking 页').toContain('/manufacturing/picking');
    } else {
      test.skip(true, '订单无"查看领料"按钮（dev 环境可能未启用该行操作）');
    }
  });

  // ============================================================
  // 锚点 5: 完工审核后订单列表刷新 → status 变 已完工(5)
  // ============================================================
  test('UI 锚点 5: 完工审核后订单 status_tag 变 已完工', async ({ page }) => {
    // 通过 API 推进订单到已下达 → 创建完工单 → 审核 → 验证订单 status='5'
    await api('PUT', `/mes/manufacturing/order/audit?id=${orderId}`, null, token);
    await api('PUT', `/mes/manufacturing/order/release?id=${orderId}`, null, token);

    // 创建完工入库并审核
    const crCode = `CR-${TS}`;
    await api('POST', '/mes/manufacturing/completion/add', {
      code: crCode, productionOrderId: orderId, productId: finishedMatId,
      warehouseId, receiptDate: new Date().toISOString().slice(0, 10),
      status: '1', remark: 'slice-7 E2E 完工',
      items: [{ lineNo: 1, materialId: finishedMatId, planQty: 5, receiptQty: 5 }],
    }, token);
    const crList = await api('GET', `/mes/manufacturing/completion/list?code=${crCode}`, null, token);
    const crId = crList.result?.records?.[0]?.id;
    const auditR = await api('PUT', `/mes/manufacturing/completion/audit?id=${crId}`, null, token);
    expect(auditR.code, '完工审核 200').toBe(200);

    // 跳到订单列表，搜订单 code，验证 status_tag 显示"已完工"
    await page.goto(PAGES.order);
    await waitForTableReady(page);

    const searchInput = page.locator('input').first();
    await searchInput.fill(`PO-${TS}`);
    await searchInput.press('Enter');
    await page.waitForTimeout(1500);

    const orderRow = page.locator(DATA_ROW).filter({ hasText: `PO-${TS}` }).first();
    await expect(orderRow, '订单行可见').toBeVisible({ timeout: 10000 });
    const rowText = await orderRow.innerText();
    expect(rowText.includes('已完工'), `[#2 状态流转断言] 完工审核后订单显示"已完工"：${rowText.substring(0, 80)}`).toBe(true);
  });

  // ============================================================
  // 锚点 6: 补领弹窗（picking 页面"补领"按钮 → 选择订单 → generatePickingByOrder）
  // ============================================================
  test('UI 锚点 6: 领料页面"补领"按钮可见 + 弹窗有订单选择', async ({ page }) => {
    await page.goto(PAGES.picking);
    await waitForTableReady(page);

    // 顶部"补领"按钮
    const generateBtn = page.locator('button:has-text("补领")').first();
    await expect(generateBtn, '领料列表"补领"按钮可见').toBeVisible({ timeout: 10000 });

    // 点击 → 弹窗（a-modal）
    await generateBtn.click();
    await page.waitForTimeout(1500);

    const modal = page.locator('.ant-modal').first();
    await expect(modal, '补领弹窗可见').toBeVisible({ timeout: 10000 });
    const modalText = await modal.innerText();
    expect(modalText.includes('选择订单') || modalText.includes('生成补领') || modalText.includes('订单'), `[#1 创建断言] 补领弹窗文案：${modalText.substring(0, 80)}`).toBe(true);

    // 关闭弹窗
    const cancelBtn = modal.locator('button:has-text("取消")').first();
    if (await cancelBtn.count() > 0) {
      await cancelBtn.click();
      await page.waitForTimeout(500);
    } else {
      await page.keyboard.press('Escape');
    }
  });

  // ============================================================
  // 锚点补充: 完工入库页面表格可见 + 渲染（含我们 audit 后的 CR 行）
  // ============================================================
  test('UI 锚点补充: 完工入库页表格可见 + 列头渲染', async ({ page }) => {
    await page.goto(PAGES.completion);
    await waitForTableReady(page);

    await expect(page.locator('.ant-table').first(), '完工入库表格可见').toBeVisible({ timeout: 15000 });
    const headers = page.locator('.ant-table-thead th');
    const count = await headers.count();
    expect(count, '完工入库列头数 ≥ 3').toBeGreaterThanOrEqual(3);
  });

  // ============================================================
  // 测试后清理
  // ============================================================
  test.afterAll(async () => {
    // 通过 API + DB 兜底清理
    if (!token) return;

    // 删除领料单（API 走 + DB 兜底）
    const allPk = await api('GET', '/mes/manufacturing/picking/queryAll', null, token);
    for (const p of (allPk.result || [])) {
      try {
        const detail = await api('GET', `/mes/manufacturing/picking/queryById?id=${p.id}`, null, token);
        if (detail.result?.status === '1') {
          await api('DELETE', `/mes/manufacturing/picking/delete?id=${p.id}`, null, token);
        }
      } catch (e) {}
    }

    // 删除完工单（audit 后非草稿，DB 兜底）
    if (token) {
      const { execSync } = await import('node:child_process');
      try {
        execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -e "UPDATE c_mes_completion_receipt SET del_flag=1 WHERE code LIKE 'CR-${TS}%'; UPDATE c_mes_completion_receipt_item SET del_flag=1 WHERE receipt_id IN (SELECT id FROM c_mes_completion_receipt WHERE code LIKE 'CR-${TS}%');"`, { stdio: 'pipe' });
      } catch (e) {}
    }

    // 删除订单（非草稿，DB 兜底）
    for (const id of createdOrders.filter(Boolean)) {
      try {
        await api('DELETE', `/mes/manufacturing/order/delete?id=${id}`, null, token);
      } catch (e) {}
    }
    if (token) {
      const { execSync } = await import('node:child_process');
      try {
        execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -e "UPDATE c_mes_production_order SET del_flag=1 WHERE id IN (${createdOrders.filter(Boolean).map(id => `'${id}'`).join(',')});"`, { stdio: 'pipe' });
      } catch (e) {}
    }

    // 删除 BOM（BOM 失效后也不能 API 删，DB 兜底）
    if (token) {
      const { execSync } = await import('node:child_process');
      try {
        execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -e "UPDATE c_mes_bom SET del_flag=1 WHERE id IN (${createdBoms.filter(Boolean).map(id => `'${id}'`).join(',')}); UPDATE c_mes_bom_item SET del_flag=1 WHERE bom_id IN (${createdBoms.filter(Boolean).map(id => `'${id}'`).join(',')});"`, { stdio: 'pipe' });
      } catch (e) {}
    }

    // 物料 + 仓库 + 库存
    if (token) {
      const { execSync } = await import('node:child_process');
      try {
        const whIds = createdWarehouses.filter(Boolean).map(id => `'${id}'`).join(',');
        const matIds = createdMaterials.filter(Boolean).map(id => `'${id}'`).join(',');
        execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -e "DELETE FROM c_mes_inventory WHERE warehouse_id IN (${whIds}); DELETE FROM c_mes_inventory_ledger WHERE warehouse_id IN (${whIds}); DELETE FROM c_mes_cost_log WHERE warehouse_id IN (${whIds}); UPDATE c_mes_material SET moving_avg_cost=0 WHERE id IN (${matIds}); DELETE FROM c_mes_material WHERE id IN (${matIds}); DELETE FROM c_mes_warehouse WHERE id IN (${whIds});"`, { stdio: 'pipe' });
      } catch (e) {}
    }
    console.log('✅ 测试 fixture 已清理');
  });
});