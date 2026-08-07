# [2026-08-07] [regression] 回归测试双源复核 + 误判复盘 + BUG 切片三步流程

**触发条件**：跑完 `/test-regression` 后，复核 failed 切片时（避免单源 AI 误判，避免下次回归继续踩同样的坑，避免真实 BUG 责任不清）。

**处理方式**：

## 0. run-dir 自动记忆（v2 优化 2026-08-07）

> **业务人员要求**：不要每次都让用户输入 run-dir，AI 自己记忆最近一次。

**状态文件**：`.claude/.regression-state.json`

**4 级 fallback**：
1. 命令行参数 `--run-dir`（最高优先级）
2. 状态文件 `last_run_dir`（次高）
3. 目录最新 mtime（兜底）
4. 报错（都找不到时提示用户）

**更新时机**：
- `/test-regression` 跑完 → 写 `last_run_dir` + `next_step = regression-review`
- `/regression-review` 完成 → `next_step = regression-retro`
- `/regression-retro` 完成 → `next_step = regression-decompose`
- `/regression-decompose` 完成 → `next_step = completed` 或下一个 run-dir

**当前最新状态**（2026-08-07）：
- `last_run_dir: 20260807-032053`
- `failed_count: 8`
- `next_step: completed`

## 1. 双源独立复核（强制）

**不要用单源 AI 复核**。2026-08-07 复盘发现单源 AI 复核有 30%+ 误判率（30+ 处误判）。

**必走双源**：
- **业务人员口头复核**（不懂技术细节）— 给出"这条是真实 BUG / 误判，因为 <业务原因>"
- **独立 AI 复核**（codex 或 Claude，**干净上下文**）— 用 `/delegate` 委派，不要当前会话

**冲突处理**：
- 业务人员 + 独立 AI 一致 → 直接采用
- 业务人员 + 独立 AI 不一致 → 走 `/orca-review` 二次评审
- AI 初判与独立 AI 不一致 → 取独立 AI（独立 AI 上文更干净）

## 2. 误判复盘（5 大类，2026-08-07 复盘归纳）

| 类别 | 特征 | 案例 | 处理 |
|---|---|---|---|
| **A. 报告生成器误归类** | issue 目录匹配错 | traceabilityBatch × 7 全标 Connection Refused | 修 `harness/scripts/regression-report.js` issue 归类逻辑（仅当 spec 实际失败才列入「失败的测试」） |
| **B. spec URL/文件名错位** | 测试用旧 URL / 旧名字 | purchase-ledger × 7（业务叫库存台账，URL `/project/mes/warehouse/ledger`）| 重命名 spec + 改 PAGE_PATH（必须与 `router/routes/modules/mes.ts` 对齐） |
| **C. 业务页面废弃未清理** | spec/前端/菜单还在但业务已下线 | batch-ledger × 5（V10.0.3 已被 traceability 替代）| 删 spec + 前端 + 移菜单（保留后端被依赖的端点）|
| **D. 测试用例与业务设计不符** | 业务上没这功能 / 业务用工具栏，测试期望行内 | codeRule 导出 + batch-inventory 新增 × 2 + sales-outbound 行内按钮 | 删断言 |
| **E. dev DB 残留干扰** | 测试期望 X，实际 dev DB 已有 Y | stocktake 期望 20 实际 15 | 改 setupFixture / 加清理 / 改测试期望为动态值 |

## 3. 真实 BUG 切片（按 P0/P1/P2/P3 分级）

每个真实 BUG 切成 1 个 cleanup 任务（6 要素）：

```markdown
# Cleanup Task: <bug-name-kebab>

## 业务名（要复盘 BUG 标题）
## 用户路径（复现路径 + 操作步骤 + 预期 + 实际）
## 验收标准（[ ] 列出可验证点）
## 依赖（涉及服务/组件/表）
## 风险（low/medium/high）
## 工作量（small/medium/large）
## Rollback（如何回滚）
## Owner（前端/后端/cleanup 脚本）
## 关联（报告路径 + 原始日志 + issue 复核）
```

**5 大真实 BUG 模式**：
- 后端精度丢失（P1，setScale 调整）
- 前端抽屉渲染失败（P1，v-if/mounted/data 时序）
- 后端权限码缺失（P0，注册权限码）
- 前端功能单调（P2，优化排期）
- 算法 / 业务逻辑正确（不需修复）

## 关联命令

- `/test-regression` — 跑回归测试（已更新，必走 3 步流程）
- `/regression-review` — 双源独立复核
- `/regression-retro` — 误判复盘
- `/regression-decompose` — 真实 BUG 切片处理
- `/delegate` — 委派任务给独立 AI
- `/orca-review` — 冲突时二次评审
- `/decompose` — 大任务切片（cleanup 任务模板复用）

## 参考

- 起源：2026-08-07 回归复盘
- 详细误判 + 真实 BUG 清单：`harness/.regression-runs/20260807-032053/regression-report.md` 第四节
- 模板演进文档：`hermes/plan/regression-report-template-evolution.md` 第 12 章
