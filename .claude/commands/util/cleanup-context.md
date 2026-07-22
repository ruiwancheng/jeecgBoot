---
description: 自有命令 — 上下文压缩：生成项目记忆卡片，用于新会话/新终端接力。卡片输出后可直接交给下一个AI。
---

# /cleanup-context

长会话上下文膨胀时，生成一份结构化"记忆卡片"——下一个 AI 拿到它，无需回看任何历史对话就能直接干活。

## 流程

1. 扫描 `.claude/rules/workflow.md` 提取全部防失忆规则
2. 读取 `.claude/memory/progress.md` 获取项目状态
3. 获取 `git log --oneline .last-deploy-commit..HEAD` 列出待部署提交
4. 合并输出记忆卡片（格式见模板）

## 记忆卡片模板

```markdown
# MES 项目记忆卡片

## 🔴 硬规则
<从 workflow.md 防失忆点 + verify 铁律 + plan 步骤 4.5 提取>

## ⚙️ 工作流（必须遵守）
1. /brainstorm → 2. /plan（≥3文件+跨模块→必须先orca-review）→ 3. 实现 → 4. /verify(curl实测) → 5. /quality-gate → 6. worker_done

## 🚫 禁止模式
<从 frontend.md / code-style.md 提取关键禁止项>

## 📊 项目状态
- 活跃模块：<progress.md 读取>
- 待部署：<git log .last-deploy-commit..HEAD --oneline | wc -l> 个提交
- 上次部署：<cat .last-deploy-commit>
- 测试基线：codeRule 20/20, sales-order 30/30

## ✅ 最近通过
- <最近 3 条通过的测试名称>

## ⚠️ 待处理
- <progress.md 的 pending_step>
- <未完成的修复项>

## 📁 工作区
- 后端边界：jeecg-boot/jeecg-boot-module/project-mes/
- 前端边界：jeecgboot-vue3/src/views/project/mes/
- 禁止写入：jeecg-boot-base-core/、jeecg-module-system/、.claude/
```

## 输出后提示

```
📋 记忆卡片已生成。以下方式使用：
1. 直接在当前会话继续
2. 关闭终端 → 新终端 → 把卡片内容粘贴给新AI
3. 用 /delegate <任务> 命令：自动开新终端 + 带卡片上下文 + 派发任务
```
