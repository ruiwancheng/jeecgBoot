# Sprint W1 Review 报告（2026-08-04）

> **报告时间**：2026-08-04 22:50
> **报告范围**：2026-08-04 Sprint W1 全部完成事项 + 销售链路测试当前状态
> **目的**：让用户**手工核实**后再决定下一步行动
> **关联**：`hermes/eagle-eye/issues/2026-08-04-sprint-tickets.md`

---

## 一、本周 Sprint W1 完成情况

### 1.1 完成 4 个 ticket（5 个真实 Bug 中修 4 个）

| Ticket | 来源 | 主题 | Commit | 工时 | 验证 |
|---|---|---|---|---|---|
| **TKT-002** | #13 | 客户管理 mes:basic:* 权限补齐 | `a8250ba` | 1h | mes_admin → customer add ✅ |
| **TKT-001** | #9+#11 | 财务收款/付款 Drawer 补齐 | `8d3b400` | 2h | 收款/付款 7. 抽屉可见 ✅ |
| **TKT-003** | #14 方案 A | SysMessageModal TS 泛型修复 | `2afa4d5` | 30min | total pageerrors: 0 ✅ |
| **TKT-004** | #14 方案 B | 全仓 `<any>` 修复 + ESLint 防复发 | `4ee13c0` | 1h | 11 个 Options API 文件修 + warn 规则 |

**实际工时**：~4.5h（估算 5.5-8h，省了 ~1h 因为 TKT-002 的 Runner 自动注册无需手写 SQL 迁移）

### 1.2 验收证据汇总

**TKT-002（mes:basic:* 权限修复）**：
- `MesMenuRegistry.java` 加 `addPerms(list, "mes:basic:", "mes_basic_customer", new String[]{"list","add","edit","delete","deleteBatch","import","export"})`
- MesMenuAutoRegisterRunner 启动自动完成：INSERT 7 个 mes:basic:* 权限码 + bindRole 到 admin + mes_admin
- 数据库实测（mysql sys_role_permission 查得）：
  ```
  admin      mes:basic:add / delete / deleteBatch / edit / export / import / list
  mes_admin  mes:basic:add / delete / deleteBatch / edit / export / import / list
  ```
- `sales-receipt-flow.test.js` step **0.3 创建客户: id=2084661159193075714** ✅（之前 401 'Subject does not have permission [mes:basic:add]'）

**TKT-001（财务 Drawer 补齐）**：
- 新建 `CollectionDrawer.vue` + `PaymentDrawer.vue`（参考 SupplierDrawer 模板）
- 修改 `collection/index.vue` + `payment/index.vue`：用 `useDrawer.openDrawer` 替代 `router.push`（错误路由不存在导致 404）
- spec 验证：收款管理 7 + 付款管理 7 → **2 passed**
- 截图（`harness/e2e/screenshots/tkt001-*.png`）：两个 Drawer 标题 + 7 字段 + 取消/确认按钮完整渲染

**TKT-003（SysMessageModal TS 泛型）**：
- 替换 4 处 `ref<any>(...)` / `reactive<any>(...)` → `ref(...)` / `reactive(...)`
- 踩坑：初版用 `as string[]` 类型断言失败（babel parser 不支持），最终用"省略泛型"方案
- 验证：访问任意页面 `total pageerrors: 0`；commonSetting.spec.ts console errors: 无

**TKT-004（全仓 `<any>` + ESLint）**：
- **根因确认**：vue/compiler-sfc 用 babel parser 解析不带 `lang="ts"` 的 `<script>`，babel 不识别 TS 泛型语法 → `<any>` 保留为运行时标识符
- 批量修复 11 个 Options API 文件中的 25 处 `<any>` 泛型（SysMessageModal 在 TKT-003 已修）
- `.eslintrc.js`：`'@typescript-eslint/no-explicit-any'` 由 `off` → `warn`（防复发，不阻断 CI）
- 验证：访问 7 个不同页面（user/role/depart/airag/desform 等）→ 全部 pageerrors: 0

---

## 二、销售链路测试当前状态（用户问 "先给我份报告"）

### 2.1 链路测试结果（2026-08-04 22:48 跑测）

**`tests/chains/sales-receipt-flow.test.js`** 当前 9 通过 / 4 失败 = 69.2%

```
===== 销售链路：9 通过, 4 失败 =====
===== 通过率：69.2% =====
```

**对照 TKT-002 修复前**：step 0.3 直接卡死，整个链路 0% 通过
**TKT-002 修复后**：step 0.3 通过，链路跑通至 8.1 cleanup，**4 个失败都是测试代码 bug + 级联失败**

### 2.2 4 个失败逐条分析（按建议手工核实顺序）

| # | 失败测试 | 根因 | 业务 bug vs 测试 bug | 修复建议 |
|---|---|---|---|---|
| **1.1** | 创建销售订单：交货日期不能为空 | 测试代码 bug：request body 没传 `deliveryDate` 字段 | **测试 bug**（业务规则合理，销售订单必须交货日期）| 在 test.js 第 ~80 行补 `deliveryDate: '2026-08-04'` |
| **5.1** | 库存减少错误：期望 -10，实际 0 | 1.1 失败的级联（订单没创建，库存没动） | **级联失败**（非独立 bug） | 修 1.1 后自动通过 |
| **5.3** | 库存台账出库不足：期望 10，实际 0 | 1.1 失败的级联 | **级联失败**（非独立 bug） | 修 1.1 后自动通过 |
| **7.1** | 创建收款单：收款金额(150)超过未结金额(100.00) | 测试代码 bug：amount=150 但历史应收只有 100 | **测试 bug**（使用历史 receivableId 而非新建；应收总额 500 也对不上 10×15=150）| test.js 应基于 1.1 创建后的应收单做收款；或修正测试期望金额 |

### 2.3 关键证据（供手工核实）

**1.1 失败详情**：
```
请求: POST /mes/sales/order/add
      {"code":"SO-856926084172","orderDate":"2026-08-04","customerId":"...","items":[{"materialId":"...","quantity":10,"unit..."}
响应: {"success":false,"message":"交货日期不能为空","code":500,"result":null}
```

**业务规则确认**（不是 bug）：
- `jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/sales/service/impl/MesSalesOrderServiceImpl.java:233`:
  ```java
  if (entity.getDeliveryDate() == null) throw new JeecgBootException("交货日期不能为空");
  ```
- 这是合理的业务约束（销售订单必须有交货日期），不是产品 bug

**7.1 失败详情**：
```
请求: POST /mes/finance/collection/add
      {"code":"COL-856926084172","collectionDate":"2026-08-04","customerId":"...","amount":150,"receivableId":"2083032721981177857","remark"...}
响应: {"success":false,"message":"收款金额(150)超过未结金额(100.00)"}
```
- 测试假设 `amount=150`（10 件 × 15 元）
- 但请求里用的 `receivableId: 2083032721981177857` 是**历史数据**（之前测试遗留），未结金额只剩 100
- 同时 step 6.2 报告应收 500（历史数据残留），与 150 期望对不上
- 这是测试**没有基于本次创建的应收单做收款**，而是用了历史 ID

### 2.4 链路测试代码现状

`tests/chains/sales-receipt-flow.test.js` 是一个 9-step 完整链路测试，每个 step 用 try/catch 包装，失败后续 step 跳过。当前 step 0.x setup 全过，1.x 创建订单失败导致后续 5.x 数据校验全失败。

---

## 三、技术债务与遗留风险

### 3.1 已修复（4 个）

| Bug | 修复 commit | 验收方式 |
|---|---|---|
| #9 收款 Drawer 404 | 8d3b400 | spec + 截图 |
| #11 付款 Drawer 404 | 8d3b400 | spec + 截图 |
| #13 mes:basic:* 权限缺失 | a8250ba | 数据库 + API 实测 |
| #14 SysMessageModal TS 泛型 + 全仓 | 2afa4d5 + 4ee13c0 | pageerrors: 0 |

### 3.2 剩余风险（需要后续处理）

| 风险 | 严重度 | 说明 | 建议 |
|---|---|---|---|
| **链路测试 4 个失败**（1.1/5.1/5.3/7.1） | P2 | 测试代码 bug（1.1 缺 deliveryDate、7.1 用历史 receivableId）+ 级联 | 用户选定 E 后跟进 |
| **ESLint 'no-explicit-any' 仍是 warn** | P3 | 项目 720+ 处其他 `any` 用法（不在 Options API 文件中） | 未来 Sprint 升级为 error |
| **#2 库存预警产品优化**（TKT-005） | P2 | 5 个产品优化方向待业务侧明确范围 | 等业务侧对齐 |
| **前端 Drawer 缺 import 校验** | P3 | sys-level 的 `<any>` 修复是治标（11 个文件），治本需 babel parser 配置升级 | TKT-004 文档化根因 |

### 3.3 误判（8 个已确认不是 bug）

| Issue | 误判原因 |
|---|---|
| #1 库存总览 | spec URL 错（应 `/warehouse/inventory`） |
| #3 编码规则 | 产品决策不需导出 |
| #5 批次台账 | 只读数据流页面，不该有新增 |
| #6 批次库存 | 同 #5 |
| #7 其它入库预填 | spec 硬编码 MAT-A000027 不存在 |
| #8 应收账款 | 同 #5，只读页 |
| #10 应付账款 | 同 #8 |
| #12 采购台账 | spec 凭空猜的页面（实际是"库存台账"） |

---

## 四、本周 commit 链总览

```
a8250ba  fix(mes): TKT-002 客户管理 mes:basic:* 权限码补齐
8d3b400  fix(mes): TKT-001 财务收款/付款 Drawer 补齐（修复 #9 + #11）
2afa4d5  fix(mes): TKT-003 SysMessageModal TS 泛型 <any> 未剥离修复（#14 方案 A）
4ee13c0  fix(mes): TKT-004 全仓 Options API <any> 泛型修复 + 开启 ESLint 防复发（#14 方案 B）
87d0f39  docs(eagle-eye): 13 个 issue 复核完毕，建立 2026-08-04 Sprint 排期
535b1fc  docs(eagle-eye): TKT-002 标记为已完成（commit a8250ba）
```

外加 14 个之前复核 commit（mes-2026-08-04-business-bugs#1 ~ #13）

---

## 五、进程与端口状态

| 服务 | 状态 | 端口 | PID |
|---|---|---|---|
| 后端 fat-jar | ✅ 健康 | 8080 | 48372 |
| 前端 Vite dev | ✅ 健康 | 3100 | 115207 |
| MySQL | ✅ 健康 | 3306 | — |

日志路径：`harness/.regression-runs/backend/fat-jar.out`（后端）

---

## 六、用户待办（手工核实）

**请用户核对以下要点**（如有问题再讨论）：

1. ✅ **本周完成度**：4 个 ticket 全部完成（a8250ba → 4ee13c0），实际工时 ~4.5h
2. ⏸️ **链路测试 4 个失败**：全部是测试代码 bug（缺字段、用历史 ID），不是产品 bug
3. ⏸️ **业务规则"交货日期不能为空"**：合理约束，不是 bug
4. ⏸️ **TKT-005 库存预警产品优化**：待业务侧对齐范围（不在 W1 范围）
5. ⏸️ **ESLint 'no-explicit-any' 仍是 warn**：未来 Sprint 升级为 error（需先清理存量 720+ 处）

---

## 七、后续选项

### 选项 E：跟进 sales-receipt-flow 链路测试

**预计工时**：1-1.5h
**具体步骤**：
1. 修 `tests/chains/sales-receipt-flow.test.js` step 1.1：补 `deliveryDate` 字段
2. 修 step 7.1：使用本次创建的 receivableId 而非历史 ID；修正金额期望
3. 重跑链路：预期 13/13 通过
4. commit + push

### 选项 F：TKT-005 库存预警产品优化（等业务侧对齐）

### 选项 G：Sprint 收尾总结（PR 描述 / Sprint Review 文档）

### 选项 H：其他指示

---

> **报告生成完毕**。请用户**手工核实**第 1-5 项 + 4 个失败逐条分析（第二节 2.2）。
> 确认无误后告知选哪个选项（E/F/G/H）。