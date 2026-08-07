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

    ids.push(await withOrphanRow(c, { qty: 5 }));
    const positive = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[1]}`);
    c.check('UI 拒绝有库存孤儿行', positive.code === 400 || positive.code === 500, `code=${positive.code}`);

    const batchIds = [];
    for (let i = 0; i < 3; i++) { const id = await withOrphanRow(c, { qty: 0 }); batchIds.push(id); ids.push(id); }
    const batch = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: batchIds });
    c.check('UI 批量删除孤儿行', batch.code === 200, `code=${batch.code}`);

    const audit = dbCleanup('SELECT 1;');
    c.check('审计清理路径可执行', audit === true, 'dbCleanup 可用');
  } finally {
    await cleanupFixtures(c, ids);
  }
  process.exit(c.summary('库存孤儿行 UI 删除测试') ? 0 : 1);
}

run().catch((e) => { console.error('FATAL:', e); process.exit(2); });
