export const meta = {
  name: 'tiequan-audit-mes-sales',
  description: 'MES Sales module audit',
  phases: [
    { title: 'Product Review', detail: 'Customer, boundary, financial risk' },
    { title: 'Dev Review', detail: 'Architecture, code details, concurrency' },
    { title: 'QA Review', detail: 'Functional, boundary, performance, reconciliation' },
  ],
}

const BASE = 'jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/sales'
const VUE = 'jeecgboot-vue3/src/views/project/mes/sales'

const ENTITIES = BASE + '/entity'
const SERVICES = BASE + '/service/impl'
const CONTROLLERS = BASE + '/controller'

function readAllFiles() {
  return 'Read all files under: ' + ENTITIES + ' (7 entities), ' + SERVICES + ' (4 impls), ' + CONTROLLERS + ' (4 controllers), ' + VUE + ' (16 vue/ts files), plus SQL files under jeecg-boot/jeecg-boot-module/project-mes/db/ (V3.0.0 and V5.0.0).'
}

phase('Product Review')

const p1Prompt = 'You are a product risk auditor reviewing MES Sales module from the CUSTOMER PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. End-to-end business flow completeness: Customer order -> Sales Order -> Outbound -> Delivery -> Receipt\n2. Field naming and UI layout: Are they intuitive for business users?\n3. Required vs optional fields: Are critical fields missing validation?\n4. Default values: Are defaults for status, dates reasonable?\n5. Data linkage: Does changing a sales order cascade to outbound/delivery?\n6. Document number generation rules\n7. Price module linkage with sales orders\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const p2Prompt = 'You are a product risk auditor reviewing MES Sales module from the EDGE CASE & EXCEPTION PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Concurrent operations: Multiple users editing same order simultaneously\n2. Reverse operations: Cancel approved orders, reverse shipped goods, return deliveries\n3. Edge values: Zero quantity/amount, negative values, very large imports\n4. Upstream/downstream linkage: Sales order changes not synced to outbound/delivery\n5. State machine bypass: Can skip approval to outbound? Can modify shipped orders?\n6. Null/special chars: Code with special chars, empty names, abnormal dates\n7. Data consistency: Header/detail mismatch, summary vs detail amount mismatch\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const p3Prompt = 'You are a product risk auditor reviewing MES Sales module from the FINANCIAL LOSS & COMPLIANCE PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Amount field precision: BigDecimal vs Double for price/amount/tax\n2. Calculation correctness: qty*price==amount, tax calculation, rounding rules\n3. Inventory deduction correctness: Outbound inventory deduction accuracy, oversell prevention\n4. Price linkage: Sales order price vs price module consistency, price change traceability\n5. Amount summary: Header total vs detail sum correctness\n6. Reconciliation: Sales order amount vs outbound amount vs delivery amount\n7. Refund/return: Return inventory replenishment correctness, refund calculation\n8. AR linkage: Risk of amount mismatch between sales and finance\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const [product1, product2, product3] = await parallel([
  () => agent(p1Prompt, {label: '产品大佬1号_客户视角', phase: 'Product Review'}),
  () => agent(p2Prompt, {label: '产品大佬2号_边界异常', phase: 'Product Review'}),
  () => agent(p3Prompt, {label: '产品大佬3号_资损合规', phase: 'Product Review'}),
])

phase('Dev Review')

const d1Prompt = 'You are a dev risk auditor reviewing MES Sales module from the ARCHITECTURE PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Transaction boundaries: @Transactional usage correctness, propagation behavior\n2. Service layering: Controller->Service->Mapper chain clarity, no layer skipping\n3. Performance risks: N+1 queries, full table scans, missing indexes\n4. JeecgBoot compliance: Entity inheritance, Controller extends JeecgController, Service extends ServiceImpl\n5. Exception handling: Unified exception handling, no swallowed exceptions\n6. Cross-module coupling: Sales module dependencies on purchase/production/warehouse\n7. Circular dependencies: Service circular dependency risks\n8. Database design: Table structure, index coverage, redundant fields\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const d2Prompt = 'You are a dev risk auditor reviewing MES Sales module from the CODE DETAILS PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Input validation: Controller and Service parameter validation (non-null, length, format, range)\n2. SQL injection: String concatenation in Mapper XML (especially ${} in dynamic SQL)\n3. Null handling: Null checks on potentially null returns\n4. Precision: BigDecimal construction, comparison, calculation correctness\n5. Hardcoded values: Magic numbers, hardcoded strings\n6. VO matching: Backend returns all data frontend needs\n7. Frontend-backend alignment: Controller paths/params match frontend api.ts\n8. Code modification markers: update-begin/update-end comments on new/modified code\n9. Dict field matching: Entity @Dict annotations match frontend dictCode\n10. Unique indexes: Composite unique index on code+del_flag\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location (exact file and line) | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const d3Prompt = 'You are a dev risk auditor reviewing MES Sales module from the CONCURRENCY SAFETY PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Oversell risk: Concurrent outbound of same product - inventory deduction concurrency protection (optimistic/pessimistic/distributed lock)\n2. Duplicate submission: Frontend button debounce, backend idempotency\n3. Distributed lock: If @DistributedLock used, check lock granularity\n4. DB isolation level: Sufficient to prevent dirty/phantom reads\n5. Idempotency: Creating/updating operations safely retryable\n6. Check-then-act: Non-atomic "query-check-write" patterns\n7. Document number: Concurrency-safe unique number generation\n8. Inventory deduction: Atomic inventory deduction on outbound\n9. State machine concurrency: Multiple users operating same document status simultaneously\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const [dev1, dev2, dev3] = await parallel([
  () => agent(d1Prompt, {label: '研发大牛1号_架构全局', phase: 'Dev Review'}),
  () => agent(d2Prompt, {label: '研发大牛2号_代码细节', phase: 'Dev Review'}),
  () => agent(d3Prompt, {label: '研发大牛3号_并发安全', phase: 'Dev Review'}),
])

phase('QA Review')

const t1Prompt = 'You are a QA auditor reviewing MES Sales module from the FUNCTIONAL TESTING PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Forward flow: Create order -> approve -> outbound -> delivery - is the chain complete?\n2. Reverse flow: Cancel order, return outbound, void delivery supported?\n3. CRUD completeness: Full CRUD + batch delete + import/export for each module?\n4. State transitions: State machine completeness and rationality for order/outbound/delivery\n5. Header-detail linkage: Detail row changes correctly update header\n6. Query functionality: List search fields cover common scenarios\n7. Data validation: Required fields, format validation, business rule validation\n8. Excel import/export: Import template correctness, export data completeness\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const t2Prompt = 'You are a QA auditor reviewing MES Sales module from the BOUNDARY & EXCEPTION TESTING PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Extreme inputs: Integer.MAX_VALUE quantity, huge amounts, year 2099 dates\n2. Null/empty: Empty code, null customer, empty detail lines, null dates\n3. Invalid params: SQL injection attempts, XSS vectors, invalid enum values\n4. Concurrency conflicts: Status conflicts from simultaneous operations\n5. Overlong inputs: Code/name/remark exceeding column limits\n6. Data type boundaries: Integer overflow, BigDecimal precision overflow\n7. Business boundaries: Outbound qty > order qty, delivery qty > outbound qty\n8. Unauthenticated/unauthorized API access\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const t3Prompt = 'You are a QA auditor reviewing MES Sales module from the PERFORMANCE TESTING PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. N+1 queries: Does header-detail query loop over database?\n2. Full table scans: Is list query paginated? Are query conditions indexed?\n3. Slow SQL risks: Multi-table JOINs, subqueries, unbounded exports\n4. Large transactions: Are import/batch operations in single transaction? Batched?\n5. Caching: Reasonable cache usage\n6. Connection leaks: Database connection leak risks\n7. Deep pagination: Optimization for deep page queries\n8. Concurrent throughput: Estimated QPS and bottleneck analysis\n9. Data growth: Table design supports large data volumes (millions of rows)\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const t4Prompt = 'You are a QA auditor reviewing MES Sales module from the FINANCIAL RECONCILIATION PERSPECTIVE.\n\n' + readAllFiles() + '\n\nAudit focus:\n1. Amount consistency: Order amount == sum(detail amounts), tax correctness, total with tax\n2. Quantity consistency: Order qty vs outbound qty vs delivery qty - can they be reconciled?\n3. Inventory accuracy: Correct deduction after outbound, correct replenishment after return\n4. Price consistency: Sales order price consistency with price module\n5. Document amount summary: Header totalAmount vs detail sum consistency\n6. Precision loss: BigDecimal operation precision loss risks\n7. Write-back: Outbound/delivery completion correctly writes back to sales order status/qty\n8. AR linkage: Risk of amount mismatch between sales module and finance AR\n\nOutput format:\n## Conclusion\n1-2 sentence summary\n\n## Findings (P0/P1/P2/P3)\nEach: Level | Location | Problem | Impact | Fix Suggestion\n\nOutput ONLY your audit report.'

const [test1, test2, test3, test4] = await parallel([
  () => agent(t1Prompt, {label: '测试牛马1号_基础功能', phase: 'QA Review'}),
  () => agent(t2Prompt, {label: '测试牛马2号_边界异常', phase: 'QA Review'}),
  () => agent(t3Prompt, {label: '测试牛马3号_性能压测', phase: 'QA Review'}),
  () => agent(t4Prompt, {label: '测试牛马4号_资损对账', phase: 'QA Review'}),
])

log('All 10 agents completed. Returning results for consensus analysis.')
return { product1, product2, product3, dev1, dev2, dev3, test1, test2, test3, test4 }
