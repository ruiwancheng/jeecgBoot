---
name: cleanup-context
description: 上下文压缩领域知识 — 记忆卡片模板、输出格式、状态提取规则、质量门控条件。被 /cleanup-context 命令加载。
version: 1.0.0
---

# cleanup-context — 上下文压缩领域知识

## 记忆卡片模板

```markdown
# MES 记忆卡片

## 🤖 恢复指令（给下一个AI看的）
- **当前阶段**：<brainstorm / plan / implement / verify / debug>
- **行为**：<继续分析不要写代码 / 直接执行下一步 / 继续验证>
- **接力次数**：第<N>次（≥3次时提示用户"建议人工确认方向"）

## 🎯 当前会话（最重要——新终端无法自己获取）
- **正在做**：<当前任务/需求一句话>
- **关键决策**：
  - <决策1 + 原因>
  - <决策2 + 原因>
- **已排除**：<排查过但否定的方向>
- **下一步[自动执行]**：<具体可操作的动作，含文件路径、接口路径>

## ⚠️ 关键提醒（容易忘的——完整规则新终端会自己加载）
- /verify 禁止 mvn clean，用 mvn compile
- 任何代码改动必须先 orca-review（仅纯文本/注释/样式免评）
- 写完代码自动 /verify，不要等用户提醒
- 本地8080在跑时必须 curl 实测

## 📊 项目状态
- 活跃模块：见 progress.md
- 待部署：<N> 个提交
- 上次部署：<commit>
- 工作区：见 @rules/boundary.md
- 禁止写入：见 @rules/boundary.md 和 @rules/code-style.md

## ⚠️ 待处理
- <progress.md 的 pending_step>
```

## 输出后提示模板

```
📋 记忆卡片已生成。以下方式使用：
1. 直接在当前会话继续
2. 关闭终端 → 新终端 → 把卡片内容粘贴给新AI
3. 用 /delegate <任务> 命令：自动开新终端 + 带卡片上下文 + 派发任务
```

## 质量门控规则

"下一步[自动执行]"必须含文件路径（/ 或 .java 或 .vue 或 .ts 或 .xml 或 .sql），不含路径则重写直到满足。这是卡片**唯一不可妥协的要素**。

## 状态提取规则

从 `.claude/memory/progress.md` 获取项目状态，从 `git log --oneline .last-deploy-commit..HEAD` 获取待部署提交列表。
