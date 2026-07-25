# Harness 工程完整性审计报告

**审计时间：** 2026-07-22
**审计范围：** `.claude/` 全部目录（commands、skills、rules、hooks）+ `~/.claude/agents/`
**审计方式：** 只读代码检查，不修改任何文件

---

## 一、防失忆规则完整性 ✅

### 1.1 workflow.md 防失忆触发条件

| # | 失忆点 | 状态 | 行号 |
|:--:|------|:--:|:--:|
| 1 | 写完代码跳过了 /verify | ✅ | 第 36 行（最常见失忆点注释） |
| 2 | /verify 通过但没 commit+push | ✅ | 第 38 行（第二失忆点注释） |
| 3 | 多轮改动每轮都部署 | ✅ | 第 40 行（第四失忆点注释） |
| 4 | mvn compile 就认为验证通过 | ✅ | 第 42 行（第六失忆点注释） |
| 5 | 写完代码自动进 /verify | ✅ | 第 26 行（触发规则） |
| 6 | /verify 通过 → 自动 commit+push+部署 | ✅ | 第 27 行（触发规则） |

**新增链路检查：** `/verify → /quality-gate → 部署 → 差集回归` 链路：

| 节点 | 状态 | 位置 |
|------|:--:|------|
| /verify 通过 → 提示 /quality-gate | ✅ | workflow.md 第 28 行（new 07-22②） |
| /quality-gate BLOCKED → 阻断提交 | ✅ | criteria.md + pre-commit hook |
| 部署完成 → 差集回归 | ✅ | workflow.md 第 30 行 |
| 差集回归 → 分级测试 | ✅ | workflow.md 第 31-33 行 |

**判定：完整。** 6 条失忆点 + quality-gate 触发链路均在 workflow.md 中有明确条目。

### 1.2 步骤清单完整性

workflow.md 的步骤清单（第 81-93 行）覆盖了 /brainstorm 到 /done 的全流程。

**缺失：** 步骤清单中没有 `/quality-gate`、`/deep-inspect`、`/quality-dashboard` 三个新命令。虽然防失忆表已有 quality-gate 触发（第 28 行），但步骤清单未同步更新。

---

## 二、命令-技能-规则对应关系

### 2.1 命令 → 技能引用 ✅

| 命令 | 引用的技能 | 状态 |
|------|------|:--:|
| `commands/quality/gate.md` | `quality-gate` | ✅ 正确 |
| `commands/quality/deep-inspect.md` | `deep-inspect` | ✅ 正确 |
| `commands/quality/dashboard.md` | `quality-dashboard` | ✅ 正确 |

### 2.2 技能 → 规则引用 ❌

| 技能 | 应引用的规则 | 状态 |
|------|------|:--:|
| `skills/quality-gate/SKILL.md` | `security-gate-checklist.md` | ❌ 未引用 |
| `skills/deep-inspect/SKILL.md` | `deep-inspect-schedule.md` | ❌ 未引用 |
| `skills/quality-dashboard/SKILL.md` | `quality-escalation.md` | ❌ 未引用 |

技能文件只在末尾"相关技能"节列出了其他技能，但没有列出它依赖的规则文件。这会导致 AI 在加载技能时不会自动加载关联规则，可能遗漏检查项。

**对比：** `quality-gate-criteria.md` 正确引用了 `security-gate-checklist.md` 和 `workflow.md`。规则的交叉引用是好的，但技能的交叉引用有缺口。

### 2.3 规则 → 技能引用 ✅

| 规则 | 引用的技能/规则 | 状态 |
|------|------|:--:|
| `quality-gate-criteria.md` | `security-gate-checklist.md` + `workflow.md` | ✅ |
| `security-gate-checklist.md` | `pre-commit-check.sh` + `quality-gate/SKILL.md` | ✅ |
| `deep-inspect-schedule.md` | 无外部引用 | ✅（自包含） |
| `quality-escalation.md` | `workflow.md` + `quality-gate-criteria.md` + `security-gate-checklist.md` | ✅ |

---

## 三、verify / quality-gate 证据要求拆分 ⚠️

### 3.1 拆分状态（三分之二完成）

| 文件 | 拆分状态 | 说明 |
|------|:--:|------|
| `rules/quality-gate-criteria.md` | ✅ 已拆分 | 第 20 行声明"不重复收集证据"，将证据收集委托给 /verify |
| `skills/quality-gate/SKILL.md` | ❌ 未拆分 | 第 23-31 行仍有独立的证据要求矩阵（Controller→curl 等），与 verify/SKILL.md 重复 |
| `commands/quality/gate.md` | ❌ 未拆分 | Step 1 仍说"分析 git diff 确定变更类型"，未改为"检查 /verify 结果" |
| `skills/verify/SKILL.md` | ✅ 保持原样 | 证据收集的权威来源 |

**问题影响：** criteria.md 说"不重复"，但 gate.md 和 skill.md 仍保留了完整的证据收集指令。AI 运行 /quality-gate 时会同时看到 criteria.md 的"不要重复"和 skill.md 的"逐项收集"两套矛盾指令。

### 3.2 具体修复点

**quality-gate command (gate.md) Step 1 应改为：**
```
**Step 1 — 现实核查：**
- 检查 /verify 是否已运行（verify 结果是否存在）
- 如果 /verify 未运行 → 强制要求先跑 /verify
- 如果 /verify 已运行 → 逐项检查 verify 证据是否充分
- 检测自动失败触发器（零发现、模糊措辞、证据不足）
- 输出当前评级（基于 /verify 结果，不重新收集证据）
```

**quality-gate skill (SKILL.md) 应删除/替换第 23-42 行的证据要求矩阵，改为引用 verify 结果。**

---

## 四、pre-commit-check.sh 审计 ✅

### 4.1 @RequiresPermissions 移除

**之前（评审发现）：** P0 规则但 hook 只 WARN（不 exit）\
**现在：** ✅ 已修复。第 46-48 行升级为 `QUALITY_GATE_BLOCK=1`，配合后续 exit 1 逻辑阻断提交。

### 4.2 SQL 拼接正则

**之前：** 可能误判日志消息和注释中的 SELECT 字符串\
**现在：** ✅ 已修复。第 115 行正则增加了排除过滤：
```bash
grep -v -E '^\+\s*//|^\+\s*\*|log\.|logger\.'
```
排除以 `//` 开头的注释行、以 `*` 开头的块注释行、包含 `log.` 或 `logger.` 的日志行。

### 4.3 原有逻辑与质量门控重叠检查

| 原 hook（行号） | 质量门控（行号） | 关系 |
|------|------|:--:|
| SQL DROP/TRUNCATE (17-23) | 无 | ✅ 互补 |
| TS 语法 (26-37) | 无 | ✅ 互补 |
| @Transactional 移除 WARN (40-44) | P1 规则 | ✅ 一致 |
| @RequiresPermissions 移除 (46-48) | P0 阻断 (86-103 缺失检测) | ✅ 一致，都 BLOCK |
| 测试门控 (51-74) | 无 | ✅ 互补 |
| 受保护目录 (152-166) | 无 | ✅ 互补 |

**判定：无冗余、无冲突。** 原 hook 的检查项（DDL 危险操作、TS 语法、测试运行、目录保护）与质量门控的检查项（权限、密钥、SQL 参数化）覆盖不同维度，形成了完整的预提交防线。

---

## 五、settings.json Hook 配置 ✅

| Hook 事件 | 引用的脚本 | 存在？ |
|------|------|:--:|
| PreToolUse (Edit\|Write) | `pre-write-check.sh` | ✅ |
| PreToolUse (Bash) | `block-dangerous.sh` | ✅ |
| PreToolUse (Skill) | `pre-plan-check.sh` | ✅ |
| PreToolUse (Bash git commit) | `pre-commit-check.sh` | ✅ |
| PreToolUse (Bash docker compose) | `pre-deploy-check.sh` | ✅ |
| SessionStart | `session-start.sh` | ✅ |
| PostToolUseFailure | `post-tool-failure.sh` | ✅ |
| SessionEnd | `session-end.sh` | ✅ |

**判定：8/8 全部存在，无死链。**

额外发现：`settings.json` 中只有 8 个 hook 注册，但 `.claude/hooks/` 目录实际有 9 个脚本（含 `orca-setup.sh`）。`orca-setup.sh` 未在 settings.json 中注册——如果这是有意为之（Orca 专用、由 Orca 自身触发），则无问题。

---

## 六、新规则 Frontmatter 完整性 ✅

| 规则文件 | name | description | glob | version | 状态 |
|------|:--:|:--:|:--:|:--:|:--:|
| `quality-gate-criteria.md` | ✅ | ✅ | ✅ `**/*` | ✅ 1.0.0 | ✅ |
| `security-gate-checklist.md` | ✅ | ✅ | ✅ `**/*.java` | ✅ 1.0.0 | ✅ |
| `deep-inspect-schedule.md` | ✅ | ✅ | ✅ `**/*` | ✅ 1.0.0 | ✅ |
| `quality-escalation.md` | ✅ | ✅ | ✅ `**/*` | ✅ 1.0.0 | ✅ |

**判定：4/4 规则 frontmatter 字段完整。**

额外检查：`security-gate-checklist.md` 的 glob 为 `**/*.java`（仅 Java 文件触发），这是正确的——安全检查不需要在 .vue/.ts 文件变更时激活。其他三个规则 glob `**/*` 覆盖所有文件。

---

## 七、Agent 文件隔离 ❌

### 7.1 当前状态

69 个 agent 文件平铺在 `~/.claude/agents/` 目录，无子目录分类：

| 类别 | 文件数 | 与 JeecgBoot 相关？ |
|------|:--:|:--:|
| 工程 (engineering-*) | 11 | ✅ 相关 |
| 测试 (testing-*) | 8 | ✅ 相关 |
| 支持 (support-*) | 6 | ⚠️ 部分（legal/finance 不相关） |
| 项目管理 (project-manag*) | 5 | ✅ 相关 |
| 协调/策略/专项 | 4 | ✅ 相关 |
| **小计（相关）** | **34** | |
| 营销 (marketing-*) | 11 | ❌ 无关 |
| 设计 (design-*) | 8 | ❌ 无关 |
| 空间计算 (xr/visionos/macos/terminal) | 6 | ❌ 无关 |
| 产品/销售/数据 (product/data/report/sales) | 10 | ❌ 无关 |
| **小计（无关）** | **35** | |

### 7.2 风险

当 Claude Code 用户输入 "activate Frontend Developer" 或 "use API Tester" 时：
- Claude Code 扫描 `~/.claude/agents/` 中的所有文件
- 69 个平铺文件全部参与匹配
- 可能存在命名冲突（如 marketing 和 engineering 下都有类似的 agent 名称）

### 7.3 建议

将无关 agent 移入子目录隔离：
```bash
mkdir -p ~/.claude/agents/_unused/{marketing,design,spatial,other}
mv ~/.claude/agents/marketing-*.md ~/.claude/agents/_unused/marketing/
mv ~/.claude/agents/design-*.md ~/.claude/agents/_unused/design/
mv ~/.claude/agents/xr-*.md ~/.claude/agents/visionos-*.md ~/.claude/agents/macos-*.md ~/.claude/agents/terminal-*.md ~/.claude/agents/_unused/spatial/
mv ~/.claude/agents/product-*.md ~/.claude/agents/specialized-*.md ~/.claude/agents/data-*.md ~/.claude/agents/report-*.md ~/.claude/agents/sales-*.md ~/.claude/agents/_unused/other/
```

或者更轻量：创建 `~/.claude/agents/.inactive/` 目录，把无关 agent 移入（`_` 前缀目录通常被 Claude Code 跳过）。

---

## 八、汇总

### 通过项

| # | 检查项 | 结果 |
|:--:|------|:--:|
| 1 | 防失忆规则 6 条完整性 | ✅ 全部在 workflow.md |
| 2 | verify→gate→deploy→回归 链路 | ✅ 链路完整 |
| 3 | 命令→技能引用 | ✅ 3/3 正确 |
| 4 | @RequiresPermissions 移除已升级为 BLOCK | ✅ 已修复 |
| 5 | SQL 拼接正则排除注释/log | ✅ 已修复 |
| 6 | settings.json hook 脚本存在性 | ✅ 8/8 |
| 7 | 新规则 frontmatter | ✅ 4/4 完整 |
| 8 | pre-commit 原有逻辑与质量门控无冗余 | ✅ |

### 待修复

| # | 问题 | 严重度 | 修复文件 |
|:--:|------|:--:|------|
| 1 | quality-gate skill 证据矩阵未拆分 | P1 | `skills/quality-gate/SKILL.md` 第 23-42 行 |
| 2 | quality-gate command Step 1 仍引用 git diff | P1 | `commands/quality/gate.md` 第 27-31 行 |
| 3 | 技能→规则交叉引用缺失（3 处） | P1 | `skills/quality-gate/SKILL.md`、`skills/deep-inspect/SKILL.md`、`skills/quality-dashboard/SKILL.md` |
| 4 | 35 个无关 agent 未隔离 | P2 | `~/.claude/agents/` 目录 |
| 5 | workflow.md 步骤清单未含新命令 | P2 | `rules/workflow.md` 第 81-93 行 |

### 结论

**Harness 工程基础工作流可执行。** 上次评审（orca-review）发现的 3 个 P0 问题（verify/gate 重复、防失忆表缺失、@RequiresPermissions 移除不阻断）中，2 个已完全修复，1 个（verify/gate 拆分）在 criteria.md 中修复但在 skill 和 command 文件中遗留了重复内容。新发现的 5 个问题均为 P1/P2 级别，不影响基础工作流的可执行性。
