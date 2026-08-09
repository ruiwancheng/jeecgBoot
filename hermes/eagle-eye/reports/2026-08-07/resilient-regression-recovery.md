<!--
MES 回归测试报告模板（v2）
基于 2026-08-04 Sprint Review 风格（CLAUDE.md 工作流 + SKILL.md 标准）

输出位置：
  harness/.regression-runs/<run-id>/regression-report.md  （本次运行的详细分析报告）
  hermes/eagle-eye/reports/<YYYY-MM-DD>/regression-report.md  （每日归档）

要求：用真实数据填充占位符 {{...}}，不允许保留模板标记。

v2 (2026-08-07) 更新：
  - 第四节「失败切片逐条分析」新增两个固定字段：
    · 复现步骤（自动从 issues/*.md 抽取）
    · 复核结果（业务人员手工填写：真实BUG / 误判 + 原因）
  - 任何后续回归报告必须包含这两段，业务人员才能完成核实
-->
# MES 可恢复回归报告 — 2026-08-07

> **报告时间**：2026-08-07 14:51 UTC
> **运行 ID**：`20260807-220917`
> **任务**：MES regression recovery 2026-08-04 (FULL: 30 slices + chain)
> **范围**：full（38 个切片）
> **关联**：`harness/.regression-runs/20260807-220917/summary.md` + `hermes/eagle-eye/reports/2026-08-07/issues/`

---

## 一、通过率总览

| 指标 | 数值 |
|------|:--:|
| **总切片数** | 38 |
| **passed** | 23 ✅ |
| **failed** | 14 ❌ |
| **verdict** | 1 ⚖️ |
| **pending** | 0 ⏸ |
| **通过率** | 60.5% |
| **总耗时** | 2527.0s |

---

## 二、本次会话关键改动（commit 链）

| Commit | 类型 | 说明 |
|---|---|---|
| `5d590da` | test(mes-chain): business-chains.json 反映 slice-9 后覆盖率 100% |
| `5fc4e3f` | test(mes-chain): [/add-tests] 补 /exportXls 4 端点（12 断言） |

---

## 三、各切片结果

| 切片 | 名称 | 状态 | 耗时 | 备注 |
|---|---|:---:|:--:|---|
| 0-build | 完整构建后端并安装本地依赖 | ✅ passed | 14.0s | command exited with code 0 |
| frontend-static | 前端类型检查与构建验证 | ⚖️ verdict | 21.4s | command exited with code 1 |
| test-quality | API 测试断言质量扫描 (R009) | ✅ passed | 0.2s | command exited with code 0 |
| smoke-api | 变更感知冒烟 (核心接口) | ✅ passed | 0.8s | command exited with code 0 |
| smoke-e2e | 变更感知冒烟 (核心 E2E) | ✅ passed | 49.2s | command exited with code 0 |
| 1.1 | 采购申请到订单 | ✅ passed | 0.4s | command exited with code 0 |
| 1.2 | 采购订单到入库 | ✅ passed | 0.6s | command exited with code 0 |
| 1.3 | 采购入库到付款 | ✅ passed | 2.2s | command exited with code 0 |
| 1.4 | 采购链路贯通（编排器：申请→订单→入库→付款） | ✅ passed | 2.6s | command exited with code 0 |
| 2.1 | 销售收发货基础链路 | ❌ failed | 2.8s | command exited with code 1 |
| 3.2 | 生产链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 4.2 | 财务链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 5.3 | 库存链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 6.2 | 批次链路编排 | ✅ passed | 0.4s | command exited with code 0 |
| 7.2-global-switch | 批次总开关模块 | ✅ passed | 0.2s | command exited with code 0 |
| 7.2-manual | 批次手工录入模块 | ✅ passed | 0.2s | command exited with code 0 |
| 8.1 | 核心三页面 E2E | ✅ passed | 84.7s | command exited with code 0 |
| 8.2-manufacturing | 生产页面 E2E | ✅ passed | 97.5s | command exited with code 0 |
| 8.2-finance | 财务页面 E2E | ✅ passed | 0.6s | command exited with code 0 |
| 8.2-stocktake | 盘点页面 E2E | ❌ failed | 17.5s | command exited with code 1 |
| 8.3 | 批次六页面 E2E | ❌ failed | 220.7s | command exited with code 1 |
| module-basic-1 | Module API 测试 batch-1: basic-accountSubject ~ basic-location (12 个) | ✅ passed | 3.0s | command exited with code 0 |
| module-basic-2 | Module API 测试 batch-2: basic-material ~ finance (12 个) | ❌ failed | 4.1s | command exited with code 1 |
| module-extended | Module API 测试 batch-3: manufacturing ~ sales (12 个) | ❌ failed | 2.8s | command exited with code 1 |
| module-final | Module API 测试 batch-4: sales-outbound ~ warehouse-ledger (9 个) | ❌ failed | 2.0s | command exited with code 1 |
| e2e-basic | E2E batch-1: basic-* (16 个 spec) | ❌ failed | 739.0s | command exited with code 1 |
| e2e-biz | E2E batch-2: batch-* + commonSetting + finance + manufacturing + materialBatch (8 个 spec) | ❌ failed | 384.5s | command exited with code 1 |
| e2e-purchase-sales | E2E batch-3: purchase + sales + stocktake + traceability (11 个 spec) | ❌ failed | 862.4s | command exited with code 1 |
| e2e-smoke | E2E smoke tests (4 个 spec: login/user-list/role-list/logout) | ✅ passed | 5.3s | command exited with code 0 |
| concurrent-audit | 并发安全：audit 幂等性测试 | ✅ passed | 0.2s | command exited with code 0 |
| chain.purchase-chain.1 | 链路 采购链路 · 申请→订单 | ✅ passed | 0.4s | command exited with code 0 |
| chain.purchase-chain.2 | 链路 采购链路 · 订单→入库 | ✅ passed | 0.4s | command exited with code 0 |
| chain.purchase-chain.3 | 链路 采购链路 · 采购→入库→付款 | ✅ passed | 2.0s | command exited with code 0 |
| chain.manufacturing-chain.1 | 链路 生产链路 · BOM状态机+同产品一生效 | ❌ failed | 0.8s | command exited with code 1 |
| chain.manufacturing-chain.2 | 链路 生产链路 · 订单状态机+库存校验+推领料单 | ❌ failed | 0.8s | command exited with code 1 |
| chain.manufacturing-chain.3 | 链路 生产链路 · 完工联动订单completedQty+status推进 | ❌ failed | 0.8s | command exited with code 1 |
| chain.manufacturing-chain.4 | 链路 生产链路 · 补领量=总需-已领累计 | ❌ failed | 0.8s | command exited with code 1 |
| chain.manufacturing-chain.5 | 链路 生产链路 · UI流全链路(BOM→订单→领料→完工) | ❌ failed | 0.2s | command exited with code 1 |

---

## 四、失败切片逐条分析（按建议核实顺序）

> 每个失败切片包含 **状态 / 症状 / 关键错误 / 失败的测试 / 复现步骤 / 复核结果 / 修复建议** 七段。
> **复现步骤** 由报告生成器自动从 `hermes/eagle-eye/reports/2026-08-07/issues/` 抽取；
> **复核结果** 是 AI 根据业务人员口头反馈记录的（业务人员不直接编辑报告）。
> 当业务人员核完一条后，给 AI 一句中文描述（例：「这条是 dev DB 残留数据导致的误判」），AI 会填入对应小节。

### 4.1 `2.1` — 销售收发货基础链路

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=2.842s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.1 `2.1` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/2.1.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.2 `8.2-stocktake` — 盘点页面 E2E

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Error: expect(received).toBe(expected) // Object.is equality
```

**失败的测试**：
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） (8.0s)`
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） (retry #1) (8.1s)`
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） ───────────────`
  - `e2e/mes/stocktake.spec.ts:48 — 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4） ────────────────`

**复现步骤**：页面路径: `/project/mes/stock/stocktake`

**spec**: `mes/stocktake.spec.ts`
- 测试位置：`48:7` 标题：›  › mes/stocktake.spec.ts › 盘点单（黄金模板重构版） › 全盘→快照→录入实盘→审核→库存校准→显示值为编码（锚点#4）
  操作步骤：
    1. 登录系统
    2. 创建唯一盘点 fixture
    3. 执行盘点、快照、实盘、审核和清理
  预期结果（业务描述）：盘点页面独立完成业务流验证并清理测试数据
  实际结果：断言失败【盘点账面数量(`bookQty`)、批次单位成本(`unitCost`)】：期望值 `20`，实际值 `380`

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.2 `8.2-stocktake` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/8.2-stocktake.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.3 `8.3` — 批次六页面 E2E

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Test timeout of 60000ms exceeded.
```

**失败的测试**：
  - `e2e/mes/commonSetting.spec.ts:6 — 切片B：通用设置页面端到端验证 (4.8s)`
  - `e2e/mes/materialBatch.spec.ts:13 — 切片C.1：物料列表显示"启用批次"列 (6.5s)`
  - `e2e/mes/materialBatch.spec.ts:23 — 切片C.2：总开关开启时物料表单 batchEnabled 可编辑 (9.1s)`
  - `e2e/mes/materialBatch.spec.ts:66 — 切片C.3：总开关关闭时物料表单 batchEnabled 被禁用`
  - `e2e/mes/materialBatchEnabledSave.spec.ts:13 — batchEnabled 字符串 "1"/"0" Jackson 反序列化为 Integer 1/0 (69ms)`

**复现步骤**：页面路径: `/project/mes/basic/material, /project/mes/stock/other-in, 未登记页面路径, /project/mes/batch/traceability`

**spec**: `mes/materialBatch.spec.ts`
- 测试位置：`23:5` 标题：›  › mes/materialBatch.spec.ts › 切片C.2：总开关开启时物料表单 batchEnabled 可编辑
  操作步骤：
    1. 打开通用设置并开启生产批次管理
    2. 进入物料页面
    3. 打开第一条物料编辑抽屉
    4. 检查启用批次开关是否可编辑
  预期结果（业务描述）：总开关开启时，物料编辑抽屉中的启用批次开关可编辑
  实际结果：Error: 总开关开启时 batchEnabled 不应禁用
**spec**: `mes/other-stock-in.spec.ts`
- 测试位置：`23:7` 标题：›  › mes/other-stock-in.spec.ts › 其它入库 › 新增入库单-物料选中后自动预填移动平均成本
  操作步骤：
    1. 登录系统
    2. 打开其它入库页面
    3. 点击新增
    4. 选择入库类型和仓库
    5. 打开物料选择弹窗
    6. 搜索有移动平均成本的测试物料
    7. 确认物料并检查成本单价
  预期结果（业务描述）：物料选择成功，成本单价自动预填为移动平均成本
  实际结果：断言失败：期望值 `92.5887`，实际值 `0`
**spec**: `mes/traceabilityBatch.spec.ts`
- 测试位置：`171:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 5. 导出按钮可见 + 点击触发下载
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`96:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 3. R005 搜索特殊字符不报错
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：测试超时（>60秒）
- 测试位置：`204:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 7. 重置按钮清空搜索条件
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`192:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 6. 列表列不包含旧 ledger 字段
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`125:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 4. 点击查看追溯 → 抽屉显示口径提示 + 流水表
  操作步骤：
    1. 登录系统
    2. 打开批次追溯页面
    3. 选择有流水的批次
    4. 点击查看追溯
    5. 检查批次追溯抽屉和批次流水区域
  预期结果（业务描述）：抽屉显示批次追溯口径提示、批次流水标题和流水表头
  实际结果：页面元素未出现：expect(locator).toBeVisible() failed
- 测试位置：`51:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 1. 页面加载 + 列表显示批次级字段
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`73:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 2. 搜索批次号
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`222:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 8. 翻页到第二页（如有数据）
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.3 `8.3` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/8.3.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.4 `module-basic-2` — Module API 测试 batch-2: basic-material ~ finance (12 个)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=4.052s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.4 `module-basic-2` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/module-basic-2.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.5 `module-extended` — Module API 测试 batch-3: manufacturing ~ sales (12 个)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=2.846s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.5 `module-extended` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/module-extended.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.6 `module-final` — Module API 测试 batch-4: sales-outbound ~ warehouse-ledger (9 个)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=2.038s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.6 `module-final` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/module-final.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.7 `e2e-basic` — E2E batch-1: basic-* (16 个 spec)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Test timeout of 60000ms exceeded.
```

**失败的测试**：
  - `e2e/mes/basic-accountSubject.spec.ts:15 — MES 会计科目 E2E（/add-tests 完整版） › 会计科目 1. 路由可达性 + 页面渲染 (4.6s)`
  - `e2e/mes/basic-accountSubject.spec.ts:23 — MES 会计科目 E2E（/add-tests 完整版） › 会计科目 2. 表格 + 列头可见 (3.6s)`
  - `e2e/mes/basic-accountSubject.spec.ts:31 — MES 会计科目 E2E（/add-tests 完整版） › 会计科目 3. 工具栏：新增科目 + 导出 + 树形视图 (3.6s)`
  - `e2e/mes/basic-accountSubject.spec.ts:39 — MES 会计科目 E2E（/add-tests 完整版） › 会计科目 4. 数据行或空状态可见 (4.0s)`
  - `e2e/mes/basic-accountSubject.spec.ts:50 — MES 会计科目 E2E（/add-tests 完整版） › 会计科目 5. 点击新增科目 → SubjectDrawer 打开 (5.1s)`

**复现步骤**：页面路径: `/project/mes/basic/codeRule, /project/mes/basic/inventory, /project/mes/basic/inventoryAlert`

**spec**: `mes/basic-codeRule.spec.ts`
- 测试位置：`47:7` 标题：›  › mes/basic-codeRule.spec.ts › MES 编码规则 E2E（gen-tests 完整版） › 编码规则 4. 导出按钮可见
  操作步骤：
    1. 登录系统
    2. 打开编码规则页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：编码规则页面完成基础交互验证
  实际结果：页面元素未出现：编码规则 导出按钮
**spec**: `mes/basic-inventory.spec.ts`
- 测试位置：`73:7` 标题：›  › mes/basic-inventory.spec.ts › MES 库存总览 E2E（只读 dashboard） › 库存总览 6. 库存金额合计可见（页面特性）
  操作步骤：
    1. 登录系统
    2. 打开库存总览页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存总览页面完成基础交互验证
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`54:7` 标题：›  › mes/basic-inventory.spec.ts › MES 库存总览 E2E（只读 dashboard） › 库存总览 4. 仓库筛选下拉可见
  操作步骤：
    1. 登录系统
    2. 打开库存总览页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存总览页面完成基础交互验证
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`32:7` 标题：›  › mes/basic-inventory.spec.ts › MES 库存总览 E2E（只读 dashboard） › 库存总览 1. 路由可达性 + 页面渲染
  操作步骤：
    1. 登录系统
    2. 打开库存总览页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存总览页面完成基础交互验证
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`48:7` 标题：›  › mes/basic-inventory.spec.ts › MES 库存总览 E2E（只读 dashboard） › 库存总览 3. 搜索表单 + 查询按钮可见
  操作步骤：
    1. 登录系统
    2. 打开库存总览页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存总览页面完成基础交互验证
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`62:7` 标题：›  › mes/basic-inventory.spec.ts › MES 库存总览 E2E（只读 dashboard） › 库存总览 5. 数据行或空状态可见
  操作步骤：
    1. 登录系统
    2. 打开库存总览页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存总览页面完成基础交互验证
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`40:7` 标题：›  › mes/basic-inventory.spec.ts › MES 库存总览 E2E（只读 dashboard） › 库存总览 2. 表格 + 列头可见
  操作步骤：
    1. 登录系统
    2. 打开库存总览页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存总览页面完成基础交互验证
  实际结果：前端页面无法访问（Connection Refused）
**spec**: `mes/basic-inventoryAlert.spec.ts`
- 测试位置：`25:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 1. 路由可达性 + 页面渲染
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`59:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 6. 数据行或空状态可见
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：页面元素未出现：库存预警 空状态
- 测试位置：`41:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 3. 搜索表单 + 查询按钮可见
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：页面元素未出现：库存预警 查询按钮
- 测试位置：`47:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 4. 导出按钮可见
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：页面元素未出现：库存预警 导出按钮
- 测试位置：`70:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 7. 点击新增 → 抽屉可见
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：测试超时（>60秒）
- 测试位置：`78:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 8. 预警级别筛选可见
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：Error: 预警页 select 数
- 测试位置：`53:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 5. 新增按钮可见
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：页面元素未出现：库存预警 新增按钮
- 测试位置：`33:7` 标题：›  › mes/basic-inventoryAlert.spec.ts › MES 库存预警 E2E（gen-tests 完整版） › 库存预警 2. 表格 + 列头可见
  操作步骤：
    1. 登录系统
    2. 打开库存预警页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：库存预警页面完成基础交互验证
  实际结果：页面元素未出现：库存预警 表格可见

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.7 `e2e-basic` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/e2e-basic.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.8 `e2e-biz` — E2E batch-2: batch-* + commonSetting + finance + manufacturing + materialBatch (8 个 spec)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Test timeout of 60000ms exceeded.
```

**失败的测试**：
  - `e2e/mes/batch-inventory.spec.ts:25 — MES 批次库存 E2E（gen-tests 完整版） › 批次库存 1. 路由可达性 + 页面渲染 (4.6s)`
  - `e2e/mes/batch-inventory.spec.ts:33 — MES 批次库存 E2E（gen-tests 完整版） › 批次库存 2. 表格 + 列头可见 (3.0s)`
  - `e2e/mes/batch-inventory.spec.ts:41 — MES 批次库存 E2E（gen-tests 完整版） › 批次库存 3. 搜索表单 + 查询按钮可见 (3.0s)`
  - `e2e/mes/batch-inventory.spec.ts:47 — MES 批次库存 E2E（gen-tests 完整版） › 批次库存 4. 导出按钮可见 (3.0s)`
  - `e2e/mes/batch-inventory.spec.ts:53 — MES 批次库存 E2E（gen-tests 完整版） › 批次库存 5. 新增按钮可见 (13.2s)`

**复现步骤**：页面路径: `/project/mes/batch/inventory, /project/mes/batch/ledger, /project/mes/basic/material`

**spec**: `mes/batch-inventory.spec.ts`
- 测试位置：`53:7` 标题：›  › mes/batch-inventory.spec.ts › MES 批次库存 E2E（gen-tests 完整版） › 批次库存 5. 新增按钮可见
  操作步骤：
    1. 登录系统
    2. 打开批次库存页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：批次库存页面完成基础交互验证
  实际结果：页面元素未出现：批次库存 新增按钮
- 测试位置：`70:7` 标题：›  › mes/batch-inventory.spec.ts › MES 批次库存 E2E（gen-tests 完整版） › 批次库存 7. 点击新增 → 抽屉可见
  操作步骤：
    1. 登录系统
    2. 打开批次库存页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：批次库存页面完成基础交互验证
  实际结果：测试超时（>60秒）
**spec**: `mes/batch-ledger.spec.ts`
- 测试位置：`78:7` 标题：›  › mes/batch-ledger.spec.ts › MES 批次台账 E2E（gen-tests 完整版） › 批次台账 8. 批次选择下拉可见（listByBatchId 端点）
  操作步骤：
    1. 登录系统
    2. 打开批次台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：批次台账页面完成基础交互验证
  实际结果：Error: 批次台账 select 数
- 测试位置：`70:7` 标题：›  › mes/batch-ledger.spec.ts › MES 批次台账 E2E（gen-tests 完整版） › 批次台账 7. 点击新增 → 抽屉可见
  操作步骤：
    1. 登录系统
    2. 打开批次台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：批次台账页面完成基础交互验证
  实际结果：测试超时（>60秒）
- 测试位置：`53:7` 标题：›  › mes/batch-ledger.spec.ts › MES 批次台账 E2E（gen-tests 完整版） › 批次台账 5. 新增按钮可见
  操作步骤：
    1. 登录系统
    2. 打开批次台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：批次台账页面完成基础交互验证
  实际结果：页面元素未出现：批次台账 新增按钮
**spec**: `mes/materialBatch.spec.ts`
- 测试位置：`23:5` 标题：›  › mes/materialBatch.spec.ts › 切片C.2：总开关开启时物料表单 batchEnabled 可编辑
  操作步骤：
    1. 打开通用设置并开启生产批次管理
    2. 进入物料页面
    3. 打开第一条物料编辑抽屉
    4. 检查启用批次开关是否可编辑
  预期结果（业务描述）：总开关开启时，物料编辑抽屉中的启用批次开关可编辑
  实际结果：Error: 总开关开启时 batchEnabled 不应禁用

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.8 `e2e-biz` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/e2e-biz.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.9 `e2e-purchase-sales` — E2E batch-3: purchase + sales + stocktake + traceability (11 个 spec)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Test timeout of 60000ms exceeded.
```

**失败的测试**：
  - `e2e/mes/other-stock-in.spec.ts:23 — 其它入库 › 新增入库单-物料选中后自动预填移动平均成本 (9.0s)`
  - `e2e/mes/other-stock-in.spec.ts:23 — 其它入库 › 新增入库单-物料选中后自动预填移动平均成本 (retry #1) (8.9s)`
  - `e2e/mes/purchase-ledger.spec.ts:25 — MES 采购台账 E2E（gen-tests 完整版） › 采购台账 1. 路由可达性 + 页面渲染 (4.6s)`
  - `e2e/mes/purchase-ledger.spec.ts:33 — MES 采购台账 E2E（gen-tests 完整版） › 采购台账 2. 表格 + 列头可见 (33.5s)`
  - `e2e/mes/purchase-ledger.spec.ts:33 — MES 采购台账 E2E（gen-tests 完整版） › 采购台账 2. 表格 + 列头可见 (retry #1) (33.5s)`

**复现步骤**：页面路径: `/project/mes/stock/other-in, /project/mes/purchase/ledger, /project/mes/sales/outbound, 未登记页面路径, /project/mes/batch/traceability`

**spec**: `mes/other-stock-in.spec.ts`
- 测试位置：`23:7` 标题：›  › mes/other-stock-in.spec.ts › 其它入库 › 新增入库单-物料选中后自动预填移动平均成本
  操作步骤：
    1. 登录系统
    2. 打开其它入库页面
    3. 点击新增
    4. 选择入库类型和仓库
    5. 打开物料选择弹窗
    6. 搜索有移动平均成本的测试物料
    7. 确认物料并检查成本单价
  预期结果（业务描述）：物料选择成功，成本单价自动预填为移动平均成本
  实际结果：断言失败：期望值 `92.5887`，实际值 `0`
**spec**: `mes/purchase-ledger.spec.ts`
- 测试位置：`41:7` 标题：›  › mes/purchase-ledger.spec.ts › MES 采购台账 E2E（gen-tests 完整版） › 采购台账 3. 搜索表单 + 查询按钮可见
  操作步骤：
    1. 登录系统
    2. 打开采购台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：采购台账页面完成基础交互验证
  实际结果：页面元素未出现：采购台账 查询按钮
- 测试位置：`70:7` 标题：›  › mes/purchase-ledger.spec.ts › MES 采购台账 E2E（gen-tests 完整版） › 采购台账 7. 点击新增 → 抽屉可见
  操作步骤：
    1. 登录系统
    2. 打开采购台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：采购台账页面完成基础交互验证
  实际结果：测试超时（>60秒）
- 测试位置：`59:7` 标题：›  › mes/purchase-ledger.spec.ts › MES 采购台账 E2E（gen-tests 完整版） › 采购台账 6. 数据行或空状态可见
  操作步骤：
    1. 登录系统
    2. 打开采购台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：采购台账页面完成基础交互验证
  实际结果：页面元素未出现：采购台账 空状态
- 测试位置：`33:7` 标题：›  › mes/purchase-ledger.spec.ts › MES 采购台账 E2E（gen-tests 完整版） › 采购台账 2. 表格 + 列头可见
  操作步骤：
    1. 登录系统
    2. 打开采购台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：采购台账页面完成基础交互验证
  实际结果：页面元素未出现：采购台账 表格可见
- 测试位置：`47:7` 标题：›  › mes/purchase-ledger.spec.ts › MES 采购台账 E2E（gen-tests 完整版） › 采购台账 4. 导出按钮可见
  操作步骤：
    1. 登录系统
    2. 打开采购台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：采购台账页面完成基础交互验证
  实际结果：页面元素未出现：采购台账 导出按钮
- 测试位置：`53:7` 标题：›  › mes/purchase-ledger.spec.ts › MES 采购台账 E2E（gen-tests 完整版） › 采购台账 5. 新增按钮可见
  操作步骤：
    1. 登录系统
    2. 打开采购台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：采购台账页面完成基础交互验证
  实际结果：页面元素未出现：采购台账 新增按钮
- 测试位置：`78:7` 标题：›  › mes/purchase-ledger.spec.ts › MES 采购台账 E2E（gen-tests 完整版） › 采购台账 8. 成本/库存台账 tab 切换可见
  操作步骤：
    1. 登录系统
    2. 打开采购台账页面
    3. 检查路由、表格、查询、导出、新增、抽屉
  预期结果（业务描述）：采购台账页面完成基础交互验证
  实际结果：断言失败：期望值 `>=`，实际值 `0`
**spec**: `mes/sales-outbound.spec.ts`
- 测试位置：`92:7` 标题：›  › mes/sales-outbound.spec.ts › MES 销售出库 E2E（gen-tests 完整版） › 销售出库 8. 行操作：审核 / 取消（controller 暴露的扩展操作）
  操作步骤：
    1. 登录系统
    2. 打开销售出库页面
    3. 检查路由、表格、查询、导出、新增、审核和抽屉
  预期结果（业务描述）：出库页面独立完成基础交互验证，路由可达，审核/取消操作可发现
  实际结果：Error: 销售出库 行操作按钮数
**spec**: `mes/traceabilityBatch.spec.ts`
- 测试位置：`171:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 5. 导出按钮可见 + 点击触发下载
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`96:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 3. R005 搜索特殊字符不报错
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：测试超时（>60秒）
- 测试位置：`204:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 7. 重置按钮清空搜索条件
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`192:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 6. 列表列不包含旧 ledger 字段
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`125:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 4. 点击查看追溯 → 抽屉显示口径提示 + 流水表
  操作步骤：
    1. 登录系统
    2. 打开批次追溯页面
    3. 选择有流水的批次
    4. 点击查看追溯
    5. 检查批次追溯抽屉和批次流水区域
  预期结果（业务描述）：抽屉显示批次追溯口径提示、批次流水标题和流水表头
  实际结果：页面元素未出现：expect(locator).toBeVisible() failed
- 测试位置：`51:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 1. 页面加载 + 列表显示批次级字段
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`73:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 2. 搜索批次号
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）
- 测试位置：`222:7` 标题：›  › mes/traceabilityBatch.spec.ts › MES 批次追溯 V10.0.3 批次级 E2E › 8. 翻页到第二页（如有数据）
  操作步骤：
    1. 登录系统
    2. 打开测试对应页面
    3. 执行测试用例操作
  预期结果（业务描述）：页面完成加载并显示业务内容，或显示明确的空数据状态
  实际结果：前端页面无法访问（Connection Refused）

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.9 `e2e-purchase-sales` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/e2e-purchase-sales.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.10 `chain.manufacturing-chain.1` — 链路 生产链路 · BOM状态机+同产品一生效

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=0.814s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.10 `chain.manufacturing-chain.1` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/chain.manufacturing-chain.1.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.11 `chain.manufacturing-chain.2` — 链路 生产链路 · 订单状态机+库存校验+推领料单

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=0.814s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.11 `chain.manufacturing-chain.2` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/chain.manufacturing-chain.2.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.12 `chain.manufacturing-chain.3` — 链路 生产链路 · 完工联动订单completedQty+status推进

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=0.814s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.12 `chain.manufacturing-chain.3` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/chain.manufacturing-chain.3.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.13 `chain.manufacturing-chain.4` — 链路 生产链路 · 补领量=总需-已领累计

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
timed_out=False duration=0.81s
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.13 `chain.manufacturing-chain.4` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/chain.manufacturing-chain.4.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

### 4.14 `chain.manufacturing-chain.5` — 链路 生产链路 · UI流全链路(BOM→订单→领料→完工)

**状态**：failed

**症状**：`command exited with code 1`

**关键错误**：
```
Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/e2e/mes/helpers/diagnostic-test' imported from /Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/e2e/me
```

**失败的测试**：(无 Playwright 测试，API/链路切片)
  - (无 Playwright spec 匹配)

**复现步骤**：
⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。
   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.14 `chain.manufacturing-chain.5` 是真实 BUG / 误判，因为 ... 」，AI 用 edit 工具填入下方「复核结果」。

**复核结果**：
```
⏳ 待 AI 填充（业务人员复核后由 AI 记录）

记录格式示例：
  - 判定：[真实 BUG / 误判]
  - 严重度：[P0 阻塞 / P1 主流程 / P2 次要]
  - 业务侧原因：[一句话描述原因]
  - 跟进负责人：[XXX]
  - 复核人 / 时间：[业务人员名 / YYYY-MM-DD]
```

**原始日志**：`/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260807-220917/logs/chain.manufacturing-chain.5.attempt-1.log`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 `hermes/eagle-eye/reports/issues/` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 `python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed` 重跑

---

## 五、E2E 失败复核证据

- 复核目录：`hermes/eagle-eye/reports/2026-08-07/issues/`
- 复核文件：39 个（每个失败 spec 包含 .md + .json + runtime-diagnostics.json）

**按判定分类**：
- 🔴 **suspected_bug**: 39 个

**详情（前 10 个）**：
| 文件 | 页面 | 判定 | 分类 |
|---|---|---|---|
| mes-basic-inventoryAlert-spec-ts-MES-库存预警-E2E-gen-tests-完整版-… | /project/mes/basic/inventoryAlert | suspected_bug | page_rendering |
| mes-traceabilityBatch-spec-ts-MES-批次追溯-V10-0-3-批次级-E2E-5-导出按… | 未登记页面路径 | suspected_bug | unclassified |
| mes-stocktake-spec-ts-盘点单-黄金模板重构版-全盘-快照-录入实盘-审核-库存校准-显示值为编码-… | /project/mes/stock/stocktake | suspected_bug | test_design |
| mes-batch-inventory-spec-ts-MES-批次库存-E2E-gen-tests-完整版-批次库存-… | /project/mes/batch/inventory | suspected_bug | page_rendering |
| mes-basic-inventoryAlert-spec-ts-MES-库存预警-E2E-gen-tests-完整版-… | /project/mes/basic/inventoryAlert | suspected_bug | page_rendering |
| mes-basic-inventoryAlert-spec-ts-MES-库存预警-E2E-gen-tests-完整版-… | /project/mes/basic/inventoryAlert | suspected_bug | page_rendering |
| mes-basic-inventoryAlert-spec-ts-MES-库存预警-E2E-gen-tests-完整版-… | /project/mes/basic/inventoryAlert | suspected_bug | page_rendering |
| mes-purchase-ledger-spec-ts-MES-采购台账-E2E-gen-tests-完整版-采购台账-… | /project/mes/purchase/ledger | suspected_bug | page_rendering |
| mes-purchase-ledger-spec-ts-MES-采购台账-E2E-gen-tests-完整版-采购台账-… | /project/mes/purchase/ledger | suspected_bug | page_rendering |
| mes-batch-inventory-spec-ts-MES-批次库存-E2E-gen-tests-完整版-批次库存-… | /project/mes/batch/inventory | suspected_bug | page_rendering |
| _...还有 29 个_ | | | |

---

## 六、技术债务与遗留风险

### 6.1 已修复

| 问题 | 修复 commit | 验收方式 |
|---|---|---|
| (本次会话无 fix: commit) | - | - |

### 6.2 剩余风险

| 风险 | 严重度 | 说明 | 建议 |
|---|:--:|---|---|
| (待人工补充) | - | - |

---

## 七、用户待办（AI 记录复核结果）

> 工作流：**业务人员口头复核 → 通知 AI → AI 用 edit 工具填入对应小节**
>
> 业务人员不需要懂技术，不需要操作 markdown，只需要用中文口头反馈给 AI。
> 反馈模板：
>   「4.X <切片id> 是真实 BUG / 误判，因为<原因>，严重度 P0/P1/P2，负责人 XXX」
>
> AI 收到后会在第四节对应小节填入以下结构：
> ```markdown
> **复核结果**：
> - 判定：真实 BUG / 误判
> - 严重度：P0 (阻塞) / P1 (主流程) / P2 (次要)
> - 业务侧原因：...
> - 跟进负责人：...
> - 复核人 / 时间：业务人员名 / YYYY-MM-DD
> ```

- 核对通过率（60.5%）
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

报告生成完毕。请用户手工核实第 1-5 项 + 失败逐条分析（第四节，每条须含「复核结果」）。确认无误后告知选哪个选项。
