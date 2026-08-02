# MES 批次管理 P0 修复开工单

> 范围：铁拳团 2026-07-31 审计指出的 5 个 P0 中，本次确认真实可立即修的 4 项 + 1 项需业务决策的项。
> 工作区已含之前 P0-1 warehouseId=" "、批次库存行锁、FIFO 行锁 3 个 Java 改动（未提交）。
> 写代码前必须先 Orca 变更前评审；每个文件改动必须包 update-begin/end；测试数据用唯一后缀且测试结束清理。
> 验收证据：本地 8080 + 3100 实测 + curl + 并发测试。
> 边界：不要改 jeecg-boot-base-core、jeecg-module-system、jeecg-system-start/src；不要新增 Maven 模块。

---

## P0-1 批次号并发发号（P0-1/铁拳团，6/10 共识）

**根因**
`MesBatchServiceImpl.createBatch` 用 `this.count(seqQw) + 1` 计算当日序号，事务内无锁。并发创建同一物料的批次时两个事务取到相同 seq → 触发 `uk_batch_no_del` 唯一索引冲突 → `DuplicateKeyException` → 整单回滚；集成点已先增加主库存，造成主库存与批次库存不一致。

**文件**
- `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/batch/master/service/impl/MesBatchServiceImpl.java`

**修复要点（推荐方案 A：锁物料主档行后发号）**
1. `createBatch` 开头增加物料主档行锁（避免“无记录可锁”竞态）：
   - `MesMaterial mat = materialMapper.selectByIdForUpdate(materialId);`
   - 若 `mat == null` 抛 `JeecgBootException("物料不存在")`；
   - 若 `materialId` 为空抛 `JeecgBootException("物料不能为空")`（顺带修 P1-3 NPE）。
2. 锁持有后，再按 `prefix+date` 查当天最大序号 + 1（`SELECT MAX(batch_no) FROM c_mes_batch WHERE batch_no LIKE 'BT-XXXXXX-YYYYMMDD%'` 走单 SQL，原生 `@Select`），新 `batchNo` 生成在同一事务内。
3. `this.save(batch)` 之后 `uk_batch_no_del` 仍作为最后兜底；`@Transactional` 已存在，失败回滚整单。

**注意**
- 不要新增 `synchronized`（项目规范禁用）。
- 物料主档行锁可能导致同一物料的批次创建串行化，跨物料互不阻塞，可接受。
- `materialMapper.selectByIdForUpdate` 需先确认基础模块是否提供 `FOR UPDATE` 行锁；如未提供，新增 `MesMaterialMapper` 中 `@Select("SELECT * FROM c_mes_material WHERE id=#{id} FOR UPDATE")` 方法。

**验收证据**
- 并发 10 个线程同时对同一物料调用 `createBatch`：
  - 9/31 / 10/31 / 11/31 等连续序号；
  - 全部 `code=200`；
  - 数据库 `c_mes_batch.batch_no` 无重复。
- 物料不存在的请求返回 `code=500, message` 含"物料不存在"。
- `materialId=null` 返回 `code=500, message` 含"物料不能为空"。

---

## P0-2 Ledger Mapper 缺 SQL 实现（铁拳团 5/10 共识）

**根因**
`MesBatchLedgerMapper` 接口声明了 `selectByBatchId` 和 `selectByBiz`，但没有 `@Select` 注解或 XML 映射。`MesBatchLedgerServiceImpl.listByBiz` 调用 `baseMapper.selectByBiz(...)` 在运行时抛 `BindingException`（非启动期，注：审计报告"启动即失败"不准确）。

**文件**
- `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/batch/ledger/mapper/MesBatchLedgerMapper.java`

**修复要点**
在 Mapper 接口内补两个 `@Select`（参数化，不允许 `${}` 拼接）：

```java
@Select("SELECT * FROM c_mes_batch_ledger " +
        "WHERE batch_id = #{batchId} AND del_flag = 0 " +
        "ORDER BY occur_time DESC")
List<MesBatchLedger> selectByBatchId(@Param("batchId") String batchId);

@Select("SELECT * FROM c_mes_batch_ledger " +
        "WHERE biz_type = #{bizType} AND biz_id = #{bizId} AND del_flag = 0 " +
        "ORDER BY occur_time DESC")
List<MesBatchLedger> selectByBiz(@Param("bizType") String bizType, @Param("bizId") String bizId);
```

需 `import org.apache.ibatis.annotations.Select` 和 `org.apache.ibatis.annotations.Param`。

**验收证据**
- `mvn compile -pl jeecg-boot-module/project-mes -am` 通过。
- 启动后 `curl /mes/batch/ledger/listByBatchId?batchId=<已有id>` 返回 `code=200, success=true, result=[...]`。
- 故意调用 `IMesBatchLedgerService.listByBiz("1", "<某入库单id>")`（在测试脚本内直接调或临时 endpoint）不再抛 `BindingException`。

---

## P0-3 生产领料审核顺序（P0-3/铁拳团 4/10 共识）

**根因**
`ProductionPickingServiceImpl.audit` 当前顺序：先 `stockOut` 主库存、再 `stockOutFifo` 批次库存、最后 `baseMapper.auditWithGuard`。违反项目强制规则"先原子状态守卫、后执行副作用"。`@Transactional` 兜底可在 `auditWithGuard` 返回 0 时回滚全部扣减，但保留"先扣后守卫"会导致不必要的主库存行锁竞争，与销售出库已对齐的"先守卫后扣减"模式不一致。

**文件**
- `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/manufacturing/picking/service/impl/ProductionPickingServiceImpl.java`

**修复要点（与 `MesSalesOutboundServiceImpl.audit` 对齐）**
1. 方法头：
   - `queryWithItems(id)` 校验非空、状态=草稿；
   - 计算 `username`/`now`；
   - 先 `int rows = baseMapper.auditWithGuard(id, username, now);`；
   - 若 `rows == 0` 抛 `JeecgBootException("审核失败：领料单不存在或状态已变更，请刷新后重试")`。
2. `auditWithGuard` 成功后再 for 循环执行：
   - `inventoryService.stockOut(...)` 主库存；
   - `mat.getBatchEnabled()=1` 时 `batchInventoryService.stockOutFifo(...)`。
3. `update-begin/end` 标记仅包被改动的核心两段。

**验收证据**
- 草稿状态领料单 audit 成功：HTTP 200，主库存 / 批次库存按明细扣减。
- 同一领料单连续 audit 两次：第二次返回 `code=500, message` 含"审核失败：领料单不存在或状态已变更"。
- 并发两线程对同一草稿 audit：恰好一次成功（HTTP 200），另一次返回守卫失败，库存无多扣。

---

## P0-4 批次 4 页面导出链路（铁拳团 3/10 共识；注：审计报告只点名 ledger，实际 4 个页面都缺）

**根因**
4 个批次页面（master/inventory/ledger/traceability）的 `index.vue` 都 `import { getExportUrl }`，但各自 `*.api.ts` 都没导出该函数；同时 3 个 Controller（master/inventory/ledger）也都没有 `/exportXls` 端点。审计报告 P0-4 只指出 ledger，但实际 4 个页面都会运行时 `Uncaught ReferenceError: getExportUrl is not defined`，且点击导出按钮 404。

**文件**
- 前端 4 个：`jeecgboot-vue3/src/views/project/mes/batch/{master,inventory,ledger,traceability}/{master,inventory,ledger,traceability}.api.ts`
- 后端 3 个 Controller：见下
  - `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/batch/master/controller/MesBatchController.java`
  - `.../inventory/controller/MesBatchInventoryController.java`
  - `.../ledger/controller/MesBatchLedgerController.java`
- 路由权限：`.../config/init/MesMenuRegistry.java` 当前 `mes:batchInventory:list/export` 和 `mes:batchLedger:list/export` 已配置，master 已有 `export` 权限，无需调整。

**修复要点（与基础模块对齐）**

**后端**：3 个 Controller 各加一个端点，参考 `MesWarehouseController.exportXls` 风格：

```java
@GetMapping("/exportXls")
@RequiresPermissions("mes:batchXxx:export")
public ModelAndView exportXls(MesBatchXxx entity, HttpServletRequest req) {
    if (service.count(new QueryWrapper<>()) > QUERY_ALL_MAX) {
        throw new JeecgBootException("批次xxx超过" + QUERY_ALL_MAX + "条，请使用分页导出");
    }
    return super.exportXls(req, entity, MesBatchXxx.class, "批次xxx");
}
```

- 复制每个 Controller 已有的 `QUERY_ALL_MAX` 常量。
- 复用 `JeecgController.exportXls(req, entity, clazz, "导出名")`。
- 不需要 Controller 的 `import` 调整，MesBatchController 已存在基本结构。

**前端**：4 个 `*.api.ts` 都补上：

```ts
export function getExportUrl() {
  return '/mes/batch/xxx/exportXls';
}
```

- `master.api.ts` → `/mes/batch/master/exportXls`
- `inventory.api.ts` → `/mes/batch/inventory/exportXls`
- `ledger.api.ts` → `/mes/batch/ledger/exportXls`
- `traceability.api.ts` → `/mes/batch/traceability/exportXls`（**注意**：追溯页实际查询主档数据，导出应调主档端点 `/mes/batch/master/exportXls`，或根据业务决定导出内容；建议先临时复用主档端点，并在 `traceability/index.vue` 导出按钮旁加注释或 `console.log` 占位，方便后续按需调整）

**验收证据**
- 4 个页面在浏览器点"导出"按钮：无 `Uncaught ReferenceError`。
- `curl -H "X-Access-Token: $TOKEN" -o /tmp/out.xls http://localhost:8080/jeecg-boot/mes/batch/master/exportXls` 返回 HTTP 200，文件可打开。
- 同样对 inventory/ledger 测一遍。
- `curl` 无 token 时返回 HTTP 401。

---

## P0-5 `stockOutFifo` 返回值落点 —— 需要业务决策，不直接修

**根因**
`stockOutFifo` 返回 `List<BatchOutDetail>(batchId, batchNo, qty, unitCost)`，销售出库 audit 和生产领料 audit 都没接收。审计报告建议：

```java
item.setUnitCost(...);
```

但**当前实体和数据库都没有 `unitCost` 字段**：

- `MesSalesOutboundItem` 只有 `unitPrice/amount`（`unitPrice` 是销售价，不是成本）。
- `MesProductionPickingItem` 也没有批次成本字段。
- 已有 ADR 0001："销售出库 audit 锁定物料移动平均成本，不重算"。

铁拳审计建议会与 ADR 0001 冲突，**不要按该建议直接 setUnitCost**。这一项需要业务/财务确认走以下哪个分支，再写代码。

**请按以下问题，先和业务/客户确认，再做后续修复（这一项不要求本次提交）**

1. 批次成本只落 `c_mes_batch_ledger.unit_cost`，不落到业务明细。
2. 给 `c_mes_sales_outbound_item` 和 `c_mes_production_picking_item` 新增 `unit_cost/cost_amount` 字段，写迁移脚本 + 改实体 + 改前端列表 + 加财务链路。
3. 主台账 `c_mes_inventory_ledger` 落批次成本：调整 `inventoryService.stockOut` 调用，把批次成本作为 `unitCost` 参数传入。
4. 暂不处理，后续 sprint 排期。

**当前可立即做的**：
- 在 `MesSalesOutboundServiceImpl.audit` 和 `ProductionPickingServiceImpl.audit` 中**接收 `List<BatchOutDetail>`** 并通过 `//update-begin` 注释标明 `// TODO: 批次成本落点（待业务确认 ADR 0002）`，不写入实体字段。这样不增加数据风险，但代码意图清晰，调试可见。

**验收证据**
- 上述 `// TODO` 注释在 diff 中可见。
- 业务确认后再决策，不需要本次必须改出实际效果。

---

## 修复顺序建议

1. P0-2（Mapper SQL，5 分钟，零风险）
2. P0-4（前后端导出，30 分钟）
3. P0-3（生产领料 audit 顺序，30 分钟）
4. P0-1（批次号并发锁，1 小时，需要先确认 `MesMaterialMapper.selectByIdForUpdate` 是否存在）
5. P0-5（仅加 TODO 注释，等业务决策）

## 通用约束

- 写代码前先 Orca 变更前评审（review-only 任务）；
- 每个文件改动用 `update-begin---author:...---date:YYYY-MM-DD---for: ...` 包裹；
- 新增的 SQL 注解方法必须参数化 `#{}`，不允许 `${}`；
- 测试数据用 `ts = Date.now()` 后缀避免冲突；
- 测试结束用 `harness/tests/helpers/fixtures.js#dbCleanup` 清理；
- 修改后跑 `mvn install -DskipTests` + `mvn compile -pl jeecg-boot-module/project-mes -am` + 重启后端 + curl/并发测试；
- 写完代码自动 /verify，最后 /quality-gate。
