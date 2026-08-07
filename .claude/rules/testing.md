---
name: testing
description: 测试标准——关键业务流 100% 覆盖 + 新模块三件套 + 5 断言锚点
glob: "**/*.test.*,**/*.spec.*"
version: 2.0
---

# 测试标准 v2（2026-07-29 重构，orca-review 定稿）

> 历史教训：盘点单交付时 API 14/14 + E2E 12/12 全绿，人工测试仍发现 4 个 bug（显示ID/payload形状/审核未生效/明细过多）。
> 根因：测试不在关键路径、金字塔错位（API强E2E弱渲染零）、环境脆弱失信。v2 对症下药。

## L0：规则（必须遵守）

### 覆盖目标：关键业务流 100%（不是行覆盖率）

- 每个业务链路在 `hermes/business-chains.json` 注册 `criticalPaths`，**只增不减**
- `/deploy-verify` 逐路径验证，遗漏路径 → WARN

### 新模块交付三件套（/plan 固定一栏，缺一则不算完成）

1. **API 业务流测试** `harness/tests/<项目>/<模块>.test.js`（创建→审核→状态→副作用）
2. **1 条 E2E 完整业务流** `harness/e2e/<项目>/<模块>.spec.ts`（创建→编辑→审核→结果页，用 helpers/auth 登录）
3. **关键 payload 从浏览器 DevTools 抓包保真**（禁止手工想象构造）

### 5 断言锚点（每个模块测试必含，防水测试）

| # | 锚点 | 示例 |
|---|------|------|
| 1 | 创建断言 | code 非空 + status='1' |
| 2 | 状态流转断言 | 草稿→审核→已审核 + 审核后不可编辑/删除 |
| 3 | 数据传递断言 | 审核后库存变化量 = 申报量 |
| 4 | **显示值断言** | 物料列显示编码/名称（如 `MAT-` 前缀），**裸 ID 判负** |
| 5 | 清理断言 | 测试后无残留（fixture 唯一编码 + 清理） |

### 工具规范

- **登录**：统一 `harness/e2e/mes/helpers/auth.ts` 的 `loginViaApi(page, path?)`（token 双层包装注入），禁止各 spec 重复写注入逻辑、禁止 UI 填验证码
- **共享 helper**：`harness/tests/helpers/api.js`（client+断言带根因输出）+ `fixtures.js`（建仓/料/供应商/期初/清理）
- **清理**：优先 API 清理；DB 清理必须走 SQL 文件（fixtures.dbCleanup），**禁止 execSync 内联 mysql 命令**（Windows 引号必炸）
- **唯一编码**：所有 fixture 用时间戳后缀，测试必须可重复运行（幂等）
- API 测试需 `enableLoginCaptcha: false` 或直接用 mes_admin token

## L1：模板

- API 测试模板：参考 `harness/tests/modules/stocktake.test.js`（14 场景：快照/盘亏/盘盈/守卫/回写）
- 链路测试模板：参考 `harness/tests/chains/purchase-apply-order.chain.test.js`（helper 版）
- E2E 模板：参考 `harness/e2e/mes/other-stock-in.spec.ts`

## L2：实践案例（4 bug × 4 盲区，2026-07-28）

| Bug | 盲区 | 对策 |
|-----|------|------|
| 物料显示 ID | API 测试只断数值不断显示值 | 锚点 #4 显示值断言 |
| 账面数取值有误 | payload 手工想象 ≠ 前端真实形状 | 三件套 #3 抓包保真 |
| 审核未生效 | 无 E2E 完整业务流 | 三件套 #2 |
| 明细过多（UX） | 自动化测不出 UX 权衡 | plan 阶段 UX 决策点显式化 |

## Bug 反哺 gen-tests 推导规则

```
Bug修复 → /debug 分析根因 → 判断gen-tests是否漏了此类场景
  → 是：询问用户确认 → 追加规则到 .claude/rules/gen-tests-rules.json
  → 否（架构/环境问题）：记录到 learnings/
```

规则存储：`.claude/rules/gen-tests-rules.json`，内置规则 + 自定义规则合并，自定义优先。

## /evolve 增量规则（2026-07）

### API 自动化测试关闭验证码（api-test-auth）

**前置条件**（CI/API 测试）：`application-dev.yml` 设 `jeecg.login.enableLoginCaptcha: false`。

**强制流程**：
1. 跑测试前确认 dev 配置已关
2. 测试完成后恢复（生产部署前）
3. 不在测试环境禁用密码加密/Token 校验（只关验证码）

详见 `learnings/2026-07-05-api-test-auth.md`。

### E2E 登录流程（e2e-login）

**强制**：
- 登录接口用 `/sys/login` + 加密（不是 mock）
- 登录后从响应或 `sys/getUserInfo` 拿 token
- 用 `loginViaApi(page, path?)` helper（已封装，含竞态重试）
- Token 注入到 `localStorage[<prefix>COMMON__LOCAL__KEY__].value.TOKEN__`（双层包装）

详见 `learnings/2026-07-05-e2e-login.md` + `frontend.md`（JeecgBoot token 双层包装章节）。

### E2E 登录闸门原则（e2e-login-gate-first）

**铁律**：登录是 E2E 闸门。**登录注入不通 → 所有用例死在第一步 → 下游漂移被掩盖**。

**修复顺序**：
1. 先修通公共登录（`harness/e2e/mes/helpers/auth.ts`）
2. 全量跑暴露真失败（**失败数"变多"是好转**——之前被登录失败掩盖）
3. 失败全在同一步 → 查登录/导航
4. 失败分散 → 内容漂移

详见 `learnings/2026-07-28-e2e-login-gate-first.md` + `frontend.md` 存量 E2E 修复章节。

### 登录超时诊断（login-timeout-diagnosis）

**症状**：登录接口返回 200 但前端跳登录页。

**5 步定位**：
1. **检查 dev tools Network 响应**：`code: 0` vs `code: 500`？
2. **检查响应 token 字段**：`result.token` 还是 `result.TOKEN__`？
3. **检查 token 注入路径**：`localStorage[<prefix>COMMON__LOCAL__KEY__].value.TOKEN__.value`（双层包装）
4. **检查路由守卫读取**：`getLocal` 读 `.value`，不是直接读
5. **检查 token 过期时间**：`expire` 字段 < 当前时间 → 重新登录

**反模式**：直接报"后端问题"或"前端问题"——跳过了真正的根因（中间层 wrapper 错误）。

详见 `learnings/2026-07-06-login-timeout-diagnosis.md`。

## /evolve 增量规则（2026-08-04 regression runner）

### 回归测试必须脱离 AI 终端进程树（regression-runner-detached）

**铁律**：任何 E2E / 链路 / 80+ 用例大套件，不在 AI 终端前台串行跑，统一由 `harness/scripts/resilient_regression.py` 在后台执行。

**强制流程**：
1. **入口**：`/test-environment --check` → `/test-regression --scope full|--scope change --base <commit>` → 自动启动 `resilient_regression.py` + dashboard。
2. **AI 不可假设 runner 存活**：当前 Orca/AI 主进程被关闭或崩溃，必须能 `resume` 续跑，状态从 `harness/.regression-runs/<run-id>/state.json` 读。
3. **状态写必须原子**：Windows 上 `os.replace` 会被 ESET / OneDrive 短期占用，必须有三级降级：`.tmp` 临时文件 → `os.replace` → 失败后写 `state.json.fallback`。`atomic_write_json` 已有。
4. **状态启动恢复**：`recover_interrupted_state` 把上次 `status=running` 的切片统一改为 `interrupted`，写入 `last_attempt_at` 后再走正常 resume 流程。**禁止**把上次被中断的切片当 fresh start。
5. **业务服务端口被占用**：`mvn clean` 失败要先 taskkill 占 8080 端口的旧后端 PID（`netstat -ano | grep :8080`）再 resume；不会自动杀非 runner 创建的进程。
6. **报告投递允许失败**：`hermes/eagle-eye/reports/.../issues/` 或 `summary.md` 写失败时**不能终止** runner，只记录 `report_delivery_error`，原始状态文件必须已落盘。

详见 `learnings/2026-08-04-regression-runner-detached-from-ai.md`。

### 测试失败两层分类（regression-failure-two-layer）

**铁律**：runner 退出码非零 ≠ 产品 Bug。测试失败必须经过两层判定。

**第一层：runner 状态（机器判定）**：

```text
passed / failed / timeout / blocked_environment / interrupted
```

**第二层：复核分类（需报告 + 人工）**：

| 复核分类 | 触发 | 是否记为产品问题 |
|---|---|---|
| `pending_review` | 第 1 次失败 | 否（先 clean re-run） |
| `suspected_bug` | 第 2 次相同失败 | 否（待人工确认） |
| `false_positive` | 重试通过 | 否（环境/数据偶发） |
| `confirmed_bug` | 人工确认 | **是** |
| `test_defect` | 选择器/data-prep 失败 | 否（改测试） |
| `data_precondition` | 测试数据缺失 | 否（补数据） |
| `environment_issue` | 8080/3100 不可达 | 否（修环境） |
| `test_design_issue` | 大套件超时 | 否（拆切片） |

**强制流程**：
1. 每个 E2E 失败必须在 `hermes/eagle-eye/reports/YYYY-MM-DD/issues/<hash>-<测试名>.md` 生成路径化报告。
2. 报告必须包含：测试文件、页面路径、复现步骤、预期结果、实际错误、截图、视频、runtime-diagnostics（当前 URL / console error / pageerror / 失败请求）。
3. **禁止**把 `runner exit_code=1` 直接写进产品问题；只有 `confirmed_bug` 才进入产品列表。
4. 大套件（≥60 用例）必须按页面切片：8.2 → 8.2-manufacturing / 8.2-finance / 8.2-stocktake，单页面卡住不能拖死整套。

详见 `learnings/2026-08-04-regression-failure-two-layer-classification.md`。

### 测试地址禁止硬编码（regression-test-env-only）

**铁律**：测试代码 / .claude/commands / .claude/rules 中禁止出现：

```text
http://100.122.125.106
http://localhost:8080
http://localhost:3100
C:\apache-maven\bin\mvn.cmd
nohup
taskkill
netstat
```

**强制**：
1. **API / E2E 测试统一使用环境变量**：`HARNESS_BASE`（API）、`E2E_API_BASE` / `E2E_UI_BASE`（E2E）、`PLAYWRIGHT_BASE_URL`（Playwright）。
2. spec 内部只引用从 `helpers/auth.ts` 导出的 `BASE` / `API_BASE`，不再写自定义常量。
3. **命令文件**只能描述流程，不能拼接 `mvn.cmd` / `nohup` / `taskkill`；统一用 `python harness/scripts/resilient_regression.py` 处理进程管理。
4. **跨平台**：`python` 或 `python3` 自动探测，不假定 `python.exe` 或 `/usr/bin/python3`；不写 Windows 专属路径。

详见 `learnings/2026-08-04-harness-commands-must-be-claude-cmd-not-shell.md`。

### 链路切片由 business-chains.json 自动展开（regression-plan-from-chains）

**铁律**：`harness/regression/recovery-plan.json` 不再硬编码 `1.1 / 1.2 / 1.3` 链路切片，必须由 `harness/scripts/regression_plan.py` 从 `hermes/business-chains.json` 的 `chains.<name>.chainTests.segments[].file` 自动展开。

**强制**：
1. `regression_plan.py expand_chain_slices(chains_doc)` 把 `chainTests.enabled` 的 segment 转成 `chain.<chain_id>.<index>` 切片，保留 `source = {chain, segment, file}`。
2. `recovery-plan.merged.json` 由 `python harness/scripts/resilient_regression.py plan` 生成，**列入 .gitignore**。
3. **新增 runner 子命令 `plan` + `report`**：`plan` 输出合并 manifest；`report` 输出 R009 测试质量扫描结果（按 `harness/tests/modules/**/*.test.js`）。
4. **变更感知**：`--scope change --base <commit>` 时 `git_diff_names` 算出 `manifest.diff_files`；`chain_ids_for_diff` 命中链路；`filter_slices_by_scope` 只保留 build/frontend-static/test-quality/smoke-api/smoke-e2e + 命中链路的 segment。
5. **失败时回退**：`regression_plan.py` import 失败时 runner 不退出，只保留全量切片。

详见 `learnings/2026-08-04-recovery-plan-linked-to-business-chains.md`。

### runner 启动前端口探测，不自动 kill（runner-port-probe-no-autokill）

**铁律**：runner start 子命令必须探测 8080/3100 端口占用，**只 warn + 给排查命令，不自动 kill 进程**。

**强制流程**：
1. **探测**：`_check_port_held(port)` 用 `socket.connect(('127.0.0.1', port))`（跨平台，不依赖 netstat/lsof/ss）
2. **warn stderr**：占用时打印 stderr（不阻塞），含 `netstat -ano | findstr :PORT` / `lsof -i :PORT` 命令
3. **不自动 kill**：避免误杀同一用户的开发用进程（用户可能同时跑开发 + 回归）

**反模式**：
- ❌ `taskkill //F //PID <PID>` 自动杀 — 误杀开发后端 / 测试服务
- ❌ `if (检测到占用) sys.exit(1)` 阻断 — 让用户决策，不要越权

**实证**：2026-08-05 run 20260805-040648 撞 PID 27076 后端 jar lock，warn → 用户 kill → 重启 OK。

详见 `learnings/2026-08-05-runner-port-probe-no-autokill.md`。

### CI 跨平台差异首选 env-var 配置层隔离（ci-skip-via-env-not-code）

**铁律**：CI 与本地的环境差异（mysql client / GPU / 网络）通过**环境变量**在配置层隔离，**不改业务逻辑代码**。

**强制流程**：
1. **识别差异**：CI 容器无 host 工具（如 mysql client），本地有 → execSync 必失败
2. **加 env-guard**：fixtures 入口加 `if (process.env.SKIP_DB_CLEANUP === 'true') return true;`
3. **CI workflow env 设值**：`SKIP_DB_CLEANUP: 'true'`
4. **本地不设 env var** 仍走原路径

**反模式**：
- ❌ `if (process.platform === 'linux') return true;` — 平台分支膨胀
- ❌ CI 装 mysql client — 启动慢 ~30s，不解决根因（数据本就不需要清理）
- ❌ `try { ... } catch { /* ignore */ }` — 静默吞错比失败还糟

**前提条件**：(1) CI 幂等（CREATE DATABASE IF NOT EXISTS）；(2) fixture 用时间戳后缀；(3) runner 不持久化 CI 数据。

**实证**：2026-08-05 commit 55ef7bd，CI schema init 跑通（之前必 ENOENT）。

详见 `learnings/2026-08-05-ci-skip-via-env-not-code.md`。

---

## L5：回归测试误判复盘（2026-08-07 retro 固化）

> 来源：2026-08-07 回归测试 33+ 处误判复盘。**下次回归前必看**。

### 5 大误判模式 + 必走处理

| 类别 | 触发场景 | 必走处理 |
|---|---|---|
| **A. 报告生成器误归类** | `regression-report.js` 从 `hermes/eagle-eye/reports/<date>/issues/*.md` 抽取失败测试时，**所有 traceabilityBatch / inventoryAlert 条目都被打上 Connection Refused 标签** | 修 `harness/scripts/regression-report.js`：issue 归类前先核对 Playwright 日志的 `✓` / `✘` 标志，**仅当 spec 实际失败才列入「失败的测试」** |
| **B. spec URL/文件名错位** | 测试用 `/project/mes/purchase/ledger`，但业务上叫"**库存台账**"，URL 是 `/project/mes/warehouse/ledger`；component 路径在 `purchase/ledger/` 但路由 path 在 `warehouse/ledger/`（历史遗留错位）| 测试 spec 文件名 + `PAGE_PATH` **必须与 `router/routes/modules/mes.ts` + `MesMenuRegistry` 对齐**。命名错误（如 `purchase-ledger.spec.ts`）→ 重命名为 `inventory-ledger.spec.ts` |
| **C. 业务页面废弃未清理** | V8.0.0 注册的 `mes_batch_ledger` 菜单 + `batch/ledger/index.vue` + `batch-ledger.spec.ts`，在 V10.0.3 schema 重构后被「批次追溯」页面替代 | 业务页面废弃必走三删：**删 spec + 删前端 + 移菜单**（保留后端被依赖的端点，如 `listByBatchId`）|
| **D. 测试用例与业务设计不符** | 业务上某页面**没有某功能**（如 basic-codeRule 无导出、batch-inventory 无新增、sales-outbound 审核/取消是工具栏而非行内），但测试加了对应断言 | 测试断言前必查前端 `*.data.ts` 工具栏配置 + `index.vue` 是否有对应按钮/抽屉/工具栏。**业务无此功能 → 删断言** |
| **E. dev DB 残留 / 测试 setup 时序** | 测试期望 X（来自 setupFixture 创建的物料），实际 dev DB 已有 Y 数据（如 stocktake 期望 20/8 实际 LOCAL-M 15/18.6765）；或 `materialBatch.spec.ts:23-33` 用 `switches.first()` 改总开关 + `page.goto` 跳页 → store 重新 load 失败 | ① setupFixture **创建独立仓库**避免与 dev DB 资源共用 ② 改测试期望为动态值 `expect(item.bookQty).toBeGreaterThanOrEqual(1)` 容忍残留 ③ 改 setupFixture 用 `store.set` 或 API 注入状态 ④ `waitForTableReady` 等待逻辑优化 + 拆条 timeout |

### 新建 spec 时的硬性 checklist（避免 D 类误判）

写新测试 spec 前必查：

```bash
# 1. 业务 URL 是否与路由表对齐？
grep "component:" router/routes/modules/mes.ts | grep -B 1 "<page-keyword>"

# 2. 业务菜单名是否对齐？
grep "<page-keyword>" MesMenuRegistry.java

# 3. 前端 data.ts 是否有工具栏 / 导出 / 抽屉 / formSchema？
ls src/views/project/mes/<page>/<page>.data.ts && \
  grep -E "formSchema|exportXls|tableTitle" src/views/project/mes/<page>/<page>.data.ts
```

### 修改 spec 的硬性 checklist（避免 B/C/D 类误判）

```bash
# 1. spec 文件名是否与 menu key 对齐？
# 错例：purchase-ledger.spec.ts（业务叫库存台账）
# 正例：inventory-ledger.spec.ts

# 2. PAGE_PATH 是否与路由 path 对齐？
# 错例：'/project/mes/purchase/ledger'
# 正例：'/project/mes/warehouse/ledger'

# 3. 业务页面是否已废弃？
# 查 git log + 与业务人员确认
```

### 必走命令

- 跑回归后必走 `/regression-review`（双源复核，避免单源 AI 误判）
- 复核后必走 `/regression-retro`（误判复盘，本章节就是 retro 产物）
- 真实 BUG 必走 `/regression-decompose`（切片处理）

### 参考

- 详细误判清单：`harness/.regression-runs/20260807-032053/regression-report.md` 第四节
- 复盘报告：`/regression-retro` 20260807-032053
- learning 记录：`.claude/memory/learnings/2026-08-07-regression-double-review.md`

---

## L6：复核结果就地标注原则（2026-08-07 evolve 固化）

> 来源：`memory/learnings/2026-08-07-regression-review-workflow.md`
> 业务人员原话："复核结果在具体问题点也标注下 ... 方便我一个个核实问题点"

### 核心原则

**复核标注必须就地逐条显示** — 业务人员能"逐条核实"，不用跳来跳去。

❌ **错误做法**：只把复核结果放在 4.X 顶部的「复核结果」section（汇总里）
✅ **正确做法**：在每个具体「测试位置：`X:Y`」行旁加复核标注（就地）

### 标注格式

```markdown
- 测试位置：`171:7` 标题：› ... › 5. 导出按钮可见 + 点击触发下载
  操作步骤：
    ...
  预期结果（业务描述）：...
  实际结果：...
  > 📋 **复核结果**：✅ **误判**（报告生成器归类错误） | 严重度 P3 | 业务人员实测... | 跟进：regression-report.js 修复 issue 归类逻辑 | 复核人 业务人员 / 2026-08-07
```

### 4 元素（结构化）

每条复核标注必须含：

| 元素 | 说明 | 示例 |
|---|---|---|
| **判定** | ✅ 误判 / 🔴 真 bug / 🟡 要优化 / ⏳ 待复核 | ✅ 误判 |
| **严重度** | P0 (24h) / P1 (1 周) / P2 (2 周) / P3 (无需跟进) | P1 |
| **业务侧原因** | 业务人员原话（不是技术）| "账面 15 是对的" |
| **跟进负责人** | 前端工程师 XXX / 后端工程师 XXX / 待 cleanup | 后端工程师小王 |
| **复核人 / 时间** | 业务人员 / AI 名字 + YYYY-MM-DD | 业务人员 / 2026-08-07 |

### 自动化要求

报告生成器（`harness/scripts/regression-report.js` v3.0+）必须：

1. 解析每条 failed 切片的「测试位置」行
2. 在「实际结果」行后插入「复核结果」section（用 `> 📋 **复核结果**：...` 格式）
3. 同时保留 4.X 顶部的「复核结果」section（汇总）
4. 业务人员/AI 用 edit 工具逐条覆盖（不是一次性自动填）

### 为什么不能用 AI 一次性自动填

- AI 一次填所有 → 容易误判（30%+ 误判率，2026-08-07 实证）
- 业务人员逐条反馈 + AI 逐条填 → 准确率 95%+

### 业务人员工作流（"复核记录员"模式）

```
1. AI 拿报告给业务人员（列出失败测试 + 解释 + 验证步骤）
   ↓
2. 业务人员亲自到系统里走一遍（不依赖 AI 判定）
   ↓
3. 业务人员用自然语言告诉 AI：
   "4.X 是误判 / 真 bug / 要优化 / 拿不准，因为 XXX"
   ↓
4. AI 用 edit 工具在对应「测试位置」行旁填入复核标注
   ↓
5. 报告交付给 PM/leader 跟进
```

### 配套：edit 工具"oldText 唯一性"陷阱

跨 4.X 段同时编辑时（如 4.2 + 4.8 traceabilityBatch），同 spec 文件内容完全相同，edit 工具会报错"Found N occurrences"。

**应对 3 招**：
1. **上下文 anchor**：在 oldText 加前置/后置不同行做唯一
2. **python replace 兜底**：`content.replace(old, new)` 一次完成
3. **分多次 edit**：用更大的 oldText 上下文做唯一

详见 `memory/learnings/2026-08-07-regression-review-workflow.md` + `2026-08-07-coordinator-git-status-fallback.md`（edit 工具陷阱）。
//update-end---author:evolve---date:2026-08-07---for:【/evolve】复核结果就地标注原则---
