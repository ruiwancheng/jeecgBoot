# Super Harness 插件能力差距评估

**日期**：2026-07-04 | **已安装插件**：ECC、Superpowers、Feature-dev、Caveman、Context7、GitHub、Remember

---

## 一、评估方法

业务人员不会安装任何插件。本 Harness 必须不依赖外部插件，所有能力通过 Rules/Commands/Hooks/Skills 自包含。对照已安装插件的核心能力，逐项检查覆盖情况。

---

## 二、差距矩阵

### Superpowers

| 能力 | 需要？ | 本 Harness | 差距 |
|------|--------|-----------|------|
| brainstorming（需求澄清） | 必需 | 无 | **缺 `/brainstorm`**——业务人员最需要的能力 |
| writing-plans（实施方案） | 必需 | 部分 | `/start-task` 太轻量，缺任务分解、模式参照 |
| executing-plans（按计划执行） | 需要 | 无 | 无计划执行检查点 |
| TDD（测试驱动） | 需要 | 部分 | `rules/testing.md` 有标准，无强制流程 |
| systematic-debugging | 需要 | 无 | **缺调试流程** |
| verification-before-completion | 需要 | 无 | **缺"做完验证"检查清单** |
| finishing-a-development-branch | 需要 | 无 | **缺"开发完后怎么办"** |

### ECC

| 能力 | 需要？ | 本 Harness | 差距 |
|------|--------|-----------|------|
| plan | 必需 | 部分 | 缺文件级分解、模式参照 |
| code-review | 需要 | 有 | `/review` 已覆盖 |
| build-fix | 需要 | 无 | **缺编译报错处理流程** |
| pr | 需要 | 无 | 缺 PR 创建 |
| test-coverage | 需要 | 无 | 缺覆盖率检查 |
| security-scan | 需要 | 部分 | 有规范，缺自动扫描 |

### Feature-dev

| 能力 | 需要？ | 本 Harness | 差距 |
|------|--------|-----------|------|
| code-explorer | 需要 | 部分 | `features.json` 有，缺"怎么找代码"指引 |
| code-reviewer | 需要 | 有 | `/review` 已覆盖 |
| code-architect | 部分 | 部分 | 缺"新功能放哪"决策流程 |

---

## 三、关键缺失总结

### P0（业务人员无法正常工作）

1. **需求澄清**——没 `/brainstorm`，AI 不确认需求就直接写代码
2. **完整实施计划**——`/start-task` 太轻量，缺文件清单、完成标准
3. **做完验证**——改完了没有"验证→再提交"的检查清单
4. **调试流程**——遇到报错不知道怎么排查

### P1（效率和质量）

5. **编译报错处理**——`/build-fix` 流程
6. **开发完成后流程**——开发完→提交？部署？通知？
7. **TDD 强制**——有标准但无"先测试再代码"流程
8. **PR 提交**——缺 PR 创建和描述模板

### P2（锦上添花）

9. **新功能放哪的决策树**——新建 vs 覆盖 vs 扩展
10. **审查意见处理**——收到问题后怎么改的标准化
11. **安全自动扫描**——Hook 层密钥泄露检查

---

## 四、建议新增

### Commands

| Command | 用途 | 优先级 |
|---------|------|--------|
| `/brainstorm` | 需求澄清：先聊清楚再动手 | P0 |
| `/plan` | 完整计划：任务分解 + 模式参照 + 验证方式 | P0 |
| `/done` | 完成检查：验证→manifest→提交 | P0 |
| `/debug` | 标准化调试流程 | P0 |
| `/build-fix` | 编译报错处理 | P1 |
| `/finish` | 开发收尾：自查→提交→通知 | P1 |

### Rules

| Rule | 用途 | 优先级 |
|------|------|--------|
| `workflow.md` | 完整开发流程：需求→计划→实现→验证→提交 | P0 |
| `debugging.md` | 标准化调试检查清单 | P0 |
| `decision-tree.md` | 新建 vs 覆盖 vs 扩展决策树 | P2 |
