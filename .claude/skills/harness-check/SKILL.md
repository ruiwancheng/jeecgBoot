---
name: harness-check
description: Harness 巡检 — 检查 CLAUDE.md、Commands、Rules、Hooks 完整性，七轴评分（含交叉验证）并输出改进建议。Audit harness integrity with seven-axis scoring (including cross-validation) and improvement suggestions.
version: 1.0.0
---

# harness-check — Harness 工程巡检

## 完整文件清单

### 根文件（2 个）
- `CLAUDE.md` — 项目指令主文件
- `.claude/settings.json` — 项目级设置
- `.claude/features.json` — 功能模块清单

### 命令 Commands（31 个）
`admin/admin`, `dev/brainstorm`, `dev/plan`, `dev/done`, `dev/debug`, `dev/verify`, `dev/finish`, `review/review`, `review/harness-check`, `review/architecture-report`, `review/dead-code-check`, `admin/new-project`, `learn/session-wrap`, `learn/learn`, `learn/auto-learn`, `generate/gen-tests`, `generate/new-module`, `admin/list-projects`, `admin/restart-backend`, `admin/setup`, `admin/switch-project`, `test/test-all`, `test/test-api`, `test/test-e2e`, `test/test-frontend`, `learn/evolve`, `git/commit`, `git/pr`, `util/cleanup-context`, `util/token-usage`, `util/anti-pattern`

### 规则 Rules（16 个）
`file-scope`, `backend-first`, `code-style`, `no-platform-modify`, `frontend`, `security`, `testing`, `workflow`, `debugging`, `skill-command-boundary`, `data-scope`, `override-mechanism`, `audit-classification`, `engineering-artifacts`, `tiequan-report-retention`, `tiequan-report-scope`

### 钩子 Hooks（9 个）
`pre-write-check`, `pre-commit-check`, `block-dangerous`, `session-start`, `post-tool-failure`, `session-end`, `pre-plan-check`, `orca-setup`, `pre-deploy-check`

### 其他
- `.claude/memory/progress.md` — 项目进度记录
- `harness/` — 测试工程目录
- `hermes/` — 部署与运维脚本目录

## 七轴评分细则（每轴 0-5 分）

### 1. 结构（Structure）
- 目录层级清晰
- 文件命名一致
- **命令与技能边界检查（结构轴子项）：** 扫描 `.claude/commands/*.md` 中是否存在以下违规内容：

| 违规类型 | 示例 | 扣分 |
|---------|------|:---:|
| 文件路径常量 | `/jeecg-boot/jeecg-module-system/...` | -0.5 |
| DB 连接串 | `jdbc:mysql://localhost:3306/...` | -0.5 |
| 代码模板 | Java/Vue 完整代码片段 | -0.5 |
| 进程名/类名 | `JeecgSystemApplication` | -0.5 |
| 构建命令参数 | `-pl jeecg-module-system/...` | -0.5 |
| 组件名称 | `BasicTable`, `JeecgController` | -0.5 |
| 配置 schema | YAML 完整配置块 | -0.5 |
| 评分细则 | 硬编码评分标准数字 | -0.5 |

> 命令文件只应引用规则文件（`@rules/xxx`）和技能（`/skill-name`），不应内联具体技术细节。

### 2. 上下文（Context）
- `CLAUDE.md` 反映当前项目状态
- 规则无过时假设（如引用已删除的目录）
- `features.json` 与实际模块同步

### 3. 规划（Planning）
- `/brainstorm` → `/plan` 流程完整
- 有清晰决策树（新建 vs 覆盖 vs 扩展）

### 4. 执行（Execution）
- Hooks 正常工作
- Commands 覆盖开发全流程

### 5. 验证（Verification）
- `/done` 检查清单完备
- `/review` 覆盖安全检查
- `/debug` 流程实用

### 6. 改进（Improvement）
- `/session-wrap` 定期执行
- `/learn` 在捕获经验
- `progress.md` 在更新

### 7. 交叉验证（Cross-Validation）

逐文件检查引用完整性和内容一致性。每项违规扣 0.5 分。

#### 7.1 悬空引用

| 检查 | 方法 | 扣分 |
|------|------|:--:|
| CLAUDE.md 引用的命令存在 | grep 命令名 → 检查 commands/ 对应文件 | -0.5 |
| CLAUDE.md 引用的规则存在 | grep 规则文件名 → 检查 rules/ 对应文件 | -0.5 |
| Skill 引用的技能存在 | grep `jeecg-*` → 检查 skills/ 目录 | -0.5 |
| Rule 引用的文件存在 | grep 文件路径 → 检查磁盘文件 | -0.5 |

#### 7.2 Frontmatter 完整性

| 检查 | 规则 | 扣分 |
|------|------|:--:|
| Rules 有 `name` | 所有 rules/*.md 的 YAML frontmatter | -0.5 |
| Rules 有 `version` | 同上 | -0.5 |
| Rules 有 `glob`/`globs` | 同上 | -0.5 |
| Skills 有 `name` | 所有 skills/*/SKILL.md 的 YAML frontmatter | -0.5 |
| Skills 有 `description` | 同上 | -0.5 |

#### 7.3 配置一致性

| 检查 | 方法 | 扣分 |
|------|------|:--:|
| Hook 脚本全部注册 | hooks/ 中每个 .sh → settings.json 检查是否被引用 | -0.5 |
| settings.json 的 Hook 脚本存在 | settings.json 中的 Hook → hooks/ 对应脚本 | -0.5 |

#### 7.4 内容质量

| 检查 | 方法 | 扣分 |
|------|------|:--:|
| 无空技能目录 | skills/*/ 下有 SKILL.md 且非空 | -0.5 |
| 无未替换占位符 | SKILL.md 中无 `<SKILL_NAME>` 或 `<XXX>` 模式 | -0.5 |
| CLAUDE.md 不重述 Rule | CLAUDE.md 中不包含 Rule 文件的完整规则内容（只应引用） | -0.5 |

#### 7.5 自检

| 检查 | 方法 | 扣分 |
|------|------|:--:|
| 命令计数准确 | harness-check 声明的命令数 = commands/ 实际文件数 | -1 |
| 规则计数准确 | harness-check 声明的规则数 = rules/ 实际 .md 数 | -1 |
| Hook 计数准确 | harness-check 声明的 Hook 数 = hooks/ 实际脚本数 | -1 |

> 自检项权重更高（-1 分/项），因为计数错误会导致巡检报告失信。

#### 7.6 构建一致性

推送前必检。防止模块声明了但代码没提交导致编译失败。

| 检查 | 方法 | 扣分 |
|------|------|:--:|
| boot-module 模块目录存在 | `pom.xml` 中 `<module>` 声明 → 检查对应目录存在且含 pom.xml | -1 |
| system-start 依赖声明 | 新增模块目录 → 检查 system-start/pom.xml 是否有对应 `<dependency>` | -1 |
| 模块目录已提交 | 本地有但 `git ls-files` 未跟踪 → 警告漏提交 | -1 |
| 前后端配套完整 | 后端模块目录存在 → 检查对应前端路由文件和页面目录也存在且已 git 跟踪 | -1 |
| 前端文件已提交 | `git ls-files --others` 中无前端页面文件 → 有则警告漏提交 | -1 |

> 构建一致性权重 -1 分/项。漏提交模块代码会导致 CI 编译失败，影响整个团队。

### 8. 代码结构健康（Code Structure Health）

通过 code-review-graph MCP 工具评估代码库结构质量。每项违规扣 0.5 分，起评 5 分，最低 0 分。

| 检查项 | 工具 | 参数 | 扣分规则 |
|--------|------|------|---------|
| 知识缺口 | `get_knowledge_gaps_tool` | 默认参数 | 每个未测试热点（untested hotspot）-0.5 |
| 过大函数 | `find_large_functions_tool` | `min_lines=75`, `kind="Function"`, `limit=20` | 每个 >75 行函数 -0.5，上限 -2 |
| 架构耦合 | `get_architecture_overview_tool` | `detail_level="minimal"` | 每对高耦合社区警告 -0.5 |
| 图谱新鲜度 | `list_graph_stats_tool` | 默认参数 | `last_updated` >7 天 -1；图谱不存在 -2 |

### 降级策略

- MCP 服务不可用 / 超时（>10s）→ 跳过第 8 轴，输出 `"第 8 轴（代码结构健康）：SKIPPED - graph unavailable"`，总分分母从 40 调整为 35
- 部分工具失败 → 可用工具仍参与评分，失败项不扣分

## 推送前快速检查（轻量模式）

执行 `git push` 前，AI 自动运行轻量版检查（约 3 秒），只覆盖 7.1（悬空引用）+ 7.6（构建一致性）两项。发现阻塞项（扣 -1 的）先修复再推送，不阻断业务人员。

## 演进检查方法

- 逐 Rules 问"还编码了有效假设吗？"
- 逐 Commands 问"还在使用吗？"
- 过时规则标记为废弃状态，不直接删除

## 铁律

**必须输出改进建议。** 只评分不给建议 = 未完成检查。
