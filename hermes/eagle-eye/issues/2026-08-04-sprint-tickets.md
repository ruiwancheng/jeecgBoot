# MES Sprint 排期 — 2026-08-04 真实 Bug 清单

> 生成时间：2026-08-04
> 数据来源：`hermes/eagle-eye/issues/mes-2026-08-04-business-bugs.md` 复核结果
> 复核范围：13 个 issue 全部完成 + 复核中发现的 1 个独立 issue（#14）
> 真实问题：5 个（含 1 个产品优化 + 4 个技术 Bug）

## 排期概览

| Ticket | 来源 | 主题 | 优先级 | 工时 | Sprint | 状态 |
|---|---|---|---|---|---|---|
| TKT-001 | #9 + #11 合并 | 财务收款/付款 Drawer 补齐 | P2 | 2-3 h | W1 | 🟡 待开工 |
| TKT-002 | #13 | 客户管理权限命名不一致修复 | P3 | 1-2 h | W1 | 🟡 待开工 |
| TKT-003 | #14 方案 A | SysMessageModal TS 泛型未剥离 | P3 | 30 min | W1 | 🟡 待开工 |
| TKT-004 | #14 方案 B | 全仓 `mes:basic:*` 与 `mes:customer*:*` 命名统一 | P3 | 2-3 h | W2 | 🔵 计划 |
| TKT-005 | #2 | 库存预警工作台优化（产品范围待定） | P2 | 待定 | 待定 | 🔵 等业务侧 |

**工时合计**：5.5-8 h（不含 TKT-005 产品优化）

---

## TKT-001 财务收款/付款 Drawer 补齐（合并 #9 + #11）

| 字段 | 内容 |
|---|---|
| **Ticket ID** | TKT-001 |
| **来源 Issue** | #9 收款管理 + #11 付款管理 |
| **优先级** | P2（影响业务演示，阻塞日常操作） |
| **工时估算** | 2-3 h |
| **建议 Sprint** | 2026-08-04 W1（本周） |
| **建议 Owner** | 业务前端（基础架构组） |
| **关联文件** | `src/views/project/mes/finance/collection/index.vue` + `payment/index.vue` |
| **阻塞** | 销售/采购收款付款链路无法操作 |

### 问题描述

`finance/collection/index.vue:27` 与 `finance/payment/index.vue:26` 的 `handleAdd()` 调用：

```typescript
function handleAdd() { router.push('/project/mes/finance/collection/add'); }
```

但 router 中**没有** `collection/add` 和 `payment/add` 子路由（`router/routes/modules/mes.ts:207-208` 只注册了顶级路由）。点击"新增"按钮 → 跳 404。

参考 `finance/invoice/index.vue` 的正确做法是 `useDrawer` + `openDrawer(true, { isUpdate: false })` + 同目录下 `InvoiceDrawer.vue`。

### 验收标准

1. 新建 `CollectionDrawer.vue` + `PaymentDrawer.vue`（参考 `InvoiceDrawer.vue` 模板）
2. 修改 `collection/index.vue` + `payment/index.vue`：
   - 引入 `useDrawer` 和对应 Drawer 组件
   - `handleAdd()` 改为 `openDrawer(true, { isUpdate: false })`
3. 重跑 `harness/e2e/mes/finance.spec.ts`：
   - "收款管理 7. 点击新增 → 弹窗/抽屉可见" 通过
   - "付款管理 7. 点击新增 → 弹窗/抽屉可见" 通过
4. 手动验证：点击"新增收款"/"新增付款"按钮 → 弹出表单抽屉 → 填写并保存 → 后端落库

### 任务拆分

- [ ] 子任务 A：创建 `CollectionDrawer.vue`（表单 schema 字段需与 `MesCollection` entity 对齐）
- [ ] 子任务 B：创建 `PaymentDrawer.vue`（参考 A）
- [ ] 子任务 C：修改 `collection/index.vue` + `payment/index.vue`
- [ ] 子任务 D：E2E 验证（finance.spec.ts 7. 应通过）

---

## TKT-002 客户管理权限命名不一致修复（#13）

| 字段 | 内容 |
|---|---|
| **Ticket ID** | TKT-002 |
| **来源 Issue** | #13 销售链路 fixture |
| **优先级** | P3（阻塞链路测试，影响 E2E 准确性） |
| **工时估算** | 1-2 h |
| **建议 Sprint** | 2026-08-04 W1（本周） |
| **建议 Owner** | 后端（基础架构组） |
| **关联文件** | `MesMenuRegistry.java:31-34` + 新迁移脚本 `db/V10.x.x__mes_basic_perms_bind.sql` |
| **阻塞** | sales-receipt-flow.test.js 链路 fixture 创建客户失败 |

### 问题描述

`MesCustomerController` 用 `mes:basic:*` 权限注解（list/add/edit/delete/deleteBatch/import），但 V10 重构后 `MesMenuRegistry.java:31-34` 只声明了 `mes:customerAddress:*` / `Contact:*` / `FollowUp:*` / `Price:*` 子模块权限——**`mes:basic:*` 7 个权限码在 `sys_permission` 表根本不存在**。

实测对比：
- admin → 200 '添加成功'（admin bypass Shiro）
- mes_admin → 401 'Subject does not have permission [mes:basic:add]'

### 验收标准

1. `MesMenuRegistry.java` 的 `mes_basic_customer` 菜单下补齐 `mes:basic:*` 7 个权限声明
2. 新迁移脚本 `V10.x.x__mes_basic_perms_bind.sql` 把 `mes:basic:*` 绑给 admin + mes_admin
3. 重启后端后，`sys_permission` 表有 `mes:basic:add` 等 7 行
4. 重跑 `tests/chains/sales-receipt-flow.test.js`：step 0.3 创建客户成功

### 任务拆分

- [ ] 子任务 A：修改 `MesMenuRegistry.java:31-34`，为 `mes_basic_customer` 补 `addPerms(list, "mes:basic:", "mes_basic_customer", new String[]{"list","add","edit","delete","deleteBatch","import","export"})`
- [ ] 子任务 B：新建 `db/V10.x.x__mes_basic_perms_bind.sql`（参考 V10.1.1 写法）
- [ ] 子任务 C：本地 mvn install + 重启 fat-jar + 验证 `sys_permission` 表
- [ ] 子任务 D：重跑 sales-receipt-flow.test.js step 0.3

### 风险提示

TKT-001/TKT-002 都涉及重启后端。**两者必须顺序执行**（避免同时重启导致时间窗叠加）。建议顺序：先 TKT-002（修权限 + 验证链路）→ 再 TKT-001（前端 Drawer + 验证）。

---

## TKT-003 SysMessageModal TS 泛型未剥离修复（#14 方案 A）

| 字段 | 内容 |
|---|---|
| **Ticket ID** | TKT-003 |
| **来源 Issue** | #14 SysMessageModal `any is not defined` |
| **优先级** | P3（不影响渲染但污染所有页面控制台 + 让 E2E "console 无错"断言批量误报） |
| **工时估算** | 30 min |
| **建议 Sprint** | 2026-08-04 W1（本周） |
| **建议 Owner** | 业务前端（基础架构组） |
| **关联文件** | `src/views/system/message/components/SysMessageModal.vue` + `useSysMessage.ts` |
| **阻塞** | 大量 E2E "不应有运行时错误"断言被 pageerror 误报 |

### 问题描述

调试 spec 抓到的完整 stack：

```
ReferenceError: any is not defined
    at setup (SysMessageModal.vue:66:37)
```

**4 处位置**（2 文件）：

| 文件 | 行 | 代码 |
|---|---|---|
| `SysMessageModal.vue` | 201 | `const searchParams = reactive<any>({...})` |
| `SysMessageModal.vue` | 299 | `const searchRangeDate = ref<any>([])` |
| `useSysMessage.ts` | 31 | `const messageList = ref<any>([])` |
| `useSysMessage.ts` | 35 | `const searchParams = reactive<any>({...})` |

`SysMessageModal` 在 `src/layouts/default/header/components/notify/index.vue` 全局加载，**任何页面都触发**这个错误。

### 验收标准

1. 4 处 `<any>` 泛型全部替换为具体类型或省略泛型：
   - `searchParams` → `Record<string, any>` 或具体接口
   - `searchRangeDate` → `[Dayjs, Dayjs]` 或 `[]`
   - `messageList` → `MesMessage[]`
   - `useSysMessage.ts` 同上
2. 刷新任意页面，控制台无 `pageerror: any is not defined`
3. 重跑 `harness/e2e/mes/commonSetting.spec.ts` 的"不应有运行时错误"断言通过

### 任务拆分

- [ ] 子任务 A：替换 4 处 `<any>` 泛型
- [ ] 子任务 B：写调试 spec 验证控制台无 pageerror
- [ ] 子任务 C：重跑 commonSetting.spec.ts + finance.spec.ts 验证 console 误报下降

---

## TKT-004 全仓 `mes:basic:*` 与 `mes:customer*:*` 命名统一（#14 方案 B）

| 字段 | 内容 |
|---|---|
| **Ticket ID** | TKT-004 |
| **来源 Issue** | #14 方案 B（全仓根因排查 + lint 规则） |
| **优先级** | P3 |
| **工时估算** | 2-3 h |
| **建议 Sprint** | 2026-08-04 W2（下周） |
| **建议 Owner** | 业务前端 + 基础架构组（联动） |
| **关联文件** | `vite.config.ts` + `build/vite/plugin/*` + 全仓 `src/**/*.vue` |

### 问题描述

TKT-003 只是最小修复（替换 4 处 `<any>`）。**根因未排查**：Vite/esbuild 应该自动剥离 TypeScript 泛型，为何这 4 处会保留到运行时？

可能根因（待查）：
- `SysMessageModal.vue` 使用 `<script>`（Options API）+ `export default { ... }`，不是 `<script setup>`
- 某个自定义插件跳过了该文件的类型剥离
- vue-tsc / @vue/compiler-sfc 版本不匹配

### 验收标准

1. 排查 `vite.config.ts` + `build/vite/plugin/` 中所有自定义 esbuild 插件
2. 全仓 `grep -rn "ref<any>\|reactive<any>\|computed<any>" src/` 排查同类问题
3. 对发现的同类问题统一修复
4. 添加 lint 规则禁止 `<any>` 泛型：
   ```json
   // .eslintrc.json
   "@typescript-eslint/no-explicit-any": "error"
   ```
5. 添加 vitest 单测覆盖 SysMessageModal 等组件的 mount 不抛错

### 任务拆分

- [ ] 子任务 A：vite/esbuild 配置排查（保留根因分析文档）
- [ ] 子任务 B：全仓 grep + 修复同类问题
- [ ] 子任务 C：添加 lint 规则
- [ ] 子任务 D：写单测

---

## TKT-005 库存预警工作台优化（#2）

| 字段 | 内容 |
|---|---|
| **Ticket ID** | TKT-005 |
| **来源 Issue** | #2 库存预警 |
| **优先级** | P2 |
| **工时估算** | **待业务侧确认范围** |
| **建议 Sprint** | 2026-08-04 W3+（视业务优先级） |
| **建议 Owner** | 业务前端 + 后端 + 产品（联合） |
| **关联文件** | `MesInventoryAlertController` + `src/views/project/mes/basic/inventoryAlert/index.vue` |

### 问题描述

用户判断（2026-08-04）："目前基本没什么用，确实需要优化"。

当前实现是按 `MesMaterial.safetyStock` 和 `MesInventory.currentQty` 计算缺口的扁平表格，**没有任何业务驱动力**。用户已经列出 5 个产品优化方向：

1. 筛选能力：仓库 / 物料类别 / 预警级别（低/中/高缺口比例）
2. 分组视图：按仓库 / 按物料类别聚合
3. 交互能力：点击行展开缺料历史 + "一键生成采购建议" / 跳转到采购订单新增页并预填物料
4. 主动推送：低于阈值自动通知采购员
5. 导出/汇总：导出当前预警 + 周报/月报汇总

### 验收标准

**需业务侧先明确**：
- 最小可用版 vs 完整版范围
- 优先级排序（先做哪个）
- 与现有采购流程集成方式（直接生成采购单 / 仅通知）

工时估算待范围确认后填入。

### 任务拆分

- [ ] **阻塞**：业务侧明确范围 + 优先级
- [ ] 子任务 A（待定）：根据范围拆分

---

## Sprint 节奏建议

### W1（2026-08-04 本周）

- **Day 1**：TKT-002（权限修复 + 重启后端）→ TKT-001（Drawer 补齐）
- **Day 2**：TKT-003（TS 泛型修复）+ E2E 回归验证

### W2（2026-08-11 下周）

- TKT-004（全仓根因排查 + lint 规则）

### W3+（待业务侧）

- TKT-005（产品优化排期等业务侧）

---

## 排期约束 / 注意事项

1. **后端重启窗口**：TKT-002 需要重启后端（fat-jar PID 34916）。TKT-001 不需要后端改动。**建议先 TKT-002 → 再 TKT-001**（避免重复重启）
2. **数据兼容**：TKT-002 新迁移脚本需 MySQL 5.7 兼容（参考 V10.1.1 写法，避免 `DROP INDEX IF EXISTS`）
3. **代码标记**：所有业务代码改动必须包裹 `update-begin---author:作者 ---date:YYYY-MM-DD---for：【需求号】修改说明`
4. **commit 信息**：建议格式 `fix(mes): TKT-XXX 简述`（如 `fix(mes): TKT-001 财务收款/付款 Drawer 补齐`）
5. **验证必实测**：每个 TKT 完成后必须跑对应 spec + curl 实测（CLAUDE.md "验证必实测"）

---

## 关联文件

- 复核结果：`hermes/eagle-eye/issues/mes-2026-08-04-business-bugs.md`
- 业务代码：`jeecg-boot/jeecg-boot-module/project-mes/`
- 前端代码：`jeecgboot-vue3/src/views/project/mes/`
- 菜单注册：`MesMenuRegistry.java`
- E2E 测试：`harness/e2e/mes/`
- 链路测试：`harness/tests/chains/`

---

## 变更日志

- 2026-08-04：初版排期（5 个 ticket，覆盖 5 个真实问题）