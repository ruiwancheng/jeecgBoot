---
name: design
version: 1.0.0
globs:
  - 'jeecg-boot/jeecg-boot-module/project-mes/**/*.java'
  - 'harness/tests/**/*.js'
  - 'harness/tests/**/*.ts'
---

# 业务设计规则

> MES 批次/库存/单据领域的设计规范（2026-08-01 起从 learnings 沉淀）

## 批次台账设计（batch-ledger-design-rule）

**核心表**：`c_mes_batch_ledger` —— 全局批次流水（跨模块、跨业务来源）

**字段约定**：
- `batch_no`：批次号（业务唯一）
- `material_id`：物料 ID（关联 `c_mes_material`）
- `qty`：数量（DECIMAL(18,4)）
- `unit_cost`：单位成本（移动平均或批次价）
- `source_bill_type`：来源单据类型（PO/InStock/Trans）
- `source_bill_id`：来源单据 ID
- `source_bill_no`：来源单据号
- `in_time`/`out_time`：入库/出库时间
- `remain_qty`：剩余数量（用于 FIFO/LIFO 跟踪）

**强制规则**：
- ✅ **不删除批次记录**（即使数量为 0，加 `remain_qty=0` + `status='depleted'` 标记）
- ✅ **所有批次变动走 SQL 触发器或 Service 层**，不直接 UPDATE
- ✅ **成本计算**用 `c_mes_batch_ledger.unit_cost` 字段，不用物料表的 `moving_avg_cost`（避免双源数据）

详见 `learnings/2026-08-01-batch-ledger-design-rule.md`。

---

## 跨模块 FK + 批次 + 来源单据（cross-module-fk-batch-origin-bill）

**模式**：MES 业务单据**多对一关联批次**，单据项**多对一关联来源单据项**。

**例**：
```
采购入库单 (c_mes_purchase_receipt)
  └─ 明细项 (c_mes_purchase_receipt_item)
       ├─ batch_id → c_mes_batch_ledger.id（批次）
       ├─ material_id → c_mes_material.id（物料）
       └─ source_order_item_id → c_mes_purchase_order_item.id（来源采购订单明细）
```

**强制规则**：
- ✅ 跨模块 FK 加 `ON DELETE RESTRICT`（防止误删）
- ✅ 批次变更追溯：保留 `source_bill_*` 三件套
- ✅ 物料-批次-单据联动查询用 LEFT JOIN（兼容批次未生成场景）

详见 `learnings/2026-08-01-cross-module-fk-batch-origin-bill.md`。

---

## JSearchSelect 表字典绕过 @TableLogic（table-dict-bypasses-tablelogic）

//update-begin---author:evolve---date:2026-08-02---for:【/evolve 批 3】合并 7 月数据库/SQL 1 条 learning 到 design.md---

**问题**：前台下拉选择（JSearchSelect + `dict="c_mes_xxx,text,value"`）显示的选项与对应管理页面列表不一致 —— 列表已软删除的数据仍出现在下拉选项中。

**根因**：`JSearchSelect` 通过 `SysDictController.loadDict()` 加载表字典数据，最终走 `SysDictMapper.xml` 中的**原始 SQL 拼接**：
```sql
SELECT name as "text", id as "value" FROM c_mes_material WHERE name LIKE '%keyword%'
```

这段 SQL 通过 `${table}` `${text}` `${code}` 占位符拼接，**完全绕过 MyBatis-Plus 的 `@TableLogic` 拦截器**，不会自动追加 `WHERE del_flag=0`。而管理页面的 `Controller.list()` 使用 MyBatis-Plus 标准分页，自动获得 `del_flag=0` 过滤。

**结论**：任何使用 `dict="表名,text字段,value字段"` 的表字典选择器，都会显示已逻辑删除的数据。包括物料、仓库、客户、供应商、库位等所有用到 `@TableLogic` 的实体。

**修复方案 A（推荐，不碰平台代码）**：
```java
@GetMapping("/selectPage")
public Result<IPage<MesMaterial>> selectPage(...) {
    QueryWrapper<MesMaterial> qw = new QueryWrapper<>();
    qw.eq("status", 1); // 额外过滤停用
    // MyBatis-Plus 标准分页自动加 del_flag=0
    return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
}
```
+ 前端弹窗组件替换 JSearchSelect。

**修复方案 B（不推荐，违反 file-scope）**：修改 `SysDictServiceImpl.queryLittleTableDictItems()` 或 `SysDictMapper.xml` 加 `del_flag=0`。`jeecg-system-biz` 在受保护目录，**禁止修改**。

详见 `learnings/2026-07-20-table-dict-bypasses-tablelogic.md`。

//update-end---author:evolve---date:2026-08-02---for:【/evolve 批 3】合并 7 月数据库/SQL 1 条 learning 到 design.md------

## 增量增强 + 降级策略模式（2026-08-07 evolve 固化）

> 来源：`memory/learnings/2026-07-20-incremental-enhance-with-degradation.md`
> 核心：Harness 安全演进的基石

### 核心原则

> **演进 ≠ 重写** — 增量增强 + 失败时降级到旧版

### 模式定义

**增量增强（Incremental Enhance）**：
- 不一次性重写旧系统
- 每次迭代只加 1-2 个小功能
- 旧功能保留，新功能叠加

**降级策略（Degradation）**：
- 新功能失败时 → 自动降级到旧版（不报错）
- 业务方永远拿到可用结果
- 失败信息可观测但不阻塞流程

### 适用场景

| 场景 | 增量增强 | 降级策略 |
|---|:---:|:---:|
| 新增多语言 | ✅ | ✅（中文 fallback）|
| 新增搜索优化 | ✅ | ✅（旧 SQL 兜底）|
| 新增数据源 | ✅ | ✅（旧数据源 fallback）|
| 新增 API 端点 | ✅ | ❌（不影响旧路径）|
| 替换核心算法 | ❌ | ❌（应该重写）|

### 实施模式

```typescript
// 模式 A：try-catch 降级
async function enhancedSearch(keyword: string) {
  try {
    return await newSearchEngine.search(keyword);  // 新版
  } catch (e) {
    log.warn('new search failed, fallback', e);
    return await oldSearchEngine.search(keyword);  // 旧版 fallback
  }
}

// 模式 B：特性开关
const useNewFeature = featureFlag.isEnabled('new-search');
return useNewFeature 
  ? newSearchEngine.search(keyword)
  : oldSearchEngine.search(keyword);

// 模式 C：A/B 测试
if (Math.random() < 0.1) {  // 10% 流量
  return newSearchEngine.search(keyword);  // 新版
}
return oldSearchEngine.search(keyword);  // 90% 旧版
```

### 黄金法则

1. **新功能必须可降级** — 不能让业务方承担新功能的失败风险
2. **降级路径必须测试** — 旧版 fallback 路径必须有测试覆盖
3. **可观测性必备** — 降级发生时要 log + metric，业务方可感知
4. **开关可控** — 紧急情况可一键关闭新功能回滚

### 反模式

- ❌ **直接替换旧代码** — 出问题无法回滚
- ❌ **新功能失败抛错** — 业务方被卡住
- ❌ **降级路径不测** — fallback 失效导致 100% 不可用
- ❌ **降级不通知** — 业务方不知道在用旧版

### Harness 实战

- **2026-07-20 /evolve 批 1**：批量归档 5 条 learnings，每条都先增量写 rules，再验证功能不回归
- **2026-07-22 /evolve 批 2**：先 parallel-write，然后逐条确认
- **2026-07-30 /evolve 批 3**：合并 design.md，每条都标注 //update-begin---author---date---for:---

**核心**：Harness 演进不能破坏现有功能，**降级策略是底线**。

详见 `memory/learnings/2026-07-20-incremental-enhance-with-degradation.md`。
//update-end---author:evolve---date:2026-08-07---for:【/evolve】增量增强+降级策略模式---
