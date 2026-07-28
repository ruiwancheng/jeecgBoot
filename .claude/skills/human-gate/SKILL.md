---
name: human-gate
description: 人工介入门控框架 — Orca decision_gate 硬阻断 + 上下文膨胀保护，被 /visual-check /chain-test /deploy-verify /pre-commit-gate 共用
version: 1.0.0
---

# human-gate — 人工介入门控框架

## 设计原则

基于已验证的教训：

| 教训来源 | 规则 |
|---------|------|
| `orca-review-false-sense` | "提示用户确认"靠 AI 自觉 → 从不触发。替代：**硬机制 decision_gate** |
| `orca-review-fake-safety` | 单终端自审 = 100% 通过率。替代：**gate 等人 resolve，不等 AI 自判** |
| `rule-condition-blind-spot` | 模式级豁免覆盖不该覆盖的场景。替代：**按操作级判断，不留豁免** |
| `/delegate` decision_gate 模式 | 工人发 gate → 轮询 → 等人 resolve → 继续。已验证可行。 |

## 上下文膨胀保护

每条命令启动时先检查 token 用量。检查方法：

1. **查看系统提醒**：搜索 `<system-reminder>` 中的 token 使用信息（如 `COST: ...` 或 `token usage` 等标识）
2. **估算值**：如果无精确数据，通过上下文中的对话轮数 + 文件读取次数估算——超过 15 轮对话 + 20 次文件读取 → 视为高负载
3. **判定阈值**：
   - 预估使用量 > 80% → 先执行 `/cleanup-context` 压缩，再继续
   - 预估使用量 > 95% → 拒绝执行，输出：
     ```
     ⚠️ 上下文接近上限，继续执行可能导致 AI 放飞自我。
     建议：/new-terminal 开新会话 + 粘贴记忆卡片 + 重新执行此命令。
     ```

## decision_gate 硬门控

### 何时触发

AI 执行到以下节点时**必须发 gate**，禁止自己判定：

| 场景 | gate 类型 | 选项 |
|------|---------|------|
| 发现 UI 差异 | `visual-diff` | accept_baseline / fix_required / ignore |
| 自动修复完成 | `auto-fix` | accept_fix / reject_fix / manual |
| 链路验证断裂 | `chain-break` | code_bug / config_issue / chain_def_wrong |
| 部署验证异常 | `deploy-anomaly` | rollback / skip / fix_forward |
| 提交前阻塞 | `commit-block` | fix_now / skip_no_verify / abort_commit |

### gate 发送步骤

**步骤 1：创建 gate**

```bash
orca orchestration gate-create \
  --task <当前任务ID> \
  --title "<问题标题>" \
  --description "<详细上下文>" \
  --options '<JSON选项数组>' \
  --json
```

如果 `gate-create` 不可用，回退到 `orchestration send` + `--type decision_gate`。

**步骤 2：输出人类可读的上下文**

```
🛑 需要人工判定 — <问题标题>

  上下文：
  ├─ 当前步骤：<步骤>
  ├─ 已完成：<列表>
  └─ 发现：<具体问题>

  选项：
  [1] <选项1>
  [2] <选项2>
  [3] <选项3>

  等待判定中（超时：5 分钟）...
```

**步骤 3：轮询等待**

```bash
# 每 30 秒轮询 gate 状态
# Windows: python3 可能是 WindowsApps 商店占位 stub（command -v 能找到但执行 exit 49 零输出）→ 必须 --version 实测过滤
PY_CMD=$(command -v python3 || command -v python || echo python)
$PY_CMD --version >/dev/null 2>&1 || PY_CMD=$(command -v python || echo python)
orca orchestration gate-list --json | $PY_CMD -c "
import sys,json
gates = json.load(sys.stdin).get('result',{}).get('gates',[])
for g in gates:
    if g['id'] == '<gate_id>' and g['status'] == 'resolved':
        print(g['resolution'])
        sys.exit(0)
print('PENDING')
"
```

- 收到 `resolved` → 提取 resolution → 按解析结果继续或停止
- 持续 `PENDING` → 继续轮询（最多 5 分钟）
- 5 分钟超时 → 标记 "人工未响应"

**步骤 4：超时处理**

```
⏰ 人工判定超时（5 分钟未响应）

  命令：<命令名>
  卡在：<步骤>
  上下文已保存到：hermes/logs/gate-timeout-YYYY-MM-DD-HHmmss.md

  后续操作：
  ├─ 重新执行此命令
  ├─ 手动判定后继续
  └─ 查看日志：hermes/logs/gate-timeout-*.md
```

超时日志内容：
```markdown
# Gate 超时记录 — <命令名>

- **时间**: YYYY-MM-DD HH:MM:SS
- **Gate ID**: <id>
- **当前步骤**: <步骤>
- **已完成**: <列表>
- **阻塞原因**: <问题描述>
- **可选动作**: <选项列表>
- **上下文**: <关键文件/状态摘要>
```

### 禁止事项

- ❌ **禁止 AI 自己 resolve gate**——gate 是单行道，只有人能解
- ❌ **禁止"假设人可能会选 X"然后继续**——gate 未 resolve 前禁止任何后续操作
- ❌ **禁止跳过 gate**——即使"问题很小、很明显该选什么"，也必须等
- ✅ **超时后记录上下文，停止**——不自动选择默认动作

## 与各命令的集成点

```
/visual-check   → 步骤 4（发现 UI 差异）→ human-gate
/chain-test     → 步骤 4（链路断裂）    → human-gate
/deploy-verify  → 步骤 4（异常判定）    → human-gate
/pre-commit-gate → 步骤 5（BLOCKED 判定）→ human-gate
```
