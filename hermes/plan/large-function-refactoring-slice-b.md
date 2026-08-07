# 大型函数拆分 Slice B（harness-check 第 8 轴扣分修复）

**作者**：pi
**日期**：2026-08-06
**前置**：harness-check 第 8 轴扣分（-2.5），5 个 project-mes 函数 >75 行
**目标范围**：拆分 5 个超大函数至 ≤50 行

---

## 1. 现状（5 个 >75 行函数）

| # | 函数 | 行数 | 文件 |
|---|---|---:|---|
| 1 | `MesMenuRegistry.buildMenus` | 149 | config/init/MesMenuRegistry.java |
| 2 | `MesPurchaseReceiptServiceImpl.audit` | 118 | purchase/receipt/service/impl/ |
| 3 | `MesSalesOutboundServiceImpl.audit` | 92 | sales/service/impl/ |
| 4 | `MesSalesOutboundServiceImpl.validate` | 92 | sales/service/impl/ |
| 5 | `MesStocktakeServiceImpl.audit` | 86 | stock/service/impl/ |

---

## 2. 拆分方案

### 函数 1：buildMenus → 按业务域拆 7 个私有方法

**当前**：1 个 149 行方法，按 7 大业务域顺序注册菜单。

**目标**：
```java
private static List<MesMenuDefinition> buildMenus() {
    List<MesMenuDefinition> list = new ArrayList<>();
    list.add(MesMenuDefinition.folder("mes_menu_001", ...)); // MES 根
    buildBasicMenus(list);      // 基础设置
    buildProductMenus(list);    // 商品
    buildWarehouseMenus(list);  // 仓储管理
    buildPurchaseMenus(list);   // 采购管理
    buildSalesMenus(list);      // 销售管理
    buildManufacturingMenus(list); // 生产管理
    buildFinanceMenus(list);    // 财务
    return list;
}
```

每个 `buildXxxMenus(List)` 控制在 ≤25 行。

### 函数 2-5：audit / validate → 按状态机拆 3-4 个私有方法

**当前模式**：1 个 audit 方法处理所有状态（草稿→提交→审核/反审核），内部大段 if-else。

**目标模式**（**P1-1 修正**：业务模型是 draft-to-audit 单步，**无 submitted 中间态**，改名 `executeStatusGuard` 匹配 `baseMapper.auditWithGuard` 语义）：
```java
public void audit(String id) {
    MesPurchaseReceipt entity = getById(id);
    validateAuditPreconditions(entity);
    executeStatusGuard(entity);      // status 1 → 2，原子化
    applyAuditSideEffects(entity);   // 库存扣减、应付生成等
    save(entity);
}

private void validateAuditPreconditions(MesPurchaseReceipt entity) { ... }
private void executeStatusGuard(MesPurchaseReceipt entity) { ... }
private void applyAuditSideEffects(MesPurchaseReceipt entity) { ... }
```

**P1-2 关键修正**：audit 内层 for 循环遍历 items 是 70+ 行（atomicReceive → updateMovingAvgCost → inventoryService.stockIn → batchService → itemMapper.updateById），单拆 3 个方法不够。**需要二级拆分**：
```java
private void applyAuditSideEffects(MesPurchaseReceipt entity) {
    for (MesPurchaseReceiptItem item : entity.getItems()) {
        applySingleItemSideEffects(item);   // 每个 item 的副作用 ≤30 行
    }
    persistAfterItems(entity);              // 后续持久化 ≤20 行
}

private void applySingleItemSideEffects(MesPurchaseReceiptItem item) { ... }
private void persistAfterItems(MesPurchaseReceipt entity) { ... }
```

每个私有方法 ≤30 行。

---

## 3. 执行策略

**5 个函数 = 3 个 commit**（**P1-3 修正**：5 commits 太碎，2 个 MesSalesOutbound 方法必须在同 commit 避免中间态）：

1. **Commit 1**：MesMenuRegistry.buildMenus 拆分（无业务逻辑，仅结构）
2. **Commit 2**：MesSalesOutboundServiceImpl（audit + validate 同文件同 commit）
3. **Commit 3**：MesPurchaseReceipt + MesStocktake（2 个 service audit，跨文件同 commit）

每个 commit 后 `mvn compile -pl project-mes -am` 验证。

**P2-4 修正**：保留所有 update-begin/end 历史 markers，拆分时不能截断或合并多个 marker 区域。

---

## 4. 风险

| 风险 | 缓解 |
|---|---|
| 行为变化（重构引入 bug）| 单元测试 + mvn compile 通过 |
| 性能回退（方法调用开销）| Java JIT 内联，< 1% 影响 |
| 调试栈变深 | 私有方法命名清晰 |

---

## 5. 验收

- [ ] 5 个函数每个 ≤50 行
- [ ] mvn compile -pl project-mes 通过
- [ ] 测试覆盖率不下降（项目目前无强制覆盖率，按现有测试通过为准）
- [ ] harness-check 第 8 轴从 2.5/5 恢复到 5/5

---

## 6. 不做的（Out of Scope）

- 拆 MesMenuDefinition 等辅助类
- 改方法命名（保留原 audit / validate 公开 API）
- 性能 profiling

---

## 7. 参考

- harness-check 第 8 轴扣分（hermes/reviews/2026-08-06-harness-check-full-8axis.md）
- .claude/rules/code-style.md 函数规范章节

## 8. Plan 修订记录

| 版本 | 日期 | 修订 | 来源 |
|---|---|---|---|
| v1 | 2026-08-06 | 初版 | PI /plan Slice B |
| v2 | 2026-08-06 | 修复 3 P1（orca-review `task_bcc21f7f77c7`）：<br>1. 改名 `transitionToSubmitted` → `executeStatusGuard`（业务无中间态，匹配 auditWithGuard 语义）<br>2. **关键**：audit 内层 for 循环 70+ 行，需二级拆分（applySingleItemSideEffects + persistAfterItems）<br>3. 5 commit → 3 commit（合并 MesSalesOutbound 2 方法 + 合并 purchase+stocktake 跨文件）<br>P2-4：保留 update-begin/end 历史 markers | orca-review `task_bcc21f7f77c7` |