import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi, API_BASE } from './helpers/auth';
import { dbCleanup } from '../../tests/helpers/fixtures';

let accessToken: string;

/** 建测试料+期初库存（使用现有仓库，避免 add 仓库后 dropdown 找不到新仓库），返回 {api, whId, matId, matCode, inDocId} */
async function setupFixture(suffix: string) {
  const h = { 'Content-Type': 'application/json', 'X-Access-Token': accessToken };
  const api = async (method: string, path: string, body?: any) => {
    const res = await fetch(`${API_BASE}${path}`, { method, headers: h, body: body ? JSON.stringify(body) : undefined });
    return res.json();
  };
  // 使用 dev DB 现有仓库（修复：新建仓库在 UI dropdown 里可能因缓存/权限不可见）
  const wh = (await api('GET', `/mes/basic/warehouse/list?pageNo=1&pageSize=5`)).result.records[0];
  if (!wh) throw new Error('dev DB 无可用仓库，请先 seed c_mes_warehouse');
  await api('POST', '/mes/basic/material/add', { code: `MAT-STE-${suffix}`, name: '盘点E2E料', type: '1' });
  const mat = (await api('GET', `/mes/basic/material/list?pageNo=1&pageSize=5&code=MAT-STE-${suffix}`)).result.records[0];
  const inCode = `STEIN_${suffix}`;
  await api('POST', '/mes/stock/otherIn/add', { code: inCode, inType: '2', warehouseId: wh.id, reason: '期初', stockDate: '2026-07-29', items: [{ materialId: mat.id, qty: 20, unitCost: 8 }] });
  const inDoc = (await api('GET', `/mes/stock/otherIn/list?pageNo=1&pageSize=5&code=${inCode}`)).result.records[0];
  await api('PUT', `/mes/stock/otherIn/audit?id=${inDoc.id}`);
  return { api, whId: wh.id, whCode: wh.code, matId: mat.id, matCode: mat.code, inDocId: inDoc.id };
}

async function cleanup(fx: any, pdCode: string) {
  const { api, matId, inDocId } = fx;
  // 注意：whId 是 dev DB 现有仓库，不能删
  const pd = (await api('GET', `/mes/stock/stocktake/list?pageNo=1&pageSize=5&code=${pdCode}`)).result.records[0];
  if (pd) await api('DELETE', `/mes/stock/stocktake/delete?id=${pd.id}`);
  // 调整单（盘盈/盘亏）清理
  for (const [path, code] of [['/mes/stock/otherOut/list', null], ['/mes/stock/otherIn/list', null]] as const) {
    const docs = (await api('GET', `${path}?pageNo=1&pageSize=20`)).result.records.filter((d: any) => (d.reason || '').includes(pdCode));
    for (const d of docs) {
      await api('PUT', `${path.replace('/list', '')}/unaudit?id=${d.id}`);
      await api('DELETE', `${path.replace('/list', '')}/delete?id=${d.id}`);
    }
  }
  await api('PUT', `/mes/stock/otherIn/unaudit?id=${inDocId}`);
  await api('DELETE', `/mes/stock/otherIn/delete?id=${inDocId}`);
  await api('DELETE', `/mes/basic/material/delete?id=${matId}`);
  // 不删 whId（dev DB 共享资源）
}

test.describe('盘点单（黄金模板重构版）', () => {
  test.beforeEach(async ({ page }) => { accessToken = await loginViaApi(page, '/project/mes/stock/stocktake'); });

  test('全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4）', async ({ page }) => {
    const suffix = String(Date.now()).slice(-8);
    const fx = await setupFixture(suffix);
    const pdCode = `PDE2E${suffix}`;

    // 1. 新增全盘盘点单
    await page.locator('button:has-text("新增盘点单")').click();
    await page.waitForTimeout(1500);
    const drawer = page.locator('.ant-drawer:has-text("新增盘点单")').first();
    await drawer.locator('input[placeholder="PD-YYYYMMDD-0001"]').fill(pdCode);
    await drawer.locator('.ant-select').filter({ hasText: '请选择仓库' }).first().locator('.ant-select-selector').click();
    await page.waitForSelector('.ant-select-dropdown:visible .ant-select-item-option', { timeout: 5000 });
    await page.waitForTimeout(400);
    await page.locator('.ant-select-dropdown:visible .ant-select-item-option', { hasText: fx.whCode }).first().click({ force: true });
    await drawer.getByRole('button', { name: '确 认' }).click();
    await page.waitForTimeout(2000);

    // 2. 列表应有该单（创建断言：status=草稿）
    const listRes = await fx.api('GET', `/mes/stock/stocktake/list?pageNo=1&pageSize=5&code=${pdCode}`);
    const pd = listRes.result.records[0];
    expect(pd).toBeTruthy();
    expect(pd.status).toBe('1');
    console.log('✅ 创建断言: 草稿单已生成');

    // 3. 快照明细断言（数据传递锚点）
    const detail = await fx.api('GET', `/mes/stock/stocktake/queryById?id=${pd.id}`);
    const item = detail.result.items[0];
    expect(Number(item.bookQty)).toBe(20);
    expect(Number(item.unitCost)).toBe(8);
    expect(detail.result.snapshotTime).toBeTruthy();
    console.log('✅ 快照断言: book=20 cost=8 snapshotTime 记录');

    // 4. 展开行：物料列显示编码（显示值锚点#4，DOM 级限定防全页误判）
    await page.locator('.ant-table-row-expand-icon').first().click();
    await page.waitForTimeout(1500);
    const subTableCell = page.locator('.ant-table-expanded-row .ant-table-tbody td').first();
    await expect(subTableCell).toContainText(fx.matCode);
    console.log(`✅ 显示值断言: 子表物料列含编码 ${fx.matCode}（DOM级）`);

    // 5. 录入实盘（抽屉物料列也是编码）
    await page.locator('a:has-text("录入实盘"), button:has-text("录入实盘")').first().click();
    await page.waitForTimeout(2500);
    const drawerCell = await page.locator('.ant-drawer .ant-table-tbody .ant-table-row').nth(0).locator('td').nth(0).innerText();
    expect(drawerCell).toContain(fx.matCode);
    console.log('✅ 显示值断言: 抽屉物料列=' + drawerCell.slice(0, 30));

    const actualInput = page.locator('.ant-drawer .ant-table-tbody .ant-table-row').nth(0).locator('input').nth(0);
    await actualInput.fill('17');
    await actualInput.press('Enter');
    await page.waitForTimeout(400);
    await page.locator('.ant-drawer').getByRole('button', { name: '确 认' }).click();
    await page.waitForTimeout(2000);

    // 6. 审核（行内操作按钮，popConfirm 确认）
    await page.locator('.ant-table-tbody .ant-table-row').nth(0).locator('button:has-text("审核")').first().click();
    await page.waitForTimeout(600);
    const confirmBtn = page.locator('.ant-popover button.ant-btn-primary, .ant-popconfirm button.ant-btn-primary').first();
    await confirmBtn.click();
    await page.waitForTimeout(2500);

    // 7. 状态流转断言 + 数据传递断言
    const after = await fx.api('GET', `/mes/stock/stocktake/queryById?id=${pd.id}`);
    expect(after.result.status).toBe('2');
    const inv = await fx.api('GET', `/mes/warehouse/inventory/list?pageNo=1&pageSize=5&warehouseId=${fx.whId}`);
    expect(Number(inv.result.records[0].current_qty)).toBe(17);
    console.log('✅ 审核断言: 状态=已审核, 库存 20→17（盘亏3）');

    // 8. 守卫断言：已审核单无操作按钮
    await page.reload();
    await page.waitForTimeout(2000);
    const actions = await page.locator('.ant-table-tbody .ant-table-row').nth(0).locator('a:has-text("删除")').count();
    expect(actions).toBe(0);
    console.log('✅ 守卫断言: 已审核单无删除入口');

    // 9. 清理：先 DB 清（库存/台账/已审核盘点单），再 API 清（仓/料/单据）——避免仓被库存行引用删不掉
    dbCleanup(`
      DELETE si FROM c_mes_stocktake_item si JOIN c_mes_stocktake s ON si.take_id=s.id WHERE s.code='${pdCode}';
      DELETE FROM c_mes_stocktake WHERE code='${pdCode}';
      DELETE FROM c_mes_inventory WHERE warehouse_id='${fx.whId}';
      DELETE FROM c_mes_inventory_ledger WHERE warehouse_id='${fx.whId}';
      DELETE FROM c_mes_cost_log WHERE warehouse_id='${fx.whId}';
    `);
    await cleanup(fx, pdCode);
    console.log('✅ 清理完成（DB+API 双段）');
  });
});
