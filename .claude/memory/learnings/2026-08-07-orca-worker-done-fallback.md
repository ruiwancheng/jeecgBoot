# Orca worker_done 协议失败的兜底模式

**日期**：2026-08-07
**上下文**：8 个 slice 派工 + 5 轮评审全部遇到 `Orca runtime stale_bootstrap` 错误
**经验**：不要让 codex 卡在 worker_done 协议上，靠 git log 兜底

## TL;DR

`orca orchestration send --type worker_done` 在 8 个 slice 派工 + 5 轮评审中**100% 失败**（Orca runtime stale_bootstrap）。所有"worker_done"消息都是 degraded 状态。但产物（commit + 文件）已实际落地。

## 协议失败模式

### 错误 1：缺 taskId
```
Rejected worker_done: worker_done requires taskId.
```

### 错误 2：缺 dispatchId
```
Rejected worker_done: worker_done requires dispatchId.
```

### 错误 3：未知 dispatch
```
Rejected worker_done: worker_done references unknown dispatch dispatch_xxx.
```

### 错误 4：Orca runtime stale
```
ERROR: Could not connect to the running Orca app.
Run 'orca open' first.
```

## 兜底模式（必须）

### 协调者侧的 3 层兜底

```
第 1 层：worker_done 协议成功
  ↓ 失败
第 2 层：git log 检测产物（commit hash 出现 = 完成）
  ↓ 失败
第 3 层：orion terminal preview 看 codex "任务完成"总结
  ↓ 失败
判定：未完成，继续轮询
```

### 实现：轮询脚本（核心）

```bash
TASK_SLUG="slice-N"
COORDINATOR_HANDLE="term_ae8d7e18-b178-46b3-be13-9a503d89270c"
WORKER_HANDLE="term_893f7603-8fee-497e-84ed-732bc301bd89"

for i in $(seq 1 20); do
  sleep 30

  # 第 2 层兜底：git log 检测
  if git log --oneline -3 | grep -q "${TASK_SLUG}"; then
    echo "✅ [Layer 2] git log 检测到产物"
    break
  fi

  # 第 1 层：inbox worker_done 检测
  HAS=$(orca orchestration inbox --json | python -c "
import json, sys
data = json.load(sys.stdin)
msgs = data['result']['messages']
matched = [m for m in msgs if isinstance(m, dict) and m.get('type')=='worker_done']
print('1' if matched else '0')
")
  if [[ "$HAS" == "1" ]]; then
    echo "✅ [Layer 1] worker_done 消息送达"
    break
  fi

  # 第 3 层：preview 看 codex 总结
  PREVIEW=$(orca terminal read --terminal "$WORKER_HANDLE" 2>&1 | tail -5)
  if echo "$PREVIEW" | grep -qE "(完成|committed|pushed|✅)"; then
    echo "✅ [Layer 3] preview 检测到完成总结"
    # 等 git log 落地（一般 5-10s）
    sleep 10
    if git log --oneline -3 | grep -q "${TASK_SLUG}"; then
      break
    fi
  fi
done
```

### 协调者手动代发 worker_done

如果派工后 5 分钟无 worker_done 但 git log 有产物：

```bash
# 协调者手动补发 degraded message
orca orchestration send \
  --to "$COORDINATOR_HANDLE" \
  --type status \
  --subject "[${TASK_SLUG}] 协调者代发·产物到位" \
  --body "codex worker 未发 worker_done（Orca runtime down），但产物已确认：commit=<hash> files=<list>"
```

## Orca runtime 间歇性故障原因（推测）

1. **Electron codesign 错误**：`task_name_for_pid: (os/kern) failure (5)` - macOS 权限问题
2. **Stale bootstrap**：长时间运行的 Orca app 状态不一致
3. **缺少定时重启**：Orca daemon 需要定期重启

## 修复建议（未来）

- 短期：每次大派工前 `orca open` 重启 runtime
- 中期：写 `bootstrap-orca.sh` 自动检测 + 重启
- 长期：Orca 团队加 daemon watchdog

## 不推荐做法

- ❌ 让 codex 反复重试 worker_done（context 浪费）
- ❌ 在 worker_done 失败时判 slice 未完成（git log 已确认则 OK）
- ❌ 不轮询直接判失败（30s 内可能成功）
