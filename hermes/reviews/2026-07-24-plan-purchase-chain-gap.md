# 采购链路补齐方案 — 架构评审报告

> 评审日期：2026-07-24 | 评审人：Claude (架构评审视角)
> 方案文件：`.claude/plans/purchase-chain-gap-fix.md`
> 状态：**NEEDS WORK** (3 个阻断问题需解决，2 个高优先级补充)

---

## 一、总体评价

方案方向正确，缺口识别基本完整。但存在 **1 个状态模型根本性不一致**、**1 个关键字段缺失（编码生成）**、和 **1 个方案选择已被代码强制收敛**。以下逐项展开。

---

## 二、缺口分析完整性

### 已识别的缺口 (✅ 5/5)

| # | 缺口 | 方案覆盖 | 评价 |
|---|------|:--:|------|
| P0-1 | 订单无 `purchaseApplyId` | SQL+Entity | ✓ |
| P0-2 | 审核后不生成订单 | audit 追加逻辑 | ⚠️ 状态模型冲突 (见§三) |
| P0-3 | 搜索无申请单号 | 前端 searchForm+columns | ✓ |
| P1-4 | 申请无驳回 | reject API+Mapper | ✓ |
| P2-5 | 行单价无自动带出 | validateApply 补充 | ✓ |

### 遗漏的缺口 (❌ 4 个)

| # | 遗漏项 | 严重度 | 说明 |
|---|--------|:--:|------|
| 🔴 G1 | **自动生成订单的编码问题** | **P0** | `saveWithItems` 要求 `code` 非空。自动生成的订单没有编码——方案未提及如何获取编码。申请有 `mes_code_rule_PA`(前缀SQ)，订单应有对应的 `mes_code_rule_PO`。需确认编码规则是否已注册，并在 `generateDraftPurchaseOrder` 中调用 `getNextCode`。 |
| 🟡 G2 | **订单 `purchaseType` 缺失** | **P1** | 订单实体有 `purchaseType` 字段，但申请实体没有。自动生成订单时，`purchaseType` 应如何赋值？选项：A) 申请加 `purchaseType`；B) 默认值兜底。需在方案中明确。 |
| 🟡 G3 | **申请反审核 (unaudit) 缺失** | **P1** | 采购订单已有 `unauditWithGuard` (3→1)。如果申请审核后自动生成了订单，反审核申请时如何处理已生成的订单？方案未提及。建议：unaudit 时检查是否存在关联订单（`purchaseApplyId`），若订单仍在草稿(1)则允许反审核并同步作废订单；若订单已确认则禁止反审核。 |
| 🟢 G4 | **申请行 `taxRate` 缺失** | P2 | 订单行有 `taxRate`（默认 0.13），但申请行没有。自动生成订单行时税率为空。可接受为 P2，前端后续可补充。建议临时方案：默认 0.13。 |

---

## 三、方案 A vs 方案 B 分析：A 胜出且已被代码强制

### 结论：方案 A（申请加 supplierId）是唯一选择

**证据**：`MesPurchaseOrderServiceImpl.validateOrder()` 第 192 行：

```java
if (!StringUtils.hasText(entity.getSupplierId())) throw new JeecgBootException("供应商不能为空");
```

`saveWithItems` 内部调用 `validateOrder`，若 `supplierId` 为空则直接抛异常。**方案 B（留空让用户补填）在技术上行不通**，除非修改 `validateOrder` 加条件分支（"自动生成时跳过 supplierId 校验"），但这会引入技术债务和安全隐患。

### 方案 A 的优势

1. **业务合理性**：申请阶段就应指定向谁采购——这是标准采购 SOP
2. **代码复用**：不需要修改 `saveWithItems` 的校验逻辑
3. **前端一致性**：生成的订单在列表中可以正确显示供应商名称（通过 `@Dict` 注解）

### 方案 A 的实施要点

- SQL: `ALTER TABLE c_mes_purchase_apply ADD COLUMN supplier_id varchar(32) COMMENT '供应商ID'`
- Entity: `MesPurchaseApply` + `supplierId` 字段，加 `@Dict(dictTable = "c_mes_supplier", ...)`
- 前端: `apply.data.ts` formSchema 加供应商选择（`JSearchSelect` 或 `ApiSelect`）
- 生成订单时：`order.setSupplierId(apply.getSupplierId())`

---

## 四、核心问题：状态模型不一致 (🔴 CRITICAL)

### 现状 vs 方案 vs 代码 — 三者冲突

| 来源 | audit 目标状态 | 状态流转 |
|------|:--:|------|
| **DDL 字典 V6.0.0** | — | 1草稿→2已提交→3已通过→4已驳回 |
| **代码 `auditWithGuard`** | **'2' (已提交)** | `SET status = '2' WHERE status = '1'` |
| **方案文档描述** | **'3' (已通过)** | "1草稿→3已通过(有audit, 无reject)" |
| **采购订单模式 (对标)** | **'3' (已确认)** | `SET status = '3' WHERE status = '1'` |

### 问题分析

当前代码的 `auditWithGuard` 将申请从 `'1'` 草稿 → `'2'` 已提交（待审批），**不是已通过**。但方案说"审核后自动生成订单"，隐含 audit = approve，应设状态为 `'3'`。

如果按当前代码 (1→2)，则：
- 订单生成发生在"提交"阶段，不发生在"审批通过"阶段 — 语义矛盾
- `loadApplyItemsForOrder` 已经校验 `status == '2'` — 与当前代码一致，但与方案意图不符

如果改为 (1→3)，则：
- 需要修改 `auditWithGuard` SQL：`SET status = '3'` 
- `loadApplyItemsForOrder` 的校验也要改为 `status == '3'`
- 状态 '2' (已提交) 将变为未使用（类似采购订单中 '2' 待确认也被跳过）

### 建议：统一为采购订单模式 (1→3)

**理由**：
1. 采购订单已有先例：`auditWithGuard` 直接 1→3，跳过 2 (待确认)
2. 采购申请的业务场景不需要"提交审核"中间态——申请人提交即等于审批通过
3. 如未来需要多级审批，应走 BPM 工作流而非状态机

**修改清单**：
```java
// MesPurchaseApplyMapper.auditWithGuard — 改为：
@Update("UPDATE c_mes_purchase_apply SET status = '3', ... WHERE id = #{id} AND status = '1'")

// MesPurchaseOrderServiceImpl.loadApplyItemsForOrder — 改为：
if (!"3".equals(apply.getStatus())) throw ...  // '2' → '3'
```

**reject 端点**：audit→3 后，reject 应守卫 `status = '1'`（驳回草稿申请），即 `WHERE status = '1'` → `SET status = '4'`。

> ⚠️ 此修改需与产品确认：是否接受"跳过已提交中间态"的简化设计。

---

## 五、receivedQty 初始化分析：无坑但需确认

### 结论：初始化安全

**证据链**：

1. **DDL** (`V9.5.3`): `received_qty DECIMAL(18,4) DEFAULT 0` — 数据库层默认 0
2. **Entity** (`MesPurchaseOrderItem`): `private BigDecimal receivedQty;` — Java 层无默认值，为 null
3. **方案行为**: `generateDraftPurchaseOrder` 逐行复制申请行 → 创建 `MesPurchaseOrderItem`，未提及设置 `receivedQty`

### 风险分析

- **写入时**：`itemMapper.insert(item)` — receivedQty 为 null，数据库写入 NULL，覆盖 DEFAULT 0
- **入库扣减时**：`atomicReceive` 使用 `received_qty + #{qty} <= quantity`，若 received_qty 为 NULL 则 SQL 结果为 NULL，条件永远不成立 → **原子扣减静默失败**

### 修复

生成订单行时必须显式设置 `receivedQty = BigDecimal.ZERO`：

```java
MesPurchaseOrderItem orderItem = new MesPurchaseOrderItem();
orderItem.setReceivedQty(BigDecimal.ZERO); // ← 必须显式设 0
```

> 这是采购订单 P0-4 `atomicReceive` 在生产中正确运行的**硬前提**。

---

## 六、其他模块影响分析

### 采购链路（直接影响）

| 模块 | 影响 | 变更 |
|------|:--:|------|
| purchase/apply | **改** | +supplierId, audit 改状态, +reject |
| purchase/order | **改** | +purchaseApplyId, 复用现有 saveWithItems |
| purchase/receipt | 无 | receipt 通过 order_id 链接，间接可追溯 apply |
| purchase/ledger | 无 | 台账在 receipt audit 时生成，不感知 apply |
| finance/payable | 无 | 应付在 receipt audit 时生成 |

### 销售链路（参照对比）

| 特征 | 采购链路 | 销售链路 |
|------|---------|---------|
| 上游单据 | 采购申请 | — (销售订单是起点) |
| 自动生成下游 | 申请→订单 (方案新增) | — (无此模式) |
| 下游引用上游 | 订单.purchaseApplyId | — (销售订单无上游引用) |

**结论**：采购链路的"申请→自动生成订单"是新的业务模式，销售链路没有可参考的实现。

### 已有复用资产

- `MesPurchaseApplyItemForOrder` DTO — 已在订单 Service 中使用，`generateDraftPurchaseOrder` 可复用
- `loadApplyItemsForOrder()` — 已实现从申请行加载数据，但当前是给前端手动创建订单用的
- `saveWithItems()` — 已实现完整的保存+校验+resurrect，直接复用

---

## 七、风险矩阵

| # | 风险 | 等级 | 缓解措施 |
|---|------|:--:|------|
| R1 | 状态模型冲突：代码→2 vs 方案→3 | **🔴 CRITICAL** | 统一为 1→3 (见§四)，需产品确认 |
| R2 | 自动生成订单无编码 | **🔴 HIGH** | 确认 `mes_code_rule_PO` 存在 + `getNextCode` |
| R3 | receivedQty=null 导致入库扣减失效 | **🔴 HIGH** | 显式设 `BigDecimal.ZERO` (见§五) |
| R4 | 申请反审核无处理 | **🟡 MEDIUM** | 加 unaudit 守卫 (见§二-G3) |
| R5 | purchaseType 缺失 | **🟡 MEDIUM** | 申请加字段或默认值 (见§二-G2) |
| R6 | audit 幂等性依赖 `purchaseApplyId` 索引 | **🟡 MEDIUM** | SQL 已建 `idx_po_apply`，方案正确 |
| R7 | audit 事务回滚：自动生成订单失败时申请 audit 也回滚 | 🟢 OK | 同一 `@Transactional`，原子性有保障 |
| R8 | 供应商为空时生成订单直接失败 | 🟢 OK | Plan A 解决，supplierId 从申请传递 |
| R9 | 前端 supplierId 下拉组件 | 🟢 LOW | JSearchSelect/ApiSelect，有成熟模式 |

---

## 八、实施建议修正清单

### 方案文档需补充的内容

1. **编码生成** (P0): 明确订单编码来源——调用 `getNextCode(MES_BIZ_CODE.PO)` 还是其他
2. **状态模型** (P0): 确认 audit 目标状态为 '3'，同步修改 `auditWithGuard` SQL 和 `loadApplyItemsForOrder` 校验
3. **receivedQty 初始化** (P0): `generateDraftPurchaseOrder` 中显式设置 `orderItem.setReceivedQty(BigDecimal.ZERO)`
4. **purchaseType** (P1): 明确如何给自动生成的订单赋值
5. **反审核** (P1): 补充 apply unaudit 守卫——存在关联订单时的处理策略

### 涉及文件清单（修正后）

| 层 | 文件 | 变更 |
|---|------|------|
| SQL | `V9.7.1__purchase_order_apply_id.sql` | +purchaseApplyId + idx (方案已有) |
| SQL | `V9.7.1__purchase_apply_supplier.sql` | +supplierId (方案已有) |
| Mapper | `MesPurchaseApplyMapper.java` | **改 auditWithGuard: 1→3** |
| Mapper | `MesPurchaseApplyMapper.java` | +rejectWithGuard: 1→4 |
| Service | `MesPurchaseApplyServiceImpl.audit()` | +generateDraftPurchaseOrder |
| Service | `MesPurchaseOrderServiceImpl.loadApplyItemsForOrder()` | **改 status 校验 2→3** |
| Entity | `MesPurchaseOrder.java` | +purchaseApplyId |
| Entity | `MesPurchaseApply.java` | +supplierId |
| Controller | `MesPurchaseApplyController.java` | +reject() |
| 前端 | `order.data.ts` | +searchFormSchema + columns |
| 前端 | `apply.data.ts` | +supplierId formSchema |

---

## 九、判定：NEEDS WORK

| 维度 | 评级 | 说明 |
|------|:--:|------|
| 缺口分析 | ✅ 良好 | 5/5 主缺口覆盖，4 个遗漏已标注 |
| 方案 A vs B | ✅ **A 必须** | 代码强制，无需纠结 |
| 状态模型 | 🔴 **不一致** | audit→2 vs audit→3，必须统一 |
| 编码生成 | 🔴 **缺失** | 自动生成的订单没有编码来源 |
| receivedQty | 🟡 **小坑** | 不设 ZERO 会导致入库扣减静默失败 |
| 影响面评估 | ✅ 清晰 | 变化局限于采购链路，不影响其他模块 |
| 风险识别 | ✅ 充分 | 9 个风险点已逐一分析 |

**阻塞项** (以下 3 项必须在进入编码阶段前解决)：
1. 🔴 状态模型：确认 audit→3，同步修改 SQL 和校验
2. 🔴 编码生成：确认 PO 编码规则存在 + 生成逻辑
3. 🔴 receivedQty：显式设为 ZERO

**通过后即可进入编码。**
