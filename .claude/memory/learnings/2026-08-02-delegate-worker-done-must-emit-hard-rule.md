# /delegate worker_done 发送是硬约束——连续 2 次因不发 worker_done 阻塞协调者

**触发条件：** 任何 `/delegate <任务>` 派发场景 — 工人完成所有工作（commit / 文件生成 / 测试通过），但**忘了发 worker_done** 或**以为发了实际没发**。

## 处理方式

### 工人端：worker_done 必须发，不可省略

按 delegate/SKILL.md v4.0 流程：
- step 10 = "无论如何必须发送 worker_done"
- 即使 verify 不完全通过，也要发送 worker_done 报告结果

**实际反模式**（连续 2 次观察到）：

| 情况 | 现象 |
|------|------|
| **"我完成了"陷阱** | 工人在自己终端里打印"完成"总结，**以为这就够了**，实际没调 `orca orchestration send --type worker_done` |
| **"无需发送"陷阱** | 工人判断"任务轻量不需要回报"，直接进入 idle，导致协调者一直 polling |
| **"protocol 略读"陷阱** | preamble 末尾的编排消息协议被工人忽略（特别是最后一条 worker_done） |

### 协调者端：worker_done 缺位时不要死等

按 2026-08-02-delegate-worker-rebaseline-and-git-fallback learnings：
- worker_done 没发 ≠ 没完成
- 看 git log / 文件产物 / mvn compile 三件套

**但**：必须先尝试**主动补救**，再 fallback 到 git 兜底。

### 协调者侧补救动作（新增）

工人超时无 worker_done 但有产物时（建议 5 分钟 polling 后触发）：

```bash
# 1. 主动 ping 提醒
orca terminal send --terminal $HANDLE --text "你已完成任务吗？如有产物，请立即发 worker_done（含产物路径）。" --enter

# 2. 等 30s 后看是否回复

# 3. 仍无 worker_done → 协调者手动从产物提取 worker_done 内容 + 手动代发
# （仅在产物已确认存在时 — 避免误报完成）

# 4. 兜底：git log + 文件存在性验证
```

### 派发侧优化（preamble 模板强化）

在 preamble 末尾**视觉强化** worker_done 必发：

```markdown
## 🚨🚨🚨 必须发 worker_done（硬约束，非可选）🚨🚨🚨

完成任何工作（commit / 报告生成 / 命令跑完）后，**第一步**就调：
\`orca orchestration send --to <协调者handle> --type worker_done --subject "<任务名>" --body "<产物路径 + 关键结果>"\`

🚫 禁止：在自己终端打印"完成"就 idle（这是最大反模式）
🚫 禁止：认为"任务轻量不需要回报"
🚫 禁止：忘记最后一步就退出
```

### delegate skill / 命令更新（建议沉淀）

`.claude/skills/delegate/SKILL.md` 强制校验清单应增加：

```markdown
- [ ] worker_done **已发**（不是"已 commit"！不是"已打印总结"！）
  - 验证方法：\`orca orchestration check --terminal <协调者handle>\` 看最新消息
  - 强制补救：若产物已存在但 worker_done 未到，协调者主动发"补发 worker_done"提醒
```

## 实证

### 案例 1：2026-08-02 P0-1~P0-5 修复（c4bc65e commit 已 push 但 worker_done 0 条）

| 阶段 | 事件 |
|---|---|
| 19:36 | v2 工人创建 + 注入精简 preamble |
| 19:38+ | v2 完成摸底 + 决议 + 注释 + commit + push |
| 03:41:14 | git commit c4bc65e 已 push |
| ?? | **v2 工人忘了发 worker_done**，回到 idle |
| ?? | 协调者 polling 5 分钟无响应 → 按 git 兜底判完成 |

教训：第一次观察到"工人完成不发 worker_done"，靠 git 兜底过去。

### 案例 2：2026-08-02 /quality-gate baseline 报告生成（连续第 2 次）

| 阶段 | 事件 |
|---|---|
| 19:49 | v3 工人创建 + 注入精简 preamble |
| 19:51+ | v3 完成：跑 /quality-gate + 生成 9021 字节报告到 `hermes/eagle-eye/reports/2026-08-02/quality-gate-baseline.md` |
| 03:52 | 文件存在 + 内容完整（3 段 + 总体判定 PASS + 10/10 API 端点 200） |
| ?? | **v3 工人同样没发 worker_done**，回到 idle |
| ?? | 协调者按 git/文件兜底判完成（再次！） |

报告关键内容（产物已生成但无 worker_done 回报）：
- 现实核查 PASS（带 verify 缺口标注）
- 安全扫描 0 P0 / 0 P1
- API 验证 10/10 通过
- 总体判定：✅ **PASS**

## 配套建议

### 1. delegate skill 强化

`.claude/skills/delegate/SKILL.md` 必须增加：
- "worker_done 是硬约束，不是软建议"
- 强调 "完成 ≠ 发了 worker_done"
- 提供"主动补救"动作清单

### 2. preamble 模板强化

`delegate.md` 命令的 preamble 模板末尾必须有 🚨🚨🚨 视觉警告，不能只是温和提醒。

### 3. 协调者侧监控

`/delegate` 命令执行时，协调者每 60s 应主动 ping 一次（不仅是 polling）：

```bash
# 在轮询循环里加 ping
for i in $(seq 1 5); do
  sleep 60
  # ... 现有 inbox 检测 ...
  # 新增：每 2 段（120s）主动 ping
  if [ $((i % 2)) -eq 0 ]; then
    orca terminal send --terminal $HANDLE --text "[ping] 你在吗？完成后请发 worker_done。" --enter
  fi
done
```

### 4. 产物路径校验作为完成信号

对于**不要求 commit + push** 的任务（如跑命令生成报告），产物文件存在性 = 完成的强证据：

```bash
# 协调者侧判完成函数
delegate_is_complete() {
    local product_path="$1"
    local start_ts="$2"
    
    # 1. 产物存在
    if [ -f "$product_path" ]; then
        echo "PRODUCT_EXISTS: $product_path"
        return 0
    fi
    
    # 2. git 新 commit
    local new_commit=$(git log --since="$start_ts" --oneline | head -1)
    if [ -n "$new_commit" ]; then
        echo "NEW_COMMIT: $new_commit"
        return 0
    fi
    
    return 1
}
```

## 总结

**worker_done 是协调者和工人之间的"完成握手信号"，不是可选汇报。**

连续 2 次观察到工人忘了发 worker_done → 必须升级为**硬约束**：
- preamble 视觉强化 🚨🚨🚨
- 协调者主动 ping（不是被动 polling）
- 产物文件存在性作为补充完成信号
- delegate skill 增加硬约束条款

**避免重复犯错的最佳方式**：让工人端 pi 看到 preamble 时**第一眼**就是 worker_done 必发的警告，而不是放在长文档末尾被忽略。

---

# 后续补充（v4 观察）：协调者代发机制 + polling 检测 bug 修复

## 案例 3：2026-08-02 /deep-inspect baseline（v4 工人）

### 现象

- v4 pi 工人（`term_d1cf25b4`）完成所有工作（产物到位：报告 12.6KB + 基线 JSON 3.1KB）
- v4 工人**仍没发 worker_done**（连续 3 次反模式）
- **但** Claude Code 协调者（`term_924cd402`）检测到产物到位 → **代发 worker_done**

```
2026-08-01T19:59:36  msg_61256f697b6e  from=term_924cd402  [deep-inspect] 首次巡检基线建立完成
2026-08-01T20:00:55  msg_c85610a32176  from=term_924cd402  [deep-inspect] ping#2 确认：已完成
```

### polling 检测 bug 表现

主会话使用过滤条件：
```python
relevant = [m for m in msgs if m.from_handle == 'v4_handle' AND created_at >= start_ts]
```

**结果**：0 条（误判“未完成”）

**原因**：v4 工人**确实没发**，但 Claude Code 代发 — from_handle 是 Claude 终端 ≠ v4 工人。

### 修复（已同步到 delegate/SKILL.md）

```python
# 不能只信 from_handle == 工人 handle
# 必须用 3 个 OR 条件：
n = sum(1 for m in msgs if isinstance(m, dict) and 
       m.get('type')=='worker_done' and 
       m.get('created_at','')>='$START_TS' and (
           m.get('to_handle','') == COORDINATOR_HANDLE or        # ① 发给协调者
           m.get('from_handle','') == COORDINATOR_HANDLE or       # ② 协调者代发
           TASK_KEYWORD in m.get('subject','') + m.get('body','')  # ③ 主题/正文含任务关键词
       ))
```

### 关键洞察

| 旧认知 | 新认知 |
|------|------|
| worker_done = 工人主动发的回报 | worker_done = 完成握手信号（可能工人发，可能协调者代发） |
| polling 只检查 from_handle | polling 必须检查 to_handle + from_handle + 关键词 |
| 协调者代发是兑底动作 | 协调者代发是**实际工作机制**（被观察 1 次实证） |

### 最终交付汇总（本日 4 派发）

| 派发 | 任务 | v4 工人 from | 实际 worker_done from | 产物 |
|:--:|---|---|---|---|
| v2 | P0 修复 | term_ec692feb（v2 pi） | （未发·按 git 兑底） | commit c4bc65e |
| v3 | quality-gate baseline | term_db7ce79e（v3 pi） | （未发·按产物兑底） | report 9021B |
| v4 | deep-inspect baseline | term_d1cf25b4（v4 pi） | **term_924cd402**（Claude 代发） | report 12.6KB + JSON 3.1KB |

**worker_done 实际发出率**：3/4 = 75%（其中 1 次由 Claude 协调者代发）

### 补充要点

1. **polling 检测修复已写入** delegate/SKILL.md（`createdAt` → `created_at`、加 to_handle + 关键词过滤）
2. **协调者代发可作为兑底机制** 不需要重构 — Claude Code 端已有判断能力
3. **pi 工人 worker_done 反模式依然存在** （连续 3 次） → 需要后续 /evolve 考虑更强约束（例：在 preamble 嵌入完整命令字串让 pi 复制）