# Orca 评审：盘点单模块 plan

> 评审对象：`hermes/reviews/2026-07-28/plan-stocktake-review-input.md`
> 评审日期：2026-07-28
> 评审依据：现有 OtherStockIn/Out 实现、Inventory 模块、Material 成本体系、仓库基础设施
> 输出：`hermes/reviews/2026-07-28/orca-review-plan-stocktake.md`

---

## 一、通过 ✅

以下策略和设计判断经对照现有基础设施后确认可行，无致命缺陷：

### 1.1 复用 OtherStockIn/OutService 生成调整单 ✅

plan 选"生成单据记录+调其 audit"（方案 A）而非跳过单据直接调 stockIn/Out，决策正确。理由：

- **留痕可溯**：盘盈盘亏作为正式出入库单据存在数据库中，审核链路可审计
- **已有成本联动**：`MesOtherStockInServiceImpl.audit()` 在 stockIn 前调 `updateMovingAvgCostOnStockIn`（先成本后库存），盘盈入库会自动更新移动平均成本
- **已有台账记录**：`stockIn`/`stockOut` 内部调 `writeLedger`，盘点生成调整单时会自动产生库存台账记录
- **反审核回冲齐全**：`unaudit` 按原明细反向回冲库存

### 1.2 unit_cost 快照取 movingAvgCost ✅

盘盈用移动平均入账、盘亏按均价出库，是标准做法。理由：

- **盘盈按均价入账 → avg 不变**：新成本 = (原库存金额 + 盘盈数量 × 均价) / (原数量 + 盘盈数量) = 均价本身。盘盈不扭曲成本体系。
- **盘亏按均价出库 → avg 不变**：出库不联动成本更新（`updateMovingAvgCostOnStockIn` 只在入库调用），盘亏自然不改变移动平均。
- **与现有代码一致**：`OtherInDrawer` 选择物料时已预填 `movingAvgCost` 作为默认成本单价（`onMaterialChange` 逻辑）。

### 1.3 编码规则 + bizCodeMap + 菜单注册 ✅

- `STOCKTAKE:'PD'` 加在 `bizCodeMap.ts`，与其他 13 个单据映射一致
- `MesMenuRegistry` 注册菜单+权限码，标准模式
- 编码规则 SQL 用 `INSERT IGNORE` + 固定 id，幂等安全

### 1.4 V1 不锁仓 + 不做红冲 ✅

文档明确提示"盘点期间勿出入库"，这是 V1 合理的业务假设。红冲留到 Phase 2 加入，不阻塞交付。

### 1.5 字典复用 ✅

`mes_other_stock_in_type`（盘盈='1'）和 `mes_other_stock_out_type`（盘亏='1'）已在 V9.8.0 种子 SQL 中注册，盘点生成调整单时可直接设 `inType='1'` / `outType='1'`。

---

## 二、遗漏 ⚠️

以下风险点在高亮问题 1-5 之外的环节，plan 未覆盖，需要在实施中补充。

### 2.0（待评审问题逐答）

#### 问题 1：生成单据+调 audit 还是直接调 stockIn/Out？

**结论：✅ 通过。** 选"生成单据+调 audit"（方案 A）。

**需要关注的坑（实施时注意）：**

| 坑 | 说明 | 缓解 |
|---|------|------|
| **盘点审核的事务边界** | 盘点审核在一个事务中：保存盘点单 status→生成出入库单据+调其 audit（库存增减+成本更新）。如果 audit 中 `stockIn`/`stockOut` 成功但 `writeLedger` 抛异常 → 整个事务回滚，但 `auditWithGuard` 的 CAS 更新已执行并提交 | **不是问题**：`auditWithGuard` 和 `writeLedger` 在同一事务中（`@Transactional` 传播 REQUIRED），CAS 更新和台账写入原子化。✅ |
| **录入数量 100、实盘 100 → diff=0 的不生成单据** | 要确保 diff=0 行仅记录在盘点明细中，不生成空单据。如果全盘 500 个物料中 498 个无差异，只生成 2 份调整单。 | 实施时注意：只对 `|diff_qty| > 0` 的行生成单据，且同仓库同步向的差异行合并为一张单据 |
| **生成入库单时 unitCost 必须传递** | `OtherStockInServiceImpl.audit()` 依赖 `item.getUnitCost()` 做成本联动。如果盘点生成入库单时 unitCost 为 null → `updateMovingAvgCostOnStockIn` 条件不满足（`compareTo(ZERO) > 0` 为 false）→ 跳过成本更新 | 实施时：unitCost 必须从盘点明细的 `unit_cost`（物料快照移动平均）传递到入库单 item |
| **生成出库单不需要 unitCost 联动** | `OtherStockOutServiceImpl.audit()` 无 `updateMovingAvgCostOnStockIn` 调用，盘亏出库按均价记账但不改成本（正确行为）✅ |

#### 问题 2：快照时点 vs 审核时点的库存偏差

**结论：⚠️ V1 可接受快照时点口径，但必须在前端+单据上明确体现。**

**业务口径：** "盘点差异 = 实盘数 - 账面数（创建盘点单时的快照）。审核期间发生的出入库不影响本次盘点结果，差异以快照时点为准。"

**向用户交代方式：**
1. **盘点单详情页**：表头标注"盘点基准日：YYYY-MM-DD HH:mm:ss（账面数为该时点快照）"
2. **差异明细行**：列 `book_qty`/`actual_qty`/`diff_qty`，一目了然
3. **审核前二次确认**：列表页"审核"按钮点击后弹出提示——"差异以盘点单创建时的账面数为准，审核前建议停止出入库操作。如有在途出入库，审核后可能需要再盘一次。"
4. **审核后库存校准结果**：由于按快照差异生成调整单，审核后实际库存 = 快照时库存 + 调整量。例：快照 100 → 审核时 90 → 实盘 95 → 账差 100-95=5（盘亏）→ 最终库存 = 90-5=85。**用户看到的实盘数 95 ≠ 最终库存 85，这是快照口径的本质。** 文档必须说清楚。

**不建议审核时重新计算差异**（方案 B），原因：
- 盘点明细的 `book_qty` 是快照态证据，审核时改掉会丢失审计线索
- 如果审核时重算，`diff_qty = 实盘 - 当前库存` 会包含其它出入库的变动→无法区分"是盘点差异还是期间正常出入库"

#### 问题 3：盘盈入账用均价 vs 0 成本 vs 手工成本

**结论：✅ 盘盈用移动平均入账（均价），标准做法。**

论证：
- **盘盈用均价 → avg 不变**（数学恒等），不扭曲成本体系
- **盘盈用 0 成本**：库存数量增加金额不变 → avg 被稀释下降，不可取
- **盘盈用手工成本**：业务场景中盘盈通常是因为"实物多了但没入库记录"，实际成本未知，手工成本无依据

**加分项**：`updateMovingAvgCostOnStockIn` 的条件是 `unitCost > 0`，如果用均价传入，条件满足，会正确写 `c_mes_cost_log` 成本变动日志（入账均价前后一致，日志中 `costBefore == costAfter`，审计可见）。

**一个边界：库存为 0 时盘盈。** `preQty = 0` → `newCost = unitCost`（就是均价本身）→ 成本不变。✅

#### 问题 4：全盘一键快照放后端 vs 前端按钮

**结论：✅ 放后端创建时自动生成（方案 A）。**

理由：
- **服务端权威**：账面库存取 `current_qty` + `movingAvgCost`，需要调 `MesInventoryMapper.selectForUpdate` 和 `MesMaterialMapper.selectByIdForUpdate`
- **全盘全仓库物料覆盖**：需 join `c_mes_inventory` + `c_mes_material`，一个 SQL 完成
- **简单可靠**：`saveWithItems` 中判断 `takeType='1'` → 自动填充明细行，无需前端调多次接口

**抽盘路径（`takeType='2'`）的处理——不会让代码分叉：**

```java
// saveWithItems 中：
if ("1".equals(entity.getTakeType()) && (items == null || items.isEmpty())) {
    // 全盘：自动快照全仓库账面库存为明细
    items = snapshotInventoryByWarehouse(entity.getWarehouseId());
} else {
    // 抽盘：前端传了 items，校验不为空即可
    // 全盘也允许前端预传 items（如用户想自定义明细行后再保存）
}
```

**统一处理：** 全盘和抽盘共用一个 `validate` + `saveItems` 路径。全盘只是自动生成了 `items` 列表，后续逻辑完全一样。代码不分叉，只在 `items` 的来源上区分。

**全盘快照时机：** 点击"新建盘点单"→创建草稿（`status='1'`）→后端在 `saveWithItems` 中快照。快照与盘点单创建时间一致，`book_qty` 和 `unit_cost` 取自该时刻的 `c_mes_inventory.current_qty` 和 `c_mes_material.moving_avg_cost`。

#### 问题 5：遗漏的高风险点

**以下是 plan 未覆盖的关键风险：**

##### 5a. 🔴 P0：盘点审核的事务中生成并审核出入库单——事务嵌套传播

`StocktakeServiceImpl.audit()` 需要调 `otherStockInService.saveWithItems(fromStocktake)` 再用 `otherStockInService.audit(inId)`。两者都有 `@Transactional`。

**传播行为分析：**
- 如果 `stocktakeService.audit()` 有 `@Transactional`（默认 REQUIRED）
- `otherStockInService.saveWithItems()` 也有 `@Transactional`（默认 REQUIRED）
- Spring AOP：调用方和被调用方在同一个 Bean 事务中合并为一个大事务

**关键时序：**
```
stocktakeService.audit(id) → @Transactional begin
  ├─ stocktakeMapper.auditWithGuard(id) — CAS '1'→'2' 成功
  ├─ 遍历 diff>0 的行:
  │   ├─ otherStockInService.saveWithItems(inEntity) — 创建入库单（草稿）
  │   ├─ otherStockInService.audit(inId) — 审核入库单（这又会触发 stockIn+updateMovingAvg）
  │   └─ 如果 audit 失败 → RuntimeException → 整个事务回滚 → 盘点单的 auditWithGuard 也回滚！
  └─ 遍历 diff<0 的行: (同上镜像)
```

**这个设计是正确的 ✅**——所有操作在一个事务中，任一失败全部回滚。但有前提条件：

1. `otherStockInService.saveWithItems` 和 `audit` 方法必须在 Spring 代理对象上调用（不能是 `this.xxx()`），否则 `@Transactional` 失效
2. 盘点单的 CAS 和出入库单的创建/审核必须原子化

**建议实现模式：**
```java
// StocktakeServiceImpl
@Autowired private IMesOtherStockInService otherStockInService;  // Spring 代理 ✅
@Autowired private IMesOtherStockOutService otherStockOutService;  // Spring 代理 ✅

@Transactional(rollbackFor = Exception.class)
public void audit(String id) {
    // 1. FOR UPDATE 锁盘点单（防并发）
    MesStocktake locked = baseMapper.selectByIdForUpdate(id);
    // 2. CAS 更新盘点单状态
    int rows = baseMapper.auditWithGuard(id, username, now);
    if (rows == 0) throw new ...;
    // 3. 读取盘点明细
    MesStocktake e = queryWithItems(id);
    // 4. 逐差异行生成+审核调整单
    for (MesStocktakeItem item : e.getItems()) {
        if (item.getDiffQty() > 0) {
            // 盘盈 → 创建入库单 + 审核
            MesOtherStockIn in = buildInFromDiff(item, e.getWarehouseId());
            otherStockInService.saveWithItems(in);  // ← Spring代理 ✅
            otherStockInService.audit(in.getId());   // ← Spring代理 ✅
        } else if (item.getDiffQty() < 0) {
            // 盘亏 → 创建出库单 + 审核
            MesOtherStockOut out = buildOutFromDiff(item, e.getWarehouseId());
            otherStockOutService.saveWithItems(out);
            otherStockOutService.audit(out.getId());
        }
    }
}
```

**禁止：** `this.saveWithItems(in)` → 自调用绕过 Spring AOP → `@Transactional` 不生效 → 入库单创建在独立事务中，盘点回滚时入库单仍在。

##### 5b. 🔴 P1：全盘快照使用 `selectForUpdate` 锁

```java
// snapshotInventoryByWarehouse 中：
List<MesInventory> rows = inventoryMapper.selectForUpdate(materialId, warehouseId);
```

**问题：** 全盘快照需要遍历仓库下所有物料的库存记录。如果仓库有 500 个物料，`selectForUpdate` 需要逐物料加行锁——**无法用一条 SQL 完成**。

**正确做法：** 全盘快照**不需要** FOR UPDATE——快照只是读取当前账面值，创建盘点单后不会同时编辑。用普通 SELECT + 乐观假设即可。

```java
// 全盘快照用普通 select（不加锁）
@Select("SELECT i.material_id, i.current_qty, m.moving_avg_cost " +
        "FROM c_mes_inventory i " +
        "LEFT JOIN c_mes_material m ON i.material_id = m.id AND m.del_flag = 0 " +
        "WHERE i.warehouse_id = #{warehouseId}")
List<StocktakeSnapshotRow> snapshotByWarehouse(String warehouseId);
```

**解释：** V1 不锁仓，快照时点的账面值本身就是尽力的（best-effort）。加锁只会白白阻塞出入库操作，且解决不了快照后的更新问题。

##### 5c. 🟡 P2：同一仓库多差异行的单据合并策略

| 情况 | 所有盘盈行 → 一张入库单 | 所有盘亏行 → 一张出库单 |
|------|:--:|:--:|
| 仓库 A：物料 M1 盘盈 5、物料 M2 盘盈 3、物料 M3 盘亏 2 | 1 张入库单（2 行） | 1 张出库单（1 行） |
| 仓库 A + B 都有差异 | 每个仓库各 1 张入库/出库单 | 仓库独立 |

实施时建议：一个仓库的同向差异合并为一张单据，编码用盘点单号+后缀（如 `PD-20260728-0001-IN`）。

##### 5d. 🟡 P2：盘点明细的 `actual_qty` 初始值

新建盘点单时，`actual_qty` 初始值应该是 `book_qty`（等于账面，差异为 0），还是 null（等待用户填写）？

**建议：** 全盘时 `actual_qty` 初始值 = `book_qty`（默认无差异），用户只修差异项；抽盘时 `actual_qty` 初始值 = null（强制用户填写每一行）。

---

## 三、建议 💡

### 3.1 数据模型补充

#### 3.1.1 `c_mes_stocktake_item` 补字段

| 建议加字段 | 类型 | 说明 |
|-----------|------|------|
| `generated_in_id` | VARCHAR(32) | 盘盈生成入库单 ID（可追溯回查） |
| `generated_out_id` | VARCHAR(32) | 盘亏生成出库单 ID |

理由：审核后生成出入库单，需要知道"哪张盘点单产生了哪张调整单"——双击盘点明细行可以直接打开关联的出/入库单。

#### 3.1.2 `c_mes_stocktake` 字段微调

| 字段 | 建议 |
|------|------|
| `audit_by` + `audit_date` | 改为 `audit_by`/`audit_time`（与现有实体命名一致，`MesOtherStockIn` 无 audit 字段但 Mapper 的 `auditWithGuard` 更新 `update_by`/`update_time`） |
| `take_type` | 使用 `JDictSelectTag` + 新增字典 `mes_stocktake_type`（{1:'全盘',2:'抽盘'}），或不额外加字典直接用常量 |
| `snapshot_time` | **建议加**。快照时间不等于 `create_time`——如果先创建草稿再编辑明细，`create_time` 不反映账面快照时点。在 `saveWithItems` 中记录 `snapshot_time = now`。 |

### 3.2 全盘快照性能

500 个物料的全盘快照 = 1 条 SQL（`JOIN c_mes_inventory + c_mes_material WHERE warehouse_id = ?`）+ 逐行 insert 到 `c_mes_stocktake_item`。insert 500 行用批量 `insertBatch`（MyBatis-Plus `saveBatch`），不要逐行 insert。

### 3.3 审核后库存校准量的验证

审核完成后，建议在响应消息中返回摘要：

```json
{
  "message": "审核成功",
  "summary": {
    "stocktakeCode": "PD-20260728-0001",
    "warehouseId": "xxx",
    "totalItems": 500,
    "diffItems": 3,
    "inDocCode": "QT-IN-20260728-0003",   // 盘盈入库单号
    "outDocCode": "QT-OUT-20260728-0002",  // 盘亏出库单号
    "inTotalAmount": 1500.00,
    "outTotalAmount": 800.00
  }
}
```

让业务人员一眼看到"这次盘点产生了哪些调整"。

### 3.4 前端页面模式建议

不是两个页面（全盘 + 抽盘），而是一个页面 + 单选按钮「盘点类型」控制明细来源：
- **全盘**：创建时自动填充全仓库账面库存，用户只修改 `actual_qty`
- **抽盘**：创建时明细为空，用户手动添加物料行 + 填 `actual_qty`

同一个 `StocktakeDrawer.vue` + `formSchema` 中 `takeType` 的值控制行为。

### 3.5 与其它出入库的状态流转隔离

当前 `mes_other_stock_status` 只有 {1:'草稿',2:'已审核'}。盘点生成的调整单创建后直接审核（不经过草稿状态的人工编辑），状态从 1 → 2 在同一个事务中完成。用户不应该在出入库列表页中看到"由盘点生成的草稿状态调整单"——它应该只存在于审核一瞬间。

**实现保障：** `saveWithItems(entity)` 保存草稿后，立即在同一事务内调 `audit(..)` 将其审核。如果 `audit` 失败，事务回滚 → 草稿也不存在。

### 3.6 与审计发现的对齐

盘点模块实施中需注意上轮铁拳团审计（`hermes/tiequan/2026-07-28/other-stock/`）对 OtherStockIn/Out 的 P0 修复是否已生效（特别是 P0-4 audit TOCTOU 修复——`audit()` 先 FOR UPDATE 再读明细）。当前代码中 `MesOtherStockInServiceImpl.audit()` **已修复**（L111: `selectByIdForUpdate`），但 `MesOtherStockOutServiceImpl.audit()` **未同步修复**（L107 仍在使用无锁的 `queryWithItems`）。盘点模块如果复用出库审核，同样暴露于 TOCTOU 窗口。

**建议：** 盘点实施前先同步出库 audit 的 FOR UPDATE 修复，或至少确保盘点生成的出库单"创建→审核"在同一事务内，不存在被并发编辑的可能（实际上不存在因为调整单只由盘点创建）。

---

## 评审总结

| 维度 | 结论 |
|------|------|
| 复用 OtherStockIn/Out 方案 | ✅ 正确，留痕+成本联动+台账集成 |
| 快照时点分歧 | ⚠️ V1 可接受，但必须文档化"最终库存 ≠ 实盘数"的业务逻辑 |
| 盘盈用均价入账 | ✅ 标准做法，avg 不变，有成本日志 |
| 全盘一键快照 | ✅ 后端 create 时生成，与抽盘共用一套代码路径 |
| 事务嵌套风险 | 🔴 P0：必须用 Spring 代理调 OtherStockIn/OutService，禁止 this.xxx() |
| 全盘快照加锁 | 🔴 P1：全盘快照不应使用 FOR UPDATE，用普通 SELECT |
| 数据模型 | 补 `generated_in_id`/`generated_out_id` + `snapshot_time` |
| 前端设计 | 一个页面 + takeType 控制，不是两个页面 |
| 出库 audit 未同步修复 | ⚠️ 盘点前先修复或确保事务保护 |

**总体判定：plan 方向正确，核心决策（留单据、用均价、后端快照）与现有基础设施兼容。实施时重点关注 5a（Spring 代理）+ 5b（快照不加锁）+ 出库 TOCTOU 修复。**
