---
description: 自有命令 — 铁拳团审计：将变更内容派发 Claude 按 jeecg-tiequan-audit 技能执行 10 agent 并行审计
---

# /tiequan-audit [模块名]

把审计任务**显式派发**给独立 Claude 终端，按铁拳团技能做 10 视角并行审计。
不用自然语言碰运气——显式命令 = 硬机制（原则：靠自觉的步骤 = 从不触发）。

## 用法

```
/tiequan-audit 其它出入库       # 指定模块/变更主题
/tiequan-audit                 # 默认审计最近一次提交的变更
```

## 什么情况下用

- 新模块/大改动交付前（Entity/SQL/跨文件变更）
- 部署前的深度质量闸（在 orca-review 的方案评审之后，这是代码级审计）

## 什么情况下不用

- 小改动（文案/样式/单行修复）——铁拳团是 10 agent 重武器，投入产出不匹配
- 方案还没写代码——那是 orca-review 的阶段

## 流程

### 1. 确定审计范围

- 用户给了模块名/主题 → 以此为审计目标
- 没给 → `git log -1 --name-only --format="%h %s"` 取最近提交的变更文件清单

### 2. 前置条件检查

```bash
orca terminal list --json   # 需要可写的 Claude Code 终端
```

- 无 Claude 终端 → **降级**：提示"无可用评审终端"，在当前会话直接按 `jeecg-tiequan-audit` 技能执行（单体会话版）
- 有 → 继续

### 3. 派发审计任务

```bash
orca orchestration task-create \
  --task-title "tiequan-<主题>-<日期>" \
  --spec "按 jeecg-tiequan-audit 技能执行完整铁拳团审计（10 agent 并行）。

## 审计目标
<模块名/主题>

## 变更内容
<git log -1 --stat 输出 + 关键文件清单>

## 项目根
D:/vibecoding/jeecgBoot

## 要求
1. 严格按技能 Execution Steps 执行（环境隔离可选）
2. 报告输出到 hermes/tiequan/<YYYY-MM-DD>/<主题>/
3. worker_done 回报: P0/P1/P2 数量 + 共识高危清单 + 报告路径" \
  --json

orca orchestration dispatch --task <task_id> --to <claude_terminal> --inject
```

### 4. 等待回报

- 轮询 `orca orchestration dispatch-show --task <task_id>`（**禁止 check --wait**，TUI 截胡）
- 兜底：`test -f hermes/tiequan/<日期>/<主题>/01_风控总报告.md`
- 超时 15 分钟 → 标记"审计超时"，让用户决定是否继续等

### 5. 汇总展示 + human-gate

```
📊 铁拳团审计完成 — <主题>

  P0 阻断: <N> 个
  P1 高危: <N> 个
  P2 建议: <N> 个

  共识高危:
  ├─ <问题1>
  └─ <问题2>

  报告: hermes/tiequan/<日期>/<主题>/01_风控总报告.md
```

- **P0 > 0** → 发 human-gate（`commit-block` 类型）：修复后再部署 / 人工豁免继续
- **P0 = 0** → 输出 PASS，可进入部署阶段

## 与其他命令的关系

| 命令 | 阶段 | 深度 |
|------|------|------|
| `/orca-review` | 写代码**前**（方案评审） | 1 人 |
| `/review` | 写代码后（7 类快速扫描） | 1 人轻量 |
| **`/tiequan-audit`** | 交付**前**（代码级全面审计） | **10 人并行** |
