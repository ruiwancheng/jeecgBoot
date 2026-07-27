# [2026-07-28] [Harness] Claude Code 钩子协议四层坑——硬阻断全部静默失效

## 触发条件
排查 /learn 死循环时顺带审计 `.claude/hooks/`，对照 Claude Code 2.1.218 二进制验证协议。

## 四层坑（按危害排序）

### 1. `exit 1` 不阻断（最坑）
Claude Code PreToolUse 协议：**只有 exit 2 才是阻断**（stderr 反馈给 AI），exit 1 只是非阻断错误。
项目里 7 处"硬阻断"全写 exit 1 → 保护目录写入、/plan 缺失、SQL DROP、质量门控 BLOCKED **从未真正拦过任何东西**。
**正确姿势：** `echo "原因" >&2; exit 2`

### 2. `{"action":"block"}` JSON 格式不被识别
这是早期臆造格式。现行协议（2.1.218 二进制实证）：
- 阻断：`exit 2` + stderr，或 `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}`
- 提醒送达 AI：`{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"..."}}`
- **PreToolUse exit 0 的 stdout 不会送达 AI**（只在 ctrl+o verbose 可见）——所有"提示型"钩子输出必须用 additionalContext

### 3. Windows python 三重陷阱（ hooks 集体静默失效的真凶）
- **WindowsApps python3 是商店占位 stub**：`command -v python3` 存在但执行退出码 49 无输出。`PYTHON=$(command -v python3 || ...)` 必须再补 `$PYTHON --version` 实测
- **GBK 默认编码**：print/写文件含中文或 emoji → `UnicodeEncodeError`。钩子首部加 `export PYTHONIOENCODING=utf-8`，`open()` 显式 `encoding='utf-8'`
- **bash `true` ≠ Python `True`**：bash 变量直接插值进 Python 代码 → NameError，被 `2>/dev/null` 吞掉 → jsonl 两年没写进去一条

### 4. 管道退出码
`cmd | tail -20; EXIT=$?` 取的是 tail 的退出码，被测命令失败永远检测不到 → 用 `${PIPESTATUS[0]}` 或先捕获输出。

## 处理方法
2026-07-28 已修复全部 6 个钩子文件，逐分支实测（exit 码 + stderr + JSON 合法性）。

## 排查方法论（可复用）
1. 不信文档，grep 安装包二进制验证协议字符串（`grep -a -o 'pattern' claude.exe`）
2. 钩子测试 = 构造 stdin JSON 管道输入 + 断言 exit code + 断言 stdout/stderr 去向
3. `bash -x` 追踪插值结果——本次 NameError 就是 trace 里看到 `true == 'true'` 才定位的
