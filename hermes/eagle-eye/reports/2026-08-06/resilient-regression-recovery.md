<!--
MES 回归测试报告模板（v1）
基于 2026-08-04 Sprint Review 风格（CLAUDE.md 工作流 + SKILL.md 标准）

输出位置：
  harness/.regression-runs/<run-id>/regression-report.md  （本次运行的详细分析报告）
  hermes/eagle-eye/reports/<YYYY-MM-DD>/regression-report.md  （每日归档）

要求：用真实数据填充占位符 {{...}}，不允许保留模板标记。
-->
# MES 可恢复回归报告 — 2026-08-06

> **报告时间**：2026-08-06 14:49 UTC
> **运行 ID**：`20260806-224035`
> **任务**：MES regression recovery 2026-08-04 (FULL: 30 slices + chain)
> **范围**：full（32 个切片）
> **关联**：`harness/.regression-runs/20260806-224035/summary.md` + `hermes/eagle-eye/reports/2026-08-06/issues/`

---

## 一、通过率总览

| 指标 | 数值 |
|------|:--:|
| **总切片数** | 32 |
| **passed** | 22 ✅ |
| **failed** | 9 ❌ |
| **verdict** | 1 ⚖️ |
| **pending** | 0 ⏸ |
| **通过率** | 68.8% |
| **总耗时** | 559.0s |

---

## 二、本次会话关键改动（commit 链）

| Commit | 类型 | 说明 |
|---|---|---|
| `b1fbf47` | fix(harness): Phase 4 P0 bugfix - regression-report.js L369 路径双重嵌套 |
| `e256608` | feat(harness): Phase 4 / 建议 6 - 废弃 Python generate_report，统一 Node 生成 |
| `8d2ea4c` | fix(harness): Phase 3 P0 bugfix - regression-report.js L436 PROJECT → REPO |
| `d91de5e` | feat(harness): Phase 3 - 剩余 4 个 driver 切换到 paths.json |
| `9964e1f` | feat(harness): Phase 3 - resilient_regression.py + regression-report.js 切换到 paths.json |
| `dc16a6d` | feat(harness): Phase 3 / 建议 5 - 新增 paths.json + Python/Node 路径加载助手 |
| `ac22d4c` | fix(harness): Phase 1 bugfix - slice 1.4 移除错误 deps + run-batch.js 修双点命名 |
| `8e15aa9` | feat(harness): regression-report.js v2 多路径写入 + TZ 修复（Phase 2 / 建议 4） |
| `38f5ec3` | feat(harness): resilient_regression.py 多路径写入 + best-effort 错误隔离（Phase 2 / 建议 4） |
| `3971caa` | feat(harness): manifest 加 report_paths[] + report_mirror_paths[]（Phase 2 / 建议 4） |
| `c7c2362` | fix(harness): 3 个 .test.mjs 重命名为 .test.js + 加入 MODULE_BATCHES（修复 P0 漏跑） |
| `3220c5f` | chore(harness): 删除 run-regression.sh/.bat 死代码 + 修复 package.json 配置错 |
| `bf054a5` | feat(harness): manifest 加 slice 1.4 调度 purchase-chain 编排器（修复 P0 漏跑） |
| `0cd725a` | tool: 扩展 manifest 到全量测试（28 切片 / 31 含 chain） |
| `b2a703a` | tool: regression-report v2 真实数据抽取 + 全角冒号兼容 |
| `40ab570` | docs(skill): test-all v3.1 — 必跑步骤 5 自动调用 /eagle-eye-report |
| `c610f02` | tool: 固化回归报告生成器 (0804 Sprint Review 风格) + manifest report_path 模板化 |
| `72705ee` | fix(e2e): P1 修复 5 个 E2E spec（断言过严/数据前置/前端 WS 过滤） |
| `8f77419` | fix: 7.2-global-switch 测试逻辑修复 + batch_ledger 列重命名 |
| `dc2aa76` | fix: dev DB schema 补齐 + batch 测试 cleanup 字段修正 |
| `a09160a` | fix: regression manifest 跨平台化 (0-build mvn 命令 + test-quality python3) |
| `83330e8` | test: slice-14 misc-extra (batch+receivable+apply+receipt 补充端点) |
| `b71b748` | test: slice-13 basic-extra (codeRule+material+warehouse+customer 补充端点) |
| `08dd140` | test: slice-12 sales-extra (delivery+order+outbound+price 补充端点) |
| `a3ab491` | test: slice-11 purchase-order (edit+deleteBatch+queryAll+exportXls+selectPage+audit+unaudit+loadApplyItemsForOrder) |
| `76ea2a8` | test: slice-10 manufacturing-crud (bom/completion/order/picking edit+deleteBatch+queryAll+exportXls) |
| `b267c6b` | tool: 固化 v4 覆盖率扫描器到 harness/scripts/coverage.js (CLI 友好) |
| `62d185a` | fix: slice-4 ledger 路径注释澄清（controller 真实路径 /mes/warehouse/ledger） |

---

## 三、各切片结果

| 切片 | 名称 | 状态 | 耗时 | 备注 |
|---|---|:---:|:--:|---|
| 0-build | 完整构建后端并安装本地依赖 | ✅ passed | 12.2s | command exited with code 0 |
| frontend-static | 前端类型检查与构建验证 | ⚖️ verdict | 22.0s | command exited with code 1 |
| test-quality | API 测试断言质量扫描 (R009) | ✅ passed | 0.2s | command exited with code 0 |
| smoke-api | 变更感知冒烟 (核心接口) | ✅ passed | 0.6s | command exited with code 0 |
| smoke-e2e | 变更感知冒烟 (核心 E2E) | ✅ passed | 50.0s | command exited with code 0 |
| 1.1 | 采购申请到订单 | ✅ passed | 0.4s | command exited with code 0 |
| 1.2 | 采购订单到入库 | ✅ passed | 0.6s | command exited with code 0 |
| 1.3 | 采购入库到付款 | ✅ passed | 2.2s | command exited with code 0 |
| 1.4 | 采购链路贯通（编排器：申请→订单→入库→付款） | ✅ passed | 3.1s | command exited with code 0 |
| 2.1 | 销售收发货基础链路 | ✅ passed | 3.1s | command exited with code 0 |
| 3.2 | 生产链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 4.2 | 财务链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 5.3 | 库存链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 6.2 | 批次链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 7.2-global-switch | 批次总开关模块 | ✅ passed | 0.2s | command exited with code 0 |
| 7.2-manual | 批次手工录入模块 | ✅ passed | 0.4s | command exited with code 0 |
| 8.1 | 核心三页面 E2E | ✅ passed | 88.7s | command exited with code 0 |
| 8.2-manufacturing | 生产页面 E2E | ✅ passed | 98.3s | command exited with code 0 |
| 8.2-finance | 财务页面 E2E | ✅ passed | 0.6s | command exited with code 0 |
| 8.2-stocktake | 盘点页面 E2E | ❌ failed | 17.9s | command exited with code 1 |
| 8.3 | 批次六页面 E2E | ❌ failed | 239.1s | command exited with code 1 |
| module-basic-1 | Module API 测试 batch-1: basic-accountSubject ~ basic-location (12 个) | ❌ failed | 3.7s | command exited with code 1 |
| module-basic-2 | Module API 测试 batch-2: basic-material ~ finance (12 个) | ❌ failed | 5.1s | command exited with code 1 |
| module-extended | Module API 测试 batch-3: manufacturing ~ sales (12 个) | ❌ failed | 3.0s | command exited with code 1 |
| module-final | Module API 测试 batch-4: sales-outbound ~ warehouse-ledger (9 个) | ❌ failed | 1.8s | command exited with code 1 |
| e2e-basic | E2E batch-1: basic-* (16 个 spec) | ❌ failed | 0.2s | command exited with code 1 |
| e2e-biz | E2E batch-2: batch-* + commonSetting + finance + manufacturing + materialBatch (8 个 spec) | ❌ failed | 0.2s | command exited with code 1 |
| e2e-purchase-sales | E2E batch-3: purchase + sales + stocktake + traceability (11 个 spec) | ❌ failed | 0.2s | command exited with code 1 |
| concurrent-audit | 并发安全：audit 幂等性测试 | ✅ passed | 0.2s | command exited with code 0 |
| chain.purchase-chain.1 | 链路 采购链路 · 申请→订单 | ✅ passed | 0.4s | command exited with code 0 |
| chain.purchase-chain.2 | 链路 采购链路 · 订单→入库 | ✅ passed | 0.6s | command exited with code 0 |
| chain.purchase-chain.3 | 链路 采购链路 · 采购→入库→付款 | ✅ passed | 2.2s | command exited with code 0 |

---

## 四、失败切片逐条分析（按建议核实顺序）

### 4.1 `8.2-stocktake` — 盘点页面 E2E

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Error: Cannot read properties of null (reading 'records')
```

**失败的测试**：
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） (8.3s)`
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） (retry #1) (8.3s)`
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） ───────────────`
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） ────────────────`

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/8.2-stocktake.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.2 `8.3` — 批次六页面 E2E

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Test timeout of 60000ms exceeded.
```

**失败的测试**：
  - `e2e/mes/commonSetting.spec.ts:6 — 切片B：通用设置页面端到端验证 (11.7s)`
  - `e2e/mes/materialBatch.spec.ts:13 — 切片C.1：物料列表显示"启用批次"列 (10.2s)`
  - `e2e/mes/materialBatch.spec.ts:23 — 切片C.2：总开关开启时物料表单 batchEnabled 可编辑 (8.3s)`
  - `e2e/mes/materialBatch.spec.ts:66 — 切片C.3：总开关关闭时物料表单 batchEnabled 被禁用`
  - `e2e/mes/materialBatch.spec.ts:13 — 切片C.1：物料列表显示"启用批次"列 (retry #1) (5.1s)`

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/8.3.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.3 `module-basic-1` — Module API 测试 batch-1: basic-accountSubject ~ basic-location (12 个)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=3.656s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/module-basic-1.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.4 `module-basic-2` — Module API 测试 batch-2: basic-material ~ finance (12 个)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=5.078s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/module-basic-2.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.5 `module-extended` — Module API 测试 batch-3: manufacturing ~ sales (12 个)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=3.044s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/module-extended.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.6 `module-final` — Module API 测试 batch-4: sales-outbound ~ warehouse-ledger (9 个)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=1.827s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/module-final.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.7 `e2e-basic` — E2E batch-1: basic-* (16 个 spec)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Error: Cannot find module '/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/harness/scripts/run-batch.js'
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/e2e-basic.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.8 `e2e-biz` — E2E batch-2: batch-* + commonSetting + finance + manufacturing + materialBatch (8 个 spec)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Error: Cannot find module '/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/harness/scripts/run-batch.js'
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/e2e-biz.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.9 `e2e-purchase-sales` — E2E batch-3: purchase + sales + stocktake + traceability (11 个 spec)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Error: Cannot find module '/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/harness/scripts/run-batch.js'
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-224035/logs/e2e-purchase-sales.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

---

## 五、E2E 失败复核证据

- 复核目录：`hermes/eagle-eye/reports/2026-08-06/issues/`
- 复核文件：12 个（每个失败 spec 包含 .md + .json + runtime-diagnostics.json）

**按判定分类**：
- 🔴 **suspected_bug**: 11 个
- 🟢 **false_positive**: 1 个

**详情（前 10 个）**：
| 文件 | 页面 | 判定 | 分类 |
|---|---|---|---|
| mes-stocktake-spec-ts-盘点单-黄金模板重构版-全盘-快照-录入实盘-审核-库存校准-显示值为编码-… | `/project/mes/stock/stocktake` | suspected_bug | test_design |
| mes-traceabilityBatch-spec-ts-MES-批次追溯-V10-0-3-批次级-E2E-2-搜索批… | `未登记页面路径` | suspected_bug | unclassified |
| mes-purchase-spec-ts-库存台账-E2E-06-页面加载自检.md | `未登记页面路径` | suspected_bug | unclassified |
| mes-traceabilityBatch-spec-ts-MES-批次追溯-V10-0-3-批次级-E2E-3-R00… | `未登记页面路径` | suspected_bug | unclassified |
| mes-commonSetting-spec-ts-切片B-通用设置页面端到端验证.md | `/project/mes/basic/commonSetting` | suspected_bug | frontend_runtime |
| mes-purchase-spec-ts-采购申请-E2E-01-页面加载-列表渲染.md | `未登记页面路径` | suspected_bug | unclassified |
| mes-basic-spec-ts-MES-基础设置-E2E-库位管理-左树右表-批量生成按钮.md | `未登记页面路径` | false_positive | unclassified |
| mes-traceabilityBatch-spec-ts-MES-批次追溯-V10-0-3-批次级-E2E-4-点击查… | `/project/mes/batch/traceability` | suspected_bug | traceability_drawer |
| mes-other-stock-in-spec-ts-其它入库-新增入库单-物料选中后自动预填移动平均成本.md | `/project/mes/stock/other-in` | suspected_bug | data_precondition |
| mes-traceabilityBatch-spec-ts-MES-批次追溯-V10-0-3-批次级-E2E-1-页面加… | `未登记页面路径` | suspected_bug | unclassified |
| _...还有 2 个_ | | | |

---

## 六、技术债务与遗留风险

### 6.1 已修复

| 问题 | 修复 commit | 验收方式 |
|---|---|---|
| Phase 4 P0 bugfix - regression-report.js L369 路径双重 | `b1fbf47` | 通过验证（详见 commit message） |
| Phase 3 P0 bugfix - regression-report.js L436 PROJ | `8d2ea4c` | 通过验证（详见 commit message） |
| Phase 1 bugfix - slice 1.4 移除错误 deps + run-batch.j | `ac22d4c` | 通过验证（详见 commit message） |
| 3 个 .test.mjs 重命名为 .test.js + 加入 MODULE_BATCHES（修复 | `c7c2362` | 通过验证（详见 commit message） |
| P1 修复 5 个 E2E spec（断言过严/数据前置/前端 WS 过滤） | `72705ee` | 通过验证（详见 commit message） |
| 7.2-global-switch 测试逻辑修复 + batch_ledger 列重命名 | `8f77419` | 通过验证（详见 commit message） |
| dev DB schema 补齐 + batch 测试 cleanup 字段修正 | `dc2aa76` | 通过验证（详见 commit message） |
| regression manifest 跨平台化 (0-build mvn 命令 + test-qu | `a09160a` | 通过验证（详见 commit message） |
| slice-4 ledger 路径注释澄清（controller 真实路径 /mes/warehou | `62d185a` | 通过验证（详见 commit message） |

### 6.2 剩余风险

| 风险 | 严重度 | 说明 | 建议 |
|---|:--:|---|---|
| (待人工补充) | - | - |

---

## 七、用户待办（手工核实）

- 核对通过率（68.8%）
- 复核第四节失败切片根因
- 阅读第五节 E2E 复核证据
- 选择第八节后续选项

---

## 八、后续选项

- **选项 A**：跟进剩余 failed 切片
- **选项 B**：前端 Bug 修复（移交前端工程师）
- **选项 C**：覆盖率维护 + 新增 slice
- **选项 D**：其他指示

---

报告生成完毕。请用户手工核实第 1-5 项 + 失败逐条分析（第四节）。确认无误后告知选哪个选项。
