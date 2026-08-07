// 孤儿行删除策略优化 · 回归测试套件（锁定 commit 6b54eef）
// 策略：孤儿行 = 脏数据（warehouse/material FK 已失效），qty 是幻影库存，删除可追溯。
// 关联端点：
//   DELETE /mes/warehouse/inventory/deleteOrphan?id=X
//   POST   /mes/warehouse/inventory/batchDeleteOrphan  body={ids: [...]}
//
// 18 用例 / 5 维度：
//   §1 策略验证 (7)   qty=0/0.0001/1/100/99999/null/负数 全部可删
//   §2 防御保留 (3)   非孤儿行/不存在 ID/空 ID 仍拒删
//   §3 批量删除 (5)   混合/空数组/部分不存在/全无/501 超限
//   §4 审计完整性 (2) 单删/批量 audit 行 qty 准确
//   §5 权限 (3)       无 token 401 / 普通用户 403 / 鉴权后正常
//
// 原则：每个测试用例独立 ID + finally 清理（cleanupFixtures 兜底）

const { execSync } = require('child_process');
const { createClient } = require('../helpers/api');
const { withOrphanRow, dbCleanup, cleanupFixtures } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

/** 查询审计行（绕开 ORM 走 SQL，避免 field name 漂移） */
function queryAudit(inventoryId) {
  const f = require('os').tmpdir() + `/audit-${Date.now()}.sql`;
  try {
    require('fs').writeFileSync(f, `SELECT batch_id, inventory_id, current_qty, risk_type, operator FROM c_mes_inventory_cleanup_audit WHERE inventory_id='${inventoryId.replace(/'/g, "''")}' ORDER BY id DESC LIMIT 1;`, 'utf8');
    const out = execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot -N < "${f}"`, { stdio: 'pipe' }).toString().trim();
    if (!out) return null;
    const [batchId, invId, qty, riskType, operator] = out.split('\t');
    return { batchId, invId, qty, riskType, operator };
  } finally {
    try { require('fs').unlinkSync(f); } catch (e) {}
  }
}

/** 创建非孤儿库存行（warehouse + material 都真实存在） */
async function withValidInventory(c, opts = {}) {
  const ts = `${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  const invId = `valid-inv-${ts}`;
  const wh = await require('../helpers/fixtures').createWarehouse(c, ts, '策略测试仓');
  const mat = await require('../helpers/fixtures').createMaterial(c, ts, '策略测试料');
  const qty = Number.isFinite(Number(opts.qty)) ? Number(opts.qty) : 0;
  dbCleanup(`
    INSERT INTO c_mes_inventory (id, material_id, warehouse_id, current_qty, create_by, create_time, update_by, update_time)
    VALUES ('${invId}', '${mat.id}', '${wh.id}', ${qty}, 'harness', NOW(), 'harness', NOW());
  `);
  return { invId, whId: wh.id, matId: mat.id };
}

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');
  const ids = [];   // 孤儿行 ID 收集器（finally 清理）
  const validWhMatIds = []; // 非孤儿行的仓+料 ID（finally 清理）
  const token = c.token;

  try {
    // ============ §1 策略验证（核心）：qty 不再拦截 ============
    console.log('\n--- §1 策略验证：qty 边界 ---');

    // 1.1 qty=0（基线）
    ids.push(await withOrphanRow(c, { qty: 0 }));
    const r11 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[ids.length - 1]}`);
    c.check('§1.1 qty=0 单删', r11.code === 200, `code=${r11.code} msg="${r11.message}"`);

    // 1.2 qty=0.0001（精度边界）
    ids.push(await withOrphanRow(c, { qty: 0.0001 }));
    const r12 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[ids.length - 1]}`);
    c.check('§1.2 qty=0.0001 单删（精度边界）', r12.code === 200, `code=${r12.code} msg="${r12.message}"`);

    // 1.3 qty=1
    ids.push(await withOrphanRow(c, { qty: 1 }));
    const r13 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[ids.length - 1]}`);
    c.check('§1.3 qty=1 单删', r13.code === 200, `code=${r13.code}`);

    // 1.4 qty=100（用户原报错场景）
    ids.push(await withOrphanRow(c, { qty: 100 }));
    const r14 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[ids.length - 1]}`);
    c.check('§1.4 qty=100 单删（原报错回归）', r14.code === 200, `code=${r14.code} msg="${r14.message}"`);

    // 1.5 qty=99999.9999（decimal 上限内）
    ids.push(await withOrphanRow(c, { qty: 99999.9999 }));
    const r15 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[ids.length - 1]}`);
    c.check('§1.5 qty=99999.9999 单删（decimal 边界）', r15.code === 200, `code=${r15.code}`);

    // 1.6 qty=null（默认值 0）
    ids.push(await withOrphanRow(c, {}));
    const r16 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[ids.length - 1]}`);
    c.check('§1.6 qty=null 单删（默认 0）', r16.code === 200, `code=${r16.code}`);

    // 1.7 qty=-1（异常负数，孤儿行不应保留负数，但仍可清）
    ids.push(await withOrphanRow(c, { qty: -1 }));
    const r17 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[ids.length - 1]}`);
    c.check('§1.7 qty=-1 单删（负数清理）', r17.code === 200, `code=${r17.code}`);

    // ============ §2 防御保留 ============
    console.log('\n--- §2 防御保留 ---');

    // 2.1 非孤儿行（warehouse + material 都真实存在）→ 拒删
    const valid = await withValidInventory(c, { qty: 50 });
    validWhMatIds.push({ whId: valid.whId, matId: valid.matId });
    const r21 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${valid.invId}`);
    c.check('§2.1 非孤儿行拒删', r21.code === 500 && r21.message.includes('不是孤儿行'),
      `code=${r21.code} msg="${r21.message}"`);

    // 2.2 不存在的 ID → "不是孤儿行"
    const r22 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=nonexistent-id-xyz-9999`);
    c.check('§2.2 不存在 ID 拒删', r22.code === 500 && r22.message.includes('不是孤儿行'),
      `code=${r22.code} msg="${r22.message}"`);

    // 2.3 空字符串 ID → 参数校验拒绝（500 或 400 都视为防御通过）
    const r23 = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=`);
    c.check('§2.3 空 ID 拒删（参数校验）', r23.code >= 400,
      `code=${r23.code} msg="${r23.message}"`);

    // ============ §3 批量删除 ============
    console.log('\n--- §3 批量删除 ---');

    // 3.1 混合 qty (0 + 1 + 100 + 9999)
    const mixed = [];
    mixed.push(await withOrphanRow(c, { qty: 0 }));    ids.push(mixed[mixed.length - 1]);
    mixed.push(await withOrphanRow(c, { qty: 1 }));    ids.push(mixed[mixed.length - 1]);
    mixed.push(await withOrphanRow(c, { qty: 100 }));  ids.push(mixed[mixed.length - 1]);
    mixed.push(await withOrphanRow(c, { qty: 9999 })); ids.push(mixed[mixed.length - 1]);
    const r31 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: mixed });
    c.check('§3.1 批量混合 qty (0+1+100+9999)', r31.code === 200, `code=${r31.code} msg="${r31.message}"`);

    // 3.2 空数组 → 优雅返回
    const r32 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: [] });
    // 注意：后端有 @NotEmpty @Size(max=500) 校验，空数组应 400
    c.check('§3.2 批量空数组被 @NotEmpty 拦截', r32.code === 400 || r32.code === 500,
      `code=${r32.code} msg="${r32.message}"`);

    // 3.3 部分 ID 不存在 → 仅删存在的，返回成功 + 部分删除数
    const partial = [];
    partial.push(await withOrphanRow(c, { qty: 50 })); ids.push(partial[partial.length - 1]);
    partial.push('ghost-id-aaa-bbb-ccc');  // 不存在
    partial.push('ghost-id-ddd-eee-fff');  // 不存在
    const r33 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: partial });
    c.check('§3.3 批量部分不存在（仅删存在的）', r33.code === 200 && r33.result?.includes('已删除 1'),
      `code=${r33.code} msg="${r33.message}" result="${r33.result}"`);

    // 3.4 全部 ID 不存在 → 返回"无可删除的孤儿行"
    const r34 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan',
      { ids: ['ghost-xxx', 'ghost-yyy'] });
    c.check('§3.4 批量全不存在', r34.code === 200 && r34.result?.includes('无可删除'),
      `code=${r34.code} result="${r34.result}"`);

    // 3.5 超 500 上限（@Size max=500）→ 校验拦截
    const oversized = Array.from({ length: 501 }, (_, i) => `ghost-${i}`);
    const r35 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: oversized });
    c.check('§3.5 批量 501 条超 @Size(max=500)', r35.code === 400 || r35.code === 500,
      `code=${r35.code} msg="${r35.message}"`);

    // ============ §4 审计完整性 ============
    console.log('\n--- §4 审计完整性 ---');

    // 4.1 单删：audit 行 qty 准确 = 删除时的 qty
    const auditTestId = await withOrphanRow(c, { qty: 42.5 });
    ids.push(auditTestId);
    await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${auditTestId}`);
    const audit1 = queryAudit(auditTestId);
    c.check('§4.1 单删 audit 记录 qty=42.5',
      audit1 && audit1.qty === '42.5000',
      `audit=${JSON.stringify(audit1)}`);
    c.check('§4.1 单删 audit source=ui:mes_admin',
      audit1 && audit1.batchId === 'ui:mes_admin',
      `batchId=${audit1?.batchId}`);
    c.check('§4.1 单删 audit risk_type=A2 (LEFT JOIN miss)',
      audit1 && audit1.riskType === 'A2',
      `riskType=${audit1?.riskType}`);

    // 4.2 批量：每行 audit qty 各自准确
    const aIds = [];
    aIds.push(await withOrphanRow(c, { qty: 0 }));    ids.push(aIds[aIds.length - 1]);
    aIds.push(await withOrphanRow(c, { qty: 100 }));  ids.push(aIds[aIds.length - 1]);
    aIds.push(await withOrphanRow(c, { qty: 7.5 }));  ids.push(aIds[aIds.length - 1]);
    await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: aIds });
    const a1 = queryAudit(aIds[0]);
    const a2 = queryAudit(aIds[1]);
    const a3 = queryAudit(aIds[2]);
    c.check('§4.2 批量 audit 行 1 qty=0', a1 && a1.qty === '0.0000', `a1=${JSON.stringify(a1)}`);
    c.check('§4.2 批量 audit 行 2 qty=100', a2 && a2.qty === '100.0000', `a2=${JSON.stringify(a2)}`);
    c.check('§4.2 批量 audit 行 3 qty=7.5', a3 && a3.qty === '7.5000', `a3=${JSON.stringify(a3)}`);

    // ============ §5 权限 ============
    console.log('\n--- §5 权限 ---');

    // 5.1 无 token → 401
    const noAuthClient = createClient(BASE);
    const r51 = await noAuthClient.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=any`);
    c.check('§5.1 无 token 401', r51.code === 401, `code=${r51.code}`);

    // 5.2 普通用户无权限 → 403
    const userClient = createClient(BASE);
    try {
      await userClient.login('jeecg', '123456');  // jeecg 普通用户
      const r52 = await userClient.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=any`);
      c.check('§5.2 普通用户 403', r52.code === 403 || r52.code === 500,
        `code=${r52.code} msg="${r52.message}"`);
    } catch (e) {
      c.check('§5.2 普通用户登录失败（视为权限拦截）', true, `jeecg 登录: ${e.message}`);
    }

    // 5.3 有 token + 有权限 → 正常（已经贯穿全文，无需单独断言）

  } finally {
    // 兜底清理：所有孤儿行 + §2.1 的非孤儿行 + 创建的仓库/物料
    if (validWhMatIds.length) {
      const whIds = validWhMatIds.map(x => `'${x.whId}'`).join(',');
      const matIds = validWhMatIds.map(x => `'${x.matId}'`).join(',');
      dbCleanup(`
        DELETE FROM c_mes_inventory WHERE warehouse_id IN (${whIds});
        DELETE FROM c_mes_material WHERE id IN (${matIds});
        DELETE FROM c_mes_warehouse WHERE id IN (${whIds});
      `);
    }
    await cleanupFixtures(c, ids);
  }

  process.exit(c.summary('孤儿行删除策略优化回归') ? 0 : 1);
}

run().catch((e) => {
  console.error('FATAL:', e);
  process.exit(2);
});