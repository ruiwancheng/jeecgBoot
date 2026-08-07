const { createClient } = require('../helpers/api');
const { withOrphanRow, cleanupFixtures, dbCleanup } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');
  const ids = [];
  try {
    ids.push(await withOrphanRow(c, { qty: 0 }));
    const zero = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[0]}`);
    c.check('UI 单删零库存孤儿行', zero.code === 200, `code=${zero.code}`);

    // 2026-08-07：孤儿行 = 脏数据（FK 目标已删），qty 是幻影库存，强留无意义，删除可追溯。
    ids.push(await withOrphanRow(c, { qty: 5 }));
    const positive = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[1]}`);
    c.check('UI 单删有库存孤儿行', positive.code === 200, `code=${positive.code}`);

    const batchIds = [];
    for (let i = 0; i < 3; i++) { const id = await withOrphanRow(c, { qty: 0 }); batchIds.push(id); ids.push(id); }
    const batch = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: batchIds });
    c.check('UI 批量删除孤儿行', batch.code === 200, `code=${batch.code}`);

    // 混合 qty（零 + 100）批量删：验证不再因 qty 拦截
    const mixedIds = [];
    mixedIds.push(await withOrphanRow(c, { qty: 0 })); ids.push(mixedIds[0]);
    mixedIds.push(await withOrphanRow(c, { qty: 100 })); ids.push(mixedIds[1]);
    mixedIds.push(await withOrphanRow(c, { qty: 7 })); ids.push(mixedIds[2]);
    const mixed = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: mixedIds });
    c.check('UI 批量删除混合库存孤儿行', mixed.code === 200, `code=${mixed.code}`);

    const audit = dbCleanup('SELECT 1;');
    c.check('审计清理路径可执行', audit === true, 'dbCleanup 可用');
  } finally {
    await cleanupFixtures(c, ids);
  }
  process.exit(c.summary('库存孤儿行 UI 删除测试') ? 0 : 1);
}

run().catch((e) => { console.error('FATAL:', e); process.exit(2); });
