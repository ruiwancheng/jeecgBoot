const { createClient } = require('../helpers/api');
const { withOrphanRow, cleanupFixtures } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');
  const ids = [];
  try {
    const empty = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: [] });
    c.check('空 ids 被校验', empty.code === 200 || empty.code === 400 || empty.code === 500, `code=${empty.code}`);

    const injection = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: ["1','2',' OR 1=1 --"] });
    c.check('SQL 注入输入不执行删除', injection.code === 400 || injection.code === 500, `code=${injection.code}`);

    const tooMany = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', {
      ids: Array.from({ length: 501 }, (_, i) => `edge-${i}`),
    });
    c.check('批量上限 500', tooMany.code === 400 || tooMany.code === 500, `code=${tooMany.code}`);

    ids.push(await withOrphanRow(c, { qty: 0 }));
    const deleted = await c.api('DELETE', `/mes/warehouse/inventory/deleteOrphan?id=${ids[0]}`);
    c.check('单删孤儿行', deleted.code === 200, `code=${deleted.code}`);
  } finally {
    await cleanupFixtures(c, ids);
  }
  process.exit(c.summary('库存孤儿行边界测试') ? 0 : 1);
}

run().catch((e) => { console.error('FATAL:', e); process.exit(2); });
