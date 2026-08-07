# code-review-graph MCP 不可用 → 派 Claude subagent（用户明确要求）

**触发条件：** claude-code-graph MCP 工具在当前会话中不可用（不在工具列表 / capability_hash revoked / server 挂了）。

**处理方式：**
1. **禁止静默降级到 Grep/Read**（违反 project instructions，会让用户失去架构感知能力）。
2. **改派 Claude subagent**：用 `orca orchestration task-create + dispatch` 把调研任务派给 Claude 终端（`term_20ea31ad-*` 系列），Claude 自带 MCP，可深度分析。
3. **subagent 工具失败时降级**：`subagent` 工具偶尔"成功但未注入" → 改用 `orca terminal send --text "..." --enter` 直接 inject 任务到 Claude 终端。
4. **回报机制**：subagent 通过 `orca orchestration send --task <id> --to run:<id> --type worker_done` 回报；用 inbox 轮询拿结果。
5. **如 MCP 仍报不可用**：subagent 内部也用 Read/Grep，但报告时明确标注"X MCP 工具调用次数 = 0（不可用）"。

**实证：** 2026-08-06 回归测试体系整合 brainstorm 阶段，第一轮 Claude 完整跑（19 MCP 调用，0 降级），输出 11 节深度报告；第二轮用户修复 MCP 后复用同一流程。

**配套：** 用户偏好（2026-08-06）"派发子任务可参考 orca-review 命令"——`orca terminal list` 找 Claude 终端 → `task-create` → `dispatch --inject`。