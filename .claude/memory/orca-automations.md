---
name: orca-automations
description: Orca定时自动化任务 — 每周工程巡检、每日死代码扫描、部署后冒烟测试
metadata:
  type: reference
---

# Orca 定时自动化任务

JeecgBoot Harness 工程通过 Orca Automations 实现持久化定时任务，跨会话存活。

## 已规划的自动化任务

### 1. 每周工程健康巡检

```bash
orca automations create \
  --cron "37 9 * * 1" \
  --prompt "/review:harness-check 检查 Harness 工程完整性，输出七轴评分和改进建议" \
  --recurring true \
  --durable true \
  --description "每周一早9:37自动运行Harness工程巡检"
```

### 2. 每日死代码扫描

```bash
orca automations create \
  --cron "17 18 * * 1-5" \
  --prompt "/review:dead-code-check 扫描前后端未引用代码，输出清理建议" \
  --recurring true \
  --durable true \
  --description "工作日18:17自动扫描死代码"
```

### 3. 部署后冒烟测试

见 `skills/test-e2e/SKILL.md` 冒烟测试集章节。

## 注册命令

将上面的命令逐条在终端执行即可注册。Orca 会持久化到 `.claude/scheduled_tasks.json`。

## 查看状态

```bash
# 查看所有自动化
orca automations list

# 查看某个自动化的详情
orca automations show --id <automation_id>

# 查看运行历史
orca automations runs --id <automation_id>
```

## 降级策略

- Orca 不可用 → 自动化不执行，不影响开发流程
- 可通过 `/harness-check` 和 `/dead-code-check` 手动触发等价检查

**Why:** 让工程健康检查和死代码扫描从"想起来才跑"变成"自动定时跑"，防止质量退化。
**How to apply:** 终端执行上述 `orca automations create` 命令注册。
