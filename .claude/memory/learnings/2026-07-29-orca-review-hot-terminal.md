# orca-review 必须复用热 Claude 终端，不可直接 create

**场景**：执行 orca-review 时，直接 `orca terminal create --command "claude"` 新建终端 + `terminal send` 文本注入。skip 了 SKILL.md 步骤 2a「找到 Claude 终端（热终端复用）」。

**根因**：混淆了两种场景：
- `/delegate` preamble：跨 worktree，强调"创建独立 Claude 评审终端"
- `orca-review/SKILL.md`：同 worktree 内评审，强调"复用热终端，已验证同一终端可多次 dispatch"

**正确流程**：
```bash
# 1. 先查热终端
orca terminal list --json
# 找到 title 含 "Claude" 且 writable=true 的 handle

# 2. 有 → dispatch --inject（优先）
orca orchestration task-create --spec "..." --task-title "review-xxx"
orca orchestration dispatch --task <id> --to <handle> --inject

# 3. 没有 → 再 create（降级）
orca terminal create --worktree active --command "claude"

# 4. orchestration 不可用 → terminal send 到已有终端（最终降级）
orca terminal send --terminal <handle> --text "..." --enter
```

**判断信号**：评审结果正常返回但执行方式不对 → 查 `terminal list` 历史，如有可用 Claude 终端就是跳了步骤 2a。

**实证**：2026-07-29 `/business-description` 方案 orca-review 时跳过步骤 2a 直接 create，用户指出后修复。
