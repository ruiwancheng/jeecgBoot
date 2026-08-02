# orca-review 评审报告：批次追溯列表粒度重做（批次级）

> **评审方**：Claude（独立评审终端 term_2d7a42e9）
> **日期**：2026-08-03
> **评审对象**：批次追溯列表从 ledger 级 → batch 级聚合方案
> **结论**：⚠️ 核心方向正确，发现 2 个关键遗漏 + 3 个薄弱环节

---

## 零、现状摸底——发现了一个关键事实

在评审方案前，先查了当前代码的真实状态：

### 当前 traceability 页面的 API 调用链路

```
traceability.api.ts → import { queryBatchList } from '../master/master.api.ts'
                   → /mes/batch/master/list  （批次主档列表，不是追溯端点）
```

**这意味着**：当前"批次追溯"页面实际调用的是**批次主档**的 list 端点（`c_mes_batch`），而不是 `/mes/batch/traceability/list`（`c_mes_batch_ledger`）。

主档端点返回的是 `MesBatch` 记录（batch 级别），而 `traceability.data.ts` 的 columns 定义却包含 `bizType`、`bizNo`、`inQty`、`outQty` 这些 ledger 字段——这些字段在 batch 主档中根本不存在，页面会显示为空。

**同时**，drawer 的 `openDrawer(true, { batchId: record.id })` 中 `record.id` 已经是 batch ID（因为调用的是 master list），所以 drawer 实际上能正确查到批次——这点与任务描述"抽屉空白"矛盾。我怀疑"抽屉空白"可能来自另一个用户路径（比如从其他页面跳转，传了错误的 batchId）。

### 抽屉的真实行为

```ts
// Drawer L87-88:
const batchResp = await queryBatchList({ id: data.batchId, pageSize: 1 });
// → /mes/batch/master/list?id=<batchId> → QueryGenerator → WHERE id = ?
```

如果 `data.batchId` 真的是 `c_mes_batch.id`，QueryGenerator 会构建 `WHERE id = '<batchId>'`，这应该能查到。只有当 `data.batchId` 是 ledger row ID 时才会查不到。

**结论**：抽屉空白的根因实际上取决于用户是从哪个入口点"查看追溯"的。如果从当前的 traceability 页面（走 master list）点，应该不空白；如果从其他页面（走 ledger list）点，就会空白。

---

## 一、8 个待评审问题的逐一回答

### Q1: VO 字段命名一致性（驼峰 vs 下划线）

**判定**：✅ MyBatis 自动映射能处理，但建议用显式 `<resultMap>`

MyBatis 的 `mapUnderscoreToCamelCase` 配置（Spring Boot 默认开启）会自动将 `batch_no` → `batchNo`、`material_id` → `materialId`。聚合别名 `total_in_qty` → `totalInQty`、`ledger_count` → `ledgerCount` 也能自动映射。

**但**，自动映射有两个隐患：
1. 字段名完全依赖别名与 VO 属性名的精确匹配，人工审查容易遗漏
2. 未来如果 VO 字段名与列别名的驼峰转换结果不一致（如 `last_occur_time` → `lastOccurTime` vs 写成 `lastOccurTime`），静默映射为 null，无编译期报错

**建议**：使用显式 `<resultMap id="batchTraceabilityVOMap" type="...MesBatchTraceabilityVO">`，每个字段显式 `<result column="..." property="..."/>`。成本很低（~15 行 XML），收益是编译期可审查。

---

### Q2: @Dict 注解在 VO（非 @TableName 实体）上是否生效？

**判定**：✅ **生效，已验证 DictAspect 源码**

关键代码路径——`DictAspect.checkHasDict()`：

```java
// DictAspect.java L455-464
private Boolean checkHasDict(List<Object> records){
    if(oConvertUtils.isNotEmpty(records) && records.size()>0){
        for (Field field : oConvertUtils.getAllFields(records.get(0))) {
            if (oConvertUtils.isNotEmpty(field.getAnnotation(Dict.class))) {
                return true;
            }
        }
    }
    return false;
}
```

`oConvertUtils.getAllFields(records.get(0))` 反射读取运行时对象的实际 class——**不检查 `@TableName`**。只要 VO 的字段上有 `@Dict` 注解，DictAspect 就会：
1. 在 `parseDictText` 中收集所有 `@Dict` 字段
2. 批量调用 `commonApi.translateDictFromTableByKeys()` 翻译
3. 回填 `_dictText` 后缀字段

**但有一个前提**：Controller 返回类型必须是 `Result<IPage<MesBatchTraceabilityVO>>`（切点匹配 `execution(public org.jeecg.common.api.vo.Result org.jeecg..*.*(..))`），且 `IPage.getRecords()` 中的元素是 `MesBatchTraceabilityVO` 实例。

**结论**：不需要前端 dictText 兜底方案，后端 @Dict 直接生效。

---

### Q3: LEFT JOIN 性能

**判定**：⚠️ **小数据量安全，但缺少一个关键索引**

当前索引：
- `c_mes_batch_ledger`: `idx_bl_batch (batch_id)` — 覆盖 JOIN 的 `l.batch_id = b.id`
- **缺失**：`(batch_id, del_flag)` 复合索引

JOIN 条件是 `l.batch_id = b.id AND l.del_flag = 0`。单列索引 `idx_bl_batch` 只能加速 batch_id 匹配，`del_flag` 过滤需要在回表后再检查。如果大部分 ledger 行都是 `del_flag=1`（软删除），这个开销会增大。

**建议**：加一个复合索引（成本极低，SQL 锚点中加一行）：

```sql
-- 如果索引不存在则创建（幂等）
CREATE INDEX IF NOT EXISTS idx_bl_batch_del ON c_mes_batch_ledger(batch_id, del_flag);
```

但注意 MySQL 5.7 **不支持** `CREATE INDEX IF NOT EXISTS`。替代写法：
```sql
-- 用存储过程判断
DROP PROCEDURE IF EXISTS create_idx_if_not_exists;
DELIMITER //
CREATE PROCEDURE create_idx_if_not_exists()
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.statistics 
                   WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch_ledger' 
                   AND index_name = 'idx_bl_batch_del') THEN
        CREATE INDEX idx_bl_batch_del ON c_mes_batch_ledger(batch_id, del_flag);
    END IF;
END //
DELIMITER ;
CALL create_idx_if_not_exists();
DROP PROCEDURE IF EXISTS create_idx_if_not_exists;
```

对于当前数据量（估计 < 10000 行），不加也问题不大。但随着数据增长，建议现在加。

---

### Q4: 抽屉兼容性

**判定**：✅ 方案正确，但需确认一个前提

抽屉的 `queryBatchList({ id: data.batchId, pageSize: 1 })` 调用的是 `/mes/batch/master/list`（`MesBatch` 实体 → `c_mes_batch` 表）。

新方案中：
- 列表 `/list` 返回 `MesBatchTraceabilityVO`，`id` 字段 = `b.id`（`c_mes_batch.id`）
- `record.id` = batch ID → `openDrawer(true, { batchId: batchId })`
- 抽屉 `queryBatchList({ id: batchId })` → `QueryGenerator.initQueryWrapper(MesBatch)` → `WHERE id = '<batchId>'` → ✅ 能查到

**前提**：`QueryGenerator.initQueryWrapper` 对于 `id` 参数的处理是精确匹配。已验证——`QueryGenerator` 默认对实体字段做 `eq` 匹配（除非参数名带 `_begin`/`_end` 等后缀），所以 `id=<batchId>` 会生成 `WHERE id = ?`。

**另外**：抽屉还调用 `listLedgerByBatchId({ batchId })` → `/mes/batch/ledger/listByBatchId?batchId=xxx`。这个端点在 `MesBatchLedgerController` 中已经实现了（`QueryWrapper.eq("batch_id", batchId)`），不需要改。

**结论**：抽屉不改也能工作。如果能同时跑，建议把 `queryBatchList` 调用改为直接用 batch ID 查单条（减少一次分页查询开销），但非必需。

---

### Q5: 导出 Excel 同步改动

**判定**：⚠️ **需要改，但计划不够具体**

当前状态：
- `traceability.api.ts` 的 `getExportUrl()` → `/mes/batch/master/exportXls`（主档导出）
- Controller 的 `/exportXls` 用 `super.exportXls(...)` + `MesBatchTraceability`（ledger 实体）

改动后的问题：如果列表已是 batch 级聚合数据，导出应该是同样的 batch 级视图。需要：

1. **新导出端点**在 Controller 中：不走 `super.exportXls`（EasyPoi 依赖实体注解），改为手动构建导出数据（调 `queryBatchPage(pageSize=1000)` + 写入 Excel）
2. **或者**：给 `MesBatchTraceabilityVO` 加 `@Excel` 注解，让它也能被 EasyPoi 导出
3. **前端** `getExportUrl()` 也需要从 `/mes/batch/master/exportXls` 改为新端点

建议用方案 2（VO 加 @Excel 注解），与项目导出模式一致。

---

### Q6: 测试场景覆盖

**判定**：✅ 场景较全面，补充 2 个边界

补充：
1. **排序测试**：列表默认按 `last_occur_time DESC` 排序，确认有流水的批次排在无流水批次前面（LEFT JOIN 导致 `last_occur_time = NULL` 的批次排序行为：MySQL 默认 NULL 排在最后）
2. **搜索测试**：`batchNo` 搜索是模糊匹配（`LIKE '%xxx%'`）还是精确匹配？如果是自定义 Mapper 而非 QueryGenerator，需要自己在 SQL 里处理 `WHERE b.batch_no LIKE CONCAT('%', #{batchNo}, '%')`

---

### Q7: SQL 兼容性与幂等性

**判定**：✅ 无新 DDL 无风险。索引建议见 Q3。

---

### Q8: 回归影响

**判定**：⚠️ 有一个未注意到的回归点

`MesBatchTraceabilityController` 继承 `JeecgController<MesBatchTraceability, IMesBatchTraceabilityService>`。

如果 `/list` 改为返回 `Result<IPage<MesBatchTraceabilityVO>>`：
- 与父类的泛型不一致（父类期望 `MesBatchTraceability`，你返回 `MesBatchTraceabilityVO`）—但这在 Java 泛型擦除后**不会报错**，只是类型不安全
- `/exportXls` 如果继续用 `super.exportXls(...)`，仍用 `MesBatchTraceability` 实体，不受影响
- **最关键**：旧 `MesBatchTraceability` 实体（`@TableName("c_mes_batch_ledger")`）保留不删是正确的——export 和未来的 detail 端点可能还需要它

**外部调用检查**：
- 前端 `traceability.api.ts` 的 `queryBatchList` 实际 import 自 `master.api.ts` → 不调 `/mes/batch/traceability/list`
- 没有其他模块引用 `MesBatchTraceabilityController`
- 权限码 `mes:batchTraceability:list` 已注册，不受影响

---

## 二、方案 3 个最薄弱环节

### 🔴 薄弱点 1：前端 API 调用链路混乱（最高优先级）

**严重度**：P0（计划未察觉的关键事实）

当前 `traceability.api.ts` 的 `queryBatchList` 实际 import 自 `master.api.ts`，列表页调用的是 `/mes/batch/master/list`（批次主档），**不是** `/mes/batch/traceability/list`。

方案中"列表接口从 ledger 级 → batch 级聚合"的假设前提是"当前列表是 ledger 级"，但实际代码中列表调的是 master（batch 级）。这意味着：

1. 后端改造 `/mes/batch/traceability/list` 为 batch 级聚合后，**前端如果不改 api.ts 的 import，列表不会有任何变化**（仍然调 master 端点）
2. 前端改 api.ts 后，columns 必须同步改为 batch 级聚合字段（`totalInQty`、`totalOutQty`、`ledgerCount`、`lastOccurTime`），否则会显示空白列

**修复**：在计划的文件 #7-8 中，明确写清楚：
- `traceability.api.ts`：**新增** `queryTraceabilityList` 函数（调 `/mes/batch/traceability/list`），替代当前从 master 重导出的 `queryBatchList`
- `traceability.data.ts`：columns **全部重写**为 batch 聚合字段
- `index.vue`：`useListPage` 的 `api` 从 `queryBatchList` 改为新函数

### 🟡 薄弱点 2：Controller 泛型不一致的隐藏风险

**严重度**：P1（现在不报错，未来可能报错）

`JeecgController<MesBatchTraceability, IMesBatchTraceabilityService>` 的泛型 `<T>` 在父类方法签名中多处使用。如果 `/list` 返回 `Result<IPage<MesBatchTraceabilityVO>>` 而不是 `Result<IPage<MesBatchTraceability>>`：

- 编译器不会报错（Java 泛型擦除）
- 但父类其他方法（如 `exportXls`）仍然依赖 `<T>` 类型，如果未来有人重构父类加了泛型约束，可能冲突

**建议**：
- 方案 A（推荐）：`/list` 方法不 override 父类，独立声明返回类型
- 方案 B：Controller 不再继承 `JeecgController`，改为独立 Controller（更干净但改动大）

当前用方案 A 即可。

### 🟡 薄弱点 3：exportXls 端点改造范围被低估

**严重度**：P1（导出按钮放在列表页，用户期望导出的数据与列表一致）

当前 `/exportXls` 用 `super.exportXls()`（EasyPoi → 读 `MesBatchTraceability` 的 `@Excel` 注解 → 导出 ledger 行）。改为 batch 级后：

1. `MesBatchTraceabilityVO` 需要加 `@Excel` 注解（不然 EasyPoi 不知道列名和顺序）
2. 导出逻辑需要从 `super.exportXls(...)` 改为手动调 `queryBatchPage` + EasyPoi 导出
3. 阈值检查 `service.count()` 需要改为 `COUNT(DISTINCT b.id)`（方案已提到，但没展开实现细节）

工作量比计划中预估的"改 Controller 端点"多——至少需要在 VO 上加 8-10 个 `@Excel` 注解，并在 Controller 中手写导出逻辑（~30 行）。

---

## 三、2 个可立即采纳的改进

### 💡 改进 1：在 traceability.api.ts 中明确区分 master 和 traceability 端点

当前 `queryBatchList` 从 master 重导出是混乱的根源。改为：

```typescript
// traceability.api.ts — 重构后
import { defHttp } from '/@/utils/http/axios';

// 批次追溯：batch 级聚合列表
export function queryTraceabilityList(params: any) {
  return defHttp.get({ url: '/mes/batch/traceability/list', params });
}

// 批次追溯：batch 级导出
export function getTraceabilityExportUrl() {
  return '/mes/batch/traceability/exportXls';
}

// 抽屉用：查批次主档详情（留用 master 端点——语义正确）
export { queryBatchList } from '../master/master.api';

// 抽屉用：查批次流水（留用 ledger 端点——语义正确）
export { listLedgerByBatchId } from '../ledger/ledger.api';  // 如果存在的话
```

这样可以**从命名上区分**"追溯列表"和"主档列表"，避免后续维护者再次混淆。

### 💡 改进 2：加 `(batch_id, del_flag)` 复合索引（成本极低，一次性）

在 SQL 锚点文件中加（MySQL 5.7 兼容写法）：

```sql
-- 幂等创建复合索引，加速 LEFT JOIN c_mes_batch_ledger ON l.batch_id = b.id AND l.del_flag = 0
DROP PROCEDURE IF EXISTS mes_add_batch_ledger_idx;
DELIMITER //
CREATE PROCEDURE mes_add_batch_ledger_idx()
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.statistics 
                   WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch_ledger' 
                   AND index_name = 'idx_bl_batch_del') THEN
        CREATE INDEX idx_bl_batch_del ON c_mes_batch_ledger(batch_id, del_flag);
    END IF;
END //
DELIMITER ;
CALL mes_add_batch_ledger_idx();
DROP PROCEDURE IF EXISTS mes_add_batch_ledger_idx;
```

此索引同时惠及 ledger 模块自身的 `listByBatchId` 查询（也是 `WHERE batch_id = ? AND del_flag = 0`）。

---

## 四、文件清单修正

原计划的 10 个文件需要修正为实际可执行的清单：

| # | 路径 | 改动 | 备注 |
|---|------|------|------|
| 1 | **NEW** `MesBatchTraceabilityVO.java` | 新建 batch 级聚合 VO + @Dict + @Excel | — |
| 2 | `MesBatchTraceabilityMapper.java` | + `queryBatchPage` 方法 | — |
| 3 | **NEW** `MesBatchTraceabilityMapper.xml` | GROUP BY SQL + 显式 `<resultMap>` | 当前无 XML 文件 |
| 4 | `IMesBatchTraceabilityService.java` | + `queryBatchPage` 接口方法 | — |
| 5 | `MesBatchTraceabilityServiceImpl.java` | + `queryBatchPage` 实现 | — |
| 6 | `MesBatchTraceabilityController.java` | `/list` 改用 batch 聚合；`/exportXls` 手动导出 | **⚠️ 改动量比计划大** |
| 7 | `traceability.data.ts` | **全部重写** columns（batch 聚合字段） | **⚠️ 不只是"改列"** |
| 8 | `traceability.api.ts` | **拆分** master 重导出 → 新增 traceability 端点函数 | **⚠️ 不只是"调整"** |
| 9 | `index.vue` | `api` 指向新函数；`getExportUrl` 指向新端点 | — |
| 10 | **NEW** `V10.0.3__mes_traceability_batch_level.sql` | 索引 + 版本锚点 | 原计划无 DDL，建议加索引 |

> **实际工作量**：文件 #6-8 的改动量被原计划**低估**了——Controller 需要手写导出逻辑（~30 行），data.ts 需要全部重写 columns（~15 行），api.ts 需要拆分重导出（~10 行）。建议将工期从"轻量"调为"标准"。

---

## 五、总体判定

| 维度 | 评级 | 说明 |
|------|:----:|------|
| 问题分析 | ⚠️ 部分准确 | 抽屉空白的根因分析可能不完全准确（当前代码走 master list，id 可能已经正确） |
| 方案设计 | ✅ 正确 | batch 级聚合是正确的业务方向 |
| 前端现状理解 | 🔴 遗漏 | 未察觉 api.ts 实际调的是 master 端点而非 traceability 端点 |
| 实施细节 | ⚠️ 需补充 | exportXls 手动导出 + VO @Excel 注解的细节未展开 |
| @Dict 可行性 | ✅ 确认 | DictAspect 反射运行时 class，不依赖 @TableName，VO 可用 |

**最终建议**：方案可以实施，但必须先解决薄弱点 1（前端 API 调用链路）——这是整个方案的前提假设，如果忽略会导致"后端改完了前端还是老行为"。建议实施顺序：

1. 先确认当前 drawer 到底在哪里空白（从哪个入口点"查看追溯"），用实际数据验证根因
2. 创建 VO + Mapper + Service（后端 batch 聚合）
3. 改前端 api.ts 拆分 + data.ts 重写（确保新端点被正确调用）
4. 改 Controller（包括 exportXls 手动导出）
5. SQL 锚点（含索引）
6. 测试 + 回归验证
