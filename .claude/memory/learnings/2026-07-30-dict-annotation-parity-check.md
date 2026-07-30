# 跨链路 @Dict 注解一致性扫描（黄金模板对齐前必做）

**场景**：黄金模板对齐涉及关联编码展示（Alert 文案 / 列表列显示关联单号）。一个链路有 `@Dict` 注解能跑，另一个链路漏注解同样代码段失效。

**根因**：
- 后端实体的 `@Dict(dictTable, dicText, dicCode)` 注解是手动添加的
- 跨模块（销售/采购/库存等）相同语义的关联字段（如 purchaseApplyId / salesOrderId）独立维护
- 黄金模板对齐只改前端，但前端依赖后端 `@Dict` 才能让 list 接口带 `_dictText`
- Claude 评审能发现这类"对齐盲点"——但 pi 自己的 plan/brainstorm 阶段不会主动跨模块扫描

**实际踩坑**：

```
销售链路 (V3.0.0/V4.0.0/V5.0.0)：4 关联字段全部有 @Dict ✅
  - MesDeliveryNote.salesOrderId ✓
  - MesSalesOutbound.deliveryNoteId ✓
  - MesSalesOutbound.salesOrderId ✓
  - MesDeliveryNote.warehouseId ✓

采购链路 (V6.0.0/V6.0.1/V6.0.2)：2 关联字段漏 @Dict ❌（阻塞级）
  - MesPurchaseOrder.purchaseApplyId     ← 没 @Dict
  - MesPurchaseReceipt.purchaseOrderId  ← 没 @Dict
```

Claude 评审 plan 时主动 grep 后端 Entity，发现采购链路的 2 个字段缺注解。如果不评审就开干，Alert 文案会显示 UUID 而非业务编码（已发生 fallback 缓解，但列表列只能显示 ID 而非编码）。

**正确处理**：

```bash
# 黄金模板对齐前必做的跨链路扫描
grep -E "@Dict\(dictTable" jeecg-boot/jeecg-boot-module/project-mes/src/main/java/.../{apply,order,receipt,delivery,outbound}/entity/*.java
```

| 检查项 | 方法 |
|---|---|
| 跨链路同语义字段是否都有 @Dict | grep `@Dict(dictTable`，按列名分组对照 |
| list 接口实测 `_dictText` 返回 | 插 1 条演示数据 → curl list → 检查字段 |
| Alert 文案响应式生效 | 打开 Drawer 编辑模式 → 检查文案显示 |

**判断信号**：
- Claude 评审 plan 时反复提醒"前端依赖后端"——往往是 @Dict 不一致
- 看到"`_dictText` 在 list 接口有但 queryById 没有"——也是这次发现的现象（详见 learning 2026-07-30-dict-text-only-on-list）

**避免**：不要相信"黄金模板对齐只动前端"的假设——链路联动依赖后端注解。plan/brainstorm 阶段必须用 grep 扫描所有相关字段。

**实证**：2026-07-30 采购链路黄金模板对齐，阻塞 #1 的 2 字段 5 分钟修复（1 行注解 × 2 文件）。如果不评审就改前端，会出现"代码看起来都对，文案却显示 UUID"的诡异 bug。