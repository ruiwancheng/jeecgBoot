# 切片 B 进度：通用设置页 + 菜单注册 + 路由

**日期**：2026-07-31
**切片**：B（前端通用设置页 + 菜单 + 路由 + 后端 Service/Controller 在切片 A 已就绪）

## 完成清单

### 后端（切片 A 已就绪，本切片继续利用）
- [x] `MesGlobalSwitch` 实体（c_mes_global_switch 表）
- [x] `MesGlobalSwitchServiceImpl.checkCanClose(switchKey)` — L1/L3 检查
- [x] `MesGlobalSwitchServiceImpl.closeBatchSwitch()` — 原子关闭（总开关=0 + 物料 batch_enabled 全置 0）
- [x] `MesGlobalSwitchServiceImpl.isEnabled(switchKey)` — 切片 D 接入用
- [x] `MesGlobalSwitchController` — 4 个端点：list / save / closeCheck / closeBatchSwitch
- [x] `CloseCheckResult` VO（canClose + errors[{layer, title, detail}]）
- [x] SQL V8.0.2：建表 + 种子数据（mes_global_switch_batch_001 = 0）

### 前端（本切片新增）
- [x] **API 类型** `api/project/mes/system/model/commonSettingModel.ts`（MesGlobalSwitch / CloseCheckError / CloseCheckResult）
- [x] **API 封装** `api/project/mes/system/commonSetting.api.ts`（listAll / saveCommonSetting / closeCheck / closeBatchSwitch）
- [x] **Pinia store** `store/modules/mesGlobalSwitch.ts`（switches map + isBatchEnabled getter + load/set/reset action）
- [x] **通用设置页** `views/project/mes/basic/commonSetting/index.vue`：
  - BasicTable 列出所有开关
  - 开启：直接调 save
  - 关闭：先调 closeCheck → 有错误弹窗显示清单 / 无错误弹二次确认 → 调 closeBatchSwitch
  - loading 状态用 `loadingKeys: Set<string>`（避免 record 上挂临时属性导致响应式失效）
  - 二次确认用 `Modal.confirm` 包成 Promise 直接 await（替代脆弱的 setTimeout 等待 onOk 方案）
- [x] **列定义** `commonSetting/commonSetting.data.ts`（开关名称/标识/状态/说明）
- [x] **路由** `router/routes/modules/mes.ts` 新增 `commonSetting` 子路由
- [x] **菜单** `MesMenuRegistry.java` 新增 `mes_basic_commonSetting`（sortNo 4，icon: control-outlined）
- [x] **权限码** `mes:commonSetting:list` + `mes:commonSetting:edit`

## 验证证据

### 1. 后端接口（Node 直连 8080）
- 登录：200
- list：返回种子 `mes_batch_enabled = 0`
- closeCheck：返回 L1 错误（3 条批次库存余额）→ 与页面弹窗预期一致
- closeBatchSwitch：被阻断时 errors 正确返回、值未变（数据库一致性）
- 无 token：401 拦截

### 2. 前端类型 + Lint
- `npx eslint`：5 个新文件全绿
- `vue-tsc`：本切片文件无 TS 错误（其余报错为 build/mock/components 既有，与本切片无关）

### 3. 端到端 Playwright（1/1 通过）
- `harness/e2e/mes/commonSetting.spec.ts`
- 流程：登录 → 跳转 `/project/mes/basic/commonSetting`
- 验证：URL 保持 / 通用设置标题可见 / 生产批次管理行可见 / Switch 组件可见 / 点击开关成功翻转 / 控制台无致命错误
- 截图：`harness/e2e/screenshots/commonSetting.png`（1280×720）

### 4. 清理
- 测试时点开的开关已回滚为 0（不影响后续切片 C/D）

## 关键设计决策

| 决策 | 理由 |
|------|------|
| `Modal.confirm` 包成 `Promise<boolean>` 直接 await | 替代脆弱的 `setTimeout + onOk 改外部变量` 方案（首次实现就是这个，已经修复）|
| `loadingKeys: Set<string>` 替代 `record._loading` | 响应式可靠（Set 用新对象替换触发 ref 刷新）；旧写法把临时属性挂到 record 上不刷新 |
| 关闭前置检查用 `closeCheck` 端点（GET） | 区分"检查"和"执行"：用户可以"看到检查结果后取消"；避免每次切开关都改 DB |
| `closeBatchSwitch` 单端点原子操作 | 同时处理"关闭总开关"+"物料 batch_enabled 批量归零"（P1-4 竞态修复）|
| Pinia store 替代 `window.__MES_BATCH_ENABLED__` | 跨 Tab 同步、响应式可靠（评审 P2-1）|

## 切片依赖关系

- **本切片（B）依赖**：切片 A（建表 + 后端基础 + 种子数据）✅
- **本切片（B）解锁**：切片 C（material 联动用 store.isBatchEnabled）+ 切片 D（4 个 Service 集成用 isEnabled）
- **未实现功能**：material 联动（D 之前的准备片）→ 留到切片 C，本切片不涉及

## 下一步

- 切片 C：material 表单加 batchEnabled 字段，disabled 状态从 store 读
- 切片 D：4 个 Service 注入 IMesGlobalSwitchService，在创建/扣减批次前判断总开关
