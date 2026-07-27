# Orca 评审：其它出入库实施计划

**评审对象**：MES"其它入库""其它出库"新模块 24 文件 + 3 注册点实施计划
**评审日期**：2026-07-28
**评审人**：Claude Opus（Orca 独立终端 dispatched worker）

---

## 一、通过 ✅

### 1. 后端包 `mes/stock/` 位置合理

已查现有模块布局：
- `mes/purchase/` — 采购（申请/订单/入库/台账）
- `mes/sales/` — 销售（订单/出库/价格/发货）
- `mes/manufacturing/` — 生产（BOM/订单/领料/完工入库）
- `mes/basic/` — 基础（库存/物料/仓库/库位/供应商/客户）
- `mes/finance/` — 财务（应收/应付/收款/付款/凭证/发票）

"其它出入库"不属于采购、销售、生产三链中的任何一条，是**独立业务类型**。`basic/` 是基础设施（不包含业务单据），`inventory/` 是库存数据（不包含业务流水）。新建 `stock/` 包在语义上正确——它是库存变动的业务操作层，不是基础数据。

### 2. 库存联动签名调用正确

已查 `IMesInventoryService`（`jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/service/IMesInventoryService.java`）：
```java
void stockIn(String materialId, String warehouseId, BigDecimal qty,
    BigDecimal unitCost, BigDecimal amount, String bizType, String bizId);
void stockOut(String materialId, String warehouseId, BigDecimal qty,
    BigDecimal unitCost, BigDecimal amount, String bizType, String bizId);
```

方案中计划传 `null` 给 `unitCost` 和 `amount` 参数，已查 `MesInventoryServiceImpl.stockOut`（L42-53）和 `stockIn`（L28-39），确认：
- `stockIn(null, null)` → `writeLedger(..., unitCost=null, amount=null, ...)` → 台账中 `inAmount`/`unitCost` 为 null，**符合"不记成本价、不影响库存金额"的业务需求**
- `stockOut(null, null)` → 同上，不影响金额，**符合"不产生应收应付"的需求**
- `stockOut` 内置库存不足拦截（L47：`if (before.compareTo(qty) < 0) throw ...`）→ **出库超量拦截已覆盖** ✅

### 3. 镜像模式选取正确

| 要镜像的模块 | 镜像原因 | 关键模式 |
|-------------|---------|---------|
| `purchase/receipt` | 入库流程（审核=原子状态守卫+库存+台账） | auditWithGuard、累计校验 |
| `sales/outbound` | 出库流程（超量拦截、库存扣减） | validate 超量、calcTotal |

已读 `MesPurchaseReceiptServiceImpl.audit()`（L128-197）和 `MesSalesOutboundServiceImpl.audit()`（L108-178），确认审核模式为：
1. 先原子改状态 `auditWithGuard`（`UPDATE ... WHERE status='1'` → rows=0 抛异常）
2. 成功后再执行副作用（库存变动/台账/业财联动）

此模式已通过采购入库 P0 修复验证，镜像实现正确。

### 4. 字典/编码规则/权限注册的分工正确

对照 `code-style.md` 约束：

| 事项 | 正确做法 | 方案是否遵守 |
|------|---------|:--:|
| 字典注册 | SQL DELETE+INSERT 幂等 | ✅ |
| 菜单注册 | Java Runner（MesMenuRegistry） | ✅ |
| 权限码 | leaf() + addPerms()，perms=id | ✅ |
| 编码规则种子 | INSERT IGNORE 固定 id | ✅（计划中） |
| SQL 不含中文菜单名 | SQL 只做建表/字典/角色绑定 | ✅ |
| 角色授权 | INSERT IGNORE sys_role_permission | ✅ |

### 5. 文件清单对照完整

对照 `purchase/receipt` 模块（7 个 Java 文件 + 5 个前端文件 = 12 个模块文件）：

| 组件 | purchase/receipt | 方案 其它入库 | 方案 其它出库 |
|------|:--:|:--:|:--:|
| Controller | 1 | 1 | 1 |
| Entity (header) | 1 | 1 | 1 |
| Entity (item) | 1 | 1 | 1 |
| Mapper (header) | 1 | 1 | 1 |
| Mapper (item) | 1 | 1 | 1 |
| Service (I) | 1 | 1 | 1 |
| Service (Impl) | 1 | 1 | 1 |
| **小计 (Java)** | **7** | **7** | **7** |
| index.vue | 1 | 1 | 1 |
| *.api.ts | 1 | 1 | 1 |
| *.data.ts | 1 | 1 | 1 |
| *Drawer.vue | 1 | 1 | 1 |
| *ItemsSubTable.vue | 1 | 1 | 1 |
| **小计 (Vue)** | **5** | **5** | **5** |

14 后端文件 + 10 前端文件 = 24 新文件 ✅（方案计数一致）

---

## 二、遗漏 ⚠️

### 漏-1 (P0)：其它出库反审核回退遗漏 — 库存恢复未提及

**现状分析**：
- `sales/outbound` 的 `cancel()`（L180-207）有完整的库存红冲：`stockIn(..., null, null, "销售出库红冲", e.getCode())` + 应收作废
- `purchase/receipt` 的 `unaudit()`（L200-208）只改状态不回冲库存（`status='2'→'1'`），因为采购入库不退货，反审核是管理流程

**评审问题**：其它出库审核后扣了库存，**反审核是否需要恢复库存**？计划中提到"审核流（草稿→已审核→库存原子变动+台账）"，但未提反审核。如果不需要反审核，应该明确说明并禁止；如果需要，应该像 sales/outbound cancel 一样有库存恢复。

**建议**：明确反审核策略。其它出库反审核应当恢复库存（类似 sales/outbound.cancel），其它入库反审核可以仅改状态（类似 purchase/receipt.unaudit）。两者不对称是因为入库可以物理移除，出库需要归还库存。

### 漏-2 (P0)：完工入库 `CompletionReceiptServiceImpl.audit()` 先库存后状态 — 方案镜像的是 bug 版

已读 `CompletionReceiptServiceImpl.audit()`（L114-127）：
```java
// 先加库存 → 再改状态 ← 顺序反了！
for (item : e.getItems()) {
    inventoryService.stockIn(..., "完工入库", e.getCode());  // 先执行
}
int rows = baseMapper.auditWithGuard(id, username, now);  // 后改状态
```

这与 `purchase/receipt` 的 audit 模式（先 `auditWithGuard` 后 `stockIn`）**顺序相反**——这是一个**已知 bug**（违反了 P0-01 修复规则"先改状态再执行副作用"）。`purchase/receipt` 已在 L137-138 修复了这个顺序问题，但 `completion` 模块未同步修复。

**方案影响**：如果其它出入库镜像的是 `purchase/receipt` 的正确模式，则无问题。但如果参考了 `completion` 模块，会引入同款 bug。**建议方案中显式声明以 purchase/receipt.audit 的顺序为准。**

### 漏-3 (P1)：明细表缺少审计字段

对照现有明细实体：

| 实体 | 有审计字段？ |
|------|:--:|
| `MesPurchaseReceiptItem` | ✅ createBy/createTime/updateBy/updateTime |
| `MesSalesOutboundItem` | ✅ createBy/createTime/updateBy/updateTime |
| `MesCompletionReceiptItem` | ✅ createBy/createTime/updateBy/updateTime |

方案中提到"库位：明细仅记录"，但**未明确说明明细表的审计字段**（createBy/createTime/updateBy/updateTime）。对照清单应包含这些字段，且 `saveItems()` 需设置（参照 `MesPurchaseReceiptServiceImpl.saveItems()` L299-311）。

### 漏-4 (P1)：`edit`/`delete` 缺少 FOR UPDATE 行锁

`purchase/receipt` 已修复此问题（`updateWithItems` L92-95 调用 `selectByIdForUpdate`，`removeWithItems` L115-118 调用 `selectByIdForUpdate`），但 `completion` 模块的 `checkStatus` 方法（L181-192）仍用普通 `selectById` 无锁。方案镜像 purchase/receipt 模式需确保带上 FOR UPDATE。

### 漏-5 (P1)：Controller 缺少 `loadOrderItemsForReceipt` 等价接口

purchase/receipt 的 Controller 有 `/loadOrderItemsForReceipt`（L99-104）用于"选择采购单后加载明细行"。其它出入库没有关联订单，不需要此接口。但出库超量拦截的逻辑不依赖累计出库量校验（因为没有关联上游单据），仅依赖 `stockOut` 内置的库存不足异常。**方案应明确说明：不与订单/申请关联，因此不需要累计出库量校验（无需 loadXxxItems 接口）**，否则评审时会认为是遗漏。

### 漏-6 (P1)：其它出库的 `deliveryQty`/`actualQty` 字段语义不清晰

`sales/outbound` 明细有 `deliveryQty`（发货单来源，不可修改）和 `actualQty`（实际出库，用户填写）。其它出库没有发货单来源，**只有一个数量字段**。方案未明确明细表应该有一个字段还是两个字段。

**建议**：明细用一个 `qty` 字段（本次出入库数量），不需要 deliveryQty/actualQty 分离。在 DDL 和 Entity 中明确。

### 漏-7 (P2)：前端没有 `ItemsSubTable.vue` 的独立需求分析

其它出库明细不需要"从发货单加载→锁定 deliveryQty 不可修改"的复杂逻辑，SubTable 会比 sales/outbound 简单很多（只有物料选择+数量输入，类似 completion 的 SubTable 但加上库位和原因）。但方案中计入了 ItemsSubTable.vue 文件。

对照现有 practice：
- `purchase/receipt` 有 `ReceiptItemsSubTable.vue`（需从采购订单加载可入库明细）
- `sales/outbound` **没有** ItemsSubTable.vue（明细直接在 OutboundDrawer.vue 内用 BasicTable + inline editing 实现）
- `manufacturing/completion` 也没有独立 ItemsSubTable.vue

**建议**：明确其它出入库的明细是否走独立 SubTable 组件（类似 receipt）还是内联实现（类似 sales/outbound）。文件计数可能偏高。

### 漏-8 (P2)：编码规则需要在 `bizCodeMap.ts` 和 SQL 中注册

方案提到编码规则种子×2（INSERT IGNORE），但未提前端映射：
- `jeecgboot-vue3/src/views/project/mes/basic/codeRule/bizCodeMap.ts` 需要新增 `OTHER_STOCK_IN: 'QT-IN'` 和 `OTHER_STOCK_OUT: 'QT-OUT'` 两条
- Drawer 内需要调 `getNextCode(MES_BIZ_CODE.OTHER_STOCK_IN)` 自动编码

当前 `bizCodeMap.ts` 已有 12 条映射，新增 2 条是标准操作，但方案中应明确。

---

## 三、建议 💡

### 建议-1：表名字遵循现有命名前缀

现有表以 `c_mes_` 前缀（`c_mes_purchase_receipt`、`c_mes_sales_outbound`），方案应使用：
- `c_mes_other_stock_in` / `c_mes_other_stock_in_item`
- `c_mes_other_stock_out` / `c_mes_other_stock_out_item`

**建议**：在 DDL 计划中使用明确表名，而非缩写或代号。

### 建议-2：DDL 中 `uk_code_del` 索引用统一命名

现有表统一使用 `UNIQUE INDEX uk_xxx_code_del (code, del_flag)` 命名：
- `uk_receipt_code_del` (purchase/receipt)
- `uk_outbound_code_del` (sales/outbound)
- `uk_completion_code` (completion — 命名不规范，历史包袱)

**建议**：新表使用标准命名：`uk_other_stock_in_code_del` / `uk_other_stock_out_code_del`。

### 建议-3：字典名用两个独立字典（非共用一个）

方案提到"类型走可维护数据字典（两个字典）"，确认是两个独立字典（如 `mes_other_stock_in_type` 和 `mes_other_stock_out_type`），而非一个字典的两种选项。入库类型（盘盈入库、调整入库等）与出库类型（盘亏出库、报废出库等）不同，分开维护符合业务语义。

### 建议-4：复合唯一索引 vs 普通索引

`purchase/receipt` 明细表只有 `INDEX idx_item_receipt_id (receipt_id)`（普通索引），`sales/outbound` 明细表也只有 `INDEX idx_obi_outbound_id (outbound_id)`（普通索引）。新模块的明细表应一致使用普通索引（不需要唯一索引——明细行可以有重复，同一单内同一物料允许多行）。

### 建议-5：`editWithItems` 需要 `selectByIdForUpdate` + `status` 保护

`purchase/receipt` 的 `updateWithItems`（L89-110）已包含：
1. `selectByIdForUpdate` FOR UPDATE 行锁
2. `status != "1"` 禁止编辑
3. 敏感字段置 null（`delFlag`/`createBy`/`createTime`/`status`）

`completion` 的 `updateWithItems`（L73-87）**缺少 FOR UPDATE 锁**（用 checkStatus 普通 selectById）。新模块应以 `purchase/receipt` 为参照，不是 `completion`。

### 建议-6：Controller 权限码命名规范

`purchase/receipt` 的权限码是 `mes:purchaseReceipt:list/add/edit/delete/...`，`sales/outbound` 是 `mes:outbound:list/add/edit/delete/...`。

**建议**新模块用语义化前缀：
- 其它入库：`mes:otherStockIn:list/add/edit/delete/deleteBatch/export/audit`
- 其它出库：`mes:otherStockOut:list/add/edit/delete/deleteBatch/export/audit`

### 建议-7：`reason`（原因）字段不设为字典——允许手工填写

方案提到"原因手工填"，确认不建字典（`remark` 字段就是 VARCHAR 自由文本）。但需要区分"备注"和"原因"——如果是独立字段，DDL 中需要单独列（如 `reason VARCHAR(500)`）。

### 建议-8：business-chains.json 应注册新链路

`hermes/business-chains.json` 可能需要新增"其它出入库"链路条目（取决于是否参与已有的质量门控链路）。如果其它出入库不在采购/销售/生产链路中，可以作为独立模块注册或标记为 `standalone`。

---

## 总结

| 维度 | 判定 |
|------|:--:|
| 包位置 mes/stock/ | ✅ 通过 — 独立业务类型，既不属三链也不属基础数据 |
| 库存签名调用 | ✅ 通过 — null cost 传参经代码确认可行 |
| 镜像模式选取 | ✅ 通过 — purchase/receipt + sales/outbound 是正确参照 |
| 文件计数 | ✅ 通过 — 14 Java + 10 Vue = 24 新文件 |
| 注册分工 | ✅ 通过 — SQL/Dict/Runner/Route 分工符合约束 |
| 反审核回退 | ⚠️ 遗漏 P0 — 出库反审核库存恢复未提及 |
| audit 顺序 | ⚠️ 遗漏 P0 — 需显式以 purchase/receipt（先状态后副作用）为准 |
| 明细审计字段 | ⚠️ 遗漏 P1 — DDL 未明确 createBy/createTime 等 |
| 行锁保护 | ⚠️ 遗漏 P1 — edit/delete 需 FOR UPDATE |
| 字段语义 | ⚠️ 遗漏 P1 — 出库明细 qty vs deliveryQty/actualQty 待明确 |
| 前端 SubTable | ⚠️ 遗漏 P2 — 独立组件 vs 内联实现未决定 |
| 编码规则映射 | ⚠️ 遗漏 P2 — bizCodeMap.ts 需加 2 条 |
