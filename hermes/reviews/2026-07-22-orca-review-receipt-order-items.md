# Orca Review: 采购入库单 — 采购订单明细选择方案

**评审日期:** 2026-07-22  
**评审人:** Orca Worker (term_9ea59870)  
**结论: 调整（Adjust）** — 方案方向正确，有 6 项必须调整的缺口和 3 项建议优化

---

## 1. 现有代码理解

阅读了以下 9 个文件确认当前状态：

| 文件 | 关键发现 |
|------|---------|
| `MesPurchaseReceiptController.java` | 标准 CRUD + audit，无订单明细加载端点 |
| `MesPurchaseReceipt.java` | 有 `purchaseOrderId`、`supplierId`、`warehouseId`、`status`、transient `items` |
| `MesPurchaseReceiptItem.java` | 有 `materialId`、`orderQuantity`、`receiptQuantity`、`unitPrice`、`amount`、`qcResult` |
| `MesPurchaseOrderItem.java` | 有 `materialId`、`quantity`、`receivedQty`、`unitPrice`、`taxRate`、`amount` |
| `IMesPurchaseReceiptService.java` | queryWithItems / save / update / remove / audit |
| `MesPurchaseReceiptServiceImpl.java` | audit 中通过 `orderId + materialId` 查订单行取单价+税率，`atomicReceive` 原子扣减 |
| `receipt.api.ts` | 现有 BASE `/mes/purchase/receipt`，6 个 API 函数 |
| `ReceiptDrawer.vue` | 手动逐行录入（物料选择 + 数量输入），无自动加载 |
| `JPurchaseOrderSelect.vue` | emit `change` 事件含 `{value, label, record}`，ReceiptDrawer 未监听 change |

---

## 2. 逐项评审

### 2.1 新建 ReceiptOrderItemDTO ✅ 方向正确，但有遗漏

**方案字段:** materialId / code / name / orderQty / receivedQty / remainQty / unitPrice

**评审:**
- ✅ 独立 DTO 是正确的——不与 Entity 耦合，`remainQty` 是计算字段
- ✅ 字段映射清晰：materialId→item.materialId, orderQty→item.orderQuantity, unitPrice→item.unitPrice
- ✅ `remainQty = orderQty - receivedQty` 可直接从 `MesPurchaseOrderItem` 字段计算，不需要查历史入库

**缺失:**
- ❌ **缺少 `taxRate`** — audit 方法取税率时依赖订单行的 `taxRate`，DTO 不含此字段意味着前端看不到税率信息，但 audit 后端仍可自行查。**影响低（可接受）。** 但如果前端需要展示含税金额供用户确认，则必须加。
- ❌ **缺少 `orderItemId`** — audit 中通过 `orderId + materialId` 查询订单行，如果同一订单同一物料出现多行（不同行号），会取到第一行。DTO 应包含 `orderItemId` 字段以便精确关联。**但方案声明不修改表结构**，可暂不关联。

### 2.2 新增 Controller 端点 `GET /receipt/orderItems/{orderId}` ⚠️ 缺少权限和校验

**方案:** Controller 新增 GET 端点，返回 `List<ReceiptOrderItemDTO>`

**评审:**
- ✅ 端点命名清晰，RESTful 风格正确
- ✅ 只读操作，无副作用

**必须调整:**
- ❌ **缺少 `@RequiresPermissions`** — 所有 Controller 方法必须加权限注解（security-gate-checklist.md P0-1）。建议使用 `mes:purchaseReceipt:add`（新增入库时使用）或 `mes:purchaseReceipt:list`
- ❌ **缺少订单状态校验** — 应校验订单 status 为 `3`（已确认）或 `4`（部分到货），只有这些状态才允许入库。`validateReceipt` 已有此校验，但端点应独立校验
- ❌ **缺少 `update-begin/update-end` 标记** — 代码规范强制要求所有新增/修改代码加痕迹注释
- ❌ **缺少 `@Operation` 注解** — 需添加 API 文档说明

**建议调整:**
- ⚠️ 建议将查询逻辑放到 Service 层（`IMesPurchaseReceiptService.loadOrderItemsForReceipt(orderId)`），遵循后端优先原则。此端点逻辑简单（join 两张表），放 Controller 也可接受

### 2.3 修改 receipt.api.ts → 新增 loadOrderItemsForReceipt ✅ 通过

**方案:** 新增前端 API 函数调用新端点

**评审:**
- ✅ 命名清晰，遵循现有命名风格
- ✅ 路径与后端端点一致

### 2.4 修改 ReceiptDrawer.vue ⚠️ 有交互设计缺口

**方案:** 选择订单后自动加载明细、勾选、编辑入库数量

**评审:**

**必须调整:**
- ❌ **缺少订单变更处理** — 当前 `JPurchaseOrderSelect` 组件 emit `change` 事件，但 ReceiptDrawer 的 slot 模板未监听。必须添加 `@change` 处理器，在订单变更时：
  - 清空已有 items（或弹确认框）
  - 调用 `loadOrderItemsForReceipt` 加载新订单明细
  - 如果清空已有 items，需提示用户数据将丢失

- ❌ **"勾选"语义不明确** — 方案说"支持勾选入库"：
  - 如果是有 checkbox 列选择哪些订单行入库 → 需要新增 `selected` 状态管理
  - 如果是所有订单行都加载，用户编辑入库数量 → 不需 checkbox，但需要"不填数量=不入库"的约定
  - **建议方案：** 所有订单行自动加载，`receiptQuantity` 默认 0（或 remainQty），用户修改入库数量，提交时过滤掉 `receiptQuantity <= 0` 的行

- ❌ **"添加行"按钮与自动加载的关系不明确** — 当前有 `addLine` 按钮支持手动添加行。订单自动加载后：
  - 是替换手动模式？
  - 是在自动加载基础上追加？
  - **建议：** 订单加载后覆盖 items，`addLine` 在已加载基础上追加（允许收非订单物料是错误做法，`validateReceipt` 会拦截）——所以应该禁用 `addLine` 当订单已加载

**建议调整:**
- ⚠️ 建议 `receiptQuantity` 默认为 `remainQty`（剩余可入库量），减少用户手动输入
- ⚠️ 建议在表格中展示 `remainQty` 列（只读），帮助用户判断是否超量
- ⚠️ 建议前端做客户端校验：`receiptQuantity <= remainQty`，后端 `validateReceipt` + `atomicReceive` 做服务端兜底

---

## 3. 综合风险分析

| 风险 | 等级 | 说明 |
|------|:--:|------|
| 并发：加载到提交之间另一入库单消耗了剩余量 | 🟡 低 | 已有 `atomicReceive` 原子扣减兜底，提交时报错即可 |
| 同物料多行混淆 | 🟡 低 | audit 通过 orderId+materialId 查单价，同物料多行取第一行——如果两行价格不同，金额可能算错 |
| 订单切换丢失数据 | 🔴 中 | 用户选错订单后切换，已填的入库数量丢失——需要确认提示 |
| 权限缺失 | 🔴 高 | 新端点无 `@RequiresPermissions`，Shiro 默认放行 |

---

## 4. 判定结论：调整（Adjust）

**方案方向正确，结构合理，可以实施。但必须先补齐以下 6 项：**

### 必须调整（实施前）

| # | 调整项 | 位置 |
|---|--------|------|
| 1 | 新端点加 `@RequiresPermissions("mes:purchaseReceipt:add")` | Controller |
| 2 | 新端点加订单状态校验（status=3 或 4） | Controller/Service |
| 3 | 所有新增/修改代码加 `update-begin/update-end` 标记 | 全部 4 个文件 |
| 4 | ReceiptDrawer 监听订单选择变更事件，变更时清空+重载 items | Vue |
| 5 | 明确"勾选"交互逻辑：建议全加载 + 默认数量=remainQty + 提交过滤零数量行 | Vue |
| 6 | 新端点加 `@Operation(summary = "...")` 注解 | Controller |

### 建议优化（可后续）

| # | 建议 | 原因 |
|---|------|------|
| 7 | DTO 加 `orderItemId` 字段（需同时扩展 receiptItem 表 + `orderItemId` 列） | 解决 audit 中同物料多行的单价歧义 |
| 8 | DTO 加 `taxRate` 字段 | 前端可展示含税金额，提升业务透明度 |
| 9 | 订单加载后禁用 `addLine` 按钮（或改为"追加非订单物料"警告） | 当前 `validateReceipt` 已拦截订单外物料，添加行没有意义 |

---

## 5. 附录：代码阅读清单

评审过程中阅读了以下文件以确保理解完整上下文：

1. `MesPurchaseReceiptController.java` — 现有端点全集
2. `MesPurchaseReceipt.java` — 入库单实体（含 transient items）
3. `MesPurchaseReceiptItem.java` — 入库行实体（含 orderQuantity/receiptQuantity/unitPrice/amount）
4. `MesPurchaseOrderItem.java` — 订单行实体（含 receivedQty 原子计数器）
5. `IMesPurchaseReceiptService.java` — 服务接口
6. `MesPurchaseReceiptServiceImpl.java` — 服务实现（含 audit + validateReceipt + atomicReceive）
7. `receipt.api.ts` — 前端 API 层
8. `ReceiptDrawer.vue` — 前端抽屉组件（含手动录入模式）
9. `receipt.data.ts` — 表单 schema
10. `JPurchaseOrderSelect.vue` — 采购订单选择组件（含 change 事件）
11. `order.api.ts` — 采购订单 API
12. `IMesPurchaseOrderService.java` — 订单服务接口
13. `MesPurchaseOrderServiceImpl.java` — 订单服务实现（queryWithItems 参考）
