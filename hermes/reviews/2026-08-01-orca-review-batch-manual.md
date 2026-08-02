# 架构评审：生产批次号手工录入模式

**评审人：** Claude Opus 4.8
**阶段：** plan（实施计划外部评审）
**日期：** 2026-08-01
**基准：** orca-review SKILL.md plan 阶段评审 6 维度 + 铁律"无 TODO/TBD"

---

## 总体评价：核心设计正确，但调用方查证不完整（漏 MesBatchController.add）

方案将自动生成改为手工录入、修正唯一索引为按物料隔离，方向正确。Deprecated 渐进迁移策略合理。3 切片划分可独立验证。

**但有一个 P0 遗漏：** `MesBatchController.add`（第 52 行）直接调 `createBatch`，计划未覆盖此调用方。前端"批次主档"新增页面会传用户输入 batchNo 但被 Controller 忽略（走自动生成逻辑）。

---

## 一、文件清单完整性

### E1：数据库 + 实体

| 文件 | 状态 | 说明 |
|------|:--:|------|
| `db/V8.0.3__mes_batch_manual_no.sql` | ✅ | 新建迁移文件 |
| `purchase/receipt/entity/MesPurchaseReceiptItem.java` | ✅ | 加 batchNo + productionDate |
| `manufacturing/completion/entity/MesCompletionReceiptItem.java` | ✅ | 同上 |

### E2：后端 Service

| 文件 | 状态 | 说明 |
|------|:--:|------|
| `batch/master/service/IMesBatchService.java` | ✅ | 接口加 createBatchWithManualNo |
| `batch/master/service/impl/MesBatchServiceImpl.java` | ✅ | 实现新方法 + 老方法 @Deprecated |
| `purchase/receipt/service/impl/MesPurchaseReceiptServiceImpl.java` | ✅ | L189 改调新方法 |
| `manufacturing/completion/service/impl/CompletionReceiptServiceImpl.java` | ✅ | L145 改调新方法 |

### ⚠️ E2 遗漏

| 遗漏 | 位置 | 说明 |
|------|------|------|
| **MesBatchController.add** | `MesBatchController.java` L52 | 直接调 `service.createBatch(entity.getMaterialId(), ...)`，走自动生成逻辑。批次主档手工新增时传了 batchNo 会被丢弃。 |

> **实证：**
> ```java
> // MesBatchController.java:48-57
> @PostMapping("/add")
> public Result<String> add(@RequestBody MesBatch entity) {
>     String id = service.createBatch(entity.getMaterialId(), entity.getOriginType(),
>         entity.getOriginBillId(), entity.getOriginBillNo(),
>         entity.getQty(), entity.getUnitCost(),
>         entity.getProductionDate(), entity.getExpiryDate());
>     return Result.ok("添加成功");
> }
> ```
> 此处 `entity.getBatchNo()` 未传入 `createBatch`。改为手工录入后，Controller 应调用 `createBatchWithManualNo`，将用户输入的 batchNo 传入。

### E3：前端

| 文件 | 状态 | 说明 |
|------|:--:|------|
| `purchase/receipt/ReceiptDrawer.vue` | ✅ | itemColumns 改 computed，加 batchNo + productionDate 列 |
| `manufacturing/completion/CompletionReceiptDrawer.vue` | ✅ | 同上 |

### ⚠️ E3 遗漏

| 遗漏 | 说明 |
|------|------|
| **MesBatchController.add 对应前端** | 批次主档新增页面也会受影响——如果"批次主档"前台也支持手工录入批次号，需确认 `batch/master` 前端 Drawer 是否也要改。不过计划限定为"采购收货+完工入库 2 个 Drawer"，可能是设计取舍。建议明确标注"批次主档仍走自动生成，不改动"。 |

---

## 二、策略判定

| 策略 | 判定 | 说明 |
|------|:--:|------|
| **拆方法 `createBatchWithManualNo`** | ✅ 正确 | 老 `createBatch` 有自动生成逻辑（22 行），拆新方法清细。比"直接在老方法加分支"更干净——分支逻辑（if 手工传参 / else 自动生成）会让自动生成代码和手工录入代码混在一个方法里，3 个月后删自动生成时容易误删校验代码。 |
| **@Deprecated 保留兜底** | ✅ 正确 | 老方法 delegate 给新方法（传入自动生成的 batchNo），外部调用方逐步迁移。保留 3-6 个月观察期合理。 |
| **不直接删老方法** | ✅ 正确 | 直接删会破坏所有调用方的编译。@Deprecated + delegate 是标准渐进迁移策略。 |

---

## 三、依赖查证（5 项标准）

| # | 检查项 | 状态 | 说明 |
|---|--------|:--:|------|
| 1 | Shiro 权限 | ✅ N/A | 不新增 Controller，不改权限 |
| 2 | SQL 兼容性 | ✅ | MySQL 5.7 information_schema + PREPARE 模式已验证（V9.0.1 同模式已测过）。DROP INDEX 无 IF EXISTS（MySQL 5.7 不支持，幂等兜底靠注释"先确认存在再执行"）。⚠️ 但 ADD UNIQUE INDEX 没用 PREPARE 判断——如果脚本重跑会报 "Duplicate key name"。建议包装为 PREPARE 模式如 V9.0.1。 |
| 3 | 前端组件 | ✅ | JMaterialSelect emit `{ value, label, record }`——record 包含 full entity 含 `batchEnabled`。A-DatePicker valueFormat 已设置 `YYYY-MM-DD`。符合 frontend.md 规范。 |
| 4 | 字典 | ✅ N/A | 不新增字典 |
| 5 | 父菜单 | ✅ N/A | 不改菜单结构 |

### ⚠️ SQL 幂等性问题

```sql
-- 当前写法：
ALTER TABLE c_mes_batch DROP INDEX uk_batch_no_del;           -- 若索引不存在 → 报错
ALTER TABLE c_mes_batch ADD UNIQUE INDEX uk_batch_material_no_del (...);  -- 若索引已存在 → 报错

-- 建议：用 PREPARE 模式包装（与 V9.0.1 同款）：
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch' AND index_name = 'uk_batch_no_del');
SET @sql = IF(@idx_exists > 0, 'ALTER TABLE c_mes_batch DROP INDEX uk_batch_no_del', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch' AND index_name = 'uk_batch_material_no_del');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_batch ADD UNIQUE INDEX uk_batch_material_no_del (material_id, batch_no, del_flag)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
```

> 理由：部署控制台自动扫描 `db/` 目录执行 SQL 脚本，脚本可能被多次执行。DROP INDEX 不幂等在二次部署会炸。

---

## 四、更优策略探讨

### 4.1 拆方法 vs 直接重构？

**草案方案：** 拆新方法 + 老方法 @Deprecated delegate。

**评审意见：** 不考虑直接重构。老 `createBatch` 有 `MaterialMapper.selectByIdForUpdate` + `QueryWrapper.likeRight` 取最大序号的核心逻辑（22 行代码 + 行锁保护），直接删掉重写风险太高。拆新方法是正确的。

### 4.2 条件显示 vs 直接删字段？

**草案方案：** 按总开关+物料开关条件显示 tab。

**评审意见：** 条件显示是正确的。总开关关闭时，入库不应创建批次——此时显示 batchNo 字段会误导用户填写无效数据。直接删字段（不显示）在总开关关闭时是正确的 UX。

### 4.3 MaterialSelectModal 返回 batchEnabled 但表格列不显示

**问题：** `MaterialSelectModal` + `JMaterialSelect` 的 `handleSelect` emit 的是 `material.api.ts` 的 `selectMaterialPage` 返回的完整 record。`selectPage` 返回完整 Entity（含 `batchEnabled`），所以 `v.record.batchEnabled` 可用。

**建议：** 在 onMaterialChange 中读 `v.record.batchEnabled` 判断是否提示"物料未启用批次"时，需要确认 `selectPage` 返回的 VO 中包含 `batchEnabled` 字段。当前 `MesMaterial` Entity 有此字段，`selectPage` 是通用分页查询接口，返回完整行——可以工作。

---

## 五、高风险步骤识别

| 风险 | 等级 | 说明 | 缓解 |
|------|:--:|------|------|
| 删唯一索引 + 新建 | 🔴 高 | `uk_batch_no_del` → `uk_batch_material_no_del`。如果数据中有跨物料重复 batchNo（如 BT-MAT-001-20260731-0001 同时被物料 A 和 B 引用），新建索引时失败。因为 7 条历史数据是自动生成的，日期+序号可能重复。 | DROP 前先 `SELECT batch_no, COUNT(*) FROM c_mes_batch GROUP BY batch_no HAVING COUNT(*) > 1` 检查是否有重复。计划已经先 DELETE 清数据，所以此风险仅存在于"如果 DELETE 没生效"的情况。 |
| DELETE 7 条数据不可逆 | 🟡 中 | 用户明确接受。不备份。 | 无需操作。 |
| 改 Service 调用点 | 🟡 中 | 2 个 Service 调用位置已确认。但 MesBatchController.add 漏查——见 P0-1。 | 补查并修改。 |
| 前端条件渲染 | 🟢 低 | computed 只需判断总开关，逻辑简单。 | E2E 覆盖即可。 |

---

## 六、步骤具体性检查（禁止 TODO/TBD）

| 切片 | 步骤 | 具体性 |
|------|------|:--:|
| E1 SQL | DDL 语句逐条列出 | ✅ |
| E1 Entity | 两个 Item 实体加字段代码具体 | ✅ |
| E2 接口 | createBatchWithManualNo 完整签名 | ✅ |
| E2 实现 | 参数校验、查重、写主档、写流水——逐段代码 | ✅ |
| E2 调用点 | PurchaseReceipt L188-194、CompletionReceipt L145——行号+对比代码 | ✅ |
| E3 itemColumns | computed 代码完整 | ✅ |
| E3 template | 槽位代码+校验代码完整 | ✅ |
| E3 E2E | 4 个场景明确 | ✅ |

### 唯一的"不够具体"

E2 顶部写"4 个 Service 改调"，但 E2 文件清单和代码只列了 **2 个 Service**（PurchaseReceipt + CompletionReceipt）。另外 2 个应该是哪两个？从代码查证：

| Service | createBatch 调用 | stockOutFifo 调用 |
|---------|:--:|:--:|
| PurchaseReceiptServiceImpl | ✅ L189 | — |
| CompletionReceiptServiceImpl | ✅ L145 | — |
| ProductionPickingServiceImpl | — | ✅ L149 |
| MesSalesOutboundServiceImpl | — | ✅ L142 |

> **核对结论：** 只有 2 个 Service 调 `createBatch`，不是 4 个。领料和销售出库调的是 `stockOutFifo`（批次出库）而非 `createBatch`（批次创建），两者不涉及批次号录入。**E2 内容正确（2 文件），但顶部描述不准确（说 4 个）。** 建议把顶部"4 个 Service 改调"改为"2 个 Service 改调 + 2 个 Service 无需改（出库方向走 stockOutFifo，不创建新批次）"。

---

## 七、3 个待定夺问题答复

### 7.1 MesBatchController.add 的外部调用方查证了吗？

**没有。** 已查证 `MesBatchController.add` L52 直接调 `service.createBatch(entity.getMaterialId(), ...)`——这里**没有传入 entity.getBatchNo()**，改为手工录入后，批次主档新增接口仍走自动生成，产生 Bug。

**修正：** E2 文件清单补 `MesBatchController.java`——将 `.add()` 方法改为调 `createBatchWithManualNo`（当 entity.getBatchNo() 非空时），或保留自动生成兜底（当 entity.getBatchNo() 为空时回退）。同时前端批次主档新增 Drawer 需要表单中加入 batchNo 输入框。

### 7.2 createBatch 标 Deprecated 后需保留自动生成兜底吗？

**需要。** 草案已设计老方法 delegate 给新方法（传入自动生成的 batchNo）。这是正确的——3 个原因：

1. **MesBatchController.add** 是外部调用方（上面已确认），迁移需要时间
2. **未来可能有其他调用方**（如集成测试、第三方系统）
3. **自动生成 batchNo 逻辑已通过铁拳团审计**（行锁保护、取最大序号），去掉后需要业务确认替代方案

建议在老方法上加 `@Deprecated` + JavaDoc 引导到新方法，同时 log.warn 输出废弃警告便于追踪剩余调用方。

### 7.3 要不要"先备份到 _backup 表"再 DELETE？

**不需要。** 用户明确说不要，且：
- 7 条数据是自动化测试生成的（BT-{物料编码}-{日期}-{序号}格式），不是生产数据
- 批次号格式改为手工录入后，旧数据的批次号格式不匹配，无法在新系统中使用
- 关联的 `c_mes_batch_inventory` 和 `c_mes_batch_ledger` 清空后不会影响主库存（主库存走 `c_mes_inventory`）

---

## 八、汇总

### 🔴 P0（必须修正）

| # | 问题 | 影响 | 修正 |
|---|------|------|------|
| P0 | `MesBatchController.add` L52 仍调 `createBatch`（自动生成），用户输入的 batchNo 被丢弃 | 批次主档手工新增功能形同虚设——填了批次号但不生效，后端自动生成并覆盖 | E2 补 Controller 改动，支持传入 batchNo 时用手工值，为空时自动生成兜底 |

### 🟡 P1（建议修正）

| # | 问题 | 修正 |
|---|------|------|
| P1-1 | SQL DROP INDEX / ADD UNIQUE INDEX 不幂等——重跑脚本时报错 | 用 PREPARE 模式包装（参考 V9.0.1） |
| P1-2 | E2 顶部描述"4 个 Service 改调"与内容（2 文件）不一致，实测也仅 2 个 Service 调 createBatch | 改为"2 个 Service 改调新方法"并注明领料/销售出库走 stockOutFifo 不涉及 |
| P1-3 | 计划未覆盖"批次主档新增"前端页面是否需要改动 | 明确决策：批次主档前端是否也要改为手工录入？还是保留自动生成？ |

### 🟢 P2（优化建议）

| # | 建议 |
|---|------|
| P2-1 | MesBatch Entity 的 batchNo 字段 JavaDoc `(系统生成 BT-...)` 改为 `(手工录入，不同物料可重号)` |
| P2-2 | MaterialSelectModal 表格列配置加 `batchEnabled` 列，让用户选择物料时能看到是否启用批次 |
| P2-3 | createBatchWithManualNo 的 JeecgBootException 友好文案统一：`"批次号 " + batchNo + " 在物料 " + mat.getCode() + " 下已存在，请更换批次号"` |

---

## 附录 A：代码查证记录

| 验证项 | 预期 | 实测 | 证据 |
|--------|------|------|------|
| createBatch 自动生成逻辑位置 | L22-46 | ✅ L32-80 | MesBatchServiceImpl.java |
| createBatch 调用点数量 | 文档说 4 个 | ⚠️ 实际 3 个（2 Service + 1 Controller） | grep `\.createBatch\(` |
| PurchaseReceipt 调用位置 | L189 | ✅ L189 | MesPurchaseReceiptServiceImpl.java |
| CompletionReceipt 调用位置 | L145 | ✅ L145 | CompletionReceiptServiceImpl.java |
| MesBatchController.add 调 createBatch | 文档未提 | ⚠️ L52 调 createBatch | MesBatchController.java |
| ProductionPicking 调 createBatch | 文档说应改 | ⚠️ L149 调 stockOutFifo 非 createBatch | ProductionPickingServiceImpl.java |
| SalesOutbound 调 createBatch | 文档说应改 | ⚠️ L142 调 stockOutFifo 非 createBatch | MesSalesOutboundServiceImpl.java |
| PurchaseReceiptItem 有 batchNo 字段 | 否（需加） | ✅ 当前无 | MesPurchaseReceiptItem.java L1-50 |
| CompletionReceiptItem 有 batchNo 字段 | 否（需加） | ✅ 当前无 | MesCompletionReceiptItem.java L1-33 |
| MesBatch Entity 有 batchNo 字段 | 是 | ✅ L33 VARCHAR(50) NOT NULL | MesBatch.java |
| 现有唯一索引 | uk_batch_no_del (batch_no, del_flag) | ✅ L29 DDL | V8.0.0__mes_batch_init.sql |
| V9.0.1 PREPARE 模式 | information_schema + PREPARE | ✅ L7-15 | V9.0.1__mes_finance_p0_fix.sql |
| JMaterialSelect emit record | 含 batchEnabled | ✅ `emit('change', { value, label, record })` | JMaterialSelect.vue L57 |
| ReceiptDrawer itemColumns 结构 | 静态数组 | ✅ L81-90 | ReceiptDrawer.vue |
| CompletionReceiptDrawer itemColumns | 静态数组 | ✅ L57-62 | CompletionReceiptDrawer.vue |
