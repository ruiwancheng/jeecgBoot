---
name: hook-authoring
description: 钩子编写规范——Claude Code 钩子协议、提醒可达性模式、Windows python 三陷阱（2026-07-28 四次静默失效事故的固化）
glob: ".claude/hooks/*.sh"
version: 1.0
---

# 钩子编写规范

> 来源：learnings/2026-07-28-claude-code-hook-protocol.md + hook-warnings-accumulator-pattern.md。
> 协议以安装包二进制实证为准（Claude Code 2.1.218），不凭记忆写。

## 阻断协议（硬约束）

- **只有 `exit 2` 阻断**——stderr 内容反馈给 AI。`exit 1` 只是非阻断错误，"硬阻断"写 exit 1 等于没写
- **禁止 `{"action":"block"}` 旧格式**——不被识别。结构化判定用 `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}`
- 阻断时原因必须走 **stderr**（exit 2 时 stdout 不送达 AI）

## 提醒可达性（不阻断时）

- **exit 0 的 stdout 不送达 AI**（仅 ctrl+o verbose 可见）
- 提醒用 WARNINGS 累加器 + 文末统一发射：
  - 内容受控（单行、无双引号）→ 裸 echo `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"..."}}`，零依赖
  - 内容不可控（含 diff 原文/用户输入）→ python `json.dumps` 转义
- 多提醒点共享触发条件时合并为一条，防重复

## Windows python 三陷阱（钩子静默失效首因）

1. **WindowsApps `python3` 是商店占位 stub**——`command -v` 能找到但执行 exit 49 零输出。探测必须 `--version` 实测：`PYTHON=$(command -v python3 || command -v python || echo python); $PYTHON --version >/dev/null 2>&1 || PYTHON=$(command -v python || echo python)`
2. **GBK 默认编码**——print/写文件含中文或 emoji 直接 UnicodeError。钩子首部 `export PYTHONIOENCODING=utf-8`，`open()` 显式 `encoding='utf-8'`
3. **bash `true` ≠ Python `True`**——bash 变量插值进 Python 代码会 NameError，在 bash 侧先转成 Python 字面量

## 脚本控制流自检（每个环节问：失败时它真的会失败吗）

- `cmd | tail; EXIT=$?` 取的是管道末尾退出码 → 用 `${PIPESTATUS[0]}`
- `grep -c` 无匹配时输出 0 且 exit 1，`|| echo 0` 会追加第二个 0 → 用 `|| true`
- **跨段共享标记用独立变量名**——段内初始化（`A=0`）会抹掉前置写入（`A=1`），最终判定处合并
- 验证脚本必须消费输入做真实断言——无条件 `print("OK")` 的验证器恒真，等于没验证

## 测试钩子

构造 stdin JSON 管道输入 + 断言 exit code + 断言 stdout/stderr 去向；该成功和该失败的路径各测一次。`bash -x` 可追踪变量插值实际结果。
