# [2026-07-28] [Harness] 钩子提醒可达性模式 + 变量初始化覆盖坑

## 触发条件
Claude Code 钩子需要在**不阻断**的情况下把提醒送达 AI（exit 0 时 stdout 只有 verbose 可见）。

## 模式：WARNINGS 累加器 + 文末裸 echo additionalContext
```bash
# 顶部
WARNINGS=""
# 各提醒点（受控单行文本、不含双引号、; 分隔）
WARNINGS="${WARNINGS}检测到 XX 问题; "
# 文末（exit 0 前）
if [ -n "$WARNINGS" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"[Super Harness] 提醒: ${WARNINGS}\"}}"
fi
exit 0
```
- **裸 echo 优于 python json.dumps**：零依赖、零 python3 stub 风险——但前提是累加内容受控（无双引号/换行），否则会破坏 JSON
- 内容不可控（含用户输入/diff 原文）时才用 python json.dumps（配 PYTHONIOENCODING=utf-8）
- 多个提醒点共享触发条件时合并为一条，防重复提醒

## 坑：变量初始化写在使用之后
`A=1`（L52 前置检测设阻断标记）→ 后段 `A=0`（L139 段内初始化）→ 阻断被静默抹掉。
**规则**：跨段共享的标记用**独立变量名**（REMOVE_PERM_BLOCK），最终判定处合并；段内初始化只覆盖段内变量，并加注释"勿把前置标记纳入重置"。同类：grep -c 无匹配时输出 0 且 exit 1，`|| echo 0` 会追加第二个 0 → 用 `|| true`。

## 关联
- ✅ 已覆盖: 2026-07-28-claude-code-hook-protocol.md（exit 码协议基础）
- 实证: pre-commit-check.sh 2026-07-28 修复 + orca-review-precommit-warnings-fix.md
