# Orca pi 终端 7 分钟后 TUI 假死 — 派工兑底触发时机

## 现象

- 派工到 pi 终端（`orca terminal create --command "pi"`）
- 前 5-7 分钟：worker 正常发 heartbeat（`[task] heartbeat` / `[task] 进展`）
- 7 分钟以后：TUI 只显示 busy 字符 `⠙⠧⠇⠋⠸`，无新 heartbeat、buffer 被 trim、ping 无回应
- 实际 worker 可能仍在跑（或已僵死），但**协调者视角的判僵死信号全部触发**

## 时间线（本次实测 2026-08-02 test-all mes）

| 时刻 | 事件 |
|------|------|
| T+0s | 工人创建 + 注入 preamble |
| T+2:17 | 第 1 个 heartbeat（phase=investigating） |
| T+4:28 | 第 2 个 heartbeat（phase=testing） |
| T+7:01 | 第 3 个 heartbeat（API 9/12 pass, E2E 16/21 pass, 3 fail, 1 flaky, 1 not run） |
| T+8:00 | 协调者 ping #1（无回应） |
| T+12:00 | 协调者 ping #2（无回应） |
| T+14:30 | buffer trim + 仍 busy → 关闭僵死工人，兑底重派 |

## 根因（推测）

1. **TUI 渲染卡顿**：pi 终端 TUI renderer 在长时间运行后（>5 分钟）出现 busy spinner 循环但实际 worker 可能未真正卡死
2. **buffer trim 机制**：orca terminal 默认保留最近 ~2KB output，老内容被 trim 导致协调者看不到实际进度
3. **pi 启动 + 接收大消息延迟**：4-5 KB preamble 让 pi 启动耗时可能掩盖实际 worker 状态

## 触发僵死的硬条件（任意一个满足）

- [ ] preview 只显示 TUI busy 字符 > 5 分钟
- [ ] terminal read 返回 output 空（除 busy 字符外）
- [ ] 连续 2 次 ping (60s 间隔) 无回应
- [ ] buffer cursor 推进但内容仅 busy 字符（说明在 trim）

## 兑底动作（更紧凑）

| 阶段 | 动作 |
|------|------|
| T+0 | 派工 + START_TS 记录 |
| T+60s | 第 1 次轮询（看 heartbeat） |
| T+120s | **第 1 次 ping**（早于原 v4 建议的 240s） |
| T+180s | 第 3 次轮询 |
| T+240s | **第 2 次 ping** |
| T+300s | 判僵死条件 → 触发兑底 |
| T+305s | 关闭僵死工人 |
| T+310s | 协调者亲自跑 OR 精简 preamble 重派 |

## 与 v4 delegate skill 的差异

**v4 建议**：每 60s 轮询 + 每 120s (2 段) ping
**本踩坑建议**：每 60s 轮询 + 每 60s (1 段) ping + 7 分钟硬上限

理由：
- v4 的 120s 间隔对常规 30 分钟任务合适
- 但 pi 终端 7 分钟即可能假死 → 第 1 次 ping 应在 T+60s 而非 T+120s
- 7 分钟硬上限是经验值，非严格规则——实际看 worker 实际活动频率

## 派工场景的硬约束升级

```bash
# 优化版轮询（取代 v4 的"每 2 段 ping"）
for i in $(seq 1 5); do
  sleep 60
  # 看 inbox
  orca orchestration inbox --json > /tmp/inbox.json
  # 看 preview
  HAS_DONE=$(check_worker_done)
  [ "$HAS_DONE" != "0" ] && break
  # 升级：每 60s ping（而非 v4 的每 120s）
  orca terminal send --terminal $HANDLE --text "[ping #${i}] 进度？完成请发 worker_done" --enter
done
```

## 协调者亲自跑的兑底选择（新增）

按 v4 skill，重派（开新工人）是默认兑底。但本次发现：

| 场景 | 重派风险 | 亲自跑优势 |
|------|---------|----------|
| 任务 < 5 分钟 | 低 | — |
| 任务 5-15 分钟 | 中（可能再僵死） | 协调者上下文完整、可控 |
| 任务 > 15 分钟 | 高 | 强烈建议亲自跑或拆分 |

**新规则**：如果任务在 < 15 分钟内可完成且**不需要 worker 独立上下文**（如单纯跑命令），协调者亲自跑优于重派。

## 配套改进

- delegate/SKILL.md：polling 间隔从 120s 缩短到 60s
- delegate/SKILL.md：新增"7 分钟僵死硬上限"作为兑底触发条件
- delegate/SKILL.md：协调者亲自跑兑底作为重派的替代选项

## 防僵死 preamble 补充（来自 v4，未变更）

- preamble 精简到 < 8000 字节（本次 4872 字节，已合规）
- 明确禁止 `orca orchestration check --wait` 阻塞
- 强制 worker_done 协议 + 完整可复制命令字串

## 验证标准

下次派工如观察到：
- [ ] pi 终端 7 分钟内不发新 heartbeat → 立即触发 ping
- [ ] 2 次 ping 后无回应 → 关闭 + 兑底（亲自跑或重派）
- [ ] 协调者亲自跑后 5 分钟内出报告 → 视为兑底成功

## 相关 learnings

- learnings/2026-07-21-orca-coordinator-no-check-wait.md（check --wait 反模式）
- learnings/2026-08-02-delegate-worker-done-must-emit-hard-rule.md（worker_done 硬约束）
- learnings/2026-08-02-delegate-worker-rebaseline-and-git-fallback.md（工人摸底 + git 兜底）