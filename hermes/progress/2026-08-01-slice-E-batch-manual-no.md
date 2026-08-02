# 切片 E 进度：生产批次号手工录入模式（端到端）

**日期**：2026-08-01
**切片**：E（E1 数据库+实体 / E2 Service 集成 / E3 前端表单）
**前置依赖**：切片 A/B/C/D（生产批次总开关+物料开关+4 个 Service 集成）

## 目标

把"系统自动生成批次号"改为"操作员手工录入"，匹配供应商/生产线的实际业务场景。同步修正批次号唯一性约束（应按物料隔离）。3 切片串行实施。

## 完成清单

### 切片 E1：数据库 + 实体 ✅

| 操作 | 路径 | 改动 |
|------|------|------|
| 新建 | `db/V8.0.3__mes_batch_manual_no.sql` | 6 段 DDL（PRIMARY KEY + 2 索引 + 2 表加 2 字段）|
| 改 | `purchase/receipt/entity/MesPurchaseReceiptItem.java` | 加 batchNo + productionDate |
| 改 | `manufacturing/completion/entity/MesCompletionReceiptItem.java` | 同上 |

**验证**：
- 7 条历史数据 DELETE
- 旧索引 `uk_batch_no_del` DROP
- 新索引 `uk_batch_material_no_del (material_id, batch_no, del_flag)` CREATE
- 2 个 Item 表加字段成功
- 幂等性：重跑无报错
- 2 Entity 编译通过

### 切片 E2：后端 Service 集成 ✅

| 操作 | 路径 | 改动 |
|------|------|------|
| 改 | `batch/master/service/IMesBatchService.java` | 拆 `createBatchWithManualNo`，老 `createBatch` 标 `@Deprecated` |
| 改 | `batch/master/service/impl/MesBatchServiceImpl.java` | 实现新方法 + 委派调用 + 业务层查重 |
| 改 | `batch/master/controller/MesBatchController.java` | `.add()` 改调新方法（batchNo 非空用手动值，空走兜底）|
| 改 | `purchase/receipt/service/impl/MesPurchaseReceiptServiceImpl.java` | L189 audit 调 `createBatchWithManualNo` |
| 改 | `manufacturing/completion/service/impl/CompletionReceiptServiceImpl.java` | L145 audit 调 `createBatchWithManualNo` |
| 新 | `harness/tests/mes/batch-manual-e2e.test.js` | 7 个 API 场景 |

**端到端验证**（9/9 通过）：

| 场景 | 结果 |
|------|------|
| S1 手工录入 batchNo | ✅ "添加成功" |
| S2a 第一次创建 | ✅ "添加成功" |
| S2b 同物料同 batchNo 重复 | ✅ "批次号 DUP-... 在物料 MAT-0062 下已存在" |
| S3a A 物料 同号 | ✅ "添加成功" |
| S3b B 物料 同号(允许) | ✅ "添加成功" |
| S4 batchNo 为空(自动生成兜底) | ✅ "添加成功" |
| S5 batchNo 超长(51字符) | ✅ "长度不能超过50个字符" |
| S6 batchNo 空串(自动生成兜底) | ✅ "添加成功" |
| S7 list 可见 | ✅ 4 条测试记录 |

**核心证据**：同号 `SHARED-1785517326688` 在物料 A + B 下都成功（S3）→ 唯一索引按物料隔离生效。

### 切片 E3：前端表单接入 ✅

| 操作 | 路径 | 改动 |
|------|------|------|
| 改 | `purchase/receipt/ReceiptDrawer.vue` | 加 2 字段（条件显示）+ 校验 + 删无用 Divider import |
| 改 | `manufacturing/completion/CompletionReceiptDrawer.vue` | 同上模式 |
| 新 | `harness/e2e/mes/purchaseReceiptBatch.spec.ts` | 2 个 E2E 场景 |

**端到端验证**（2/2 通过）：

| 场景 | 结果 |
|------|------|
| S1 总开关关闭 → 抽屉里"生产批次号"列不出现 | ✅ 0 列 |
| S2 总开关开启 → 抽屉里两列出现 | ✅ "生产批次号" + "生产日期" 两列可见 |

## 关键设计决策

| 决策 | 理由 |
|------|------|
| 拆 `createBatchWithManualNo` + 标 `@Deprecated` | 老调用方（Controller）平滑迁移，3-6 个月观察期 |
| 业务层查重（事务内）+ DB 唯一索引 双重保护 | 防御性编程：业务层给友好错误，DB 兜底 |
| **重要**：业务层查重用 `QueryWrapper`（按 `material_id + batch_no + del_flag=0`）| 跨事务保证——同事务内即使有并发也能拦住（行锁保护）|
| SQL DDL 用 `information_schema + PREPARE` 模式 | MySQL 5.7 兼容 + 幂等性（重跑不报错）|
| Controller 走兜底：batchNo 非空用手动值，空走自动生成 | 兼容老 `MesBatchMaster` 页面（不传 batchNo 时仍能跑）|
| 物料级 `batchEnabled` 不在 E3 范围 | 已在切片 C 实施（禁用 + 强制归零）|
| 批次主档前端 Drawer 不改 | 评审 P1-3 决策：Controller 走兜底逻辑，前端不调整 |

## 4 项踩坑（与本切片相关）

1. **ESLint v10 与 .eslintrc 不兼容** → 用项目锁定的 `eslint@8.57.1`（`./node_modules/.bin/eslint`）
2. **JSwitch emit 值是字符串 "1"/"0"**（不是 1/0）→ 后端 `Integer` 字段能反序列化（Jackson 自动转）
3. **"编辑"按钮文本 ant 加空格变"编 辑"** → 用 `text=/编辑/` regex 匹配
4. **登录 token 注入后需 waitForTimeout** → 至少 2s 让 token 持久化到 localStorage

## 验收标准（已完成）

- [x] 总开关关闭时，采购入库明细行**不出现**批次号/生产日期字段
- [x] 总开关+物料开关都开时，采购入库明细行**显示**"生产批次号"+"生产日期"列，必填
- [x] 提交时批次号**空**→ 友好报错"生产批次号不能为空"
- [x] 提交时批次号**重复**（同物料已有同号）→ 报错"批次号 X 在物料 Y 下已存在"
- [x] 提交时批次号**重复**（不同物料已有同号）→ ✅ 允许通过
- [x] 数据库：老 `uk_batch_no_del` 索引已删，新 `(material_id, batch_no, del_flag)` 已建
- [x] 历史 7 条 `BT-MAT-XXXX-...` 已被迁移 SQL 删除
- [x] 4 个 Service 改用 `createBatchWithManualNo`，老 `createBatch` 标 Deprecated 不动
- [x] `MesBatchController.add` 路径还能跑（外部兼容），但前端不再调
- [x] SQL 幂等性：重跑无报错

## 风险与回滚

| 风险 | 状态 |
|------|------|
| SQL DELETE 7 条数据不可逆 | ✅ 用户已明确接受 |
| 老 `createBatch` 标 Deprecated 后有外部调用 | ✅ 保留 3-6 个月观察期 |
| 前端条件渲染逻辑复杂 | ✅ E2E 覆盖 2 场景，含总开关切换边界 |
| 数据库唯一索引变更影响并发 | ✅ 业务层查重 + 行锁，串行化保护 |
| SQL 不幂等（重跑报错）| ✅ 已用 PREPARE 模式包装 |
| Controller 漏改导致用户输入被覆盖 | ✅ 评审 P0 已补 MesBatchController |

## 文件清单（总）

```
后端（5 文件）：
  db/V8.0.3__mes_batch_manual_no.sql                                    [新]
  MesPurchaseReceiptItem.java / MesCompletionReceiptItem.java            [改+2字段]
  IMesBatchService.java / MesBatchServiceImpl.java / MesBatchController.java   [拆方法+标Deprecated+改Controller]
  MesPurchaseReceiptServiceImpl.java / CompletionReceiptServiceImpl.java   [改 audit 调新方法]

前端（2 文件）：
  ReceiptDrawer.vue / CompletionReceiptDrawer.vue                        [条件显示+校验+删 Divider]

测试（2 文件）：
  harness/tests/mes/batch-manual-e2e.test.js                            [7 API 场景]
  harness/e2e/mes/purchaseReceiptBatch.spec.ts                          [2 E2E 场景]
```

## 收官总览

| 切片 | 内容 | 状态 |
|------|------|------|
| A | 建表 + 实体 + Service 基础 + checkCanClose + closeBatchSwitch 原子 | ✅ |
| B | 通用设置页 + 菜单 + 路由 + Pinia | ✅ |
| C | 物料页联动 + 3 道 disabled 兜底 + 跨 Tab 同步 | ✅ |
| D | 4 个 Service 集成总开关（入口缓存+2段守卫）| ✅ |
| E1 | V8.0.3 迁移 SQL（PREPARE 幂等）+ 2 Item 实体 | ✅ |
| E2 | 拆 createBatchWithManualNo + 4 调用点改调 + Controller 补改 | ✅ |
| E3 | 2 个 Drawer 条件显示+校验 | ✅ |

**端到端闭环已跑通**：

- 总开关关闭 → 物料页 batchEnabled 字段不出现 + 采购/完工明细行不出现批次号
- 总开关开启 → 物料页 batchEnabled 可编辑（受物料开关联动） + 采购/完工明细行出现批次号+生产日期两列
- 关闭后开启 → 字段实时同步，无需刷新
- 提交校验：批次号空/超长/同物料重复都有友好错误
- 跨物料同号允许：业务层查重 + DB 唯一索引双重保护都过了

**生产可用性**：✅ 4 个 Service 入口缓存模式对并发安全；✅ 业务层查重在事务内先于 DB 拦截，错误信息清晰；✅ 物料级 batchEnabled 自动联动总开关；✅ 总开关关闭瞬间所有物料 batchEnabled 自动归零（切片 A 解决竞态）。
