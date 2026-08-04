# MES 回归体系评估 + 本地全量回归总结

## 日期
2026-08-05

## 分支
fix/regression-2026-08-04

## 上下文
v0.2 修复（6 commits）后的体系评估 + 本地完整回归（run 20260805-041046）+ 3 个新发现问题的修复

---

## 一、评估（修复前）

| # | 维度 | 评级 |
|---|------|:--:|
| 1 | 架构完整性 | 🟢 A |
| 2 | 业务可执行性 | 🟢 A- |
| 3 | 测试金字塔 | 🟢 A- |
| 4 | CI 闸门 | 🟡 B+ |
| 5 | 失败诊断 | 🟢 A |
| 6 | 残留技术债 | 🟡 B |
| 7 | 可演进性 | 🟢 A |

**整体**：B+ → A-（v0.2 修复后）

---

## 二、新发现的 7 个问题（v0.2 评审漏网）

| # | 等级 | 问题 | 文件 |
|---|:--:|------|------|
| **N1** | 🔴 P0 | `fixtures.js` 包装层违反 learnings/2026-08-04-js-positional-param-trap（token 静默丢弃） | harness/tests/modules/*.test.js |
| **N2** | 🔴 P0 | fixtures.js 用 Windows 全路径 mysql.exe + `mysql` 命令，Linux CI 必 ENOENT | harness/tests/helpers/fixtures.js |
| **N3** | 🟡 P1 | workflow summary job fail-open：typecheck 软门控 200 errors（基线 742）即使 typecheck 挂 workflow 仍判绿 | .github/workflows/functional-regression.yml |
| **N4** | 🟡 P1 | summary job 没 `exit 1` 在 e2e-test 失败时（C2 没修完） | .github/workflows/functional-regression.yml |
| **N5** | 🟡 P1 | e2e --retries=1 与 testing.md v2 regression-failure-two-layer 直接冲突（自动 false_positive 不进报告） | .github/workflows/functional-regression.yml |
| **N6** | 🟢 P2 | `harness/playwright.config.ts:19` 注释里示范硬编码 IP（BUG-3-R 修了 13 处代码，注释没改） | harness/playwright.config.ts |
| **N7** | 🟢 P3 | fixtures.js:42 `inType: '2'` 期初无注释 | harness/tests/helpers/fixtures.js |

### 跨评估维度的"评审漏网"根因

1. 评审只看修改 commit，没读整个 fixtures.js
2. 评审假设 CI=ubuntu，没发现 fixtures.js 是 Windows 假设
3. 评审把 learning 当背景文档，N1 反模式已记录但代码仍按反模式写

---

## 三、今日已修复（commit + push）

### 修复 1：N2（commit 55ef7bd）

- **改动**：
  - `harness/tests/helpers/fixtures.js`：dbCleanup 入口加 `SKIP_DB_CLEANUP` env-guard
  - `.github/workflows/functional-regression.yml`：api-test env 加 `SKIP_DB_CLEANUP=true`
- **代码量**：2 文件 +8 行
- **验证**：本地烟雾测试两端均 return true
- **根因**：CI services 容器无 host mysql client，execSync 必然 ENOENT

### 修复 2：N1（commit dc0ed05）

- **改动**：
  - 9 个 basic-*.test.js 文件：wrapper 签名由 `(method, path, token, body)` 改为 `(method, path, body)`，直接转发 `c.api`
  - 删全部 167 处冗余 token 调用
- **代码量**：9 文件 +185/-167
- **验证**：9 文件 167 用例 100% 通过，0 回归，semgrep 全过
- **根因**：token 由 createClient 闭包管理，调用方无需传——wrapper 看似传 token 实际丢弃
- **副效**：`learnings/2026-08-04-js-positional-param-trap.md` 从"经验文档"升级为"已反哺代码"

---

## 四、本地全量回归（run 20260805-041046）

| 项 | 值 |
|---|---|
| 启动时间 | 04:10:46 |
| 完成时间 | 04:30:09 |
| 总耗时 | 19min 23s |
| 总切片 | 23 |
| ✅ PASS | 20 (87%) |
| ❌ FAIL | 3 |

### 4.1 PASS 切片（20 个）

```
0-build, test-quality, smoke-api, smoke-e2e,
1.1, 1.2, 1.3, 2.1, 3.2, 4.2, 5.3, 6.2,
7.2-global-switch, 7.2-manual,
8.1, 8.2-manufacturing, 8.2-stocktake,
chain.purchase-chain.1, chain.purchase-chain.2, chain.purchase-chain.3
```

### 4.2 FAIL 切片（3 个）

| 切片 | 退出码 | 根因 | 复核判定 |
|------|:---:|------|----------|
| frontend-static | 1 | vue-tsc 错误数 > 200（基线 742） | **N3 实证**：软门控真生效，不是装饰品 |
| 8.2-finance | 1 | 4 个子用例失败（应付/应收账款"新增"按钮找不到） | suspected_bug × 2 |
| 8.3 | 1 | 2 个子用例失败（其它入库移动平均成本未预填、批次追溯抽屉不显示流水） | suspected_bug × 2 |

### 4.3 evidence-reporter 自动工作

- 生成 8 份路径化复核报告（`hermes/eagle-eye/reports/2026-08-05/issues/`）
- 含截图 + 视频 + runtime-diagnostics（consoleErrors / pageErrors / failedRequests）
- 自动判定 `suspected_bug`（连挂 2 次 → 升级）
- review-summary.md 汇总

---

## 五、4 个真实产品 bug（待人工复核）

| # | 切片 | 页面 | 复核判定 | 历史背景 |
|---|------|------|----------|----------|
| **B1** | 8.2-finance | `/project/mes/finance/payable` 应付账款 5/7 新增按钮不可见 | suspected_bug → confirmed_bug | 已知 (slice-1.3 supplier_id NOT NULL) 新表现面 |
| **B2** | 8.2-finance | `/project/mes/finance/receivable` 应收账款 5/7 同上 | suspected_bug | 新发现（同 B1） |
| **B3** | 8.3 | 其它入库 — 物料选中后自动预填移动平均成本未生效 | suspected_bug | 新发现 |
| **B4** | 8.3 | `/project/mes/batch/traceability` 批次追溯 V10.0.3 — 抽屉显示"批次流水"区域未渲染 | suspected_bug | API listByBatchId 6.x 测过全绿，**前端 bug** |

**关键诊断**：
- B1/B2 是已知 supplier_id NOT NULL 触发 SQL 异常 → 页面渲染挂 → 按钮找不到（不是按钮本身被删）
- B4 是 6.1 API 测试全绿，但 E2E 抽屉 UI 渲染失败 → **前端代码问题**（待查是否有 `<template>` 漏渲染 / v-if 守卫等）

---

## 五-B、人工复核结果（2026-08-05）

**复核来源**：`hermes/eagle-eye/issues/mes-2026-08-04-business-bugs.md`（同日复核，已记录历史结论）

| # | 复核结论 | 历史证据 | 测试侧 action item |
|---|----------|----------|-------------------|
| **B1** 应付账款 | ✅ **confirmed_false_positive** | #10（line 628-679）：MesPayableController 仅 list/queryById/queryAll/exportXls 4 个端点，**无 add/edit/delete**，菜单权限仅 `list, export` | 调整 `finance.spec.ts` 中应付账款的 5/7 测试为 `test.skip` 或改成只读 + 导出断言 |
| **B2** 应收账款 | ✅ **confirmed_false_positive** | #8（line 502-561）：MesReceivableController 同型，数据由销售出库自动生成 | 调整 `finance.spec.ts` 中应收账款的 5/7 测试为 `test.skip` |
| **B3** 其它入库移动平均成本 | ✅ **confirmed_false_positive** | #7（line 430-497）：用户实测成功预填 71.6667/100.0000；spec 失败因硬编码 MAT-A000027 不存在 | 调整 `other-stock-in.spec.ts` 用 `apiViaPage` 动态查 `movingAvgCost > 0` 的物料代替硬编码 |
| **B4** 批次追溯抽屉 | 🔴 **confirmed_bug**（新发现） | 历史报告**未记录**——本次新发现；API 6.1 全绿（listByBatchId 工作正常），UI 抽屉不渲染 | 需新建业务修复切片（前端代码：`<template>`/v-if 守卫/`vxe-table` 列等排查） |

### 5.1 业务影响（B4）

**严重程度**：🔴 P1（核心业务追溯能力不可用）

**根因初步定位**：
- API `/mes/batch/ledger/listByBatchId?batchId=xxx` 已验证工作（6.1 全绿）
- E2E 点 "查看追溯" → 抽屉不显示 "批次流水" 区域
- diagnostics 显示抽屉 DOM 存在但内容缺失
- 候选根因（按优先级）：
  1. 抽屉 `<template>` 里 v-if 守卫条件错误（如 `v-if="ledgerList.length > 0"` 在 ledger 已加载后仍不渲染）
  2. vxe-table 列定义缺失/键错
  3. 抽屉 layout 嵌套层级问题导致内容不可见

**排期建议**：进入 P1 业务修复切片（前端工程师接手，0.5-1 人天）

### 5.2 测试侧 action items（B1/B2/B3）

不进产品排期，进测试侧改进：

1. **B1/B2 spec 改造**：`finance.spec.ts` 应付/应收账款 5/7 测试改为 `test.skip`
2. **B3 spec 改造**：`other-stock-in.spec.ts` 用 `apiViaPage` 动态查 `movingAvgCost > 0` 的物料
3. **gen-tests 模板优化**：模板应根据 controller endpoint set 调整——只有 GET /list 的 controller 不生成 add/edit/delete 期望
4. **统一处理**：与 #5/#6/#8/#10 历史误判同型，需一次性 spec 改造

---

## 六、关键观察

1. **N2 在本地未触发**（因为本地 mysql.exe 在路径中），但 CI 必然生效——本次 push 后等 CI 验证
2. **N3 软门控真实生效**（frontend-static 被拦截），不是装饰品——但**双重 fail-open** 仍是 N3 真问题
3. **runner 撞本地后端 file lock**（PID 27076 持有 jar）—— kill 后重启 OK，证明 N8（runner 端口探测）修复价值确认
4. **evidence-reporter 自动判定** `suspected_bug` 工作正常——8 份报告全到位，复核机制可信

---

## 七、明日（2026-08-06）排期建议

### 真 P0（必处理）

| # | 任务 | 工作量 | 风险 |
|---|------|:---:|------|
| **N8** | runner 端口探测：start 子命令前置 `netstat -ano \| grep :8080` 提示先停旧后端，避免 mvn clean 撞 file lock | 1h | 低（脚本） |
| **B4** | 批次追溯 V10.0.3 抽屉不渲染 — 前端 bug 修复（业务 P1） | 0.5-1 人天 | 中（前端代码） |

### 测试侧 P1（建议同步处理）

| # | 任务 | 工作量 |
|---|------|:---:|
| **TS-1** | `finance.spec.ts` 应付/应收账款 5/7 测试改 `test.skip` | 10min |
| **TS-2** | `other-stock-in.spec.ts` 物料动态化（去掉硬编码 MAT-A000027） | 30min |
| **TS-3** | gen-tests 模板改造（controller endpoint set 驱动） | 2h |

### 真 P1（建议处理）

| # | 任务 | 工作量 |
|---|------|:---:|
| **N3** | summary job fail-open 修复（去掉 typecheck 软门控 OR 加 api-test 同等的硬门控） | 1h |
| **N4** | summary job 加 `exit 1` 在 e2e-test 失败时 | 5min |
| **N5** | e2e-test 去掉 `--retries=1`（保留 testing.md v2 复核机制） | 5min |

### 真 P2（有空再处理）

| # | 任务 | 工作量 |
|---|------|:---:|
| **N6** | `harness/playwright.config.ts:19` 注释删硬编码 IP 示范 | 1min |
| **N7** | fixtures.js:42 inType:'2' 加注释（来源字典值） | 1min |
| **GAP-12** | 并发安全测试底座（FOR UPDATE 行锁 / 库存幻扣验证） | 2h |
| **GAP-13** | 权限越权测试底座 | 1h |

### 处理顺序建议

```
明天开工第 1 步：
1. N8 (1h) — 解决本地开发 + runner 共存问题（高频踩坑）
2. N4+N5 (10min) — 一行代码 + 一个 flag，立竿见影
3. N3 (1h) — 配合 N4+N5，CI 闸门才真生效
4. B1-B4 人工复核 — 等业务确认后再开业务修复切片
```

---

## 八、产物清单

| 类型 | 路径 |
|------|------|
| **本次回归 state** | `harness/.regression-runs/20260805-041046/` |
| 复核报告（8 份） | `hermes/eagle-eye/reports/2026-08-05/issues/` |
| review-summary | `hermes/eagle-eye/reports/2026-08-05/issues/review-summary.md` |
| **本报告** | `hermes/eagle-eye/reports/2026-08-05/run-summary-20260805.md` |

## 九、Commits 本日新增

```
55ef7bd fix(harness): N2 - CI 跳过 dbCleanup（services 容器无 host mysql client）
dc0ed05 fix(test): N1 - 9 module 测试消除 positional-param 反模式 wrapper
```

均已 push 至 origin/fix/regression-2026-08-04。

---

## 十、跨日变更（与昨日对比）

| 项 | 昨日（v0.2 修复后） | 今日 |
|---|---|---|
| 评估评级 | B+ → A- | A-（无变化） |
| 待办 P0 | R1（CI workflow 缺启动） | **新增 N8**（runner 端口探测）+ **B4**（批次追溯抽屉 bug） |
| 待办 P1 | R2/R3（Unit + 并发） | **新增 N3/N4/N5**（CI fail-open 链）+ **TS-1/2/3**（spec 改造） |
| 本地回归结果 | 无（v0.2 修复未跑全量） | **20/23 pass (87%)** |
| evidence-reporter | 未验证 | **8 份报告自动生成，机制可信** |
| B1-B3 复核 | 历史误判已记录（同 #5/#6/#7/#8/#10） | confirmed_false_positive（与历史一致） |
| B4 复核 | 未记录 | **confirmed_bug**（前端代码问题，进 P1） |
