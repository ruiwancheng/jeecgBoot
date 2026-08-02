---
description: 自有命令 — 任务委派：在当前会话上下文膨胀时，一键生成记忆卡片 + 开新 pi 终端派发给干净上下文的工人（统一用 pi，不再按调用者自检测）
---

# /delegate <任务描述>

上下文膨胀时，委派任务给独立的 pi 工人终端。工人只携带压缩后的规则+状态，零历史负担。

> **agent 策略**：2026-08 起统一用 pi，**不再按调用者身份自检测**（Claude 调 Claude / pi 调 pi 的旧规则已废弃）。质量通过 orca-review 独立评审环节兜底，不靠选 agent。

## 流程

使用 `delegate` 技能获取：Orca CLI 命令、preamble 模板、agent 选择矩阵、强制校验清单、降级策略。

### 1. 生成记忆卡片

运行 `/cleanup-context` 生成记忆卡片。

### 2. 创建 pi 工人终端

统一使用 pi agent（不再区分任务类型）：

```bash
orca terminal create --command "pi" --json
```

### 3. 等待就绪 + 注入 preamble + 任务

调用技能中的 **preamble 模板**，传入记忆卡片和任务描述，注入工人终端。

### 4. 等待 worker_done 回报

监听工人终端的编排消息（heartbeat / decision_gate / worker_done）。

### 5. 强制校验（不可跳过）

按技能中的**强制校验清单**逐项检查（v4.0 10 步全流程）：
- 工作流阶段完整（0 切片 → 1 brainstorm → 2 plan → 3 orca-review → 4 实现 → 5 verify → 6 分级测试 → 7 收尾自检 → 8 commit+push → 9 /done → 10 worker_done）
- orca-review 由独立终端完成（非降级）
- 分级测试级别与变更影响面匹配（轻量/标准/全量）
- /quality-gate 等价自检全过（update-begin/end 对账、git diff 范围、推送前依赖）
- git commit + push 已执行（worker_done 含 commit hash）
- /done 完成检查清单已走完
- git diff 合理
- /verify 结果

任何异常立即报告用户，不默默放行。

### 6. 关闭工人终端

回报到达后自动关闭：按技能中的 Orca CLI 命令关闭终端。

### 7. 循环

下一任务重复步骤 2-6。

## 降级

按技能中的降级策略处理：Orca 不可用 → 退化为 `/cleanup-context`；无空闲槽位 → 提示用户释放终端。

## 使用示例

```
用户：/delegate 修复采购订单审核按钮报错问题
AI  ：📋 生成记忆卡片... ✅
      🚀 创建 pi 工人终端... term_xxx ✅
      📤 派发任务... dispatched ✅
      等待工人完成 → 回报 worker_done → 汇总结果
```

---

## 🆕 v5 优化（2026-08-02 同步 SKILL.md）

### 派工前 30 秒 checklist（必走）

```bash
# 1. grep 代码确认 bug 描述准确（避免派过时任务）
grep -n "<关键符号>" <目标文件>

# 2. 确认 orca 可用 + Claude 终端在线
orca status --json | grep running
orca terminal list --json | python -c "import json,sys; d=json.load(sys.stdin); print([t['handle'] for t in d['result']['terminals'] if 'Claude' in t.get('title','')])"

# 3. 准备 preamble（≤ 1500 字节）
#    - 含完整 worker_done 命令模板
#    - 禁止让 worker 发 decision_gate
```

### orca-review 由协调者发起（不要 worker 发）

**错误**：preamble 写"用 orca orchestration send --type decision_gate"——Pi worker 不会发，会卡死思考"什么是协调者"。

**正确**：协调者在 worker 输出 plan 后，自己发 orca-review：

```bash
# 1. 找到 Claude 终端
CLAUDE=$(orca terminal list --json | python -c "
import json,sys
for t in json.load(sys.stdin)['result']['terminals']:
    if 'Claude' in t.get('title','') and t.get('writable'):
        print(t['handle']); break
")

# 2. 创建评审任务
TASK_ID=$(orca orchestration task-create \
  --spec "<背景 + 草案 + 待评审问题>" \
  --task-title "review-<任务名>-$(date +%H%M)" \
  --json | python -c "import json,sys; print(json.load(sys.stdin)['result']['task']['id'])")

# 3. dispatch 到 Claude
orca orchestration dispatch --task $TASK_ID --to $CLAUDE --inject

# 4. 等回报（最多 5 分钟，看 hermes/reviews/ 或 terminal preview）
```

### 轮询节奏 30s（不再是 60-90s）

```bash
START_TS=$(date -u +"%Y-%m-%dT%H:%M:%S")
COORDINATOR_HANDLE="<协调者 handle>"
TASK_KEYWORD="<任务关键词>"

for i in $(seq 1 20); do
  sleep 30
  # 1. lastOutputAt 检测卡死
  LAST=$(orca terminal show --terminal $HANDLE --json | python -c "import json,sys; print(json.load(sys.stdin)['result']['terminal'].get('lastOutputAt',0))")
  NOW=$(date +%s%3N)
  GAP=$((NOW - LAST))
  if [ $GAP -gt 90000 ]; then
    echo "[卡死] ${GAP}ms > 90s，ping"
    orca terminal send --terminal $HANDLE --text "[ping] 你卡住了吗？直接动手。" --enter
  fi
  # 2. inbox worker_done 检测
  HAS=$(orca orchestration inbox --json | python -c "
import json, sys
d = json.load(sys.stdin)
msgs = d['result']['messages']
n = sum(1 for m in msgs if isinstance(m, dict) and 
       m.get('type')=='worker_done' and 
       m.get('created_at','')>='$START_TS' and (
           m.get('to_handle','') == '$COORDINATOR_HANDLE' or
           '$TASK_KEYWORD' in m.get('subject','') + m.get('body','')
       ))
print(n)
")
  [ "$HAS" != "0" ] && break
done
```

### 卡死兑底

| 信号 | 阈值 |
|---|---|
| preview 重复同一段思考 > 2 分钟 | 主动 ping |
| preview 出现"但是我需要注意"等 ≥ 3 次 | 杀工人 + 重派精简版 |
| lastOutputAt gap > 90 秒 | 主动 ping |
| terminal read buffer 空 | 杀工人 + 重派 |

### worker_done payload 模板（preamble 嵌入）

```bash
orca orchestration send \
  --type worker_done \
  --subject "[<任务名>] 完成" \
  --body "commit: <hash>
filesModified: <path1, path2>
verify: <mvn compile OK / curl 200 / test N/N pass>
risks: <P0/P1 列表，如无写 'none'>
phase: completed"
```

### 决策表：orca-review 必要性

| 任务类型 | 是否要 orca-review | 评审方 |
|---|---|---|
| 纯文案/注释/样式 | ❌ | — |
| Vue/TS ≤3 文件无新 Entity | ⚠️ 协调者自评 | — |
| Java Service + Mapper | ✅ 必评 | Claude |
| SQL 改表/Entity | ✅ 必评 | Claude |
| 跨模块链路 | ✅ 必评 | Claude |

### 协调者代发兑底

Pi 工人 5 分钟未发 worker_done 但产物到位 → 协调者手动代发：

```bash
orca orchestration send \
  --to <协调者 handle> \
  --type worker_done \
  --subject "[<任务名>] 协调者代发·产物到位" \
  --body "工人未发 worker_done，但产物已确认：<path1>
关键结果：<从产物提取>"
```
