# MES 业务链路测试报告

**日期**：2026-08-04
**范围**：核心业务链路
**暴露真 bug**：2 个 P1（之前所有测试都没暴露）

## 一、链路覆盖

| 链路 | 步骤数 | 通过率 | 暴露问题 |
|---|:-:|:-:|---|
| 采购 → 入库 → 付款 | 19 | 86.4% | 🔴 1 个 P1 |
| 销售 → 出库 → 收款 | 9 | 69.2% | 🔴 1 个 P1 |

## 二、🔴 P1-1: 采购入库审核触发 SQL 异常

**调用**：
```bash
PUT /mes/purchase/receipt/audit?id=...
```

**期望**：入库审核成功 + 库存增加 + 应付单生成

**实际**：
```sql
### Error updating database.  Cause: java.sql.SQLException: Field 'supplier_id' doesn't have a default value
### The error may exist in org/jeecg/modules/mes/finance/payable/mapper/MesPayableMapper.java (best guess)
```

**根因**：
- 采购入库审核 service 同时要写**应付单**（c_mes_payable）
- 应付单生成 SQL 需要 `supplier_id`
- 但 `c_mes_purchase_receipt` 表**没有 supplier_id 字段**
- 入库单表只通过 `purchase_order_id` 关联到 `c_mes_purchase_order`，再间接关联到 `c_mes_supplier`
- SQL INSERT 时 supplier_id 为 NULL 且字段没默认值 → 报错

**修复方向**：
- **选项 A**（推荐）：采购入库单 add 时校验 / 补 supplier_id（从 order 拉）
- **选项 B**：应付单生成时 JOIN 关联查询 supplier_id（不存到 receipt 表）
- **选项 C**：应付单生成时改为 UPDATE ... SET supplier_id=(SELECT supplier_id FROM order WHERE order_id=?)

**影响**：所有采购入库审核都失败 → 入库链路断 → 库存不会自动增加 → 整个采购流程断

**之前没暴露原因**：之前测试都是只调 add/list 接口，没调 receipt/audit。

## 三、🔴 P1-2: 客户列表查询 SQL 异常

**调用**：
```bash
GET /mes/basic/customer/list?pageSize=200
```

**期望**：返回客户列表

**实际**：
```sql
### Error querying database.  Cause: java.sql.SQLSyntaxErrorException: Unknown column 'grade' in 'field list'
### The error may exist in org/jeecg/modules/mes/basic/mapper/MesCustomerMapper.java
```

**根因**：**Schema 与实体不同步**

**DB 实际字段**（c_mes_customer）— 14 列：
```
id, code, name, type, contact, phone, address, status, remark, 
create_by, create_time, update_by, update_time, del_flag
```

**MesCustomer 实体字段** — 20 列（差 6 列）：
```
实体有但 DB 无：
- grade（等级）
- creditLimit（信用额度）
- salesmanId（销售员ID）
- industry（行业）
- region（地区）
- scale（规模）
```

**修复方向**：
- 检查最近的 entity 改动 + 是否有对应的 SQL 迁移脚本
- 写一个迁移脚本：
  ```sql
  ALTER TABLE c_mes_customer
    ADD COLUMN grade VARCHAR(50),
    ADD COLUMN credit_limit DECIMAL(18,4),
    ADD COLUMN salesman_id VARCHAR(32),
    ADD COLUMN industry VARCHAR(50),
    ADD COLUMN region VARCHAR(50),
    ADD COLUMN scale VARCHAR(50);
  ```

**影响**：所有客户列表/分页查询都失败 → 销售下单选客户断 → 销售链路断

**之前没暴露原因**：之前 finance.test.js 没测 customer，sales-api.test.js 用了其他字段过滤。

## 四、链路测试其他失败（P3 测试代码问题）

### 采购链路
- ✅ 18/22：所有 setup + 创建/审核都通过
- ❌ 3 个失败全是 P1 真 bug（P1-1）

### 销售链路
- ❌ 0.3 创建客户：P1-2 真 bug
- ❌ 1.1 创建销售订单：客户 ID 为空（级联 P1-2）
- ❌ 5.1/5.3 库存对账：级联（销售订单没创建 → 出库没做）
- ❌ 7.1 创建收款单：金额超出未结金额（因为应收单是历史数据，不关联本次）

## 五、测试设计教训

1. **回归测试必须跑完整链路**：单接口 200 不能代表业务可用
2. **审核是关键节点**：add/list 看似正常，audit 才是真业务触发点
3. **跨表对账**：库存 vs 台账 vs 应付/应收 — schema 不一致会暴露在跨表查询
4. **实体 vs schema 同步**：实体加字段必须同步 DB schema（迁移脚本）
5. **关联字段缺失**：入库单没 supplier_id，但应付单需要 — 这是设计缺陷

## 六、原始日志

`hermes/eagle-eye/state/api-logs/purchase-payment-flow.log`
`hermes/eagle-eye/state/api-logs/sales-receipt-flow.log`