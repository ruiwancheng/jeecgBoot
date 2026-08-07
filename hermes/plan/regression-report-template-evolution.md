# 回归测试报告模板演进历史（Regression Report Template Evolution）

**作者**：pi
**日期**：2026-08-07
**目的**：固化今天（2026-08-07）对回归报告的 6 次优化，避免后续回归走回头路
**状态**：✅ 已合入 main，所有后续 `node harness/scripts/regression-report.js --run-dir <run-id>` 自动应用

---

## 1. 演进时间线（6 commits）

| # | Commit | 标题 | 解决了什么 |
|---|---|---|---|
| 1 | `74cdc2b` | **Slice K** 第四节新增「复现步骤」+「复核结果」固定字段 | 业务人员无法核实（缺路径/操作步骤/问题点） |
| 2 | `3106829` | extractSection 正则吞换行导致复现步骤只剩第 1 条 | bug：只显示 "1. 登录系统"，丢失后续步骤 |
| 3 | `33e11f6` | 复现步骤字段补全「问题点」段（actual_error） | 用户追问"问题点呢？" |
| 4 | `d672b76` | 新增「预期结果/实际结果」业务语言描述 | 用户要求"用业务语言" |
| 5 | `581eac5` | 实际结果字段定位断言字段名（业务语义映射） | 用户："著名具体是哪个字段 期望值 20，实际值 15" |
| 6 | `a0ffb6a` | 复核结果字段改由 AI 填充（非业务人员手填） | 用户澄清：业务人员不直接编辑 |

---

## 2. 当前报告模板结构（v3.0）

### 第四节 · 失败切片逐条分析（每条 failed 切片固定 7 段）

```
### 4.X `<slice_id>` — <slice_name>

**状态**：failed
**症状**：<message>
**关键错误**：<first error from log>

**失败的测试**：
  - <spec-name>:<line> — <title> (duration)

**复现步骤**：页面路径: `<page_path>`        ← 路径（来自 issue.page_path）

**spec**: `<spec-name>`                       ← 来源 spec 文件
- 测试位置：`<line:col>` 标题：<test title>   ← 真实测试位置
  操作步骤：                                   ← 来自 scenario-metadata.steps
    1. <step 1>
    2. <step 2>
    3. <step 3>
  预期结果（业务描述）：<expected>             ← 来自 scenario-metadata.expected
  实际结果：<business language>                 ← 来自 actual_error → 业务语言转换
    含字段名 + 业务语义（如 `盘点账面数量(bookQty)`）
    含 Expected/Received 数值

> ⏳ **AI 待记录**：业务人员复核后通知 AI 「4.X ...」

**复核结果**：
⏳ 待 AI 填充（业务人员复核后由 AI 记录）
  记录格式：
  - 判定 / 严重度 / 业务侧原因 / 跟进负责人 / 复核人+时间

**原始日志**：`<log_path>`
**修复建议**：1.读日志 2.查 issue 3.resume 重跑
```

### 第七节 · 用户待办（工作流说明）

```
工作流：业务人员口头复核 → 通知 AI → AI 用 edit 工具填入对应小节

反馈模板：「4.X <切片id> 是真实 BUG / 误判，因为<原因>，严重度 P0/P1/P2，负责人 XXX」
```

---

## 3. 数据流（6 个数据源 → 6 个字段段）

```
┌─────────────────────────────────┐
│ harness/e2e/reporters/          │
│   evidence-reporter.ts          │  ← Playwright 跑测时自动生成
│                                 │
│   输出：hermes/eagle-eye/       │
│   reports/<date>/issues/        │
│   *.md (含 7 个 sections)        │
└─────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│ harness/scripts/                │
│   regression-report.js          │
│                                 │
│  parseIssueMd()                 │  ← 从 *.md 抽取：
│  ├─ title                       │     title, test_name, code_location,
│  ├─ test_name                   │     page_path, actual_error,
│  ├─ code_location              │     reproduction, expected,
│  ├─ page_path                  │     verdict, category
│  ├─ actual_error                │
│  ├─ reproduction               │
│  └─ expected                    │
│                                 │
│  indexIssuesBySpec()             │  ← 反向索引: spec → issues
│  extractRealLineFromErrorStack()│  ← 从 stack 提取真实 expect 行号
│  extractFieldFromSpecFile()     │  ← 读 spec.ts 提取 `item.bookQty`
│                                 │
│  FIELD_NAME_MAPPING (40+ 字段)  │  ← bookQty→盘点账面数量 等
│  toBusinessLanguage()           │  ← 技术错误 → 业务语言
│  NOISE 过滤 (result/data/code 等)│
│                                 │
│  renderFailureSections()        │  ← 6 段输出（操作步骤/预期/实际/复核）
└─────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│ harness/.regression-runs/      │
│   <run-id>/regression-report.md │
└─────────────────────────────────┘
                │
                ▼
        ⏳ AI 待记录 → AI 用 edit 填复核结果
                │
                ▼
┌─────────────────────────────────┐
│ hermes/eagle-eye/reports/      │
│   <date>/resilient-             │
│   regression-recovery.md        │  ← 双写归档 + 笔记空间镜像
└─────────────────────────────────┘
```

---

## 4. 关键修复点（避免回归）

### 4.1 evidence-reporter.ts 的 errorText() 修复（commit `581eac5`）

**修复**：从 `error.message` 扩展到 `error.stack || error.message`，让 issues/*.md 「实际错误」section 包含 `at .../spec.ts:75:34`，report 才能定位真实 expect 行号。

**禁止回退**：如果改回 `error.message` 单选，字段名定位失效，业务人员看不到"哪个字段失败"。

### 4.2 parseIssueMd() lineGet() 修复（commit `581eac5`）

**修复**：去掉 markdown 反引号，避免 `issue.test_name` 多出 backticks 导致 specFile 路径错位（之前是 `` `harness/e2e/mes/stocktake.spec.ts` `` 多了一对反引号，extractFieldFromSpecFile 找不到文件 → codeLine=0 → 字段名为空）。

**修复代码**：
```js
const value = after.replace(/^[：:\s*]+/, '').replace(/\*+$/, '')
  .replace(/^`/, '').replace(/`$/, '').trim();  // ← 去掉首尾反引号
```

### 4.3 extractSection() 从正则改 split（commit `3106829`）

**禁止回退**：如果改回 `## ${header}\\s*\\n([\\s\\S]*?)(?=\\n## |$)` 正则，`\\s*` 会贪婪吞所有换行，section 内容提取失败（只剩 1 行）。

**正确实现**：
```js
const sections = txt.split(/^## /m);  // 按 ## 切分最稳
for (const s of sections) {
  const firstLine = s.split('\n')[0];
  if (firstLine.trim() === header || firstLine.includes(header)) {
    return s.substring(firstLine.length)
      .replace(/```[a-z]*\n/g, '')
      .replace(/```\n?/g, '')
      .trim()
      .split('\n')
      .slice(0, 12)  // 容纳 stack + 重复 error
      .join('\n');
  }
}
```

### 4.4 NOISE 过滤表（commit `581eac5`）

**禁止回退**：`extractFieldFromSpecFile` 必须过滤 result/data/records/keys/code/id/name/type/value/date/time/costValue/expectedCost/accessToken/loginRes/apiRes 等通用字段，避免输出「断言失败【总金额(totalAmount)、code(code)】」噪音。

---

## 5. 字段语义映射表（FIELD_NAME_MAPPING）

可扩展，位置：`harness/scripts/regression-report.js` 中。

| 字段 | 业务语义 |
|---|---|
| `bookQty` | 盘点账面数量 |
| `actualQty` | 盘点实盘数量 |
| `diffQty` | 盘点差异数量 |
| `snapshotTime` | 快照时间 |
| `unitCost` | 批次单位成本 |
| `unitPrice` | 单价 |
| `price` | 价格 |
| `amount` | 金额 |
| `totalAmount` | 总金额 |
| `totalDebit` | 借方总额 |
| `totalCredit` | 贷方总额 |
| `taxRate` | 税率 |
| `taxAmount` | 税额 |
| `batchNo` | 批次号 |
| `batchId` | 批次ID |
| `qty` / `quantity` | 数量 |
| `remainQty` | 剩余数量 |
| `inQty` | 入库数量 |
| `outQty` | 出库数量 |
| `materialId` | 物料ID |
| `materialCode` | 物料编码 |
| `warehouseId` | 仓库ID |
| `orderCode` / `orderNo` | 订单编号 |
| `supplierId` | 供应商ID |
| `customerId` | 客户ID |
| `productionOrderId` | 生产订单ID |
| `salesOrderId` | 销售订单ID |
| `status` | 状态 |
| `remark` | 备注 |
| `deliveryDate` | 交货日期 |
| `orderDate` | 订单日期 |
| `productionDate` | 生产日期 |
| `expiryDate` | 有效期 |

**如何扩展**：新字段只需在 `FIELD_NAME_MAPPING` 加一行 `"<fieldName>": "<业务语义>"`，下次跑 report 自动应用。

---

## 6. toBusinessLanguage 转换规则（业务语言）

| 技术错误 | 业务描述 |
|---|---|
| `expect(received).toBe(expected) // Object.is equality\nExpected: 20\nReceived: 15` | **断言失败【字段名(英文名)】：期望值 `20`，实际值 `15`** |
| `locator('button:has-text("导出")') ... element(s) not found` | **页面元素未出现：XXX 导出按钮** |
| `Test timeout of 60000ms exceeded` | **测试超时（>60秒）** |
| `net::ERR_CONNECTION_REFUSED` | **前端页面无法访问（Connection Refused）** |
| `Subject does not have permission [mes:xxx:list]` | **权限不足：缺失权限码 `mes:xxx:list`** |
| `Unknown column 'remark' in 'field list'` | **数据库 schema 错误：字段 `remark` 缺失或约束错误** |
| fallback | 第一行 + 截前 200 字 |

---

## 7. 工作流（业务人员 + AI 协作）

```
┌────────────────────────────────────────────────────────────────┐
│ 1. 跑回归                                                       │
│    python harness/scripts/resilient_regression.py start ...     │
│    → 33 个 slice 跑完，产出 issues/*.md + regression-report.md  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ 2. 生成报告（v3 模板，6 commits 已固化）                          │
│    node harness/scripts/regression-report.js --run-dir <run-id>│
│    → 含 7 段结构 + ⏳ 待 AI 填充的复核结果占位符               │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ 3. 业务人员口头复核（不懂技术细节）                              │
│    形式：自然语言反馈给 AI                                       │
│    例：「4.1 8.2-stocktake 是误判，因为 dev DB 残留批次数据」  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ 4. AI 用 edit 工具填入「复核结果」                              │
│    填入：判定 / 严重度 / 业务侧原因 / 跟进负责人 / 复核人+时间 │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ 5. 报告最终交付给 PM/leader 跟进                                │
│    真实 BUG：进 issue tracker，按 P0/P1/P2 分级                  │
│    误判：归档，下次回归时跳过                                    │
└────────────────────────────────────────────────────────────────┘
```

---

## 8. AI 记录反馈模板（建议固化到 pi session）

**业务人员** → **AI**：
```
4.<X> <slice_id> 是真实 BUG / 误判，因为 <一句话原因>，
严重度 P0/P1/P2，负责人 <姓名>，复核人 <业务人员名>
```

**AI** → **报告**（结构化）：
```markdown
**复核结果**：
- 判定：真实 BUG / 误判
- 严重度：P0 (阻塞) / P1 (主流程) / P2 (次要) / P3 (无需跟进)
- 业务侧原因：<业务人员原话>
- 跟进负责人：<姓名>
- 复核人 / 时间：<业务人员名> / 2026-MM-DD
```

---

## 9. 验收（一次性回归）

跑 `node harness/scripts/regression-report.js --run-dir 20260807-032053`，检查 `harness/.regression-runs/20260807-032053/regression-report.md` 中：

| 验收项 | 预期 |
|---|---|
| 8 个 failed 切片都包含「复现步骤」 | ✅ |
| 每条复现步骤含 3 段：操作步骤 / 预期结果 / 实际结果 | ✅ |
| 8.2-stocktake 的实际结果含 `bookQty`、`unitCost` 业务语义 | ✅ |
| 8.2-stocktake 的实际结果：`断言失败【盘点账面数量(bookQty)、批次单位成本(unitCost)】：期望值 20，实际值 15` | ✅ |
| 每条都标注 ⏳ AI 待记录 + 占位符 | ✅ |
| 第七节说明工作流（业务人员 → AI → edit 工具） | ✅ |

---

## 10. 未来可优化（Out of Scope）

- 自动从 spec source 抽取 expected value（如 `toBe(20)` 中的 20）作为「业务可读预期」
- 当 evidence-reporter 记录的 actual_error 包含 stack 时，自动在 issues/*.md 显示"行 X 列 Y 的表达式"
- 严重度自动建议：连续 N 次 failed → 升级 P 等级
- 误判学习库：累积历史误判类型，下次回归自动跳过

---

## 11. 参考

- git log 范围：`74cdc2b..a0ffb6a`（6 commits）
- 模板：`harness/templates/regression-report.md`
- 生成器：`harness/scripts/regression-report.js`
- Reporter：`harness/e2e/reporters/evidence-reporter.ts`
- Issues 数据源：`hermes/eagle-eye/reports/<date>/issues/*.md`
- 用户原始反馈（hermes/eagle-eye 6 次迭代）：
  1. 「需注明操作步骤/路径/问题点」
  2. 「怎么复现，登陆系统 有问题？」（extractSection bug）
  3. 「问题点呢？」（actual_error 段）
  4. 「再增加 预期结果 和 实际结果，注意用业务语言」
  5. 「著名具体是哪个字段 期望值 20，实际值 15」
  6. 「复核结果 是 AI 根据业务人员口头反馈记录的」

---

## 12. 回归后必走 3 步流程（2026-08-07 复盘新增）

> **背景**：单源 AI 复核有 30%+ 误判率。2026-08-07 回归发现 30+ 处误判（traceabilityBatch 7 条 + purchase-ledger 7 条 + basic-codeRule 导出 + batch-ledger 5 条 + batch-inventory 2 条 + sales-outbound #8）。**强制双源独立复核 + 误判复盘 + 真实 BUG 切片** 才能保证质量。

### 完整工作流（7 步）

```
1. /test-regression                          跑回归测试
   ↓
2. 报告生成（v3 模板，6 commits 已固化）      node harness/scripts/regression-report.js --run-dir <id>
   ↓
3. /regression-review --run-dir <id>         ⭐ 双源独立复核（业务 + 独立 AI）
   ↓                                          - 业务人员口头复核（不懂技术）
   ↓                                          - 独立 AI 复核（codex 或 Claude，干净上下文）
   ↓                                          - 冲突切片走 /orca-review 二次评审
   ↓
4. /regression-retro --run-dir <id>          ⭐ 误判复盘（避免下次踩坑）
   ↓                                          - 抽取所有误判切片
   ↓                                          - 按 5 大类分类（报告生成器 / spec URL / 业务页面废弃 / 用例不符 / dev DB 残留）
   ↓                                          - 写规则到 .claude/rules/
   ↓                                          - 改测试用例（删错断言 / 改错 URL）
   ↓                                          - 累积到 .claude/memory/learnings/
   ↓
5. /regression-decompose --run-dir <id>      ⭐ 真实 BUG 切片处理
   ↓                                          - 按 P0/P1/P2/P3 分级
   ↓                                          - 每个 BUG 切成 1 个 cleanup 任务（6 要素）
   ↓                                          - 派发到对应 owner（前端/后端/cleanup 脚本）
   ↓
6. 跟踪 cleanup 任务                        .claude/cleanup-tasks/<date>-<bug>.md
   ↓                                          每个任务走 /delegate → worker_done → /verify → /done
7. 下次回归前确认                            所有 cleanup 任务已 close + retro 规则已生效
```

### 误判 5 大类（2026-08-07 复盘归纳）

| 类别 | 特征 | 案例 | 处理 |
|---|---|---|---|
| **A. 报告生成器误归类** | issue 目录匹配错（traceabilityBatch 全标 Connection Refused）| 4.2 traceabilityBatch × 7 | 修 `regression-report.js` issue 归类逻辑 |
| **B. spec URL/文件名错位** | 测试用旧 URL / 旧名字（purchase-ledger 业务上叫库存台账）| 4.8 purchase-ledger × 7 | 重命名 spec + 改 PAGE_PATH |
| **C. 业务页面废弃未清理** | spec/前端/菜单还在但业务已下线（batch-ledger 已被 traceability 替代）| 4.7 batch-ledger × 5 | 删 spec + 前端 + 移菜单 |
| **D. 测试用例与业务设计不符** | 业务上没这功能 / 业务用工具栏，测试期望行内 | 4.6 codeRule 导出 + 4.7 batch-inventory × 2 + 4.8 sales-outbound | 删断言 |
| **E. dev DB 残留干扰** | 测试期望 X，实际 dev DB 已有 Y | 4.1 stocktake（期望 20 实际 15）| 改 setupFixture / 加清理 |

### 真实 BUG 5 类（2026-08-07 复盘归纳）

| 类别 | 严重度 | 案例 | 跟进 |
|---|---|---|---|
| **后端精度丢失** | P1 | other-stock-in totalAmount 4 位小数被截断为 2 位 | 后端改 setScale(2→4) |
| **前端抽屉渲染失败** | P1 | traceabilityBatch #4 抽屉未显示"批次流水" | 前端排查 v-if/mounted/data |
| **后端权限码缺失（P0）** | P0 | purchase-mesCostLog 权限码 `mes:purchase:costLog:list` 未注册 | 后端注册权限码 |
| **前端功能单调（待优化）** | P2 | inventoryAlert 页面无搜索/查询/导出/新增/筛选 | 前端优化排期 |
| **算法 / 业务逻辑正确** | — | stocktake 移动平均加权法业务人员确认正确 | 不需修复 |

### 关联命令（已固化）

- `.claude/commands/test/regression-review.md` — 双源独立复核
- `.claude/commands/test/regression-retro.md` — 误判复盘
- `.claude/commands/test/regression-decompose.md` — 真实 BUG 切片处理
- `.claude/commands/test/test-regression.md` — 已加入"回归后必走 3 步流程"章节

### 验收（一次性回归 + 流程检查）

| 验收项 | 预期 |
|---|---|
| `/test-regression` 输出含"回归后必走 3 步流程" | ✅ |
| `.claude/commands/test/regression-review.md` 存在 | ✅ |
| `.claude/commands/test/regression-retro.md` 存在 | ✅ |
| `.claude/commands/test/regression-decompose.md` 存在 | ✅ |
| `hermes/plan/regression-report-template-evolution.md` 包含第 12 章"回归后必走 3 步流程" | ✅ |
| 下次回归必走 `/regression-review` 双源复核 | 强制 |
---

## 13. run-dir 自动记忆（v2 优化 2026-08-07）

> **业务人员要求**：不要每次都让用户输入 run-dir，AI 自己记忆最近一次。

### 状态文件

**路径**：`.claude/.regression-state.json`

**当前状态**（2026-08-07）：
```json
{
  "last_run_dir": "20260807-032053",
  "last_run_at": "2026-08-07T03:20:53+08:00",
  "scope": "full",
  "slice_count": 33,
  "failed_count": 8,
  "next_step": "completed"
}
```

### 4 级 fallback 自动检测

3 个新命令（`/regression-review` / `/regression-retro` / `/regression-decompose`）启动时**自动解析** run-dir：

```
优先级：
1. 命令行参数 --run-dir（显式指定，最高优先级）
2. 状态文件 .regression-state.json 的 last_run_dir（次高）
3. harness/.regression-runs/ 目录最新 mtime（兜底）
4. 报错退出（都找不到时提示用户）
```

### 状态文件更新时机

| 时机 | next_step | 谁触发 |
|---|---|---|
| `/test-regression` 跑完回归 | `regression-review` | test-regression.md 4.5 章节 |
| `/regression-review` 完成 | `regression-retro` | regression-review.md 第 5 步 |
| `/regression-retro` 完成 | `regression-decompose` | regression-retro.md 关联命令章节 |
| `/regression-decompose` 完成 | `completed` | regression-decompose.md 第 6 步 |

### 使用方式（v2 优化后）

```bash
# 不需要 --run-dir 参数（AI 自己记忆）
/regression-review
/regression-retro
/regression-decompose

# 显式指定（覆盖自动检测，例如下次回归用）
/regression-review --run-dir 20260808-123456
```

### 状态文件位置

- 状态文件：`.claude/.regression-state.json`
- 3 个命令脚本：`.claude/commands/test/regression-{review,retro,decompose}.md`
- test-regression 写入逻辑：`.claude/commands/test/test-regression.md` 第 4.5 章节
- learning 记录：`.claude/memory/learnings/2026-08-07-regression-double-review.md`
