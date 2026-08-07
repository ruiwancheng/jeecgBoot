const { createClient } = require('../helpers/api');
const { withOrphanRow, cleanupFixtures } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');
  const ids = [];
  try {
    for (let i = 0; i < 5; i++) ids.push(await withOrphanRow(c, { qty: 0 }));
    const count = await c.api('GET', '/mes/warehouse/inventory/orphanCount');
    c.check('orphanCount 可用', count.code === 200 && Number(count.result) >= 5, `code=${count.code} result=${count.result}`);
    const response = await fetch(`${BASE}/mes/warehouse/inventory/exportOrphanXls`, { headers: { 'X-Access-Token': c.token } });
    c.check('导出占位明确拒绝', response.status === 500, `status=${response.status}`);
  } finally {
    await cleanupFixtures(c, ids);
  }
  process.exit(c.summary('库存孤儿行导出测试') ? 0 : 1);
}

run().catch((e) => { console.error('FATAL:', e); process.exit(2); });
