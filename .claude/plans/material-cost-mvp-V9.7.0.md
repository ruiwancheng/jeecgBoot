# 实施计划：物料成本价体系 MVP (V9.7.0)

## 策略判定

- **类型**：纯新增（在现有实体上加字段 + 新建成本日志表）
- **涉及标品模块**：无（全部在 `project-mes` 内）

## 依赖查证

| # | 检查项 | 状态 |
|---|--------|:--:|
| 1 | `MesMaterialMapper` 已有 `selectDeletedByCode` + `resurrect`，需新增 `selectByIdForUpdate` | ✅ |
| 2 | `MesInventoryMapper` 已有 `selectForUpdate` + `upsertWithDelta`，库存快照表无金额字段 | ⚠️ 不变更库存快照表 |
| 3 | `IMesInventoryService.stockIn/stockOut` 现有 5 个调用点需全部适配新签名 | ⚠️ 见步骤 6 |
| 4 | 成本日志表 `c_mes_cost_log` 为全新表 | ✅ |
| 5 | MySQL 5.7 不支持 `ADD COLUMN IF NOT EXISTS` | ⚠️ SQL 用存储过程判断 |

## 文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `project-mes/db/V9.7.0__mes_material_cost.sql` | **新增** | DDL: material+3列, ledger+5列, cost_log建表 |
| `basic/entity/MesMaterial.java` | **修改** | +3字段: movingAvgCost, lastPurchasePrice, lastPurchaseDate |
| `basic/mapper/MesMaterialMapper.java` | **修改** | +selectByIdForUpdate (FOR UPDATE) |
| `basic/service/impl/MesMaterialServiceImpl.java` | **修改** | +updateMovingAvgCostOnStockIn 算法 |
| `purchase/ledger/entity/MesInventoryLedger.java` | **修改** | +5字段: unitCost, inAmount, outAmount, beginningAmount, endingAmount |
| `basic/service/IMesInventoryService.java` | **修改** | stockIn/stockOut 签名增加 unitCost+amount 参数 |
| `basic/service/impl/MesInventoryServiceImpl.java` | **修改** | writeLedger 写金额字段 |
| `purchase/receipt/service/impl/MesPurchaseReceiptServiceImpl.java` | **修改** | audit() 计算不含税成本 + 传参 + 更新物料成本 |
| `sales/service/impl/MesSalesOutboundServiceImpl.java` | **修改** | stockIn/stockOut 调用点适配新签名(传null) |
| `manufacturing/picking/service/impl/ProductionPickingServiceImpl.java` | **修改** | stockOut 调用点适配新签名(传null) |
| `manufacturing/completion/service/impl/CompletionReceiptServiceImpl.java` | **修改** | stockIn 调用点适配新签名(传null) |
| **新建** `purchase/ledger/entity/MesCostLog.java` | **新增** | 成本变动日志实体 |
| **新建** `purchase/ledger/mapper/MesCostLogMapper.java` | **新增** | 成本日志Mapper |
| **新建** `purchase/ledger/service/IMesCostLogService.java` | **新增** | 成本日志Service接口 |
| **新建** `purchase/ledger/service/impl/MesCostLogServiceImpl.java` | **新增** | 成本日志Service实现 |
| `basic/material/material.data.ts` (前端) | **修改** | 列表+表单加 movingAvgCost/lastPurchasePrice |
| `purchase/ledger/ledger.data.ts` (前端) | **修改** | 列表加金额列 |

## 任务步骤

### 步骤 1：SQL 迁移脚本

**文件**: `project-mes/db/V9.7.0__mes_material_cost.sql`

```sql
-- V9.7.0: MES 物料成本价体系 MVP

-- 1. c_mes_material 新增成本价字段
-- MySQL 5.7 不支持 ADD COLUMN IF NOT EXISTS，用存储过程
DROP PROCEDURE IF EXISTS add_material_cost_columns;
DELIMITER //
CREATE PROCEDURE add_material_cost_columns()
BEGIN
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_material' AND COLUMN_NAME = 'moving_avg_cost') THEN
    ALTER TABLE c_mes_material ADD COLUMN moving_avg_cost decimal(18,4) DEFAULT 0.0000 COMMENT '移动平均成本';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_material' AND COLUMN_NAME = 'last_purchase_price') THEN
    ALTER TABLE c_mes_material ADD COLUMN last_purchase_price decimal(18,4) DEFAULT NULL COMMENT '最近采购价(含税)';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_material' AND COLUMN_NAME = 'last_purchase_date') THEN
    ALTER TABLE c_mes_material ADD COLUMN last_purchase_date datetime DEFAULT NULL COMMENT '最近采购日期';
  END IF;
END//
DELIMITER ;
CALL add_material_cost_columns();
DROP PROCEDURE IF EXISTS add_material_cost_columns;

-- 2. c_mes_inventory_ledger 新增金额字段
DROP PROCEDURE IF EXISTS add_ledger_amount_columns;
DELIMITER //
CREATE PROCEDURE add_ledger_amount_columns()
BEGIN
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'unit_cost') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN unit_cost decimal(18,4) DEFAULT NULL COMMENT '单位成本';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'in_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN in_amount decimal(18,2) DEFAULT NULL COMMENT '入库金额';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'out_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN out_amount decimal(18,2) DEFAULT NULL COMMENT '出库金额';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'beginning_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN beginning_amount decimal(18,2) DEFAULT 0.00 COMMENT '期初金额';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'ending_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN ending_amount decimal(18,2) DEFAULT 0.00 COMMENT '期末金额';
  END IF;
END//
DELIMITER ;
CALL add_ledger_amount_columns();
DROP PROCEDURE IF EXISTS add_ledger_amount_columns;

-- 3. 新建成本变动日志表
CREATE TABLE IF NOT EXISTS c_mes_cost_log (
    id varchar(32) NOT NULL COMMENT 'ID',
    material_id varchar(32) NOT NULL COMMENT '物料ID',
    warehouse_id varchar(32) DEFAULT NULL COMMENT '仓库ID',
    biz_type varchar(50) NOT NULL COMMENT '业务类型',
    biz_id varchar(100) NOT NULL COMMENT '业务单号',
    qty decimal(18,2) NOT NULL COMMENT '变动数量(+入库/-出库)',
    unit_cost decimal(18,4) NOT NULL COMMENT '本次单位成本',
    amount decimal(18,2) NOT NULL COMMENT '本次金额',
    cost_before decimal(18,4) NOT NULL COMMENT '变动前移动平均成本',
    cost_after decimal(18,4) NOT NULL COMMENT '变动后移动平均成本',
    qty_before decimal(18,2) NOT NULL COMMENT '变动前库存总数量',
    qty_after decimal(18,2) NOT NULL COMMENT '变动后库存总数量',
    create_by varchar(50) DEFAULT NULL COMMENT '操作人',
    create_time datetime DEFAULT NULL COMMENT '操作时间',
    PRIMARY KEY (id),
    INDEX idx_cost_log_material (material_id),
    INDEX idx_cost_log_biz (biz_id),
    INDEX idx_cost_log_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-成本变动日志';
```

**验证**: `mysql -u root -proot -h 127.0.0.1 jeecg-boot < V9.7.0__mes_material_cost.sql` 无报错

---

### 步骤 2：MesMaterial Entity 新增字段

**文件**: `basic/entity/MesMaterial.java`

在 `standardPrice` 字段后新增（紧跟 update-end 注释后）：

```java
//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-移动平均成本+最近采购价-----------
@Excel(name = "移动平均成本", width = 12)
@Schema(description = "移动平均成本")
private java.math.BigDecimal movingAvgCost;

@Excel(name = "最近采购价", width = 12)
@Schema(description = "最近采购价(含税)")
private java.math.BigDecimal lastPurchasePrice;

@Excel(name = "最近采购日期", width = 15, format = "yyyy-MM-dd HH:mm:ss")
@JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
@Schema(description = "最近采购日期")
private java.util.Date lastPurchaseDate;
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-移动平均成本+最近采购价-----------
```

---

### 步骤 3：MesMaterialMapper 新增 FOR UPDATE

**文件**: `basic/mapper/MesMaterialMapper.java`

```java
//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本更新-FOR UPDATE行锁-----------
@Select("SELECT * FROM c_mes_material WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
MesMaterial selectByIdForUpdate(@Param("id") String id);

@Select("SELECT COALESCE(SUM(current_qty), 0) FROM c_mes_inventory WHERE material_id = #{materialId}")
java.math.BigDecimal selectTotalStockQty(@Param("materialId") String materialId);
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本更新-FOR UPDATE行锁-----------
```

注意：需在文件头部新增 `import org.apache.ibatis.annotations.Param;`

---

### 步骤 4：MesMaterialServiceImpl 新增移动加权平均算法

**文件**: `basic/service/impl/MesMaterialServiceImpl.java`

新增方法（在 `validateEntity` 方法之前）：

```java
//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 移动加权平均算法-入库更新物料成本-----------
/**
 * 移动加权平均 — 入库时更新物料成本（FOR UPDATE 行锁防并发）
 * @param materialId 物料ID
 * @param inQty 本次入库数量
 * @param unitCost 本次不含税单价
 * @return 新的移动平均成本
 */
@Transactional(rollbackFor = Exception.class)
public java.math.BigDecimal updateMovingAvgCostOnStockIn(
        String materialId, java.math.BigDecimal inQty, java.math.BigDecimal unitCost) {
    MesMaterial mat = baseMapper.selectByIdForUpdate(materialId);
    if (mat == null) throw new JeecgBootException("物料不存在");

    // 汇总所有仓库的当前库存数量
    java.math.BigDecimal totalQty = baseMapper.selectTotalStockQty(materialId);
    java.math.BigDecimal oldCost = mat.getMovingAvgCost() != null ? mat.getMovingAvgCost() : java.math.BigDecimal.ZERO;

    java.math.BigDecimal newCost;
    if (totalQty.compareTo(java.math.BigDecimal.ZERO) == 0) {
        newCost = unitCost;
    } else {
        java.math.BigDecimal oldAmount = totalQty.multiply(oldCost);
        java.math.BigDecimal newAmount = inQty.multiply(unitCost);
        java.math.BigDecimal totalAmount = oldAmount.add(newAmount);
        java.math.BigDecimal totalQtyAfter = totalQty.add(inQty);
        newCost = totalAmount.divide(totalQtyAfter, 4, java.math.RoundingMode.HALF_UP);
    }

    mat.setMovingAvgCost(newCost);
    mat.setLastPurchasePrice(unitCost);
    mat.setLastPurchaseDate(new Date());
    baseMapper.updateById(mat);

    return newCost;
}
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 移动加权平均算法-入库更新物料成本-----------
```

注意：需新增 `import java.util.Date;`

---

### 步骤 5：MesInventoryLedger Entity 新增金额字段

**文件**: `purchase/ledger/entity/MesInventoryLedger.java`

在 `endingQty` 字段后新增：

```java
//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存台账金额字段-----------
@Excel(name = "单位成本", width = 12)
@Schema(description = "单位成本")
private java.math.BigDecimal unitCost;

@Excel(name = "入库金额", width = 12)
@Schema(description = "入库金额")
private java.math.BigDecimal inAmount;

@Excel(name = "出库金额", width = 12)
@Schema(description = "出库金额")
private java.math.BigDecimal outAmount;

@Excel(name = "期初金额", width = 12)
@Schema(description = "期初金额")
private java.math.BigDecimal beginningAmount;

@Excel(name = "期末金额", width = 12)
@Schema(description = "期末金额")
private java.math.BigDecimal endingAmount;
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存台账金额字段-----------
```

---

### 步骤 6：IMesInventoryService 接口升级 + 所有调用点适配

**文件**: `basic/service/IMesInventoryService.java`

```java
//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存接口升级-增加单价金额参数-----------
void stockIn(String materialId, String warehouseId, java.math.BigDecimal qty, java.math.BigDecimal unitCost, java.math.BigDecimal amount, String bizType, String bizId);
void stockOut(String materialId, String warehouseId, java.math.BigDecimal qty, java.math.BigDecimal unitCost, java.math.BigDecimal amount, String bizType, String bizId);
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存接口升级-增加单价金额参数-----------
```

**文件**: `basic/service/impl/MesInventoryServiceImpl.java`

`stockIn` 方法升级（从旧签名改造）：

```java
@Override
@Transactional(rollbackFor = Exception.class)
public void stockIn(String materialId, String warehouseId, BigDecimal qty, BigDecimal unitCost, BigDecimal amount, String bizType, String bizId) {
    if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("入库数量必须大于0");
    String username = getUsername();
    MesInventory inv = inventoryMapper.selectForUpdate(materialId, warehouseId);
    BigDecimal before = inv != null ? inv.getCurrentQty() : BigDecimal.ZERO;
    BigDecimal after = before.add(qty);
    String id = inv != null ? inv.getId() : UUID.randomUUID().toString().replace("-", "");
    inventoryMapper.upsertWithDelta(id, materialId, warehouseId, before, qty, username, username);
    writeLedger(materialId, warehouseId, before, qty, BigDecimal.ZERO, after, unitCost, amount, null, bizType, bizId);
}

@Override
@Transactional(rollbackFor = Exception.class)
public void stockOut(String materialId, String warehouseId, BigDecimal qty, BigDecimal unitCost, BigDecimal amount, String bizType, String bizId) {
    if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("出库数量必须大于0");
    MesInventory inv = inventoryMapper.selectForUpdate(materialId, warehouseId);
    BigDecimal before = inv != null ? inv.getCurrentQty() : BigDecimal.ZERO;
    if (before.compareTo(qty) < 0) throw new JeecgBootException("库存不足：当前库存" + before + "，出库" + qty);
    BigDecimal after = before.subtract(qty);
    String username = getUsername();
    String id = inv != null ? inv.getId() : UUID.randomUUID().toString().replace("-", "");
    inventoryMapper.upsertWithDelta(id, materialId, warehouseId, before, qty.negate(), username, username);
    writeLedger(materialId, warehouseId, before, BigDecimal.ZERO, qty, after, unitCost, null, amount, bizType, bizId);
}

// writeLedger 升级：增加金额参数
private void writeLedger(String materialId, String warehouseId,
        BigDecimal beginningQty, BigDecimal inQty, BigDecimal outQty, BigDecimal endingQty,
        BigDecimal unitCost, BigDecimal inAmount, BigDecimal outAmount,
        String bizType, String bizId) {
    MesInventoryLedger ledger = new MesInventoryLedger();
    ledger.setMaterialId(materialId);
    ledger.setWarehouseId(warehouseId);
    ledger.setBeginningQty(beginningQty);
    ledger.setInQty(inQty);
    ledger.setOutQty(outQty);
    ledger.setEndingQty(endingQty);
    ledger.setUnitCost(unitCost);
    ledger.setInAmount(inAmount);
    ledger.setOutAmount(outAmount);
    // 期初/期末金额简单计算（MVP不追溯历史）
    ledger.setBeginningAmount(BigDecimal.ZERO);
    ledger.setEndingAmount(BigDecimal.ZERO);
    ledger.setRecordDate(new Date());
    ledger.setBizType(bizType);
    ledger.setBizId(bizId);
    ledgerService.save(ledger);
}
```

**所有调用点适配**（签名变了，非采购入库调用点传 null）：

`MesSalesOutboundServiceImpl.java` L121:
```java
inventoryService.stockOut(item.getMaterialId(), e.getWarehouseId(), item.getActualQty(), null, null, "销售出库", e.getCode());
```

`MesSalesOutboundServiceImpl.java` L189:
```java
inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getActualQty(), null, null, "销售出库红冲", e.getCode());
```

`ProductionPickingServiceImpl.java` L121:
```java
inventoryService.stockOut(item.getMaterialId(), e.getWarehouseId(), item.getQuantity(), null, null, "生产领料", e.getCode());
```

`CompletionReceiptServiceImpl.java` L121:
```java
inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQty(), null, null, "完工入库", e.getCode());
```

---

### 步骤 7：采购入库审核接入成本（核心联动点）

**文件**: `purchase/receipt/service/impl/MesPurchaseReceiptServiceImpl.java`

在 `audit()` 方法中，`stockIn` 调用前计算成本，`stockIn` 后更新物料成本。修改 L136-157 区域：

```java
// 审核成功后：计算不含税成本 → 加库存 → 更新物料移动平均成本
for (MesPurchaseReceiptItem item : e.getItems()) {
    int ar = purchaseOrderItemMapper.atomicReceive(e.getPurchaseOrderId(), item.getMaterialId(), item.getReceiptQuantity());
    if (ar == 0) throw new JeecgBootException("物料[" + item.getMaterialId() + "]累计入库量超采购数量，请检查");

    // 从采购订单行取含税单价+税率
    LambdaQueryWrapper<MesPurchaseOrderItem> piQw = new LambdaQueryWrapper<>();
    piQw.eq(MesPurchaseOrderItem::getOrderId, e.getPurchaseOrderId()).eq(MesPurchaseOrderItem::getMaterialId, item.getMaterialId());
    List<MesPurchaseOrderItem> orderItems = purchaseOrderItemMapper.selectList(piQw);

    BigDecimal taxRate = new BigDecimal("0.13"); // 默认税率
    BigDecimal unitPriceWithTax = BigDecimal.ZERO; // 含税单价
    if (!orderItems.isEmpty() && orderItems.get(0).getUnitPrice() != null) {
        unitPriceWithTax = orderItems.get(0).getUnitPrice();
        if (orderItems.get(0).getTaxRate() != null) taxRate = orderItems.get(0).getTaxRate();
    }

    // 计算不含税成本单价
    BigDecimal unitCost = unitPriceWithTax.divide(BigDecimal.ONE.add(taxRate), 4, java.math.RoundingMode.HALF_UP);
    BigDecimal costAmount = unitCost.multiply(item.getReceiptQuantity()).setScale(2, java.math.RoundingMode.HALF_UP);

    // 入库（带成本）
    inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQuantity(), unitCost, costAmount, "采购入库", e.getCode());

    // 更新物料移动平均成本
    materialService.updateMovingAvgCostOnStockIn(item.getMaterialId(), item.getReceiptQuantity(), unitCost);
    writeCostLog(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQuantity(), unitCost, costAmount, "采购入库", e.getCode());

    item.setUnitPrice(unitPriceWithTax);
    item.setAmount(unitPriceWithTax.multiply(item.getReceiptQuantity()).setScale(2, java.math.RoundingMode.HALF_UP));
    totalAmount = totalAmount.add(item.getAmount());
    totalTax = totalTax.add(item.getAmount().multiply(taxRate));
}
```

需新增注入：

```java
@Autowired private MesMaterialServiceImpl materialService;
@Autowired private IMesCostLogService costLogService;
```

以及 `writeCostLog` 辅助方法 + 新增 import。

**注意**: `MesMaterialServiceImpl` 新增的 `updateMovingAvgCostOnStockIn` 方法不在 `IMesMaterialService` 接口中，需直接注入实现类或通过接口暴露。

更好的做法：在 `IMesMaterialService` 接口中声明该方法。

---

### 步骤 8：新建成本日志模块（Entity + Mapper + Service）

**新建文件列表**：

| 文件 | 路径 |
|------|------|
| Entity | `purchase/ledger/entity/MesCostLog.java` |
| Mapper | `purchase/ledger/mapper/MesCostLogMapper.java` |
| Service接口 | `purchase/ledger/service/IMesCostLogService.java` |
| Service实现 | `purchase/ledger/service/impl/MesCostLogServiceImpl.java` |

`MesCostLog.java`:
```java
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_cost_log")
@Schema(description = "MES-成本变动日志")
public class MesCostLog implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    private String id;
    private String materialId;
    private String warehouseId;
    private String bizType;
    private String bizId;
    private java.math.BigDecimal qty;
    private java.math.BigDecimal unitCost;
    private java.math.BigDecimal amount;
    private java.math.BigDecimal costBefore;
    private java.math.BigDecimal costAfter;
    private java.math.BigDecimal qtyBefore;
    private java.math.BigDecimal qtyAfter;
    private String createBy;
    private Date createTime;
}
```

`MesCostLogMapper.java`:
```java
public interface MesCostLogMapper extends BaseMapper<MesCostLog> {}
```

`IMesCostLogService.java`:
```java
public interface IMesCostLogService extends IService<MesCostLog> {
    void writeLog(String materialId, String warehouseId, BigDecimal qty, BigDecimal unitCost,
                  BigDecimal amount, BigDecimal costBefore, BigDecimal costAfter,
                  BigDecimal qtyBefore, BigDecimal qtyAfter, String bizType, String bizId);
}
```

`MesCostLogServiceImpl.java`:
```java
@Service
public class MesCostLogServiceImpl extends ServiceImpl<MesCostLogMapper, MesCostLog> implements IMesCostLogService {

    @Autowired private MesMaterialMapper materialMapper;

    @Override
    public void writeLog(String materialId, String warehouseId, BigDecimal qty, BigDecimal unitCost,
                         BigDecimal amount, BigDecimal costBefore, BigDecimal costAfter,
                         BigDecimal qtyBefore, BigDecimal qtyAfter, String bizType, String bizId) {
        MesCostLog log = new MesCostLog();
        log.setMaterialId(materialId);
        log.setWarehouseId(warehouseId);
        log.setQty(qty);
        log.setUnitCost(unitCost);
        log.setAmount(amount);
        log.setCostBefore(costBefore);
        log.setCostAfter(costAfter);
        log.setQtyBefore(qtyBefore);
        log.setQtyAfter(qtyAfter);
        log.setBizType(bizType);
        log.setBizId(bizId);
        save(log);
    }
}
```

---

### 步骤 9：前端 — 物料列表+表单展示成本字段

**文件**: `basic/material/material.data.ts`

columns 新增（在 `standardPrice` 后）：
```typescript
{ title: '移动平均成本', dataIndex: 'movingAvgCost', width: 110 },
{ title: '最近采购价', dataIndex: 'lastPurchasePrice', width: 100 },
```

formSchema 新增（在 `standardPrice` 后）：
```typescript
{ field: 'movingAvgCost', label: '移动平均成本', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 4, disabled: true }, ifShow: ({ model }) => !!model.id },
{ field: 'lastPurchasePrice', label: '最近采购价', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 4, disabled: true }, ifShow: ({ model }) => !!model.id },
```

> 成本字段只读（`disabled: true`），仅编辑已有物料时展示（`ifShow: !!model.id`）

**文件**: `purchase/ledger/ledger.data.ts`

columns 新增金额列：
```typescript
{ title: '单位成本', dataIndex: 'unitCost', width: 100 },
{ title: '入库金额', dataIndex: 'inAmount', width: 100 },
{ title: '出库金额', dataIndex: 'outAmount', width: 100 },
```

---

### 步骤 10：IMesMaterialService 接口补声明

**文件**: `basic/service/IMesMaterialService.java`

```java
//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 移动加权平均算法接口-----------
java.math.BigDecimal updateMovingAvgCostOnStockIn(String materialId, java.math.BigDecimal inQty, java.math.BigDecimal unitCost);
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 移动加权平均算法接口-----------
```

---

## 范围外

- 销售出库成本结转 → Phase 2
- 生产领料/完工入库成本归集 → Phase 2
- 人工+制造费用归集 → Phase 3
- 成本调整单 → Phase 3
- 历史数据回溯 → 不处理（存量填 0）
- Vite 前端 dev server 重启 → 新增 Vue 组件后手动 `pnpm dev`

## 风险

| 风险 | 缓解措施 |
|------|---------|
| 接口签名变更导致编译失败 | 所有 5 个调用点逐一 grep + 修改，mvn compile 验证 |
| `stockIn`/`stockOut` 调用点遗漏传参 | grep 搜索所有调用点确认 |
| `MesInventoryLedger` 金额字段 NULL 导致前端展示异常 | Entity 字段用 `BigDecimal`（可 null），前端加 `defaultValue: 0` |
| `updateMovingAvgCostOnStockIn` 并发算错 | `selectByIdForUpdate` FOR UPDATE 行锁保证串行化 |
| MySQL 5.7 `ADD COLUMN IF NOT EXISTS` 不支持 | 存储过程 + `information_schema` 判断 |

## 编译验证

```bash
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am -DskipTests
```

## API 验证

```bash
# 1. 创建采购订单（含单价+税率）
# 2. 审核入库
# 3. 验证物料 movingAvgCost 已更新
curl -s http://localhost:8080/jeecg-boot/mes/basic/mesMaterial/queryById?id={materialId} \
  -H "X-Access-Token: $TOKEN" | python3 -m json.tool | grep movingAvgCost

# 4. 验证库存台账有金额
curl -s "http://localhost:8080/jeecg-boot/mes/purchase/mesInventoryLedger/list?materialId={materialId}" \
  -H "X-Access-Token: $TOKEN" | python3 -m json.tool | grep -E "unitCost|inAmount"

# 5. 验证成本变动日志有记录
curl -s "http://localhost:8080/jeecg-boot/mes/purchase/mesCostLog/list?materialId={materialId}" \
  -H "X-Access-Token: $TOKEN" | python3 -m json.tool | grep total
```
