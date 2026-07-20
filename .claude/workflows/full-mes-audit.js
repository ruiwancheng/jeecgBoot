export const meta = {
  name: 'full-mes-audit',
  description: 'MES complete project audit - all 7 modules',
  phases: [
    { title: 'Product Review', detail: 'Business flow, exceptions, financial compliance' },
    { title: 'Dev Review', detail: 'Architecture, code details, concurrency' },
    { title: 'QA Review', detail: 'Functional, boundary, performance, reconciliation' },
  ],
}

const BASE = 'jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes'
const VUE = 'jeecgboot-vue3/src/views/project/mes'

const scope = `Audit ALL MES modules under ${BASE}:
- basic/ (customer, supplier, material, warehouse, location, inventory)
- sales/ (order, outbound, delivery, price)
- purchase/ (apply, order, receipt, ledger)
- manufacturing/ (bom, order, picking, completion)
- finance/ (subject, receivable, payable, collection, payment, voucher, invoice, purchaseInvoice)
- config/ (menu registry, runner)
- Frontend: ${VUE}/

Also check cross-module hooks:
- Sales Outbound audit: stockOut + AR generation + delivery status + order ship status
- Purchase Receipt audit: stockIn + AP generation
- Production Picking/Completion audit: stockOut/stockIn
- Collection/Payment: AR/AP status update
- Voucher: debit/credit balance check

Focus on:
1. Data integrity across modules
2. Transaction boundaries and concurrency
3. Amount/quantity calculation correctness
4. Status machine completeness
5. Missing indexes or N+1 queries
6. Unique constraint coverage
7. Error handling completeness`

phase('Product Review')

const [p1, p2, p3] = await parallel([
  () => agent('Audit MES from BUSINESS FLOW perspective:\n' + scope + '\nCheck: end-to-end flows, user experience, business rule completeness.', {label: '产品大佬1号_客户视角', phase: 'Product Review'}),
  () => agent('Audit MES from EDGE CASE perspective:\n' + scope + '\nCheck: concurrency races, reverse operations, null/empty handling, boundary values.', {label: '产品大佬2号_边界异常', phase: 'Product Review'}),
  () => agent('Audit MES from FINANCIAL COMPLIANCE perspective:\n' + scope + '\nCheck: amount precision, tax calculation, inventory accuracy, AR/AP reconciliation, financial loss risks.', {label: '产品大佬3号_资损合规', phase: 'Product Review'}),
])

phase('Dev Review')

const [d1, d2, d3] = await parallel([
  () => agent('Audit MES from ARCHITECTURE perspective:\n' + scope + '\nCheck: transaction boundaries, service layering, module coupling, JeecgBoot patterns, index coverage.', {label: '研发大牛1号_架构全局', phase: 'Dev Review'}),
  () => agent('Audit MES from CODE DETAILS perspective:\n' + scope + '\nCheck: input validation, SQL injection, null safety, BigDecimal precision, hardcoded values, update-begin/end markers, frontend-backend alignment.', {label: '研发大牛2号_代码细节', phase: 'Dev Review'}),
  () => agent('Audit MES from CONCURRENCY SAFETY perspective:\n' + scope + '\nCheck: TOCTOU races, SELECT FOR UPDATE coverage, optimistic locking, unique index guards, idempotency, duplicate submission protection.', {label: '研发大牛3号_并发安全', phase: 'Dev Review'}),
])

phase('QA Review')

const [t1, t2, t3, t4] = await parallel([
  () => agent('Audit MES from FUNCTIONAL TESTING perspective:\n' + scope + '\nCheck: CRUD completeness, state transitions, header-detail linkage, import/export coverage, query functionality.', {label: '测试牛马1号_基础功能', phase: 'QA Review'}),
  () => agent('Audit MES from BOUNDARY TESTING perspective:\n' + scope + '\nCheck: extreme values, invalid params, overlong input, unauthenticated access, SQL injection vectors.', {label: '测试牛马2号_边界异常', phase: 'QA Review'}),
  () => agent('Audit MES from PERFORMANCE perspective:\n' + scope + '\nCheck: N+1 queries, full table scans, missing indexes, large transactions, caching, batch operations.', {label: '测试牛马3号_性能压测', phase: 'QA Review'}),
  () => agent('Audit MES from FINANCIAL RECONCILIATION perspective:\n' + scope + '\nCheck: amount consistency across modules, inventory accuracy, tax calculation, AR/AP write-back, ledger integrity.', {label: '测试牛马4号_资损对账', phase: 'QA Review'}),
])

log('All 10 agents completed. Returning results for consensus analysis.')
return { p1, p2, p3, d1, d2, d3, t1, t2, t3, t4 }
