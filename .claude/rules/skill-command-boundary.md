---
name: skill-command-boundary
description: 命令与技能的边界规则。定义什么内容属于 Command（工作流编排）vs Skill（领域知识），防止知识混入命令文件。
glob: ".claude/commands/*.md,.claude/skills/*/SKILL.md"
version: 1.0
---

# 命令与技能边界规则

## 核心原则

- **命令（Command）= 工作流编排**：定义做什么、按什么顺序做、分几步做
- **技能（Skill）= 领域知识**：定义怎么做、具体的配置值、模板、模式、规则

## 命令文件 (.claude/commands/*.md) 只能包含

1. 执行步骤列表（1, 2, 3...）
2. 决策点和分支条件（"如果 A 则 B"）
3. 步骤之间的衔接（"完成后进入下一步"）
4. 对其他技能的引用（"使用 `<name>` 技能获取..."）
5. 用户交互提示模板（"是否继续？"）

## 命令文件禁止包含

1. 文件路径常量（如 `jeecg-boot/jeecg-module-system/jeecg-system-start`）
2. 数据库连接信息（如 `mysql -u root -proot -h 127.0.0.1`）
3. 代码模板（SQL、TypeScript、Java）
4. 进程名称、类名（如 `JeecgSystemApplication`）
5. 构建命令的具体参数（如 `mvn clean install -pl ... -am -DskipTests`）
6. 组件名称引用（如 `BasicTable`, `searchFormSchema`）
7. 配置文件路径及其 JSON/YAML schema 定义
8. 评分细则的具体检查项（如 harness-check 的 6 轴逐项清单）
9. 密码、密钥等凭证

## 技能文件 (.claude/skills/<name>/SKILL.md) 应包含

以上 1-9 所有被命令文件禁止的内容。技能是领域知识的唯一存放地。

## 判断标准

审查命令文件中任意一行，问一个问题：

> "这行内容如果换一个项目（如从 JeecgBoot 换成 RuoYi），还需要改吗？"

- 需要改 → 属于技能/领域知识，应该挪到 SKILL.md
- 不需要改 → 属于通用工作流，可以留在命令文件

## 执行机制

当 AI 执行任何命令时：
1. 先读取对应的命令文件获取工作流步骤
2. 检查是否存在同名技能（`.claude/skills/<command-name>/SKILL.md`）
3. 如果存在，自动通过 Skill 工具加载获取领域知识
4. 用工作流步骤编排领域知识的应用
