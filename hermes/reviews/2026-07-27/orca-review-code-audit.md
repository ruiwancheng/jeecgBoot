# Orca 外部评审 — orca-review 审计

**评审阶段**：code-review（代码完成后轻量审计）  
**评审对象**：本次新增的全部 .claude/ 文件（5 条命令 + 1 个框架 + 1 个 client-start 更新）  
**评审方**：Claude（独立终端，`term_6873d7af-881d-4ae9-a2e7-06b2379e9a86`）

## 背景

为 JeecgBoot 项目新增了基于 Orca 的 5 条开发命令 + 1 个人工门控框架 + 客户端启动命令更新。目标是在现有 `/start` `/verify` `/debug` 基础上叠加 Orca browser/orchestration 能力，深化多客户端 + 多 agent 开发场景。

## 变更范围（本次审计对象）

### 新增（12 个文件，未追踪，约 32KB）

**01 — 人工门控框架（被其他 5 条命令共用）**
- `.claude/skills/human-gate/SKILL.md` — decision_gate 硬阻断 + 上下文膨胀保护

**02 — 可视化验证**
- `.claude/commands/dev/visual-check.md` — 命令
- `.claude/skills/visual-check/SKILL.md` — 技能

**03 — 自愈测试循环**
- `.claude/commands/dev/test-loop.md` — 命令
- `.claude/skills/test-loop/SKILL.md` — 技能

**04 — 跨模块链路验证**
- `.claude/commands/dev/chain-test.md` — 命令
- `.claude/skills/chain-test/SKILL.md` — 技能

**05 — 部署后编排验证**
- `.claude/commands/quality/deploy-verify.md` — 命令
- `.claude/skills/deploy-verify/SKILL.md` — 技能

**06 — 提交前可视化门控**
- `.claude/commands/quality/pre-commit-gate.md` — 命令
- `.claude/skills/pre-commit-gate/SKILL.md` — 技能

### 已有修改（1 个文件）
- `.claude/skills/local-dev/SKILL.md` — 此次会话早期对 Windows 路径的适配

## 已查证项

| 查证项 | 状态 |
|--------|:--:|
| 命令不包含实现细节（文件路径/Shell命令/端口） | ✅ 已自查 |
| 技能文件包含 frontmatter（name/description/version） | ✅ 全部 6 个技能 |
| human-gate 被 5 条命令引用 | ✅ |
| 不修改已有文件（纯增量） | ✅ |
| 知识图谱已增量更新 | ✅ |
| Orca 可用性（app+runtime+graph ready） | ✅ |
| 独立 Claude 评审终端已创建 | ✅ term_6873d7af |

## 待评审问题

1. **human-gate 的 Orca 依赖硬编码**——当 Orca 不可用时，gate 无法发送，是否需要在技能里加一个退化模式（如：直接输出文本要求用户在终端输入 Y/N）？
2. **visual-check 的像素对比依赖 Pillow**——`pip3 show Pillow` 是否在工具链检测中覆盖？
3. **deploy-verify 三路并行编排**——如果 3 个 agent 中 2 个超时，聚合逻辑是 PASS/NEEDS WORK/BLOCKED 哪个？
4. **命令命名一致性**——chain-test 用 `-` 连接，deploy-verify 也用 `-`，但 pre-commit-gate 也是 `-`——统一吗？

## 评审提示词

你是一位 code-review 专家，请审计以上所有 `.claude/commands/` 和 `.claude/skills/` 目录下的新文件。

评审关注：
1. **完整性** — 每条命令是否覆盖了脑图中描述的所有步骤？命令文件是否引用了正确的技能名称？技能文件是否有遗漏的领域知识？
2. **一致性** — 7 个新文件之间的引用关系是否正确？human-gate 是否被所有需要它的命令引用？命令/技能边界是否清晰？
3. **安全性** — 技能文件中是否有硬编码密钥？是否有危险操作（rm -rf/force push/DROP TABLE）？
4. **可操作性** — 降级策略是否完整？Orca 不可用时每条命令的行为是否定义清楚？上下文膨胀保护是否可执行？
5. **冗余** — 是否有重复内容（多个技能文件中的重复片段）？是否有可以合并但未合并的部分？
6. **遗漏** — 相比需求分析中的 5 条命令 + 1 个框架，是否有遗漏的功能点？

请输出结构化评审报告，格式：
```
✅ 通过项：
⚠️ 发现（P1 — 高危建议修）：
💡 建议（P2 — 优化建议）：
```
