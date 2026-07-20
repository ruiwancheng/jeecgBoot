---
name: session-wrap
description: 会话收尾，检查重复信号并提示后续操作 — Session wrap-up: check repetition signals and suggest follow-up actions
version: 1.0.0
---

# 会话收尾 (Session Wrap)

## 信号检查

### 重复操作检测

同一操作在当前会话中出现 3 次以上时触发。

**触发后建议：**
```
检测到重复操作：<操作描述>（出现 N 次）
建议：创建新 Command 自动化此操作。
```

**自动化方式：** 在 `.claude/skills/` 下新建 SKILL.md 或在 `.claude/commands/` 新建指令文件。

### 重复错误检测

同一类型错误在当前会话中出现 2 次以上时触发。

**触发后建议：**
```
检测到重复错误：<错误类型>（出现 N 次）
建议：创建新 Rule 预防此类错误。
```

**Rule 示例：** 在 `.claude/rules/` 下新建规则文件，描述错误现象、根因和预防措施。

### learnings/ 累积检查

`.claude/memory/learnings/` 目录下累积 3 条或以上经验时触发。

**触发后建议：**
```
learnings/ 已累积 N 条经验。
建议：运行 /evolve 将经验反哺到规则中。
```

## progress.md 更新

每次会话结束时更新 `.claude/memory/progress.md`，格式：

```markdown
## 当前状态
<一句话描述当前开发进度>

## 本次完成
- <完成项 1>
- <完成项 2>

## 关键决策
- <决策 1>：<原因>
- <决策 2>：<原因>

## 待推进
- <待办 1>
- <待办 2>

## 经验记录
- <经验 1>
- <经验 2>
```

## 手工操作提示

收尾时汇总需要用户手工完成的操作：

```
🔧 手工操作：
  1. 提交代码（N 个文件未提交）
  2. /evolve（N 条经验待反哺）
```

**手工操作类型：**
- 代码提交（git add / commit / push）
- 经验反哺（/evolve）
- 数据库变更审批
- 部署到测试/生产环境
- 通知相关人员

## 收尾流程

1. 检查重复信号（操作/错误/learnings）
2. 更新 `progress.md`
3. 列出手工操作
4. 给用户简短总结

## 铁律

> 不自动执行提交、推送、部署。所有需审批的操作留给用户。
> progress.md 必须用业务语言，避免技术术语。
