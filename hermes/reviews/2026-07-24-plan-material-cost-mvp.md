# 架构评审：MES 物料成本价体系 MVP (V9.7.0)

> 评审日期：2026-07-24 | 评审视角：/plan 阶段架构评审
> 计划文件：`.claude/plans/material-cost-mvp-V9.7.0.md`
> 设计文件：`hermes/prd/mes/modules/material-cost-system-design.md`

## 评审结论（1句总结）

**计划结构完整、策略判定正确，但存在 1 个算法级 double-counting bug 和 2 个文件遗漏（Controller + writeCostLog 实现），修复后可执行。**

---

## ✅ 思路对齐

1. **策略判定「纯新增」正确** — 全部改动在 `project-mes` 内，不改标品。Entity 加字段 + 新建 cost_log 表 + 接口签名升级均属于项目内部演进。

2. **移动加权平均算法设计合理** — FOR UPDATE 行锁防并发（与 `code-style.md` 发号规则一致，不用 `synchronized`），4 位小数精度适合工业场景，出库不改变移动平均、仅入库改变——符合会计惯例。

3. **调用点统计准确** — grep 实测确认共 5 个调用点：
   - `MesPurchaseReceiptServiceImpl.audit()` L144 → stockIn (**MVP 接成本**)
   - `MesSalesOutboundServiceImpl` L121 → stockOut (传 null ✓)
   - `MesSalesOutboundServiceImpl` L189 → stockIn 红冲 (传 null ✓)
   - `ProductionPickingServiceImpl` L121 → stockOut (传 null ✓)
   - `CompletionReceiptServiceImpl` L121 → stockIn (传 null ✓)
   无遗漏。

4. **SQL 兼容性处理正确** — MySQL 5.7 用存储过程 `information_schema.COLUMNS` 判断列存在后再 `ALTER TABLE`，避免了 `ADD COLUMN IF NOT EXISTS` 不兼容问题。

5. **依赖字段确认** — `MesPurchaseOrderItem.taxRate` (BigDecimal) 存在，`MesPurchaseReceiptItem.unitPrice` + `amount` 存在，`c_mes_inventory` 表名和 `material_id`/`current_qty` 列确认正确。不含税成本计算 `unitPrice / (1 + taxRate)` 公式正确。

6. **存量数据策略清晰** — MVP 不追溯历史，存量填 0/NULL，从上线后第一笔采购入库开始积累。范围外（销售成本/生产成本/费用归集）明确列出。

7. **`resurrect` SQL 未覆盖新字段** — 经查 `MesMaterialMapper.resurrect()` 的 `@Update` SQL 未包含 `standardPrice`/`safetyStock`/`maxStock`/`movingAvgCost`/`lastPurchasePrice`/`lastPurchaseDate`。**但这是已有问题**（`standardPrice` 也不在 resurrect 中），非本计划引入。建议另开修复任务统一补齐所有字段。

---

## ⚠️ 遗漏或风险

### P0-1：移动加权平均算法存在 double-counting（逻辑错误）

**位置**：步骤 7 `MesPurchaseReceiptServiceImpl.audit()` 中 `stockIn` 和 `updateMovingAvgCostOnStockIn` 的调用顺序。

**问题**：审计中先调 `inventoryService.stockIn()`（更新库存数量），后调 `materialService.updateMovingAvgCostOnStockIn()`。此时 `selectTotalStockQty()` 返回的是**入库后**的总库存，但算法将其当作**入库前**数量：

```java
// audit() 中的顺序（当前计划）：
inventoryService.stockIn(materialId, warehouseId, qty, unitCost, amount, ...);  // ← 库存已 +qty
materialService.updateMovingAvgCostOnStockIn(materialId, qty, unitCost);        // ← 读到的是 post-stockIn 的总量

// updateMovingAvgCostOnStockIn 内部：
BigDecimal totalQty = baseMapper.selectTotalStockQty(materialId);  // 已含本次入库量！
// ...
BigDecimal totalQtyAfter = totalQty.add(inQty);  // ← 重复加了一次 inQty！
```

**模拟验证**：物料初始库存 10 个，成本 100。采购入库 5 个，不含税单价 120。
- 正确算法：新成本 = (10×100 + 5×120) / (10+5) = 1600/15 = 106.6667
- Bug 算法（计划）：totalQty = 15（已入库），oldAmount = 15×100=1500（过高），totalQtyAfter = 15+5=20，newCost = (1500+600)/20 = 105.0000
- **偏差 1.56%，非首笔入库即开始累积错误，批次越多偏差越大。**

**修复方案（推荐 A）**：

**方案 A**：调换顺序——先 `updateMovingAvgCostOnStockIn`，后 `stockIn`：
```java
// 先锁物料 + 读库存（入库前总量）→ 更新成本 → 再入库
materialService.updateMovingAvgCostOnStockIn(item.getMaterialId(), item.getReceiptQuantity(), unitCost);
inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQuantity(), unitCost, costAmount, "采购入库", e.getCode());
```
**验证**：同事务内 `selectByIdForUpdate` 锁住物料行，库存侧 `selectForUpdate` 锁住库存行——无死锁风险（锁获取顺序：material → inventory，全局一致）。

**方案 B**：传 pre-stockIn totalQty 参数，由调用方在 `stockIn` 前读取：
```java
BigDecimal preQty = materialMapper.selectTotalStockQty(materialId);
inventoryService.stockIn(...);
materialService.updateMovingAvgCostOnStockIn(materialId, preQty, inQty, unitCost); // 新增 preQty 参数
```

> **推荐方案 A**：改动最小、不改变方法签名。

### P0-2：缺少 `MesCostLogController` — API 验证将失败

**问题**：计划步骤 8 创建了 `MesCostLog` 的 Entity + Mapper + Service + ServiceImpl，但**没有创建 Controller**。步骤 10 的 API 验证中：
```bash
curl -s "http://localhost:8080/jeecg-boot/mes/purchase/mesCostLog/list?materialId={materialId}"
```
此端点不存在，因为没有 Controller 注册该路由。`jeecg-boot` 不会为只有 Service 的实体自动暴露 REST 端点。

**需新增文件**：`purchase/ledger/controller/MesCostLogController.java`
```java
@RestController
@RequestMapping("/mes/purchase/mesCostLog")
@Slf4j
public class MesCostLogController extends JeecgController<MesCostLog, IMesCostLogService> {
    @Autowired private IMesCostLogService mesCostLogService;
    
    @GetMapping("/list")
    @RequiresPermissions("mes:purchase:costLog:list")
    public Result<IPage<MesCostLog>> queryPageList(MesCostLog entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize,
            HttpServletRequest req) {
        QueryWrapper<MesCostLog> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        IPage<MesCostLog> page = mesCostLogService.page(new Page<>(pageNo, pageSize), qw);
        return Result.OK(page);
    }
}
```

**联动影响**：
- 文件清单需 +1：`purchase/ledger/controller/MesCostLogController.java`
- 需在 `MesMenuRegistry` 注册菜单和权限码 `mes:purchase:costLog:list`
- 前端可能需要一个成本变动日志页（设计文档 Phase 1 提到，但计划未列出）

### P0-3：`writeCostLog` 方法签名不匹配 + 实现缺失

**问题 1**：计划步骤 7 audit() 中调 `writeCostLog` 只传 7 个参数：
```java
writeCostLog(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQuantity(), unitCost, costAmount, "采购入库", e.getCode());
```
但 `IMesCostLogService.writeLog()` 签名需要 11 个参数（含 costBefore/costAfter/qtyBefore/qtyAfter）：
```java
void writeLog(String materialId, String warehouseId, BigDecimal qty, BigDecimal unitCost,
              BigDecimal amount, BigDecimal costBefore, BigDecimal costAfter,
              BigDecimal qtyBefore, BigDecimal qtyAfter, String bizType, String bizId);
```

**问题 2**：`writeCostLog` 辅助方法本身未在计划中展示实现代码。它需要：
- `costBefore`：变动前移动平均成本（需从物料读取，在 `updateMovingAvgCostOnStockIn` 之前）
- `costAfter`：变动后移动平均成本（`updateMovingAvgCostOnStockIn` 的返回值）
- `qtyBefore`：变动前库存总量
- `qtyAfter`：变动后库存总量

这些值的存在时机与 P0-1 的修复方案耦合。如果用方案 A（先更新成本、后入库），则：
```java
// 辅助方法实现（放在 MesPurchaseReceiptServiceImpl 中）
private void writeCostLog(String materialId, String warehouseId, BigDecimal qty,
        BigDecimal unitCost, BigDecimal amount, String bizType, String bizId) {
    // 此时 updateMovingAvgCostOnStockIn 已执行，但 stockIn 尚未执行
    // costBefore = updateMovingAvgCostOnStockIn 内部的 oldCost（需返回或单独查）
    // qtyBefore = selectTotalStockQty（入库前）
    // 需要修改 updateMovingAvgCostOnStockIn 返回值或改为返回 DTO
}
```

**修复建议**：将 `updateMovingAvgCostOnStockIn` 改为返回一个包含旧成本+新成本+旧数量的对象，或直接在方法内部调用 costLogService 写入日志（简化调用方）。

> **最简单的修复**：在 `updateMovingAvgCostOnStockIn` 内部完成 costLog 写入（一步到位），避免调用方管太多细节。

### P0-4：`@Param` import 遗漏风险

**位置**：步骤 3 `MesMaterialMapper.java` 新增 `selectByIdForUpdate` + `selectTotalStockQty` 使用了 `@Param` 注解。

**现状**：当前 `MesMaterialMapper.java` 使用 `@Select` / `@Update` 但**方法参数没有 `@Param`**（`selectDeletedByCode(String code)` 单参数无需 `@Param`，`resurrect(MesMaterial entity)` 是实体参数也无需）。

**风险**：新增方法的双参数使用了 `@Param`，但文件头部没有 `import org.apache.ibatis.annotations.Param;`。计划在步骤 3 末尾用"注意"提及了，但**未列入步骤中的代码段**，容易被遗漏导致编译失败。

**修复**：在步骤 3 的 Java 代码新增清单中，显式增加：
```java
import org.apache.ibatis.annotations.Param;  // 新增
```

### P1-1：台账 `beginningAmount` / `endingAmount` 永久为零

**位置**：步骤 6 `MesInventoryServiceImpl.writeLedger()` 方法中：
```java
ledger.setBeginningAmount(BigDecimal.ZERO);
ledger.setEndingAmount(BigDecimal.ZERO);
```

**影响**：`c_mes_inventory_ledger` 表的 `beginning_amount` / `ending_amount` 列始终为 0，但 `in_amount` / `out_amount` 列仅采购入库时有值（其他调用点传 null）。

台账的金额维度不完整——无法从台账推算任意时点的库存金额。这在 Phase 2 销售出库结转成本时会暴露：需要从台账的 endingAmount 推算当期库存价值。

**建议**：
1. 短期（MVP）：接受当前行为，在代码注释中标注 `// TODO Phase2: 期初/期末金额需累计计算`
2. 中期（Phase 2）：在 `writeLedger` 中根据上一笔台账的 `endingAmount` 推算本笔的 `beginningAmount`，或改为同一物料+仓库维度累计。

### P1-2：`MesMaterialMapper.resurrect` SQL 未覆盖新增字段

**现状确认**：
```java
@Update("UPDATE c_mes_material SET code=#{code}, name=#{name}, type=#{type}, spec=#{spec}, " +
        "unit=#{unit}, status=#{status}, remark=#{remark}, " +
        "update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 " +
        "WHERE id=#{id} AND del_flag=1")
```

**缺失字段**：`standardPrice`（已有）、`safetyStock`/`maxStock`（已有）、**`movingAvgCost`/`lastPurchasePrice`/`lastPurchaseDate`**（本次新增）。

**影响**：物料被软删除后，通过"借尸还魂"机制复活时，所有价格字段（售价+成本价）归零/NULL——成本追踪链断裂。**但这是已有缺陷（`standardPrice` 同样丢失），不属于本计划引入的新问题。**

**建议**：在本计划中顺手修复（改动小），或另建修复任务。

### P2-1：`c_mes_cost_log` 接口可直接用 `IMesCostLogService` 简化

**当前设计**：`IMesCostLogService.writeLog(11 args)` — 参数过多，调用方负担重。

**建议**：简化为 `IMesCostLogService.writeLog(MesCostLog entity)` 或使用 Builder 模式。另外步骤 8 中 `writeLog` 注入了 `MesMaterialMapper` 但未使用（无注入理由的字段）。

### P2-2：N+1 查询 — audit() 循环内查采购订单行

**位置**：步骤 7 audit 循环内对每个 item 执行一次 `purchaseOrderItemMapper.selectList`。

**现状**：这是已有模式（当前 audit 代码 L147-149 已这么做），非本计划引入。后续可按 `orderId` 一次性加载所有订单行到 Map 中优化。

---

## 💡 优化建议

### 1. 合并步骤 7 中的三个调用为一个原子操作

当前步骤 7 中 audit 循环体需要协调 `stockIn`、`updateMovingAvgCostOnStockIn`、`writeCostLog` 三个调用，且彼此有严格顺序依赖。建议将成本计算+日志写入内聚到 `updateMovingAvgCostOnStockIn` 中：

```java
// 在 updateMovingAvgCostOnStockIn 内部完成全部成本操作：
@Transactional(rollbackFor = Exception.class)
public CostUpdateResult updateMovingAvgCostOnStockIn(
        String materialId, BigDecimal inQty, BigDecimal unitCost,
        String warehouseId, String bizType, String bizId) {
    
    MesMaterial mat = baseMapper.selectByIdForUpdate(materialId);
    BigDecimal preQty = baseMapper.selectTotalStockQty(materialId); // 入库前
    
    BigDecimal oldCost = mat.getMovingAvgCost() != null ? mat.getMovingAvgCost() : BigDecimal.ZERO;
    BigDecimal newCost = calculateNewAvg(preQty, oldCost, inQty, unitCost);
    
    mat.setMovingAvgCost(newCost);
    mat.setLastPurchasePrice(unitCost);
    mat.setLastPurchaseDate(new Date());
    baseMapper.updateById(mat);
    
    // 写成本日志（在方法内部完成）
    costLogService.writeLog(materialId, warehouseId, inQty, unitCost,
        unitCost.multiply(inQty), oldCost, newCost, preQty, preQty.add(inQty),
        bizType, bizId);
    
    return new CostUpdateResult(oldCost, newCost, preQty);
}
```

**好处**：调用方只需一个调用，不会搞错顺序；costLog 写入时机正确；方法职责单一。

### 2. 文件清单建议补全

当前计划 19 个文件，建议补至 **22 个**：

| 补充 | 文件 | 原因 |
|------|------|------|
| +1 | `purchase/ledger/controller/MesCostLogController.java` | P0-2：缺少 Controller |
| +1 | `purchase/ledger/controller/MesInventoryLedgerController.java` | 台账金额字段需 Controller 层感知（如分页查询返回新字段） |
| +1 | `basic/material/material.data.ts` 已列入 | ✅ 已在计划中 |
| +1 | `purchase/ledger/ledger.data.ts` 已列入 | ✅ 已在计划中 |

> 注：`MesInventoryLedgerController` 如果已存在且用 MyBatis-Plus 自动映射（Entity 字段自动出现在 JSON 响应中），则不需要修改 Controller。需核实。

### 3. 前端遗漏：成本变动日志页面

设计文档 9 节明确 MVP 需要"成本变动日志 — 新页面：按物料+时间查询"。但计划只改了 `material.data.ts` 和 `ledger.data.ts`，**没有新建成本日志 Vue 页面和路由注册**。

如果 MVP 阶段不建前端页面（仅 API 可查），建议在计划"范围外"中明确声明。

### 4. `resurrect` SQL 建议本次顺手补齐

`MesMaterialMapper.resurrect()` 的 `@Update` SQL 缺少 `standardPrice`、`safetyStock`、`maxStock` 及本次新增的 3 个成本字段。建议在步骤 3 中一起修复（改动 1 行 SQL，零风险）。

### 5. 增加步骤间验证点

建议在两个关键步骤后增加编译验证（而非等全部完成后一次 compile）：
- 步骤 6（接口签名升级 + 5 调用点适配）→ `mvn compile` 确认无编译错误
- 步骤 7（采购入库核心联动）→ `mvn compile` + curl 验证

---

## 风险矩阵

| 风险 | 严重度 | 可能性 | 缓解状态 |
|------|:--:|:--:|------|
| 算法 double-counting（P0-1） | P0 | 必然 | ❌ 需修复 |
| 缺少 Controller（P0-2） | P0 | 必然 | ❌ 需新增 |
| writeCostLog 实现缺失（P0-3）| P0 | 必然 | ❌ 需补全 |
| @Param import 遗漏 | P1 | 高 | ⚠️ 需显式加入步骤 |
| beginningAmount 永为零 | P1 | 必然 | ⚠️ 记录为 Phase 2 TODO |
| resurrect SQL 字段缺失 | P2 | 中 | 建议顺手修复 |
| N+1 查询 | P2 | 已有 | 非本计划引入 |

---

## 文件清单完整性检查

| 类型 | 计划覆盖 | 实际需要 | 状态 |
|------|:--:|:--:|:--:|
| SQL DDL | 1 | 1 | ✅ |
| Entity 修改 | 2 | 2 | ✅ |
| Entity 新建 | 1 | 1 | ✅ |
| Mapper 修改 | 1 | 1 | ✅ |
| Mapper 新建 | 1 | 1 | ✅ |
| Service 接口修改 | 1 | 1 | ✅ |
| Service 接口新建 | 1 | 1 | ✅ |
| Service 实现修改 | 3 | 3 | ✅ |
| Service 实现新建 | 1 | 1 | ✅ |
| **Controller 新建** | **0** | **1** | ❌ 缺失 |
| 前端 .data.ts | 2 | 2 | ✅ |
| 前端 Vue 页面 | 0 | 0-1 | ⚠️ 成本日志页未列入 |
| 菜单注册 | 0 | ? | ⚠️ 需确认是否需要 |
| **总计** | **14** | **15-17** | — |

---

## 总结

计划的文件清单和算法框架扎实，策略判定和依赖查证准确。3 个 P0 问题（算法顺序、Controller 缺失、writeCostLog 实现缺失）需要在实施前修复。修复后计划可进入执行阶段。
