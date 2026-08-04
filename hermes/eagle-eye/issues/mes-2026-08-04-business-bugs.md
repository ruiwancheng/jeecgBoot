# MES 业务 Bug 清单（按模块分桶）

> 生成时间：2026-08-04T14:32:12+08:00
> 数据来源：`harness/.e2e-results.json`（32 E2E 失败） + 链路日志（4 链路失败）
> 提交 commit：`f15cae8 test(e2e): 补齐 10 个缺失的 MES 页面 E2E spec`
> 跑测命令：`PLAYWRIGHT_BASE_URL=http://localhost:3100 npx playwright test e2e/mes/ --workers=4`

## 总览

| 模块 | 失败切片数 | P1 | P2 | P3 |
|---|---|---|---|---|
| basic | 4 | 2 | 1 | 1 |
| batch | 3 | 0 | 1 | 2 |
| finance | 4 | 0 | 4 | 0 |
| purchase | 1 | 1 | 0 | 0 |
| sales | 1 | 0 | 0 | 1 |
| **合计** | **13** | **3** | **6** | **4** |

## 严重程度定义

- **P1**：整页不可用（所有/大部分交互失败），阻塞业务
- **P2**：核心流程缺失（新增/导出/抽屉触发等），数据可看不可改
- **P3**：次要按钮或契约不一致，不影响主流程

## 复核进度跟踪

| # | Issue | 严重程度 | 复核状态 | 核实结果 |
|---|---|---|---|---|
| 1 | 库存总览 (`/project/mes/warehouse/inventory`) | P1 | ✅ 误判 | URL 写错 + 页面是只读 dashboard，原 spec 误把“导出/新增/抽屉”当必备能力 |
| 2 | 库存预警 (`/project/mes/basic/inventoryAlert`) | P2 | 🔴 真实需求（产品优化） | 测试侧误判（spec 按 CRUD 模板生成） + 产品侧明确需要优化（用户判断：当前基本无用） |
| 3 | 编码规则 (`/project/mes/basic/codeRule`) | P3 | ✅ 误判 | 产品决策明确不需导出（后端 + 权限实际有，前端故意不接入） |
| 4 | 通用设置 (`/project/mes/basic/commonSetting`) | P1 | ✅ 误判（页面正常） + 🔴 发现独立 issue（SysMessageModal any 错误，需另建） | 页面渲染正常，pageerror 是 system 模块全局问题，与本页面无关 |
| 5 | 批次台账 (`/project/mes/batch/ledger`) | P3 | ✅ 误判 | 只读流水页面（导出有、增/删/改无），数据由入库/出库自动生成（用户判断） |
| 6 | 批次库存 (`/project/mes/batch/inventory`) | P3 | 🔵 待复核 | — |
| 7 | 其它入库自动预填 (`/project/mes/stock/other-in`) | P2 | 🔵 待复核 | — |
| 8 | 应收账款 (`/project/mes/finance/receivable`) | P2 | 🔵 待复核 | — |
| 9 | 收款管理 (`/project/mes/finance/collection`) | P2 | 🔵 待复核 | — |
| 10 | 应付账款 (`/project/mes/finance/payable`) | P2 | 🔵 待复核 | — |
| 11 | 付款管理 (`/project/mes/finance/payment`) | P2 | 🔵 待复核 | — |
| 12 | 采购台账 (`/project/mes/purchase/ledger`) | P1 | 🔵 待复核 | — |
| 13 | 销售链路 fixture (`/project/mes/sales/outbound`) | P3 | 🔵 待复核 | — |
| 14 | SysMessageModal `any is not defined`（全局 pageerror） | P3 | 🔴 真实 Bug | 已提排期（待认领） |

> 复核状态说明：
> - 🔵 待复核
> - 🟡 复核中（有问题/验证中）
> - ✅ 误判（写明核实依据）
> - 🔴 真实 Bug（写明核实依据）

---

## BASIC 模块

### [P1] 库存总览（/project/mes/warehouse/inventory）

- **后端 controller**：`MesInventoryController`
- **原报告症状**：页面 8/8 测试全失败：表格不渲染、列头/搜索/导出/新增按钮、数据行、抽屉、仓库筛选全部缺失

#### ✅ 复核结果：误判（2026-08-04 由 ruiwancheng/pi 复核）

**两个独立问题复合在一起造成误报，需拆开看：**

1. **测试 URL 写错**：spec 里写的是 `/project/mes/basic/inventory`，但菜单注册和 router 都把 inventory 放在 `warehouse` 父节点下，**正确 URL 是 `/project/mes/warehouse/inventory`**。修正 URL 后路由可达。
2. **页面是设计上的只读 dashboard**：
   - 后端 `MesInventoryController` 只暴露 `@GetMapping("/list")`，没有 add/edit/delete/exportXls
   - 前端 `inventory.api.ts` 只导出 `queryInventoryList`
   - 前端 `index.vue` 调用 `useListPage` 时**没有传** `exportConfig`、`importConfig`、也没启用新增/操作列
   - 菜单注册仅给 `mes:inventory:list` 权限
   - 对比仓库管理页（传了 `exportConfig: { url: getExportUrl }` → 有导出按钮），库存总览本来就无导出

**修正 URL + 后端就绪后重测（5 passed / 3 failed）：**

| 测试 | 结果 | 真实原因 |
|---|---|---|
| 1. 路由可达性 | ✅ pass | 路由 OK |
| 2. 表格 + 列头 | ✅ pass | 表格正常 |
| 3. 搜索表单 + 查询 | ✅ pass | 搜索表单正常 |
| 4. 导出按钮 | ❌ fail | **页面没导出按钮（设计如此）** |
| 5. 新增按钮 | ❌ fail | **页面没新增按钮（设计如此）** |
| 6. 数据行 | ✅ pass | 数据正常 |
| 7. 新增抽屉 | ❌ fail | **没新增按钮自然无抽屉（设计如此）** |
| 8. 仓库筛选 | ✅ pass | 仓库下拉正常 |

**核实依据**：调用 `cat jeecgboot-vue3/src/views/project/mes/basic/inventory/inventory.api.ts`、`MesInventoryController.java` 源码 + `MesMenuRegistry.java` 权限标记 + `useListPage` 调用参数对比仓库页。

**action items**（不进排期，作为测试侧改进）：
- 修正 `harness/e2e/mes/basic-inventory.spec.ts` 的 `PAGE_PATH` 为 `/project/mes/warehouse/inventory`
- 调整 4/5/7 三个测试为 `test.skip` 或改成只读断言（这个页面是 dashboard，不该期望新增/导出/抽屉）
- 生成时我把 basic/inventory.spec.ts 全部按 CRUD 模板生成，没看 controller 实际暴露的端点——模板应根据 controller endpoint set 调整
  - `库存总览 8. 仓库筛选可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "库存总览" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 库存预警（/project/mes/basic/inventoryAlert）

- **后端 controller**：`MesInventoryAlertController`
- **症状**：只读页面缺少查询/导出/筛选/新增按钮（后端只暴露 GET /list，前端期望更多操作）
- **失败测试**（5 个）：
  - `库存预警 3. 搜索表单 + 查询按钮可见`
  - `库存预警 4. 导出按钮可见`
  - `库存预警 5. 新增按钮可见`
  - `库存预警 7. 点击新增 → 抽屉可见`
  - `库存预警 8. 预警级别筛选可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "库存预警" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### 🔴 复核结果：测试误判 + 产品真实需求（2026-08-04 由 ruiwancheng/pi 复核）

**两层结论（需拆开看，不能简单归为误判）：**

1. **测试侧：5 个 E2E 失败属于误判** — spec 按 CRUD 模板生成，未对照 controller 实际端点
2. **产品侧：用户判断当前页面**“基本没什么用”，**确实需要优化** — 这是真实的产品需求，不能归为误判

**与 #1 库存总览不同** —— #1 是设计合理的只读 dashboard，不该期待 CRUD；#2 是**还没做出业务价值**的占位页面，需要重设计。

#### 🟡 测试侧复核：误判（与 #1 同型）

**核实依据：**

**核实依据：**

| 检查项 | 实际内容 | 文件:行 |
|---|---|---|
| 后端端点 | 仅 `@GetMapping("/list") @RequiresPermissions("mes:inventoryAlert:list")`，无 add/edit/delete/exportXls/importXls | `MesInventoryAlertController.java:24-49` |
| 后端逻辑 | 聚合查询：从 `MesMaterial.safetyStock` 和 `MesInventory.currentQty` 计算缺口并按缺口降序返回，**不接受任何查询参数** | 同上 |
| 前端模板 | 单一 `<a-table>` + `<a-alert>` 提示；无 `<BasicForm>`/`<QueryFilter>`/搜索栏；无 `<a-drawer>`/`<a-modal>`；`:pagination="false"`；用 `ref + onMounted` 拉一次数据，**没有** `useListPage` | `index.vue`（全文 39 行） |
| 前端 API | 仅 `queryInventoryAlerts()` 一个方法，调 `GET /mes/basic/inventoryAlert/list` | `inventoryAlert.api.ts`（全文 3 行） |
| 菜单权限 | `addPerms(list, "mes:inventoryAlert:", ..., new String[]{"list"})` —— 仅 list 一个权限 | `MesMenuRegistry.java:60` |

**实测 spec（5 failed / 3 passed）：**

| 测试 | 结果 | 真实原因 |
|---|---|---|
| 1. 路由可达性 | ✅ pass | 路由 OK |
| 2. 表格 + 列头 | ✅ pass | 表格 6 列（物料编码/名称/当前库存/安全库存/最高库存/缺口）正常 |
| 3. 搜索表单 + 查询按钮 | ❌ fail | **页面无搜索栏（设计如此）** |
| 4. 导出按钮 | ❌ fail | **页面无导出按钮（设计如此）** |
| 5. 新增按钮 | ❌ fail | **页面无新增按钮（设计如此）** |
| 6. 数据行或空状态 | ✅ pass | 数据/空状态正常 |
| 7. 点击新增 → 抽屉 | ❌ fail | **没新增按钮自然无抽屉（设计如此）** |
| 8. 预警级别筛选 | ❌ fail | **页面无 select 筛选（后端不接受任何查询参数）** |

**测试侧 action items**（不进排期，作为测试侧改进）：
- 调整 `harness/e2e/mes/basic-inventoryAlert.spec.ts` 的 3/4/5/7/8 五个测试为 `test.skip`，或改成只读 dashboard 断言（路由 + 表格 + 数据 + 列头）
- 同样问题在 #5 批次台账、#6 批次库存也会出现，需在 spec 改造时统一处理
- gen-tests 模板应根据 controller endpoint set 调整：对只有 GET /list 的 controller，不要生成 add/edit/delete/export 相关的测试
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/basic-inventoryAlert.spec.ts --workers=1
  ```

#### 🔴 产品侧复核：真实需求（用户判断）

**用户判断（2026-08-04）：**
> 这个页面目前就是个纯展示页面，但确实需要做优化，目前基本没什么用

**问题本质：**
- 后端仅返回**一个按缺口排序的扁平表格**，用户无法针对业务场景做任何主动操作
- 没有筛选（按仓库 / 按物料类型 / 按预警级别），实际使用中上千条物料会一屏堆满
- 没有交互（点击物料查看历史 / 触发补货单 / 跳转到采购建议），预警发现后无下游动作
- 没有分组（按仓库 / 按物料类别聚合），不解决**“哪些仓库缺货最严重”**这类管理问题
- 没有导出/汇总邮件/推送，**无法驱动补货流程**

**产品优化方向（待排期讨论，可能包含）：**
- 筛选能力：仓库 / 物料类别 / 预警级别（低/中/高缺口比例）
- 分组视图：按仓库 / 按物料类别聚合
- 交互能力：点击行展开缺料历史 + “一键生成采购建议” / “跳转到采购订单新增页并预填物料”
- 主动推送：低于阈值自动通知采购员
- 导出/汇总：导出当前预警 + 周报/月报汇总

**归属建议**（进入产品排期）：
- 需业务侧明确优化范围（最小可用版 / 完整版）
- 后端：扩展 controller 支持查询参数 + 分组聚合端点
- 前端：重设计为可筛选 + 可分组 + 可交互的预警工作台
- 复核后**不算误判**，纳入 P2 排期

### [P3] 编码规则（/project/mes/basic/codeRule）

- **后端 controller**：`MesCodeRuleController`
- **症状**：导出按钮未渲染（其它基础 CRUD 功能正常）
- **失败测试**（1 个）：
  - `编码规则 4. 导出按钮可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "编码规则" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### ✅ 复核结果：误判（2026-08-04 由 ruiwancheng/pi 复核）

**用户判断（2026-08-04）：**
> 该页面没设计导出功能，也不需要

**核实依据：**

| 检查项 | 实际内容 | 文件:行 |
|---|---|---|
| 后端 export 端点 | `@GetMapping("/exportXls") @RequiresPermissions("mes:codeRule:export")` **已实现** | `MesCodeRuleController.java:81-86` |
| 后端 CRUD 端点 | list/add/edit/delete/deleteBatch/queryById/queryAll/nextCode 共 9 个端点齐全 | 同上全文 |
| 前端 API | 8 个方法齐全，**但没有 exportUrl**（后端 exportXls 端点未接入前端） | `codeRule.api.ts`（全文 21 行） |
| 前端表格 | 用 `BasicTable + useTable`，有新增按钮 / 搜索表单 / 操作列 / 抽屉，**但未传 `exportConfig`**（对比仓库页：传了 `exportConfig: { url: getExportUrl }` 才有导出按钮） | `index.vue`（全文 38 行） |
| 菜单权限 | `list,add,edit,delete,deleteBatch,export,import` —— **export 权限已授予**（意味着未来需要时启用只需前端加 exportConfig） | `MesMenuRegistry.java:37` |

**与 #1/#2 的关键区别：** #1 后端没 exportXls，#2 后端根本没 CRUD 端点 —— 是“能力未实现”。**#3 是后端 + 权限能力都有**，仅前端未接入，是**有意为之的产品决策**（用户已明确“不需要”）。

**实测 spec（1 failed / 7 passed）：**

| 测试 | 结果 | 真实原因 |
|---|---|---|
| 1. 路由可达性 | ✅ pass | 路由 OK |
| 2. 表格 + 列头 | ✅ pass | 表格正常 |
| 3. 搜索表单 + 查询按钮 | ✅ pass | 搜索正常 |
| 4. 导出按钮 | ❌ fail | **产品决策不实现（用户明确不需要）** |
| 5. 新增按钮 | ✅ pass | 新增按钮存在 |
| 6. 数据行或空状态 | ✅ pass | 数据/空状态正常 |
| 7. 点击新增 → 抽屉 | ✅ pass | 抽屉正常 |
| 8. 编码规则类型下拉 | ✅ pass | 下拉正常 |

**action items**（不进排期，作为测试侧改进）：
- 调整 `harness/e2e/mes/basic-codeRule.spec.ts` 的测试 4 为 `test.skip`，或改成“导出能力检查”（验证后端 `GET /mes/basic/codeRule/exportXls?token=...` 返回 200/Excel 响应，不依赖前端按钮）
- 记录“该页面产品决策不需要导出”作为元数据，避免后续 gen-tests 重复生成同类期望
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/basic-codeRule.spec.ts --workers=1
  ```

### [P1] 通用设置（/project/mes/basic/commonSetting）

- **后端 controller**：`MesGlobalSwitchController`
- **症状**：整页加载失败，浏览器 runtime 报错（"pageerror: any is not defined" 已知 bug 之一）
- **失败测试**（1 个）：
  - `切片B：通用设置页面端到端验证`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "通用设置" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### ✅ 复核结果：误判（2026-08-04 由 ruiwancheng/pi 复核）

**用户判断（2026-08-04）：** 实测页面加载正常。

**核实依据：**

| 检查项 | 实际内容 | 文件:行 |
|---|---|---|
| 后端 controller | `MesGlobalSwitchController` 有 list/save/closeCheck/closeBatchSwitch 4 个端点（拆分查+写） | `MesGlobalSwitchController.java` |
| 后端逻辑 | 开关列表 + 保存/更新 + 关闭前置检查 + 原子化关闭（含检查+总开关+物料 batch_enabled 批量置 0） | 同上 |
| 前端表格 | `BasicTable + useTable`，无搜索栏/无分页/无新增/无导出（开关页不该有这些） | `index.vue` |
| 前端开关逻辑 | 开启直接调 save；关闭走 closeCheck → 二次确认 → closeBatchSwitch 三步流 | `index.vue:67-119` |
| 全局状态 | `useMesGlobalSwitchStore` (Pinia)，跨页面共享开关状态（物料页读 store 决定 batch_enabled.disabled） | `src/store/modules/mesGlobalSwitch.ts` |
| 菜单权限 | `list, edit` 两项 | `MesMenuRegistry.java:42` |

**实测（1 failed / 8 assertions passed）：**

| 断言 | 结果 |
|---|---|
| 路由可达 + URL 保持 `/project/mes/basic/commonSetting` | ✅ pass |
| 页面标题"通用设置"可见 | ✅ pass |
| "生产批次管理"开关可见 | ✅ pass |
| ant-switch 组件渲染 | ✅ pass |
| first switch `aria-checked="true"` | ✅ pass |
| 截图存证 `harness/e2e/screenshots/commonSetting.png` | ✅ pass（页面渲染完整） |
| **console 无致命错误** | ❌ fail |

#### 🔴 复核中发现的独立 issue（不是 #4 的问题）

**pageerror 来源**（调试 spec 抓到的完整 stack）：

```
ReferenceError: any is not defined
    at setup (SysMessageModal.vue:66:37)
    at callWithErrorHandling (chunk-5JWESHCG.js:2019:19)
    ...
```

**关键发现：**

- `SysMessageModal.vue` 在 `setup` 中写了 `const searchParams = reactive<any>({...})` 和 `const searchRangeDate = ref<any>([])`（行 201、299）—— **TS 泛型语法 `<any>` 被错误保留到运行时**
- `SysMessageModal` 不是 commonSetting 页面加载的，**它在顶部 header 铃铛上全局加载**（`src/layouts/default/header/components/notify/index.vue`），所以**任何页面都会触发**这个错误
- 截图显示 commonSetting 页面实际渲染完整（面包屑 + 侧边栏 + 表格 + 开关都正常）—— **与用户判断一致**

**结论拆开看：**

1. **#4 通用设置页面本身：** ✅ 误判 — 页面渲染、菜单权限、开关交互、关闭流程、后端端点全正常，与用户判断一致
2. **pageerror 真实存在但：** 🔴 是**独立 issue** — 根因在 system/message 模块的 TS 泛型未剥离问题，不是 commonSetting 的问题

**action items：**

- #4 本身不进排期，进 spec 侧改进：在 `commonSetting.spec.ts` 中加入 console 错误白名单，把 `pageerror: any is not defined`（system 全局问题）从 fatal 过滤中放行，或拆出 system 模块独立验证
- **新建独立 issue #14（建议）**：修复 `SysMessageModal.vue` 的 `<any>` TS 泛型未剥离问题（影响所有页面控制台，需要打包工具/编译配置排查）
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/commonSetting.spec.ts --workers=1
  ```

---

## BATCH 模块

### [P3] 批次台账（/project/mes/batch/ledger）

- **后端 controller**：`MesBatchLedgerController`
- **症状**：只读页面有"新增"按钮但点击后抽屉不显示（与后端只有 GET 端点的事实不符）
- **失败测试**（2 个）：
  - `批次台账 5. 新增按钮可见`
  - `批次台账 7. 点击新增 → 抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "批次台账" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### ✅ 复核结果：误判（2026-08-04 由 ruiwancheng/pi 复核）

**用户判断（2026-08-04）：**
> 批次流水页面没设计新增功能，批次流水页面的数据是由入库/出库功能生成的，无需批次流水页面新增

**核实依据：**

| 检查项 | 实际内容 | 文件:行 |
|---|---|---|
| 后端端点 | 仅 `list`（分页）/ `listByBatchId`（按批次查）/ `exportXls`（导出）共 3 个，**无 add/edit/delete** | `MesBatchLedgerController.java` 全文 |
| 后端逻辑 | 走 `QueryGenerator.initQueryWrapper` 支持搜索，默认按 `occur_time` 倒序，**纯查询型 controller** | 同上 |
| 前端表格 | `useListPage` 模板：有 `exportConfig: { name: '批次流水', url: getExportUrl }`（导出按钮），**未传 `importConfig`**，无新增/编辑/删除操作列 | `index.vue`（全文 31 行） |
| 前端 API | `queryLedgerList` + `getExportUrl` 两个方法，**无 add/edit/delete** | `ledger.api.ts`（全文 11 行） |
| 菜单权限 | `list, export` 两项，**无 add/edit/delete** | `MesMenuRegistry.java:129` |

**与 #1 库存总览完全同型**：只读数据流页面 + 有导出能力，**不该有新增/编辑/删除**。批次流水数据由入库/出库业务自动生成（用户判断验证）。

**实测 spec（2 failed / 6 passed）：**

| 测试 | 结果 | 真实原因 |
|---|---|---|
| 1. 路由可达性 | ✅ pass | 路由 OK |
| 2. 表格 + 列头 | ✅ pass | 表格正常 |
| 3. 搜索表单 + 查询按钮 | ✅ pass | 搜索正常 |
| 4. 导出按钮 | ✅ pass | **导出按钮存在且可用**（页签栏左侧 "ant-design:export-outlined"） |
| 5. 新增按钮 | ❌ fail | **页面无新增按钮（设计如此）** |
| 6. 数据行或空状态 | ✅ pass | 数据/空状态正常 |
| 7. 点击新增 → 抽屉 | ❌ fail | **没新增按钮自然无抽屉（设计如此）** |
| 8. 批次选择下拉 | ✅ pass | select 存在 |

**action items**（不进排期，作为测试侧改进）：
- 调整 `harness/e2e/mes/batch-ledger.spec.ts` 的 5/7 两个测试为 `test.skip`，或改成只读 + 导出断言
- 同样问题在 #6 批次库存也会出现，需在 spec 改造时统一处理
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/batch-ledger.spec.ts --workers=1
  ```

### [P3] 批次库存（/project/mes/batch/inventory）

- **后端 controller**：`MesBatchInventoryController`
- **症状**：只读页面有"新增"按钮但点击后抽屉不显示
- **失败测试**（2 个）：
  - `批次库存 5. 新增按钮可见`
  - `批次库存 7. 点击新增 → 抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "批次库存" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 其它入库（自动预填）（/project/mes/stock/other-in）

- **后端 controller**：`MesOtherStockInController`
- **症状**：物料选中后未自动预填移动平均成本（已写入 feature 但实现缺）
- **失败测试**（1 个）：
  - `其它入库 › 新增入库单-物料选中后自动预填移动平均成本`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "其它入库（自动预填）" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

---

## FINANCE 模块

### [P2] 应收账款（/project/mes/finance/receivable）

- **后端 controller**：`MesReceivableController`
- **症状**："新增"按钮不渲染；抽屉不可触发（receivable 是自动生成的，无 add 端点，前端 UI 与后端契约错位）
- **失败测试**（2 个）：
  - `应收账款 5. 新增按钮可见`
  - `应收账款 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "应收账款" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 收款管理（/project/mes/finance/collection）

- **后端 controller**：`MesCollectionController`
- **症状**："点击新增"后抽屉不显示（前端按钮存在但 drawer 渲染失败）
- **失败测试**（1 个）：
  - `收款管理 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "收款管理" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 应付账款（/project/mes/finance/payable）

- **后端 controller**：`MesPayableController`
- **症状**：新增按钮不渲染 + 抽屉不可触发（同 receivable，自动生成无 add 端点）
- **失败测试**（2 个）：
  - `应付账款 5. 新增按钮可见`
  - `应付账款 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "应付账款" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 付款管理（/project/mes/finance/payment）

- **后端 controller**：`MesPaymentController`
- **症状**："点击新增"后抽屉不显示
- **失败测试**（1 个）：
  - `付款管理 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "付款管理" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### 链路失败（2）

- **finance-chain** / 收款单 创建：code=COL-1785822880128 success=false — 收款单 add 端点失败（前后端契约不一致或权限缺失）
- **finance-chain** / 销项发票 创建：code=SI-1785822880128 success=false — 销项发票 add 端点失败

---

## PURCHASE 模块

### [P1] 采购台账（/project/mes/purchase/ledger）

- **后端 controller**：`MesCostLogController + MesInventoryLedgerController`
- **症状**：整页 7/8 测试失败：表格/搜索/导出/新增/数据/抽屉/tab 切换全部异常
- **失败测试**（7 个）：
  - `采购台账 2. 表格 + 列头可见`
  - `采购台账 3. 搜索表单 + 查询按钮可见`
  - `采购台账 4. 导出按钮可见`
  - `采购台账 5. 新增按钮可见`
  - `采购台账 6. 数据行或空状态可见`
  - `采购台账 7. 点击新增 → 抽屉可见`
  - `采购台账 8. 成本/库存台账 tab 切换可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "采购台账" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

---

## SALES 模块

### [P3] 销售链路 fixture（/project/mes/sales/outbound）

- **后端 controller**：`—`
- **症状**：sales-receipt-flow.test.js 无法创建客户 fixture：admin 缺 mes:basic:add 权限，链路起点失败
- **失败测试**（1 个）：
  - `sales-receipt-flow step 0.3`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "销售链路 fixture" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### 链路失败（1）

- **sales-receipt-flow** / 0.3 创建客户：Subject does not have permission [mes:basic:add] — admin 缺 mes:basic:add 权限，链路 fixture 创建失败

---

## STOCK 模块

#### 链路失败（1）

- **warehouse-chain** / m1 初始库存入库：records=0 — 入库未生效，库存台账未生成流水

---

## 处理建议

1. **P1 先修**（基本 + 采购台账）：整页不可用，影响演示和日常操作
2. **P2 批量修**（财务 4 个 + 其它入库自动预填）：抽屉触发和前端契约
3. **P3 顺手清**（批次只读页 + 编码规则 + 销售 fixture + #14 SysMessageModal）：UI 与后端契约对齐 / 全局控制台净化

## 不在本次范围

- 不修改 harness runner（已验证 E2E 失败是产品问题）
- 不修改业务代码（按 CLAUDE.md "不因为单个 E2E 失败自动修改业务代码"）
- 不修改 router/routes（已确认通过 MesMenuRegistry + 动态 addRoute 可达）

---

## #14 SysMessageModal `any is not defined`（全局 pageerror）— 已提排期

- **发现问题位置**：`src/views/system/message/components/SysMessageModal.vue`
- **复现入口**：顶部 header 铃铛全局加载 → 任何页面都触发
- **首次发现**：#4 通用设置复核调试 spec 中捕获（2026-08-04）
- **优先级**：P3（不影响渲染 / 功能，但污染所有页面控制台 + 让 E2E "console 无错" 断言批量误报）
- **预计工时**：30 分钟（方案 A 最小修复） + 2 小时（方案 B 全仓排查同类）
- **归属建议**：业务前端（基础架构组）

### 根因

`SysMessageModal.vue`（以及同模块的 `useSysMessage.ts`）使用了 Options API + `<script>`，里面写了 TypeScript 泛型语法 `reactive<any>(...)` 和 `ref<any>(...)`。**正常情况下 Vite 的 esbuild 会剥离 TS 类型，但实际运行时 `<any>` 作为标识符被抛出 `ReferenceError`** —— 说明 esbuild 对该文件的类型剥离失效或被某个插件跳过。

### 受影响位置（4 处）

| 文件 | 行 | 代码 |
|---|---|---|
| `src/views/system/message/components/SysMessageModal.vue` | 201 | `const searchParams = reactive<any>({...})` |
| `src/views/system/message/components/SysMessageModal.vue` | 299 | `const searchRangeDate = ref<any>([])` |
| `src/views/system/message/components/useSysMessage.ts` | 31 | `const messageList = ref<any>([])` |
| `src/views/system/message/components/useSysMessage.ts` | 35 | `const searchParams = reactive<any>({...})` |

### 修复方案

**方案 A（推荐先做，30 min）：最小修复 — 去掉/替换 4 处 `<any>`**

- `SysMessageModal.vue:201` searchParams 推断为 `Record<string, any>`（具体接口类型待补）
- `SysMessageModal.vue:299` searchRangeDate 推断为 `[Dayjs, Dayjs]` 或 `[]`（与 ant-design 日期组件对齐）
- `useSysMessage.ts:31/35` 同上
- 验证：刷新页面 + 重跑 E2E，console 无 `pageerror: any is not defined`

**方案 B（随后做，2 h）：根因排查 + 全仓扫描**

- 检查 `vite.config.ts` 中 esbuild 配置、`build/vite/plugin/` 自定义插件是否跳过了类型剥离
- 全仓 `grep -rn "ref<any>\|reactive<any>\|computed<any>" src/` 排查同类问题
- 对发现的同类问题统一修复
- 添加 lint 规则禁止 `<any>` 泛型（`@typescript-eslint/no-explicit-any`）

### 验收标准

1. 刷新任意页面，控制台无 `pageerror: any is not defined`
2. 重跑 `harness/e2e/mes/commonSetting.spec.ts`，`不应有运行时错误` 断言通过
3. 重跑 `harness/e2e/mes/*.spec.ts` 全量，统计"console 错误"导致的误报数（应显著下降）

### 排期建议

- **本周**：方案 A + 验收
- **下周**：方案 B（全仓扫描 + lint 规则）
