# 切片 C 进度：物料页 + batchEnabled 联动

**日期**：2026-07-31
**切片**：C（前端物料联动，依赖切片 B 的 Pinia store）

## 完成清单

### 前端（本切片新增）
- [x] **列表列** `material.data.ts` 的 `columns` 加 `启用批次`（dataIndex: `batchEnabled`，width: 90）
- [x] **表单字段** `material.data.ts` 的 `formSchema` 加 `batchEnabled`：
  - 组件：`JSwitch`（平台标准开关）
  - `checkedValue: 1, unCheckedValue: 0, defaultValue: 0`（与后端 Integer 字段对齐）
  - `helpMessage`：解释与总开关关系
- [x] **Drawer 联动** `MaterialDrawer.vue`：
  - 抽屉打开时 `mesGlobalSwitchStore.load()`（保证 store 已加载）
  - `syncBatchFieldState()`：用 `updateSchema` 把 store 当前状态推到表单字段的 `disabled`
  - `watch(batchFieldDisabled)`：跨 Tab 实时同步——用户在通用设置页关闭总开关后，物料页编辑抽屉里的 batchEnabled 立即禁用
  - 提交前最后兜底：总开关关闭时强制 `values.batchEnabled = 0`（防止前端绕过 GUI 改值）
  - 加载详情时若总开关关闭也强制 `res.batchEnabled = 0`（防止回显旧值）

### 后端（切片 A 已就绪，本切片直接利用）
- [x] `MesMaterial` 实体 `batchEnabled` 字段（V8.0.1 SQL + Entity 注解）
- [x] `MesMaterialController.queryById` / `edit` 直接透传字段（`updateById(e)` 走主键更新）
- [x] `MesGlobalSwitchServiceImpl.isEnabled()` 已就绪（供切片 D 集成）

## 验证证据

### 1. 后端（Node 直连 8080）
- `list` 接口：`batchEnabled` 字段存在且值=0
- `queryById`：返回完整对象含 `batchEnabled`
- `edit`：PUT body 包含 `batchEnabled: 1` → 200 → 读回=1 → 回滚=0 ✅

### 2. 前端类型 + Lint
- `npx eslint src/views/project/mes/basic/material` → 全绿

### 3. 端到端 Playwright（3/3 通过）
- `harness/e2e/mes/materialBatch.spec.ts`
  - **C.1** 列表显示"启用批次"列
  - **C.2** 总开关开启时打开物料编辑，batchEnabled 字段不被禁用（class 不含 `ant-switch-disabled`）
  - **C.3** 总开关关闭时打开物料编辑，batchEnabled 字段被禁用（class 含 `ant-switch-disabled`）
- 截图：
  - `harness/e2e/screenshots/material-list.png`
  - `harness/e2e/screenshots/material-drawer-enabled.png`
  - `harness/e2e/screenshots/material-drawer-disabled.png`

### 4. 清理
- 全局开关值已回滚为 0
- 物料 `MAT-0062` 的 `batchEnabled` 仍为 0（测试中未触发保存）

## 关键设计决策

| 决策 | 理由 |
|------|------|
| 表单用 `JSwitch` 而非原生 `a-switch` | 平台 JSwitch 已与 `useRuleFormItem` 集成（自动 emit change/update:value）|
| `disabled` 通过 `updateSchema` 动态写 | formSchema 在模块加载时执行，那时 store 还没初始化；用 computed + watch 才能拿到响应式值 |
| 三道兜底：1) `disabled` UI 禁用 2) `res.batchEnabled = 0` 详情回显兜底 3) `values.batchEnabled = 0` 提交前兜底 | 任何单点失效都还有下层兜底——P1-4 竞态问题的扩展（不依赖前端行为正确）|
| 跨 Tab 同步用 `watch(batchFieldDisabled)` | 评审 P2-1 改进方案：Pinia + watch 替代 window 全局变量，关闭总开关时无需刷新物料页 |
| 测试用 class 判断 disabled | `a-switch` 不挂 `aria-disabled`，用 `ant-switch-disabled` class 更可靠（受 jeecg 平台 DOM 结构影响小）|

## 切片依赖关系

- **本切片（C）依赖**：切片 A（实体字段）+ 切片 B（Pinia store）✅
- **本切片（C）解锁**：切片 D（4 个 Service 集成 `isEnabled`，前端已有 disabled 兜底）
- **遗留**：后端 4 个 Service 注入 `IMesGlobalSwitchService` 调用 `isEnabled("mes_batch_enabled")` 属于切片 D，本切片不做

## 踩坑记录

- 测试首次失败：`aria-disabled` 返回 null → 改用 `ant-switch-disabled` class 判断
- 截图保存路径相对 `process.cwd()` 解析，写成 `harness/e2e/screenshots/` 实际被解析为 `harness/e2e/harness/e2e/screenshots/`（cwd 在 e2e 目录）→ 已修复

## 下一步

- 切片 D：4 个 Service 注入 `IMesGlobalSwitchService`：
  - `CompletionReceiptServiceImpl`（完工入库）
  - `ProductionPickingServiceImpl`（生产领料）
  - `MesPurchaseReceiptServiceImpl`（采购入库）
  - `MesSalesOutboundServiceImpl`（销售出库）
  - 每个 Service 在 `createBatch` / `stockOutFifo` 前判 `isEnabled("mes_batch_enabled")`，关闭时直接走普通库存逻辑
