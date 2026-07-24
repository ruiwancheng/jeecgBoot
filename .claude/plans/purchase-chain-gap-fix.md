# 采购链路补齐方案

> 状态：/brainstorm | 日期：2026-07-24

## 背景

采购三模块（申请→订单→入库）链路存在关键断裂：申请审核后不自动生成订单，两表无外键关联，无法按申请单号追溯订单。

## 现状诊断

### 数据关联

```
采购申请 ──❌── 采购订单 ──✅── 采购入库
  ↑                  ↑              ↑
  无外键       purchaseOrderId   订单↔入库已有
```

### 状态机

```
申请: 1草稿→3已通过(有audit, 无reject)
订单: 1草稿→2待确认→3已确认→4部分到货→5已到货→6已关闭 (有audit+unaudit)
入库: 1草稿→2已入库 (有audit+unaudit)
```

### 缺口清单

| # | 缺口 | 严重度 |
|---|------|:--:|
| 1 | 申请审核后不自动生成订单 | P0 |
| 2 | 订单无 `purchaseApplyId`，无法追溯 | P0 |
| 3 | 订单搜索无申请单号 | P0 |
| 4 | 申请无驳回API | P1 |
| 5 | 申请行单价无自动带出 | P2 |

## 实施计划

### P0-1: MesPurchaseOrder 加 purchaseApplyId

**SQL**: `V9.7.1__purchase_order_apply_id.sql`
```sql
-- 存储过程判断列是否存在后 ADD COLUMN
ALTER TABLE c_mes_purchase_order ADD COLUMN purchase_apply_id varchar(32) DEFAULT NULL COMMENT '采购申请单ID';
CREATE INDEX idx_po_apply ON c_mes_purchase_order(purchase_apply_id);
```

**Entity**: `MesPurchaseOrder` +1字段
```java
@Schema(description = "采购申请单ID")
private String purchaseApplyId;
```

### P0-2: audit 自动生成草稿采购订单

**文件**: `MesPurchaseApplyServiceImpl.audit()` — 审核后追加逻辑：

```java
// 审核成功后 → 自动生成草稿采购订单（幂等：已有则跳过）
generateDraftPurchaseOrder(id, username, now);
```

**generateDraftPurchaseOrder** 方法：
1. 查是否已有订单关联此申请 (`purchaseApplyId = applyId`，幂等跳过)
2. 从申请主表取字段 → 创建 `MesPurchaseOrder`（status=1草稿）
   - 供应商：申请单上无供应商字段 → 需加 `supplierId` 到申请单，或设为空让用户补填
   - 订单日期=当前日期，交货日期=申请的需求日期
3. 从申请行逐行复制到订单行 (`MesPurchaseOrderItem`)
   - 物料、数量、单价、金额 — 一一对应
4. 调用 `saveWithItems` 保存

**关键决策**：申请单**没有供应商字段**。两种方案：
- A) 申请单加 `supplierId`，审核时带到订单
- B) 自动生成的订单 `supplierId` 留空，用户在订单页面补选

> 推荐 **方案 A**：申请阶段就要选供应商，符合采购业务常识。

### P0-3: 前端搜索 + 展示

**订单搜索** (`order.data.ts` searchFormSchema):
```typescript
{ field: 'purchaseApplyId', label: '申请单号', component: 'Input', colProps: { span: 6 } }
```

**订单列表** (`order.data.ts` columns):
```typescript
{ title: '申请单号', dataIndex: 'purchaseApplyId', width: 130 }
```

### P1-4: 申请驳回 API

**文件**: `MesPurchaseApplyController.reject()` + `Mapper.rejectWithGuard()`
```java
// Mapper:
@Update("UPDATE c_mes_purchase_apply SET status='4', update_by=#{updateBy}, update_time=#{updateTime} WHERE id=#{id} AND status='2'")
int rejectWithGuard(@Param("id") String id, ...);
```

### P2-5: 申请行单价自动带出

在 `validateApply` 中加逻辑：如果行单价为空 → 从物料 `lastPurchasePrice` 取值。

---

## 涉及文件

| 层 | 文件 | P0 | P1 | P2 |
|---|------|:--:|:--:|:--:|
| SQL | `V9.7.1__purchase_order_apply_id.sql` | ✅ | | |
| SQL | `V9.8.0__purchase_apply_supplier.sql` (如选方案A) | ✅ | | |
| Entity | `MesPurchaseOrder.java` +purchaseApplyId | ✅ | | |
| Entity | `MesPurchaseApply.java` +supplierId (方案A) | ✅ | | |
| Mapper | `MesPurchaseApplyMapper.xml` +rejectWithGuard | | ✅ | |
| Service | `MesPurchaseApplyServiceImpl.audit()` +generateDraftOrder | ✅ | | |
| Controller | `MesPurchaseApplyController.reject()` | | ✅ | |
| 前端 | `order.data.ts` searchFormSchema + columns | ✅ | | |
| 前端 | `apply.data.ts` formSchema +supplierId (方案A) | ✅ | | |

## 验证

```bash
# 1. 创建采购申请 → 审核 → 验证自动生成了草稿订单
curl POST /mes/purchase/apply/add → GET order/list?purchaseApplyId=xxx

# 2. 验证订单可追溯到申请
curl GET /mes/purchase/order/list?purchaseApplyId=xxx

# 3. 驳回申请
curl PUT /mes/purchase/apply/reject?id=xxx
```
