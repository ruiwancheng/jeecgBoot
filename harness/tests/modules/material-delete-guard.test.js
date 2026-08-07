const { createClient } = require('../helpers/api');
const { withReferencedMaterial, cleanupFixtures, dbCleanup } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');
  const ids = [];
  try {
    const inventory = await withReferencedMaterial(c, ['c_mes_inventory']); ids.push(inventory);
    const r1 = await c.api('DELETE', `/mes/basic/material/delete?id=${inventory}`);
    c.check('S1 inventory 引用拦截', r1.code === 400 || r1.code === 500, `code=${r1.code}`);

    const bom = await withReferencedMaterial(c, ['c_mes_bom_item']); ids.push(bom);
    const r2 = await c.api('DELETE', `/mes/basic/material/delete?id=${bom}`);
    c.check('S2 BOM 引用拦截', r2.code === 400 || r2.code === 500, `code=${r2.code}`);

    const batch = await withReferencedMaterial(c, ['c_mes_batch']); ids.push(batch);
    const r3 = await c.api('DELETE', `/mes/basic/material/delete?id=${batch}`);
    c.check('S3 活跃批次拦截', r3.code === 400 || r3.code === 500, `code=${r3.code}`);

    const zero = await withReferencedMaterial(c, ['c_mes_inventory']); ids.push(zero);
    dbCleanup(`UPDATE c_mes_inventory SET current_qty=0 WHERE material_id='${zero}';`);
    const r4 = await c.api('DELETE', `/mes/basic/material/delete?id=${zero}`);
    c.check('S4 qty=0 inventory 仍拦截', r4.code === 400 || r4.code === 500, `code=${r4.code}`);

    const fresh = await withReferencedMaterial(c, []); ids.push(fresh);
    const r5 = await c.api('DELETE', `/mes/basic/material/delete?id=${fresh}`);
    c.check('S5 无引用物料可删除', r5.code === 200, `code=${r5.code}`);
  } finally {
    await cleanupFixtures(c, ids);
  }
  process.exit(c.summary('物料删除守卫测试') ? 0 : 1);
}

run().catch((e) => { console.error('FATAL:', e); process.exit(2); });
