# brainstorm 评审 — 采购订单收货 P0 修复方案

> **评审视角：** 产品/业务完整性 — 正向流程覆盖、逆向/异常场景、上下游数据口径、模糊表述澄清
> **评审对象：** 采购收货 P0 修复方案草案（超收竞态 + 订单外物料 + 订单状态回写）
> **日期：** 2026-07-22

---

## 评审结论

**核心修复方向正确，但草案范围不够。**

当前 `audit()` 方法存在 4 个独立的结构性缺陷，仅修复 2 个 P0 不足以让收货链路可靠运行：
1. ✅ 草案覆盖：超收竞态（P0-a）+ 订单外物料拦截（P0-b）+ 订单状态回写（P1）
2. ⚠️ 草案**未覆盖**：审核中"先扣库存再改状态"的顺序反了（副作用先于原子守卫）→ 并发失败时库存幻增
3. ⚠️ 草案**未覆盖**：应付税额硬编码 13% 忽略订单行实际税率 → 多税率订单的业财数据不一致
4. ⚠️ 草案**未覆盖**：收货编辑/删除缺少 FOR UPDATE 行锁（与刚修复的采购订单 P0-3 同款漏洞）

**建议将本轮修复升级为 5 项（原 2 P0 + 原 P1 + 上述 ②③），收货编辑/删除锁（④）同步修以保持模式一致。**

---

## ✅ 思路对齐

以下设计方向与产品预期一致，无需调整：

| 条目 | 草案方向 | 评审 |
|------|---------|:--:|
| 超收竞态 | 订单行增加 `received_qty` 字段，入库时用 `UPDATE ... SET received_qty = received_qty + ? WHERE ... AND order_qty >= received_qty + ?` 原子扣减 | ✅ 正确，与出库模块 `stockOut` 的 FOR UPDATE 模式一致 |
| 订单外物料 | `validateReceipt` 中 `orderQtyMap.get()` 返回 null 时**报错而非跳过** | ✅ 正确，当前代码 L.214 `if (orderQty != null)` 直接跳过了 null 情况 |
| 订单状态回写 | 收货审核后，按累计入库量 vs 订单总量比较，回写 `4`（部分到货）或 `5`（已到货） | ✅ 方向正确，但需明确"累计"口径（含本次 + 历史已审核入库） |
| 收货状态 | 草稿(1) → 已入库(2)，单向不可逆 | ✅ 清晰 |

---

## ⚠️ 遗漏或风险

### 遗漏 1：审核中副作用执行顺序反了（高风险）

**位置：** `MesPurchaseReceiptServiceImpl.audit()` L.118-133

**现状：**
```java
// ① 先逐行加库存（副作用）
for (item : items) {
    inventoryService.stockIn(...);  // 库存已+10
}
// ② 再生成应付（副作用）
payableService.save(ap);            // 应付已生成
// ③ 最后才原子改状态（守卫）
int rows = baseMapper.auditWithGuard(id, username, now);  // 并发失败返回0！
```

**问题：** 如果另一个请求几乎同时审核同一张入库单，第一个请求的 `auditWithGuard` 成功（status 1→2），第二个请求的 `auditWithGuard` 返回 0（status 已是 2），但此时**库存已经 +10、应付已经生成**——事务回滚只撤 DB 写入，不撤库存服务调用（如果有独立库存服务的话）。

> **严重性：** 本项目的 `inventoryService.stockIn()` 和 `payableService.save()` 与 audit 在同一 `@Transactional` 下，MySQL 回滚会撤销 INSERT。但**这种行为依赖隐式事务传播，且与 code-style.md 明确规定的"audit 先改状态再执行副作用"原则相悖。** 同时，如果未来库存独立成微服务，这个顺序会成为分布式事务黑洞。

**建议：** 调换顺序为：
```java
// ① 先原子改状态（守卫）
int rows = baseMapper.auditWithGuard(id, username, now);
if (rows == 0) throw ...;
// ② 状态确认后才执行副作用
for (item : items) inventoryService.stockIn(...);
payableService.save(ap);
```
这与采购订单 `audit()` 的实现模式一致，且 `code-style.md` 已有明确规则（L.110）。

---

### 遗漏 2：应付税额硬编码 13%，忽略订单行实际税率（中风险）

**位置：** `MesPurchaseReceiptServiceImpl.audit()` L.144

**现状：**
```java
ap.setTaxAmount(totalAmount.multiply(new BigDecimal("0.13"))
    .setScale(2, RoundingMode.HALF_UP));
```

**问题：** 采购订单行已支持多税率（Entity 有 `taxRate` 字段），但应付生成时无视订单行的实际税率，统一按 13% 计算。结果：
- 农产品（0%）采购入库后，应付税额 = 金额 × 13% → 应付虚增
- 小规模纳税人（3%）采购入库后，应付税额 = 金额 × 13% → 多计提 10% 应付
- 财务对账时发现应付金额 ≠ 发票金额 → 调账

**建议：** 从订单行取 `taxRate`，逐行计算：`Σ(item.amount × orderItem.taxRate)`。同时 `totalAmount` 应为"不含税金额"口径，确保与订单实体的 `totalAmount`（不含税）一致。

---

### 遗漏 3：收货编辑/删除缺少 FOR UPDATE 行锁（中风险）

**位置：** `MesPurchaseReceiptServiceImpl.updateWithItems()` L.83-97 + `removeWithItems()` L.100-107

**现状：** 与采购订单第 1 轮审计时相同的"先查状态再写"两步非原子模式：
```java
checkStatus(entity, "edit");  // SELECT ... WHERE id=? → status='1' ✓
// ⚡ 并发窗口：此时另一个请求审核了该入库单，status 变为 '2'
validateReceipt(entity);
entity.setStatus("1");        // 强制回写草稿状态！
super.updateById(entity);     // 已入库的单据被静默改回草稿
```

**问题：** 这与刚修复的采购订单 P0-3 是同款漏洞。虽然收货→入库通常是单人操作（不像订单多人并发），但系统层面不应依赖"操作习惯"来防并发。

**建议：** 参照采购订单 P0-3 修复模式：
1. Mapper 增加 `selectByIdForUpdate`
2. `updateWithItems` / `removeWithItems` 改用 FOR UPDATE 行锁 + inline guard
3. 编辑不回写 status（或 null 掉）

---

### 遗漏 4：`validateReceipt` 累计校验本身也是非原子的（中风险）

**位置：** `validateReceipt()` L.189-203（历史入库量汇总）

**现状：** 即使草案实现了 `received_qty` 字段的原子扣减，`validateReceipt` 中计算历史入库量（查询 `c_mes_purchase_receipt_item` 汇总）仍与后续的 INSERT 之间存在竞态窗口：
```
请求A: SELECT SUM(receipt_qty) → 历史=50 → 校验通过(50+30=80 ≤ 100)
请求B: SELECT SUM(receipt_qty) → 历史=50 → 校验通过(50+30=80 ≤ 100)
请求A: INSERT receipt_item (qty=30)
请求B: INSERT receipt_item (qty=30)
结果: 实际入库=60+50=110 > 100（超收10）
```

**建议：** `validateReceipt` 的累计校验定位为"保存时的前置友好提示"（拦截明显超量），真正的原子防线放在 `audit()` 中用 `received_qty` 的 `UPDATE ... WHERE order_qty >= received_qty + ?` 做最后一道锁。两层防线各司其职：校验层给出友好报错信息，审核层保证并发安全。

---

### 风险 5：订单状态回写的"累计"口径需明确（中风险）

**问题：** 草案提到"按累计入库量回写订单状态 4/5"，但未明确：
- "累计"是否包含**草稿状态的收货单**？还是仅统计**已审核（status='2'）的收货单**？
- 如果某物料被部分退货（后续需求），`received_qty` 是否回退？
- 多收货单并发审核时，订单状态回写本身是否也需要原子守卫？

**建议：**
- **累计口径 = 仅已审核的收货单**（status='2'），草稿不算
- `received_qty` 初始 = 已审核累计，新增审核时原子递增
- 订单状态回写使用 `UPDATE ... WHERE id=? AND status IN ('3','4')` 的原子条件，防并发覆盖
- 当前不涉及退货，但预留 `received_qty` 可扣减的设计（如退货时 `received_qty - qty`）

---

### 风险 6：`received_qty` 字段放置位置不明确（低风险）

**问题：** 草案未明确 `received_qty` 放在订单行表还是收货行表。

**建议：** 放在**采购订单行表** (`c_mes_purchase_order_item`)，因为：
1. 这是"该订单行累计已入库量"的权威来源，与订单生命周期绑定
2. 收货行表已有 `receipt_quantity`（本次入库量），再加 `received_qty` 会冗余
3. 原子 UPDATE 需要订单行级别的行锁，放在订单行表最直接

SQL 新增字段：
```sql
ALTER TABLE c_mes_purchase_order_item ADD COLUMN received_qty DECIMAL(18,4) DEFAULT 0 COMMENT '累计已入库数量';
```

---

## 💡 优化建议

### 建议 1：审核中取价逻辑需要匹配正确的订单行

**位置：** `audit()` L.120-123

**现状：**
```java
piQw.eq(MesPurchaseOrderItem::getOrderId, e.getPurchaseOrderId())
    .eq(MesPurchaseOrderItem::getMaterialId, item.getMaterialId());
List<MesPurchaseOrderItem> orderItems = purchaseOrderItemMapper.selectList(piQw);
if (!orderItems.isEmpty() && orderItems.get(0).getUnitPrice() != null) {
```

**风险：** 同一物料在同一订单中出现两次（不同批次/规格）时，`get(0)` 可能取到错误的单价。

**建议：** 收货行增加 `order_item_id` 字段关联到具体的订单行，或至少在多条匹配时报错（`if (orderItems.size() > 1) throw ...`），避免静默取错价格。

---

### 建议 2：`resurrect` 需要增加影响行数校验

**位置：** `saveWithItems()` L.74

**现状：** `baseMapper.resurrect(entity)` 无返回值校验。

**建议：** 与采购订单 P1-2 修复保持一致：
```java
if (baseMapper.resurrect(entity) == 0) throw new JeecgBootException("入库单号已存在");
```

---

### 建议 3：应付生成 `DuplicateKeyException` 吞掉时需确认场景

**位置：** `audit()` L.148

**现状：** `catch (DuplicateKeyException ex) { /* 已生成 */ }` — 静默吞掉异常。

**风险：** 应付 code = `"AP-" + receiptCode`。如果入库单被删除后 resurrect（同编号复用），新入库单的应付 code 与旧记录冲突 → 静默跳过 → 新入库没有应付。

**建议：** 应付 code 加入时间戳或唯一业务键（`AP-{receiptCode}-{auditTime}`），或在 catch 中校验已有应付的 `sourceBillId` 是否等于当前入库单 ID，不等则报错。

---

### 建议 4：`validateReceipt` 中采购订单校验的 status 条件需检查

**位置：** `validateReceipt()` L.180

**现状：**
```java
if (!"3".equals(order.getStatus()) && !"4".equals(order.getStatus()))
    throw new JeecgBootException("采购订单状态不允许入库，仅已确认或部分到货状态可入库");
```

**确认：** 这个校验逻辑是正确的——只有已确认(3)和部分到货(4)的订单可以继续入库。但需确认状态'5'(已到货)是否也允许入库？如果一个订单已经是"已到货"状态（全部物料已入库），业务上不应再允许新建入库单。当前代码正确排除了 '5'。✅

---

## 正向业务流程覆盖检查

| 步骤 | 业务描述 | 当前 | 修复后 |
|:--:|---|:--:|:--:|
| 1 | 选择已确认的采购订单，创建入库单 | ✅ `validateReceipt` 校验订单 status ∈ {3,4} | 不变 |
| 2 | 逐行填写入库数量，系统校验不超采购量 | ⚠️ 累计校验有竞态窗口 | ✅ 双重防线：友好提示 + 原子扣减 |
| 3 | 系统拦截不在订单中的物料 | ❌ `orderQtyMap.get()==null` 静默跳过 | ✅ 直接报错 |
| 4 | 保存入库单（草稿状态） | ✅ 借尸还魂 + 编号唯一 | 不变 |
| 5 | 审核入库单：验证未超收 → 确认状态 → 扣库存 → 回写订单状态 → 生成应付 | ⚠️ 执行顺序反 + 缺订单回写 + 税额硬编码 | ✅ 调对顺序 + 回写 4/5 + 逐行取税率 |
| 6 | 全部入库后，订单状态自动变为"已到货" | ❌ 无此逻辑 | ✅ 按累计入库量判断 |
| 7 | 财务查看应付，金额含税口径一致 | ❌ 税额 13% 硬编码 | ✅ 按订单行税率逐行计算 |

---

## 上下游数据口径一致性检查

| 数据项 | 订单模块存储 | 收货模块取数 | 应付模块生成 | 是否一致？ |
|--------|:--|:--|:--|:--:|
| 不含税金额 | `totalAmount` = Σ行金额 | — | `totalAmount` = Σ(入库量 × 订单单价) | ✅ |
| 税额 | `taxAmount` = Σ(行金额 × 行税率) | — | 硬编码 13% | ❌ → 建议改为 Σ(行金额 × 订单行税率) |
| 含税总额 | `totalWithTax` = totalAmount + taxAmount | — | 未设置 | ❌ → 应付应增加含税总额字段 |
| 单价 | 订单行 `unitPrice` | `audit()` 从订单行取 | 间接通过 totalAmount | ✅ |
| 入库数量 | 订单行 `received_qty`(新) | `receipt_quantity` | — | ⚠️ received_qty 需在审核时原子递增 |
| 订单状态 | status 3→4→5 | `validateReceipt` 仅允许 3,4 | — | ⚠️ 需在审核后回写 4/5 |

---

## 建议的修复清单（优先级排序）

| 优先级 | 修复项 | 涉及文件 | 依赖 |
|:--:|------|------|:--:|
| **P0** | `validateReceipt`：订单外物料拦截（null → 报错） | ServiceImpl | 无 |
| **P0** | `audit()`：审核时原子超收守卫（`received_qty` + `UPDATE WHERE`） | Mapper + ServiceImpl + SQL | 需新增 DB 字段 |
| **P0** | `audit()`：副作用顺序调整（先改状态再扣库存） | ServiceImpl | 无 |
| **P1** | `audit()`：订单状态回写（按累计入库量 → 4/5） | ServiceImpl | 依赖 received_qty |
| **P1** | `audit()`：应付税额按订单行逐行取税率 | ServiceImpl | 无 |
| **P1** | `updateWithItems` / `removeWithItems`：FOR UPDATE 行锁 | Mapper + ServiceImpl | 参照采购订单 P0-3 模式 |
| **P2** | `saveWithItems`：resurrect 影响行数校验 | ServiceImpl | 无 |
| **P2** | `audit()`：同物料多行匹配时取价报错 / 加 orderItemId | ServiceImpl + Entity | 可选 |
| **P2** | 应付 code 幂等性加固 | ServiceImpl | 可选 |
