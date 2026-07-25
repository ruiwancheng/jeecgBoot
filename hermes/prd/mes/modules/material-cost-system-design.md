# MES 物料成本价体系设计方案

> 状态：/brainstorm 产出 | 日期：2026-07-24 | 基于当前代码库 V9.6.0

## 一、现状诊断

### 1.1 已有价格相关实体

| 实体 | 表 | 价格字段 | 定位 |
|------|------|---------|------|
| `MesMaterial` | `c_mes_material` | `standardPrice` (BigDecimal) | 物料标准**售价**（基准） |
| `MesCustomerPrice` | `c_mes_customer_price` | `price` + `minQty`/`maxQty` | 客户协议价（阶梯量价） |
| `MesPrice` | `c_mes_price` | `price` + `customerId` + `beginDate`/`endDate` | 销售价格管理（有时效） |
| `MesSalesOrderItem` | `c_mes_sales_order_item` | `unitPrice` + `amount` + `taxRate`/`taxAmount` | 销售执行价 |
| `MesPurchaseOrderItem` | `c_mes_purchase_order_item` | `unitPrice` + `amount` + `taxRate` | 采购执行价 |
| `MesPurchaseReceiptItem` | `c_mes_purchase_receipt_item` | `unitPrice` + `amount` | 入库执行价（审核时从采购订单行取） |

### 1.2 缺失的关键能力

| 缺失项 | 影响 |
|--------|------|
| **物料成本价字段** | 无法记录"这个物料进来花了多少钱" |
| **库存台账无金额** | `MesInventoryLedger` 只有数量（期初/入库/出库/期末），没有金额，无法计算库存成本 |
| **无成本计价方法** | 没有移动加权平均/先进先出/月加权平均等算法 |
| **采购入库不写成本** | `stockIn()` 只传 `materialId + warehouseId + qty`，不传单价金额 |
| **生产无成本归集** | BOM 投料没有成本卷算，完工入库没有成本核算 |
| **销售无成本结转** | 出库时不知道这批发出了多少成本，无法算毛利 |

### 1.3 现有价格流（仅销售侧）

```
物料.standardPrice ──→ 销售订单.unitPrice（兜底）
MesPrice.findActivePrice() ──→ 销售订单.unitPrice（优先级高）
客户协议价 ──→ 价格表（尚未接入自动带出逻辑）
```

**采购侧完全无成本概念**：采购订单有 `unitPrice` 字段但仅作记录，审核后不入库存成本。

---

## 二、成本价体系设计

### 2.1 核心概念

```
售价（Selling Price）  = 卖给客户的价格     ← 已有（MesPrice, standardPrice）
成本价（Cost Price）    = 买入/生产的价格    ← 本次建设
毛利（Gross Margin）    = 售价 - 成本价       ← 成本到位后自动可得
```

### 2.2 成本归集方式

采用 **移动加权平均法**（更适合 MES 场景——实时性强、逐笔更新、无需月末批处理）。

**为什么不选其他方法：**

| 方法 | 适用场景 | MES 适用性 |
|------|---------|:--:|
| 移动加权平均 | 逐笔更新，实时性强 | ✅ 首选 |
| 月加权平均 | 月末统一计算，简单 | 中期可选 |
| 先进先出 (FIFO) | 批次管理强的场景 | 后期拓展 |
| 个别计价 | 单件高价值品 | 后期拓展 |

### 2.3 计价公式

```
新移动平均成本 = (库存金额_变动前 + 本次入库金额) / (库存数量_变动前 + 本次入库数量)

出库成本 = 出库数量 × 当前移动平均成本（出库时的时点值）
```

---

## 三、业务节点成本联动逻辑

### 3.1 完整成本链路

```
采购订单(含税价)
  │  审核
  ▼
采购入库 ──→ 计算不含税单价 ──→ 更新物料移动平均成本
  │                                   │
  │  stockIn(materialId, qty,         │
  │           unitCost)               ▼
  │                            库存台账(数量+金额)
  │                              │
  │                              │ 生产领料出库
  │                              ▼
  │                            按移动平均成本出库
  │                              │
  │                              ▼
  │                            生产订单(归集材料成本)
  │                              │
  │                              │ + 人工 + 制造费用
  │                              ▼
  │                            完工入库 ──→ 计算产成品成本
  │                              │           │
  │                              │   stockIn(产成品, qty, 归集成本)
  │                              │           │
  │                              ▼           ▼
  │                            物料移动平均成本更新(产成品)
  │                              │
  │                              │ 销售出库
  │                              ▼
  └──────────────────────→  按移动平均成本出库
                                │
                                ▼
                            销售毛利 = 售价 - 成本
```

### 3.2 各节点详细联动

#### 节点①：采购入库审核

```
触发时机：MesPurchaseReceiptServiceImpl.audit()
当前行为：stockIn(materialId, warehouseId, qty, "采购入库", code)
          + 生成应付(取采购订单行的 unitPrice + taxRate)

新增行为：
  1. 从采购订单行取 unitPrice(含税) + taxRate
  2. 计算不含税单价 = unitPrice / (1 + taxRate)
  3. 计算入库金额 = 不含税单价 × receiptQuantity
  4. stockIn(materialId, warehouseId, qty, unitCost, amount, "采购入库", code)
  5. 更新物料移动平均成本
  6. 写库存台账金额字段
```

#### 节点②：生产领料出库

```
触发时机：MesProductionPickingServiceImpl.audit()
当前行为：stockOut(materialId, warehouseId, qty, "生产领料", code)

新增行为：
  1. 读取当前物料的移动平均成本
  2. 计算出库成本 = 移动平均成本 × qty
  3. stockOut(materialId, warehouseId, qty, unitCost, amount, "生产领料", code)
  4. 将材料成本归集到生产订单
```

#### 节点③：完工入库

```
触发时机：MesCompletionReceiptServiceImpl.audit()
当前行为：stockIn(产成品 materialId, warehouseId, qty, "完工入库", code)

新增行为：
  1. 归集生产订单的材料成本(BOM展开×用量×领料时成本)
  2. + 直接人工
  3. + 制造费用分摊
  4. 计算产成品单位成本 = 总成本 / 完工数量
  5. stockIn(产成品, warehouseId, qty, unitCost, totalCost, "完工入库", code)
  6. 更新产成品移动平均成本
```

#### 节点④：销售出库

```
触发时机：MesSalesOutboundServiceImpl.audit()
当前行为：stockOut(materialId, warehouseId, qty, "销售出库", code)

新增行为：
  1. 读取当前物料的移动平均成本
  2. 计算出库成本 = 移动平均成本 × qty
  3. stockOut(materialId, warehouseId, qty, unitCost, amount, "销售出库", code)
  4. 销售毛利 = 销售单价 - 出库成本（报表层面）
```

### 3.3 成本变更事件溯源

| 事件 | 影响 | 处理 |
|------|------|------|
| 采购入库 | 成本↑ | 移动加权平均重算 |
| 采购退货 | 成本↓（按入库时成本原路冲回） | 移动加权平均重算 |
| 完工入库 | 产成品成本↑ | 移动加权平均重算 |
| 采购发票差异 | 入库成本可能需要调整 | 后期拓展 |
| 采购运费分摊 | 入库成本可能需要追加 | 后期拓展 |

---

## 四、数据存储设计

### 4.1 物料表扩展（基础必备）

```sql
-- V9.7.0: c_mes_material 新增成本价字段
ALTER TABLE c_mes_material
    ADD COLUMN moving_avg_cost decimal(18,4) DEFAULT 0.0000 COMMENT '移动平均成本',
    ADD COLUMN last_purchase_price decimal(18,4) DEFAULT NULL COMMENT '最近采购价(含税)',
    ADD COLUMN last_purchase_date datetime DEFAULT NULL COMMENT '最近采购日期';
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `standard_price` | decimal(18,2) | 已有，标准售价 |
| `moving_avg_cost` | decimal(18,4) | **新增**，移动平均成本（4位小数精度） |
| `last_purchase_price` | decimal(18,4) | **新增**，最近一次采购含税价（参考） |
| `last_purchase_date` | datetime | **新增**，最近采购日期 |

### 4.2 库存台账扩展（基础必备）

```sql
-- V9.7.0: c_mes_inventory_ledger 新增金额字段
ALTER TABLE c_mes_inventory_ledger
    ADD COLUMN unit_cost decimal(18,4) DEFAULT NULL COMMENT '单位成本',
    ADD COLUMN in_amount decimal(18,2) DEFAULT NULL COMMENT '入库金额',
    ADD COLUMN out_amount decimal(18,2) DEFAULT NULL COMMENT '出库金额',
    ADD COLUMN beginning_amount decimal(18,2) DEFAULT 0.00 COMMENT '期初金额',
    ADD COLUMN ending_amount decimal(18,2) DEFAULT 0.00 COMMENT '期末金额';
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `beginning_qty` | decimal(18,2) | 已有 |
| `beginning_amount` | decimal(18,2) | **新增** |
| `in_qty` | decimal(18,2) | 已有 |
| `in_amount` | decimal(18,2) | **新增** |
| `out_qty` | decimal(18,2) | 已有 |
| `out_amount` | decimal(18,2) | **新增** |
| `ending_qty` | decimal(18,2) | 已有 |
| `ending_amount` | decimal(18,2) | **新增** |
| `unit_cost` | decimal(18,4) | **新增**，本次交易的单位成本 |

### 4.3 成本变动日志表（基础必备）

```sql
CREATE TABLE c_mes_cost_log (
    id varchar(32) NOT NULL COMMENT 'ID',
    material_id varchar(32) NOT NULL COMMENT '物料ID',
    warehouse_id varchar(32) DEFAULT NULL COMMENT '仓库ID(空=全局)',
    biz_type varchar(50) NOT NULL COMMENT '业务类型: 采购入库/采购退货/完工入库/成本调整',
    biz_id varchar(100) NOT NULL COMMENT '业务单号',
    qty decimal(18,2) NOT NULL COMMENT '变动数量(+入库/-出库)',
    unit_cost decimal(18,4) NOT NULL COMMENT '本次单位成本',
    amount decimal(18,2) NOT NULL COMMENT '本次金额',
    cost_before decimal(18,4) NOT NULL COMMENT '变动前移动平均成本',
    cost_after decimal(18,4) NOT NULL COMMENT '变动后移动平均成本',
    qty_before decimal(18,2) NOT NULL COMMENT '变动前库存数量',
    qty_after decimal(18,2) NOT NULL COMMENT '变动后库存数量',
    create_by varchar(50) DEFAULT NULL COMMENT '操作人',
    create_time datetime DEFAULT NULL COMMENT '操作时间',
    PRIMARY KEY (id),
    INDEX idx_material_id (material_id),
    INDEX idx_biz_id (biz_id),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-成本变动日志';
```

### 4.4 生产订单成本归集表（后期拓展）

```sql
-- Phase 2: 生产订单成本表
CREATE TABLE c_mes_production_cost (
    id varchar(32) NOT NULL COMMENT 'ID',
    production_order_id varchar(32) NOT NULL COMMENT '生产订单ID',
    material_cost decimal(18,2) DEFAULT 0.00 COMMENT '材料成本(BOM投料)',
    labor_cost decimal(18,2) DEFAULT 0.00 COMMENT '直接人工',
    overhead_cost decimal(18,2) DEFAULT 0.00 COMMENT '制造费用',
    total_cost decimal(18,2) DEFAULT 0.00 COMMENT '总成本',
    completed_qty decimal(18,2) DEFAULT 0.00 COMMENT '完工数量',
    unit_cost decimal(18,4) DEFAULT NULL COMMENT '单位成本',
    PRIMARY KEY (id),
    INDEX idx_production_order_id (production_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-生产订单成本';
```

---

## 五、分层实施计划

### 5.1 基础必备功能（MVP - V9.7.0）

**目标**：让每一笔采购入库都留下成本痕迹，库存不再只记数量。

| # | 功能 | 涉及文件 | 工作量 |
|---|------|---------|:--:|
| 1 | `MesMaterial` 新增 `movingAvgCost`/`lastPurchasePrice`/`lastPurchaseDate` | Entity + SQL | 小 |
| 2 | `MesInventoryLedger` 新增金额字段 | Entity + SQL | 小 |
| 3 | `c_mes_cost_log` 成本变动日志表 | 建表SQL + Entity + Mapper | 中 |
| 4 | `IMesInventoryService` 接口升级 — `stockIn`/`stockOut` 增加单价金额参数 | 接口 + 实现 + 所有调用点 | 中 |
| 5 | **采购入库审核** — 计算不含税成本 + 调用升级后的 `stockIn` + 更新移动平均成本 | `MesPurchaseReceiptServiceImpl.audit()` | 中 |
| 6 | `MesMaterialServiceImpl` — 移动加权平均计算逻辑 | Service 新增方法 | 中 |
| 7 | 物料详情页展示 `movingAvgCost` | 前端 `material.data.ts` + `index.vue` | 小 |
| 8 | 库存台账页展示金额字段 | 前端 ledger 页面 | 小 |

**MVP 交付效果**：
- 采购入库后物料有移动平均成本
- 库存台账数量+金额双维度
- 每次成本变动可追溯（`c_mes_cost_log`）
- 物料详情页可看到当前成本价

### 5.2 中期拓展（Phase 2 - V9.8.0）

| # | 功能 | 说明 |
|---|------|------|
| 9 | 销售出库按移动平均成本结转 | `MesSalesOutboundServiceImpl.audit()` |
| 10 | 生产领料出库按移动平均成本 + 归集到生产订单 | `MesProductionPickingServiceImpl.audit()` |
| 11 | 完工入库成本核算（材料成本卷算） | `MesCompletionReceiptServiceImpl.audit()` |
| 12 | 销售毛利报表 | 新报表：按订单/客户/物料维度展示 售价-成本=毛利 |

### 5.3 后期拓展（Phase 3 - V10.0.0+）

| # | 功能 | 说明 |
|---|------|------|
| 13 | 采购运费分摊到入库成本 | 按重量/体积/金额比例分摊 |
| 14 | 采购发票差异调整成本 | 发票价 ≠ 入库价时的差异处理 |
| 15 | 完工入库人工+制造费用归集 | 工时记录 × 费率 + 制造费用分摊规则 |
| 16 | 成本调整单 | 手工调整库存成本并记录原因 |
| 17 | 先进先出(FIFO)批次成本 | 个别批次管理，按批号追踪成本 |
| 18 | 月加权平均 | 月末统一重算，与移动平均并行提供选择 |

---

## 六、移动加权平均算法核心代码

```java
// MesMaterialServiceImpl 新增方法

/**
 * 移动加权平均 — 入库时更新物料成本
 * @return 新的移动平均成本
 */
@Transactional(rollbackFor = Exception.class)
public BigDecimal updateMovingAvgCostOnStockIn(
        String materialId, BigDecimal inQty, BigDecimal unitCost) {
    
    // FOR UPDATE 行锁防并发
    MesMaterial mat = materialMapper.selectByIdForUpdate(materialId);
    if (mat == null) throw new JeecgBootException("物料不存在");
    
    BigDecimal oldQty = mat.getStockQty() != null ? mat.getStockQty() : BigDecimal.ZERO;
    BigDecimal oldCost = mat.getMovingAvgCost() != null ? mat.getMovingAvgCost() : BigDecimal.ZERO;
    
    // 期初无库存时，直接取本次成本
    BigDecimal newCost;
    if (oldQty.compareTo(BigDecimal.ZERO) == 0) {
        newCost = unitCost;
    } else {
        // 新移动平均 = (原库存金额 + 本次入库金额) / (原数量 + 本次入库数量)
        BigDecimal oldAmount = oldQty.multiply(oldCost);
        BigDecimal newAmount = inQty.multiply(unitCost);
        BigDecimal totalAmount = oldAmount.add(newAmount);
        BigDecimal totalQty = oldQty.add(inQty);
        newCost = totalAmount.divide(totalQty, 4, RoundingMode.HALF_UP);
    }
    
    mat.setMovingAvgCost(newCost);
    mat.setLastPurchasePrice(unitCost);
    mat.setLastPurchaseDate(new Date());
    materialMapper.updateById(mat);
    
    return newCost;
}
```

**关键设计决策**：
- 用 `SELECT ... FOR UPDATE` 行锁，不用 `synchronized`（与 `code-style.md` 发号规则一致）
- 4 位小数精度（`decimal(18,4)`），满足大部分工业场景
- 出库不改变移动平均成本（只读当前值），仅入库改变

---

## 七、存量数据初始化

MVP 不处理历史数据回溯。历史库存的成本字段填 0 或 NULL，从 MVP 上线后的第一笔采购入库开始积累成本数据。

如需初始化历史成本，提供独立的成本初始化脚本（按物料逐个录入）。

---

## 八、影响范围汇总

### 8.1 需要修改的现有文件

| 文件 | 改动 |
|------|------|
| `MesMaterial.java` | +3 字段 |
| `MesInventoryLedger.java` | +5 字段 |
| `IMesInventoryService.java` | 接口方法签名升级 |
| `MesInventoryServiceImpl.java` | 实现升级，写金额 |
| `MesPurchaseReceiptServiceImpl.audit()` | 计算成本 + 传参 |
| `MesMaterialServiceImpl.java` | +移动平均算法 |
| `MesMaterialMapper.java` | +selectByIdForUpdate |
| `MesMaterialMapper.xml` | +FOR UPDATE SQL |
| SQL: `V9.7.0__mes_material_cost.sql` | DDL + 建成本日志表 |

### 8.2 所有 `stockIn()`/`stockOut()` 调用点

需要逐个排查并补齐成本参数（MVP 阶段非采购入库的调用点可传 null/0，后续迭代逐步接入）：

- `MesPurchaseReceiptServiceImpl.audit()` → **MVP 接成本**
- `MesSalesOutboundServiceImpl.audit()` → Phase 2
- `MesProductionPickingServiceImpl.audit()` → Phase 2
- `MesCompletionReceiptServiceImpl.audit()` → Phase 2
- 其他退货/调整类 → Phase 2

---

## 九、前端展示规划

| 页面 | 新增展示 | 阶段 |
|------|---------|:--:|
| 物料详情 | `movingAvgCost`、`lastPurchasePrice`、`lastPurchaseDate` | MVP |
| 物料列表 | `movingAvgCost` 列（可选显示） | MVP |
| 库存台账 | `unitCost`、金额列 | MVP |
| 成本变动日志 | 新页面：按物料+时间查询 | MVP |
| 采购订单行 | 提示"审核后将以此价格计算入库成本" | MVP |
| 销售毛利报表 | 新报表 | Phase 2 |
| 生产成本归集 | 新页面 | Phase 2 |

---

## 十、与现有体系的衔接

| 已有功能 | 成本体系衔接 |
|---------|------------|
| `standardPrice`（售价） | 不冲突，售价和成本是两个独立维度 |
| `MesPrice`（销售价格管理） | 不冲突，销售定价逻辑不变 |
| `MesCustomerPrice`（客户协议价） | 不冲突 |
| `MesPayable`（应付账款） | 应付款继续取采购订单含税价，与成本（不含税）分开 |
| 库存数量 | 不冲突，数量逻辑不变，金额作为新维度叠加 |

---

> **下一步**：确认设计方案后进入 `/plan` 制定 MVP 实施计划。
