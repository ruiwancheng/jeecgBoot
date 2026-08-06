#!/usr/bin/env node
// update-begin---author:pi---date:2026-08-06---for:【BATCH-RUNNER】批量跑测试文件（manifest 切片用）---
/**
 * harness/scripts/run-batch.js — 批量跑测试文件 driver
 *
 * 用法：
 *   node harness/scripts/run-batch.js module <batch-id>     # 跑一组 module 测试
 *   node harness/scripts/run-batch.js e2e <batch-id>        # 跑一组 E2E spec
 *
 * 模块测试分批（按字母顺序）：
 *   - basic-1: basic-accountSubject ~ basic-inventoryAlert (12 个)
 *   - basic-2: basic-location ~ batch-manual-e2e (12 个)
 *   - finance: finance-invoice-crud ~ misc-extra (12 个)
 *   - other: other-stock-in ~ warehouse-ledger (12 个)
 *
 * E2E spec 分批：
 *   - basic: basic-* (15 个)
 *   - biz: batch-* + commonSetting + finance + manufacturing (8 个)
 *   - purchase-sales: purchase + sales + material + stocktake + traceability + smoke-material (12 个)
 *
 * 退出码：所有测试都通过 = 0；任一失败 = 1
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PROJECT = path.resolve(__dirname, '..', '..');

// 45 个 module 测试分批（每批 ~12 个）
const MODULE_BATCHES = {
  'basic-1': [
    'basic-accountSubject', 'basic-batchInventory', 'basic-batchLedger', 'basic-batchTraceability',
    'basic-customer-supplier', 'basic-customerAddress', 'basic-customerContact', 'basic-customerFollowUp',
    'basic-customerPrice', 'basic-extra', 'basic-inventoryAlert', 'basic-location',
  ],
  'basic-2': [
    'basic-material', 'basic-otherStockOut', 'basic-supplier', 'basic.test', 'batch-freeze',
    'batch-global-switch', 'batch-manual-e2e', 'finance-invoice-crud', 'finance-invoice',
    'finance-others', 'finance-voucher-crud', 'finance.test',
  ],
  'extended': [
    'manufacturing-crud', 'manufacturing.test', 'misc-extra', 'other-stock-in',
    'purchase-ledger-costlog', 'purchase-mesCostLog', 'purchase-order', 'purchase-receipt-apply',
    'purchase.test', 'sales-delivery', 'sales-extra', 'sales-order-delivery',
  ],
  'final': [
    'sales-outbound', 'sales-price', 'stock-otherin', 'stocktake-global-switch', 'stocktake.test',
    'system.test', 'traceability-batch-level', 'warehouse-activate', 'warehouse-ledger',
  ],
};

// 35 个 E2E spec 分批
const E2E_BATCHES = {
  'basic': [
    'basic-accountSubject', 'basic-batchInventory', 'basic-batchLedger', 'basic-batchTraceability',
    'basic-codeRule', 'basic-customer', 'basic-customerAddress', 'basic-customerContact',
    'basic-customerFollowUp', 'basic-customerPrice', 'basic-inventory', 'basic-inventoryAlert',
    'basic-material', 'basic-otherStockOut', 'basic-supplier', 'basic.spec',
  ],
  'biz': [
    'batch-inventory', 'batch-ledger', 'batch-master', 'commonSetting', 'finance.spec',
    'manufacturing.spec', 'materialBatch', 'materialBatchEnabledSave',
  ],
  'purchase-sales': [
    'other-stock-in', 'purchase-ledger', 'purchase.spec', 'purchaseReceiptBatch',
    'sales-delivery', 'sales-order', 'sales-outbound', 'sales-price', 'smoke-material',
    'stocktake.spec', 'traceabilityBatch',
  ],
};

function runCmd(cmd, opts = {}) {
  return execSync(cmd, { encoding: 'utf8', cwd: PROJECT, stdio: 'inherit', ...opts });
}

function runModuleBatch(batchId) {
  const batch = MODULE_BATCHES[batchId];
  if (!batch) {
    console.error(`Unknown module batch: ${batchId}. Available: ${Object.keys(MODULE_BATCHES).join(', ')}`);
    process.exit(2);
  }
  console.log(`📦 Module batch: ${batchId} (${batch.length} 个测试)`);
  let total = 0, passed = 0, failed = 0;
  for (const name of batch) {
    const file = path.join(PROJECT, 'harness', 'tests', 'modules', `${name}.test.js`);
    if (!fs.existsSync(file)) {
      console.log(`  ⚠️  ${name}: 文件不存在，跳过`);
      continue;
    }
    total++;
    process.stdout.write(`  ▶ ${name} ... `);
    try {
      runCmd(`node "${file}"`, { stdio: 'pipe' });
      passed++;
      console.log('✅');
    } catch (e) {
      failed++;
      console.log(`❌ (exit ${e.status})`);
    }
  }
  console.log(`\n📊 Module batch ${batchId}: ${passed}/${total} 通过${failed > 0 ? `, ${failed} 失败` : ''}`);
  process.exit(failed > 0 ? 1 : 0);
}

function runE2EBatch(batchId) {
  const batch = E2E_BATCHES[batchId];
  if (!batch) {
    console.error(`Unknown e2e batch: ${batchId}. Available: ${Object.keys(E2E_BATCHES).join(', ')}`);
    process.exit(2);
  }
  const specs = batch.map(n => path.join('harness', 'e2e', 'mes', `${n}.spec.ts`));
  console.log(`📦 E2E batch: ${batchId} (${batch.length} 个 spec)`);
  try {
    runCmd(`npx playwright test ${specs.join(' ')} --workers=1`, { cwd: path.join(PROJECT, 'harness') });
  } catch (e) {
    console.log(`\n❌ E2E batch ${batchId} 失败 (exit ${e.status})`);
    process.exit(1);
  }
  console.log(`\n✅ E2E batch ${batchId} 通过`);
}

function main() {
  const [type, batchId] = process.argv.slice(2);
  if (!type || !batchId) {
    console.log('用法: node run-batch.js <module|e2e> <batch-id>');
    console.log('\nModule batches:', Object.keys(MODULE_BATCHES).join(', '));
    console.log('E2E batches:', Object.keys(E2E_BATCHES).join(', '));
    process.exit(1);
  }
  if (type === 'module') runModuleBatch(batchId);
  else if (type === 'e2e') runE2EBatch(batchId);
  else {
    console.error(`Unknown type: ${type}. Use 'module' or 'e2e'`);
    process.exit(1);
  }
}

if (require.main === module) main();
// update-end---author:pi---date:2026-08-06---for:【BATCH-RUNNER】批量跑测试文件（manifest 切片用）---
