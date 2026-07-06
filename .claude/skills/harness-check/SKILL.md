---
name: harness-check
description: Harness 巡检 — 检查 CLAUDE.md、Commands、Rules、Hooks 完整性，七轴评分（含交叉验证）并输出改进建议。Audit harness integrity with seven-axis scoring (including cross-validation) and improvement suggestions.
---

# harness-check — Harness 工程巡检

## 完整文件清单

### 根文件（2 个）
- `CLAUDE.md` — 项目指令主文件
- `.claude/settings.json` — 项目级设置
- `.claude/features.json` — 功能模块清单

### 命令 Commands（22 个）
`admin`, `brainstorm`, `plan`, `done`, `debug`, `review`, `new-project`, `session-wrap`, `learn`, `harness-check`, `evolve`, `finish`, `gen-tests`, `list-projects`, `restart-backend`, `setup`, `switch-project`, `test-all`, `test-api`, `test-e2e`, `test-frontend`, `verify`

### 规则 Rules（12 个）
`file-scope`, `backend-first`, `code-style`, `no-platform-modify`, `frontend`, `security`, `testing`, `workflow`, `debugging`, `skill-command-boundary`, `data-scope`, `override-mechanism`

### 钩子 Hooks（4 个）
`pre-write-check`, `pre-commit-check`, `block-dangerous`, `session-start`

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

## 演进检查方法

- 逐 Rules 问"还编码了有效假设吗？"
- 逐 Commands 问"还在使用吗？"
- 过时规则标记为废弃状态，不直接删除

## 铁律

**必须输出改进建议。** 只评分不给建议 = 未完成检查。
