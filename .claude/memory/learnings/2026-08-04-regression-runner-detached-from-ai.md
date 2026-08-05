# regression runner 必须脱离 Orca/AI 终端进程树

**触发条件：** Orca 控制会话被重置、Pi 终端 TUI 卡住、用户关闭 IDE/VSCode 窗口、Win11 突然重启或更新——任何让 AI 主进程消失的场景。

**处理方式：**
1. **永远不在 AI 终端前台跑测试**。测试必须由 `subprocess.Popen(... DETACHED_PROCESS / CREATE_NEW_PROCESS_GROUP ...)` 启动，runner 写入 `state.json` 和 `telemetry.jsonl`。
2. **测试期间禁止假设 runner 还活**。每个切片结果都先落盘再返回，状态读 `state.json` 而不是 runner 进程。
3. **心跳要能跨会话**：每 ~5 秒把 `(runner_pid, current_slice, services)` 写入 `telemetry.jsonl`，主会话通过 `status` 子命令只读盘。
4. **状态写必须原子**：Windows 上 `os.replace` 会被 ESET / OneDrive / 杀毒软件短期占用，必须有 `.tmp → os.replace → 失败后写 state.json.fallback` 三级降级。
5. **重启时 `recover_interrupted_state`**：把 `status=running` 的切片统一改写为 `interrupted`，写入 `last_attempt_at`，再走正常 resume 流程，避免“已死 runner 的子进程被判为 fresh start”。

**实证：** 2026-08-04 一次回归被 4 次“看起来卡住/已崩溃”打断，每次都是用 runner 状态从 `20260804-040224/` 恢复，最终跑完 14 个切片、0 个环境阻断、0 个产品误判。

**配套：** `harness/scripts/resilient_regression.py` 公共命令 `start / run / resume / status / stop / report / dashboard`，必须保留 `start --dashboard` 让用户直接拿到 URL。
