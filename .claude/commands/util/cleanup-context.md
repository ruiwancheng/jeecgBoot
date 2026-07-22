---
description: 自有命令 — 上下文压缩：生成项目记忆卡片，用于新会话/新终端接力。卡片输出后可直接交给下一个AI。
---

# /cleanup-context

长会话上下文膨胀时，生成一份结构化"记忆卡片"——下一个 AI 拿到它，无需回看任何历史对话就能直接干活。

## 流程

1. **总结当前会话状态**（最重要——这是新终端无法自己获取的信息）
   - **当前阶段**：标注是 brainstorm / plan / implement / verify / debug 哪个阶段
   - 当前正在做什么任务/需求
   - 已做的关键决策及原因（方案A被否因为XX，选了方案B）
   - 已排查/排除的问题
   - **下一步[自动执行]**：写具体可操作的动作（必须含文件路径或接口路径），新AI可以直接执行
     - ✅ 好："下一步：读取 purchase/receipt/controller/MesPurchaseReceiptController.java，在第145行附近确认 @RequiresPermissions 注解是否包含 mes:purchaseReceipt:audit"
     - ❌ 差："下一步：采购申请需要加审核端点"
     - ⚠️ **质量门控：** 如果"下一步"不含文件路径（/ 或 .java 或 .vue 或 .ts 或 .xml 或 .sql），必须重写直到满足。这是卡片唯一不可妥协的要素。
2. 读取 `.claude/memory/progress.md` 获取项目状态
3. 获取 `git log --oneline .last-deploy-commit..HEAD` 列出待部署提交
4. 合并输出记忆卡片（格式见模板）
   - **会话状态放在最前面**（这是卡片的唯一价值）
   - 规则信息压缩到"关键提醒"（规则新终端会自己加载，只列容易忘的）

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
- ≥3文件+跨模块 必须先 orca-review
- 写完代码自动 /verify，不要等用户提醒
- 本地8080在跑时必须 curl 实测

## 📊 项目状态
- 活跃模块：<progress.md>
- 待部署：<N> 个提交
- 上次部署：<commit>
- 工作区：后端 `project-mes/`，前端 `project/mes/`
- 禁止写入：`jeecg-boot-base-core/`、`jeecg-module-system/`、`.claude/`

## ⚠️ 待处理
- <progress.md 的 pending_step>
```

## 输出后提示

```
📋 记忆卡片已生成。以下方式使用：
1. 直接在当前会话继续
2. 关闭终端 → 新终端 → 把卡片内容粘贴给新AI
3. 用 /delegate <任务> 命令：自动开新终端 + 带卡片上下文 + 派发任务
```
