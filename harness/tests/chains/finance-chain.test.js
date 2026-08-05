// 链路测试: 财务 (subject 科目 → voucher 凭证 → receivable 应收 → collection 收款 → payable 应付 → payment 付款)
// 验证: 8 个 finance controller 的 CRUD + 状态字段 (空 body 友好错误)
// 修复 BUG-CUSTOMER-SCHEMA-DRIFT 后回归 (slice-2.1 验证 schema, slice-4.2 验证财务链)
//
// 注意: payable/receivable 2 个 controller 没有 /add 端点
// (MesPayable/MesReceivable 自动从入库审核/销售出库生成),
// 所以这两个只测 list / queryById / queryAll。
// MesVoucherServiceImpl 涉及借方贷方平衡, 空 items 列表会 NPE,
// 空 body 已通过 controller null check 拦截。

const { createClient } = require('../helpers/api');
const { createSupplier } = require('../helpers/fixtures');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);
const TS = Date.now();

async function createCustomer(c, suffix, name = '测试客户') {
  const code = `CUS_T_${suffix}`;
  await c.api('POST', '/mes/basic/customer/add', { code, name, type: '1', status: 1 });
  const doc = await c.findDoc('/mes/basic/customer/list', code);
  return { id: doc?.id, code };
}

async function run() {
  await c.login();
  console.log('✅ 登录成功\n');
  console.log('━━━ 链路测试: 财务 (subject → voucher → receivable → collection → payable → payment) ━━━\n');

  // ============================================================
  // Setup
  // ============================================================
  console.log('Setup: 客户 + 供应商 fixture');
  const customer = await createCustomer(c, `${TS}fin`, '财务测试客户');
  const supplier = await createSupplier(c, `${TS}fin`, '财务测试供应商');
  console.log(`✅ fixture: 客户 ${customer.code}, 供应商 ${supplier.code}\n`);

  // ============================================================
  // Step 1: 创建会计科目 (subject)
  // ============================================================
  console.log('Step 1: 创建会计科目 (subject)');
  let r = await c.api('POST', '/mes/finance/subject/add', {
    code: `SUBJ-${TS}`,
    name: '测试科目',
    direction: '1',  // 借
    type: '1',  // 资产
    category: '1',  // 流动资产
    status: '1'
  });
  c.check('会计科目 创建', r.success === true, `code=SUBJ-${TS} success=${r.success}`);

  // 查科目 id 供凭证使用
  const subjectList = await c.api('GET', '/mes/finance/subject/queryAll');
  const subjectId = subjectList.result?.[0]?.id;

  // ============================================================
  // Step 2: 创建应收单 (receivable) - 模拟从销售出库自动生成
  // ============================================================
  console.log('\nStep 2: 验证 receivable 列表 (无 add 端点)');
  r = await c.api('GET', '/mes/finance/receivable/list', { pageNo: 1, pageSize: 5 });
  c.check('应收单 list 200', r.success === true, `records=${r.result?.records?.length ?? 0}`);

  // ============================================================
  // Step 3: 创建收款单 (collection)
  // ============================================================
  console.log('\nStep 3: 创建收款单 (collection)');
  r = await c.api('POST', '/mes/finance/collection/add', {
    code: `COL-${TS}`,
    customerId: customer.id,
    amount: 1000,
    collectionDate: '2026-08-04',
    status: '1'
  });
  c.check('收款单 创建', r.success === true, `code=COL-${TS} success=${r.success}`);

  // ============================================================
  // Step 4: 创建付款单 (payment)
  // ============================================================
  console.log('\nStep 4: 创建付款单 (payment)');
  r = await c.api('POST', '/mes/finance/payment/add', {
    code: `PAY-${TS}`,
    supplierId: supplier.id,
    amount: 500,
    paymentDate: '2026-08-04',
    status: '1'
  });
  c.check('付款单 创建', r.success === true, `code=PAY-${TS} success=${r.success}`);

  // ============================================================
  // Step 5: 创建销项发票 (salesInvoice)
  // ============================================================
  console.log('\nStep 5: 创建销项发票 (salesInvoice)');
  r = await c.api('POST', '/mes/finance/salesInvoice/add', {
    code: `SI-${TS}`,
    customerId: customer.id,
    invoiceDate: '2026-08-04',
    totalAmount: 1000,
    taxAmount: 130,
    status: '1'
  });
  c.check('销项发票 创建', r.success === true, `code=SI-${TS} success=${r.success}`);

  // ============================================================
  // Step 6: 创建进项发票 (purchaseInvoice)
  // ============================================================
  console.log('\nStep 6: 创建进项发票 (purchaseInvoice)');
  r = await c.api('POST', '/mes/finance/purchaseInvoice/add', {
    code: `PI-${TS}`,
    supplierId: supplier.id,
    invoiceDate: '2026-08-04',
    totalAmount: 500,
    taxAmount: 65,
    status: '1'
  });
  c.check('进项发票 创建', r.success === true, `code=PI-${TS} success=${r.success}`);

  // ============================================================
  // Step 7: 创建凭证 (voucher) - 借贷平衡, 每行需带 accountId
  // ============================================================
  console.log('\nStep 7: 创建凭证 (voucher, 借贷平衡 100+200=200+100)');
  r = await c.api('POST', '/mes/finance/voucher/add', {
    code: `VCH-${TS}`,
    voucherNo: `VCH-${TS}`,
    voucherDate: '2026-08-04',
    status: '1',
    items: [
      { lineNo: 1, summary: '收应收', subjectId: subjectId, debitAmount: 100, creditAmount: 0 },
      { lineNo: 2, summary: '收现',   subjectId: subjectId, debitAmount: 200, creditAmount: 0 },
      { lineNo: 3, summary: '销项',   subjectId: subjectId, debitAmount: 0,   creditAmount: 200 },
      { lineNo: 4, summary: '收入',   subjectId: subjectId, debitAmount: 0,   creditAmount: 100 }
    ]
  });
  c.check('凭证 创建', r.success === true, `code=VCH-${TS} success=${r.success}`);

  // ============================================================
  // Step 8: 验证 8 个 controller queryAll 端点
  // ============================================================
  console.log('\nStep 8: 验证 8 个 controller queryAll');
  for (const mod of ['collection', 'payable', 'payment', 'salesInvoice',
              'purchaseInvoice', 'receivable', 'subject', 'voucher']) {
    r = await c.api('GET', `/mes/finance/${mod}/queryAll`);
    c.check(`${mod} queryAll 200`, r.success === true, `records=${r.result?.length ?? 0}`);
  }

  // ============================================================
  // Step 9: 验证空 body POST 友好错误 (7 处已 fix)
  // ============================================================
  console.log('\nStep 9: 验证空 body POST 不再 500');
  for (const ep of [
    'collection/add', 'payment/add', 'salesInvoice/add',
    'purchaseInvoice/add', 'subject/add', 'voucher/add'
  ]) {
    r = await c.api('POST', `/mes/finance/${ep}`, {});
    c.check(`${ep} 空 body 拦截`, r.success === false,
            `code=${r.code} msg=${(r.message || '').slice(0, 30)}`);
  }

  // ============================================================
  // 总结
  // ============================================================
  console.log('\n━━━ 链路测试完成 ━━━');
  console.log(`Passed: ${c.passed}, Failed: ${c.failed}`);
  process.exit(c.failed > 0 ? 1 : 0);
}

run().catch(err => {
  console.error('链路测试异常:', err.message);
  console.error(err.stack);
  process.exit(2);
});
