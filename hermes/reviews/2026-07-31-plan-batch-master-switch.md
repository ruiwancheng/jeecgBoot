# /plan 评审：生产批次总开关 + 物料级开关联动

**评审人：** Claude Opus 4.8
**评审日期：** 2026-07-31
**评审阶段：** plan（架构/实施可行性评审）
**基准：** orca-review SKILL.md plan 阶段评审标准（6 维度）

---

## 总体评价：方向正确，但 L2/L3 检查设计和业务表关联有 2 个 P0 级事实错误

方案的核心思路——key-value 全局开关 + Service 层注入判断——设计简洁且符合项目现有模式。文件清单覆盖了 12 个新增/修改文件，策略判定（纯新增）正确。

**但有两个 P0 级事实错误必须在实施前修正：**（1）L2 检查使用的状态值 `'IN_PROGRESS'` 在实际数据库中不存在；（2）L3 检查假设业务表有 `batch_id` 列，但实际通过 `c_mes_batch.origin_bill_id` 关联。

---

## 一、文件清单完整性

### 后端新增（7 个）

| 文件 | 判定 | 说明 |
|------|:--:|------|
| `system/entity/MesGlobalSwitch.java` | ✅ | key-value 结构合理 |
| `system/controller/MesGlobalSwitchController.java` | ✅ | 标准 CRUD + closeWithCheck |
| `system/service/IMesGlobalSwitchService.java` | ✅ | 接口定义 |
| `system/service/impl/MesGlobalSwitchServiceImpl.java` | ✅ | 含 checkCanClose |
| `system/mapper/MesGlobalSwitchMapper.java` | ✅ | — |
| `resources/mapper/mes/MesGlobalSwitchMapper.xml` | ✅ | — |
| `db/V8.0.2__mes_global_switch.sql` | ✅ | 建表 + 种子 |

### ⚠️ 遗漏 1 项

| 遗漏 | 说明 |
|------|------|
| **前端路由注册** | 草案提到 `api/project/mes/system/commonSetting.api.ts`，但没有提到路由文件 `jeecgboot-vue3/src/router/routes/modules/mes.ts` 需要新增路由条目。按 `frontend.md` 路由规范，新页面必须注册路由 + 菜单，两者缺一都 404。 |

### 后端修改（5 个）

| 文件 | 判定 | 说明 |
|------|:--:|------|
| 4 个 Service | ✅ | 4 个已确认文件路径，代码已验证 |
| MesMenuRegistry.java | ✅ | mes_basic 下加新菜单，sortNo 建议 4.0（接 codeRule 3.0 之后） |

### ⚠️ 遗漏 2 项

| 遗漏 | 说明 |
|------|------|
| **其它入库 Service** | 草案只列了 4 个 Service，但 `MesOtherStockInServiceImpl` 也可能涉及批次。需确认 V8.0.0 是否已集成其它入库的批次创建逻辑。如是 → 需补第 5 个 Service。 |
| **其它出库 Service** | 同理 `MesOtherStockOutServiceImpl`。需确认。 |

### 前端文件

| 文件 | 判定 | 说明 |
|------|:--:|------|
| `basic/commonSetting/index.vue` | ✅ | 通用设置列表页 |
| `basic/commonSetting/commonSetting.data.ts` | ✅ | 列+搜索+表单 schema |
| `api/project/mes/system/commonSetting.api.ts` | ✅ | API 路径枚举 |
| `basic/material/material.data.ts`（修改） | ⚠️ 见下文 | batchEnabled 字段 + 总开关联动 |
| `basic/material/index.vue`（修改） | ✅ | 加载总开关状态 |
| **路由文件 mes.ts（修改）** | ⚠️ 遗漏 | 必须注册新路由条目 |

### 结论

文件清单缺 1-3 个文件：路由注册（必补）、其它出入库 Service（需确认）。

---

## 二、策略判定

**判定：策略 1 纯新增** — ✅ **正确。**

不涉及标品代码修改，全部在 `project-mes/` + `src/views/project/mes/` 下。MesMenuRegistry 已有 `mes_basic` 文件夹，新菜单挂在下面即可。

---

## 三、依赖查证（5 项标准）

| # | 检查项 | 状态 | 说明 |
|---|--------|:--:|------|
| 1 | Shiro 权限链 | ✅ | 菜单在 MesMenuRegistry 注册 + addPerms 补齐权限码，模式已验证 |
| 2 | SQL 兼容性 | ⚠️ | 见下文 P0-1/P0-2 |
| 3 | 前端组件 | ⚠️ | 见下文 P2-4（window 全局变量 vs pinia） |
| 4 | 字典存在 | ✅ | 无新字典，yn 字典已存在 |
| 5 | 父菜单存在 | ✅ | mes_basic (sortNo 10.0) 已存在，子菜单有 customer/supplier/codeRule |

---

## 四、P0 发现（必须修正）

### P0-1：L2 检查使用的状态值 `'IN_PROGRESS'` 在数据库中不存在 🔴

**事实：** 草案写"进行中批次（`mes_batch_master WHERE status='IN_PROGRESS'`）"，但实际表定义：

```sql
-- V8.0.0__mes_batch_init.sql
status VARCHAR(20) DEFAULT '1' COMMENT '状态(dict:mes_batch_status)'
```

字典 `mes_batch_status` 的实际值：`'1'`=在用、`'2'`=冻结、`'3'`=已耗尽、`'4'`=过期。**没有 `'IN_PROGRESS'` 这个值**。

BatchMaster entity 也用 `String status` + `@Dict(dicCode = "mes_batch_status")`，与 DDL 一致。

**修正建议：** L2 检查"进行中批次"应改为检查 `c_mes_batch_inventory WHERE qty > 0`（有库存的批次），或直接并入 L1（L1 已检查 `mes_batch_inventory WHERE qty > 0`）。状态字典中没有"进行中"的概念——批次的状态是"在用/冻结/已耗尽/过期"，不是业务流的"进行中/已完成"。

### P0-2：L3 检查假设业务表有 `batch_id` 列，实际没有 🔴

**事实：** 草案写"`mes_completion_receipt WHERE batch_id IS NOT NULL AND status != 'COMPLETED'`"。但代码实证（`CompletionReceiptServiceImpl.audit()` L137-143）：

```java
String batchId = batchService.createBatch(
    item.getMaterialId(), "2",           // origin_type=2
    e.getId(), e.getCode(),              // origin_bill_id = 完工入库单ID
    item.getReceiptQty(), null, null, null);
```

完工入库表**本身没有 `batch_id` 列**。批次通过 `c_mes_batch.origin_bill_id` 反向引用业务单据。

同理，4 个业务表（完工入库/领料/采购入库/销售出库）都**没有 `batch_id` 列**。

**修正建议：** L3 检查应改为通过 `c_mes_batch` 表反向查：

```sql
-- 检查是否有"关联了未完结业务单据"的批次
SELECT COUNT(*) FROM c_mes_batch b
WHERE b.origin_type = '1'  -- 采购入库
  AND b.origin_bill_id IN (
    SELECT id FROM c_mes_purchase_receipt WHERE status = '1' -- 草稿（未审核）
  )
```

每个业务类型分别查。或者更简化：L3 直接纳入 L1——任何有库存的批次如果"来源单据未审核"就是一种风险状态。

---

## 五、P1 发现（建议修正）

### P1-1：9 个切片粒度过细——建议合并为 5 片

| 草案切片 | 合并建议 | 理由 |
|----------|---------|------|
| 1（建表）+ 2（Entity/Mapper） | **合并为切片 A：建表+后端基础层** | Entity 和 Mapper 只有字段定义无业务逻辑，单独成片无法独立验证（没有 Controller 调用）。建表 SQL 和执行是同一上下文，分开 commit 无意义。 |
| 3（Service+checkCanClose） | **切片 B：Service 核心逻辑** | checkCanClose 是核心业务逻辑，单独一片合理。 |
| 4（Controller） | **并入切片 B** | Controller 的 closeWithCheck 直接调 Service.checkCanClose，分开后 Service 片无法 curl 验证。 |
| 5（注册菜单） | **并入切片 C** | 菜单没有功能页面时不可验证（看不到菜单项对应的页面）。应与前端通用设置页合并。 |
| 6（前端通用设置页） | **切片 C：前端通用设置页（含菜单+路由）** | 页面 + 菜单 + 路由作为一个端到端闭环。 |
| 7（前端物料联动） | **切片 D：前端物料联动** | 依赖切片 C（总开关状态来源），独立验证场景清晰。 |
| 8（4 个 Service 补总开关判断） | **切片 E：4 个 Service 集成** | 高风险片，应独立评审。 |
| 9（E2E 集成测试） | **并入各切片** | 按 decompose 方案的"每片内嵌 verify"原则，E2E 不应单独成片——应在切片 E 完成后跑集成测试验证。 |

**合并后的 5 片：**

| 切片 | 内容 | 风险 | 依赖 |
|------|------|:--:|------|
| A. 基础层 | 建表 + Entity + Mapper + Controller + Service（含 checkCanClose） | 高 | — |
| B. 前端通用设置 | 菜单注册 + 路由 + 通用设置页（BasicTable + 开关 + 关闭弹窗） | 中 | A |
| C. 前端物料联动 | material.data.ts formSchema 加 batchEnabled + index.vue 加载总开关 | 中 | B |
| D. 4 个 Service 集成 | CompletionReceipt/Picking/PurchaseReceipt/SalesOutbound 注入总开关判断 | 高 | A |
| E. E2E 集成测试 | 9 场景全覆盖 | 高 | D |

### P1-2：其它出入库 Service 漏检

草案只列了 4 个 Service。需要确认 `OtherStockInServiceImpl` 和 `OtherStockOutServiceImpl` 是否：
- 在 V8.0.0 批次管理 Phase 3 中已集成批次逻辑？
- 如果已集成 → 需补总开关判断（第 5、6 个 Service）
- 如果未集成 → 需在方案中标注"本次不涉及，Phase 4 补充"

### P1-3：总开关关闭后出库场景存在数据漂移

**问题：** 草案说"总开关关闭时不创建批次"——但出库时（领料/销售出库）`stockOutFifo` 仍在生效。也就是说：

```
总开关关闭 → 物料 batchEnabled=1 被禁用（前端 disabled）
→ 但已存在的历史批次库存（qty > 0）仍然可以被 stockOutFifo 扣减
```

**如果用户在总开关关闭期间执行了出库操作**：出库单审核时仍会调 `batchInventoryService.stockOutFifo()`（因为代码判断的是 `mat.getBatchEnabled()` 而非总开关状态）。批次库存被扣减但入库不创建新批次 → 负库存或数据漂移。

**修正建议：** 4 个 Service 的总开关判断应该覆盖**两个方向**：
```java
// 当前草案的设计（只覆盖入库）：
if (总开关关闭) → 跳过 createBatch（入库不创建批次）

// 应该覆盖出库方向：
if (总开关关闭) → 跳过 stockOutFifo（出库不扣批次库存，退回普通库存扣减）
```

这点草案的"待评审问题 2"已经提出来了，但方案中没有给出明确的设计决策。**建议在方案中明确：出库方向同样注入总开关判断，跳过批次扣减。**

### P1-4：关闭总开关时的 checkCanClose 与实际代码状态的竞态

`checkCanClose` 是"读时检查"，不是"原子操作"。场景：

```
T1: checkCanClose → 返回无阻塞（errors=[]）
T2: 另一用户在物料档案页勾选了 batchEnabled=1 并保存
T3: 当前用户点击"关闭总开关" → 写 DB 关闭
→ 第 T2 步的物料已启用批次，但总开关已关闭 → 数据不一致
```

**建议：** 关闭总开关的同时，批量将 `c_mes_material.batch_enabled` 全部置为 0（原子 UPDATE）。这样即便竞态发生，物料侧也会被统一关闭。或者接受此竞态为设计取舍，在文档中标明"在业务低峰期操作"。

---

## 六、P2 发现（优化建议）

### P2-1：前端 window 全局变量传递总开关状态不合适

**草案方案：** `material.data.ts` 用 `window.__MES_BATCH_ENABLED__` 全局变量读总开关状态。

**问题：**

1. **多 Tab 不同步**：Tab A 开启了总开关 → pinia 更新 → Tab B 的 `window.__MES_BATCH_ENABLED__` 仍是旧值直到手动刷新页面。Pinia 天然跨组件响应式，window 全局变量不是。
2. **SSR/测试环境**：`window` 在 Node.js 测试环境（Jest/vitest）中不可用。Pinia 可以被 mock。
3. **不符合项目规范**：JeecgBoot Vue3 前端全部使用 Pinia 做状态管理（`src/store/modules/`），没有用 window 全局变量传递业务状态的先例。

**建议：** 在 `src/store/modules/` 下新建 `mesGlobalSwitch.ts` Pinia store，`commonSetting` 页面修改开关后写 store，`material` 页面的 `batchEnabled` 字段从 store 读 disabled 状态。

参考项目现有 store 模式：`user.ts`（auth token+info）、`permission.ts`（routes+perms）、`app.ts`（project config+theme）。模式统一。

### P2-2：Controller `closeWithCheck` 的 REST 风格

**草案方案：** 返回 200 + `{ errors: [...] }`，前端通过 errors 非空判断是否有阻塞项。

**建议：** 保持 200 + `{ canClose: true/false, errors: [...] }` 的结构。**不要用 HTTP 400/409 表示"无法关闭"**——这不是客户端错误，是业务规则校验的正常结果。项目现有的 audit/review 类操作都是 200 + 业务状态码。与项目风格一致。

不过，**更简洁的方案**是：让 `closeWithCheck` 只做**查询**（不执行实际关闭）。前端拿到 `canClose: false` 时展示错误清单给用户确认；用户确认后再调 `save({ switchKey: 'mes_batch_enabled', value: 0 })` 执行关闭。这样职责分离清晰，不需要 `closeWithCheck` 作为写操作。

### P2-3：菜单注册时机

**问题：** MesMenuRegistry 是 `static volatile List<MesMenuDefinition> cached`——应用启动时通过 `getMenus()` 触发的 DCL 单例缓存。新增菜单定义后：

- **Java 代码层面**：mvn compile + DevTools 热重载 → 新类加载 → `cached` 仍是旧的（static 字段在 DevTools 重启时不重置）
- **需要重启后端**：确保 MesMenuRegistry 重新初始化

这是已知行为，不是 bug。但草案没有提到。建议在步骤中注明：`MesMenuRegistry 菜单注册后需重启后端才能生效`。

### P2-4：物料 formSchema 缺少 `batchEnabled` 字段的 Switch 配置

**事实：** `material.data.ts` 第 26-40 行的 formSchema 中**没有 `batchEnabled` 字段**（已实证）。计划说"formSchema 加 batchEnabled + 读总开关决定 disabled"是正确的，但需要明确：

```typescript
// 新增字段（Switch 组件，参考 frontend.md 组件常见坑表）
{ field: 'batchEnabled', label: '启用批次管理', component: 'Switch',
  colProps: { span: 8 },
  componentProps: { checkedValue: 1, unCheckedValue: 0 },
  defaultValue: 0,
  // disabled 由总开关状态决定（从 pinia store 读取）
  dynamicDisabled: true
}
```

按 `frontend.md` 的 Switch 规范：必须设 `checkedValue: 1, unCheckedValue: 0`，否则后端接收 boolean → Integer 反序列化报错。

---

## 七、高风险步骤识别

| 步骤 | 风险 | 理由 |
|------|:--:|------|
| 建表 SQL | 中 | key-value 表结构简单，无复杂索引 |
| checkCanClose 3 层检查 | **高** | 涉及多表 JOIN，当前 L2/L3 设计有事实错误（见 P0-1/P0-2） |
| 4 个 Service 补总开关判断 | **高** | 修改已有审核链路，漏一个就产生数据漂移 |
| 前端物料联动（batchEnabled disabled 逻辑） | 中 | 如果 disabled 逻辑判断错误，物料级开关形同虚设 |
| 菜单注册 | 低 | 已模式化，参考现有注册代码 |

---

## 八、步骤完整性检查（禁止 TODO/TBD）

| 步骤 | 判定 | 说明 |
|------|:--:|------|
| 1 建表 | ✅ | 表名/字段已明确 |
| 2 Entity/Mapper | ✅ | 字段映射已知 |
| 3 Service+checkCanClose | ⚠️ | L2/L3 的 SQL 设计有 P0 错误（见上），需要重新设计 |
| 4 Controller | ✅ | 接口定义明确 |
| 5 注册菜单 | ✅ | 父菜单/sortNo/权限码已明确 |
| 6 前端通用设置页 | ✅ | 页面功能描述清晰 |
| 7 前端物料联动 | ⚠️ | "window 全局变量"具体实现方式不明确（见 P2-1） |
| 8 4 个 Service 集成 | ⚠️ | 出库方向的判断策略不明确（见 P1-3） |
| 9 E2E 集成测试 | ✅ | 9 场景已列出 |

---

## 九、汇总

### 🔴 P0 必须修正（实施前）

| # | 问题 | 影响 |
|---|------|------|
| P0-1 | L2 检查 `status='IN_PROGRESS'` 在数据库中不存在（实际值 '1'/'2'/'3'/'4'） | checkCanClose 永远返回空——任何情况下都能关闭，等于没检查 |
| P0-2 | L3 检查假设业务表有 `batch_id` 列，实际通过 `c_mes_batch.origin_bill_id` 关联 | SQL 报错 "Unknown column 'batch_id'"，关闭检查功能不可用 |

### 🟡 P1 建议修正（实施中）

| # | 问题 | 建议 |
|---|------|------|
| P1-1 | 9 片过碎 | 合并为 5 片（基础层/前端设置/物料联动/Service 集成/E2E） |
| P1-2 | 其它出入库 Service 漏检 | 确认是否需要补 |
| P1-3 | 出库方向缺少总开关判断 | 明确：出库时也跳过 batchInventory 步骤 |
| P1-4 | checkCanClose 竞态 | 接受为设计取舍并记录，或关闭时批量清理物料 batchEnabled |

### 🟢 P2 优化建议

| # | 问题 | 建议 |
|---|------|------|
| P2-1 | window 全局变量 | 改用 Pinia store（mesGlobalSwitch.ts） |
| P2-2 | closeWithCheck REST 风格 | 200 + canClose/errors 结构，或拆分为查+写两个接口 |
| P2-3 | 菜单生效需重启 | 步骤中注明 |
| P2-4 | Switch 组件配置 | 补 checkedValue/unCheckedValue，遵循 frontend.md 规范 |

### ✅ 确认正确

- 策略判定（纯新增）✅
- key-value 表结构设计 ✅（灵活扩展，不限于批次一个开关）
- checkCanClose 分层检查思路 ✅（只是 SQL 细节需要修正）
- 4 个 Service 文件路径和代码位置 ✅
- MesMaterial.batchEnabled 字段已存在 ✅
- 总开关关闭后的降级策略 ✅（防数据库膨胀）
- 父菜单 mes_basic 已存在 ✅
