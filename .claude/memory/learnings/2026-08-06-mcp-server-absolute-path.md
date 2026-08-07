---
name: mcp-server-absolute-path
description: .mcp.json 里 MCP server 的 command 必须用绝对路径，PATH 截胡导致包找不到
metadata:
  type: reference
---

# MCP server command 必须用绝对路径

## 问题

`.mcp.json` 配 MCP server 时，如果 `command` 填可执行文件名（如 `python` / `python3` / `python3.11`），会被系统 PATH 截胡到**第一个命中的同名解释器**，但这个解释器**不一定装了所需的包**。

macOS 用户通常装了多个 Python（homebrew / pyenv / 系统 Python / ~/.local 私装），PATH 第一个命中 ≠ homebrew 那个 ＝ 包安装位置不一致。

## 实证（2026-08-06 修复历程）

3 次改 `.mcp.json` 才定位根因：

| 次数 | command | 结果 |
|:---:|---------|------|
| 1 | `python` | ❌ `python` 不在 PATH → silent fail |
| 2 | `python3.11` | ❌ PATH 命中 `~/.local/bin/python3.11`，**没装 code_review_graph** → `ModuleNotFoundError` → 进程秒退 → MCP 工具不注入 |
| 3 | `/opt/homebrew/bin/code-review-graph` + `args: ["mcp"]` | ✅ 绝对路径绕过 PATH，CLI 已被 install 自校验可用 |

## 诊断信号

如果全部命中以下条件，问题 99% 在此：

1. `/capability-check` 报 MCP 不可用
2. `code-review-graph status` 显示图谱健康（26600+ 节点）
3. 直接跑命令（如 `/opt/homebrew/bin/code-review-graph mcp`）能启动 MCP server
4. Claude Code 重启后依然**无任何 `mcp__*__*` 工具**
5. Claude Code 无报错日志（stdio MCP silent fail）

**Why:** MCP server 启动失败时 Claude Code 走 stdio 协议层，进程秒退不影响 Claude Code 主进程，但它**也不会自动报错**，工具列表自然为空。

## 解决

`.mcp.json` 用绝对路径 + args 直传子命令：

```json
{
  "mcpServers": {
    "code-review-graph": {
      "command": "/opt/homebrew/bin/code-review-graph",
      "args": ["mcp"],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

修改后**完全退出 Claude Code 重开**才会生效 ——`/exit` 不够，必须整个 app 重启才能让 MCP server 重新拉起。

## 修复流程（4 步）

```bash
# 1. 找出可执行的绝对路径
which code-review-graph
# /opt/homebrew/bin/code-review-graph

# 2. 验证该路径独立可启动 MCP
/opt/homebrew/bin/code-review-graph mcp --help
# 应该看到 usage 行（不是 ModuleNotFoundError）

# 3. 改 .mcp.json 用绝对路径
# command: 绝对路径
# args: ["mcp"] 或直接子命令

# 4. 完全退出 Claude Code 重开
```

**How to apply:** 任何新增/修改 `.mcp.json` 时，`command` 字段**永远填绝对路径**，不写 `python` / `python3` / `node` / `npx` 等可被 PATH 截胡的命令名。如需传 CLI 子命令，用 `args` 数组而不是 `-c` 模式。

## 反模式

- ❌ `python3.11 -m code_review_graph serve` —— 双重不确定：PATH 不对 + 包可能没装
- ❌ `npx some-package` —— npm 全局包 vs 项目 node_modules 哪个命中说不清
- ❌ 反复改 `python3` → `python3.11` → `python3.12`，猜下一个 PATH 命中
- ❌ `pip install` 给错误的解释器装包（不解决根因，只是临时迁就）
- ❌ 静默降级走 Grep/Read —— 失去架构感知能力不可恢复
