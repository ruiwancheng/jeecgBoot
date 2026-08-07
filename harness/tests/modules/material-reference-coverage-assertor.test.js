const { execSync } = require('child_process');

const expected = [
  'c_mes_batch', 'c_mes_batch_inventory', 'c_mes_batch_ledger', 'c_mes_bom_item',
  'c_mes_completion_receipt_item', 'c_mes_cost_log', 'c_mes_delivery_note_item',
  'c_mes_inventory', 'c_mes_inventory_ledger', 'c_mes_other_stock_in_item',
  'c_mes_other_stock_out_item', 'c_mes_price', 'c_mes_production_picking_item',
  'c_mes_purchase_apply_item', 'c_mes_purchase_order_item', 'c_mes_purchase_receipt_item',
  'c_mes_sales_order_item', 'c_mes_sales_outbound_item', 'c_mes_stocktake_item',
];

function run() {
  const output = execSync(
    "mysql -h127.0.0.1 -uroot -proot jeecg-boot -N -e \"SELECT table_name FROM information_schema.columns WHERE column_name='material_id' AND table_schema=DATABASE() ORDER BY table_name\"",
    { encoding: 'utf8' },
  ).trim();
  const actual = output ? output.split(/\r?\n/) : [];
  const missing = expected.filter((table) => !actual.includes(table));
  const extra = actual.filter((table) => !expected.includes(table));
  console.log(`schema material_id tables: ${actual.length}`);
  if (missing.length || extra.length || actual.length !== expected.length) {
    console.error(`coverage mismatch; missing=${missing.join(',')} extra=${extra.join(',')}`);
    process.exit(1);
  }
  console.log('✅ MaterialReferenceCoverageAssertor schema coverage: 19/19');
}

try { run(); } catch (e) { console.error(`SKIPPED/FAILED: ${e.message}`); process.exit(2); }
