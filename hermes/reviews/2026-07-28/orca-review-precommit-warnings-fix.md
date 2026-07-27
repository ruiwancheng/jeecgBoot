# Orca 评审：pre-commit-check 提醒失效修复方案

**评审对象**：`.claude/hooks/pre-commit-check.sh` — 7 处提醒 stdout 不送达 AI 的修复方案
**评审日期**：2026-07-28
**评审人**：Claude Opus（Orca 独立终端 dispatched worker）

---

## 一、通过 ✅

### 1. WARNINGS 累加器模式可行，需注意一处子 shell

已读脚本全文（273 行），逐行追踪变量作用域。

**脚本中仅 2 处管道 `while read`（运行于子 shell）：**

| 行号 | 写法 | 子 shell？ | 变量写入安全？ |
|:--:|------|:--:|:--:|
| L127 | `echo "$VAR" \| while read f; do ... done` | ✅ 是 | ❌ 子 shell 内写入会丢失 |
| L149-157 | `while IFS= read -r file; do ... done <<< "$VAR"` | ❌ 否（here-string） | ✅ 当前 shell |
| L265 | `echo "$VAR" \| while read f; do ... done` | ✅ 是 | ❌ 同 L127 |

**方案评估**：7 处提醒点的 WARNINGS 追加都在顶层（当前 shell），不在 L127/L265 的管道 while 循环内。唯一需要在子 shell 中追加的场景是 L127 或 L265 内部——但当前方案不需要，提醒是整块追加的。

**建议**：如果未来需要在 L127 或 L265 的 while 循环内追加 WARNINGS，改用进程替换 `< <(echo "$VAR")` 保持当前 shell。当前方案不受影响。

### 2. additionalContext 模式已有实证背书

已验证 3 个兄弟钩子的实现：

| 钩子 | additionalContext 方式 | 状态 |
|------|----------------------|:--:|
| `pre-write-check.sh:62` | 裸 `echo` 硬编码 JSON 字符串（无需 python） | ✅ 已实测 |
| `pre-plan-check.sh:115-120` | python `json.dumps` + 环境变量传值 | ✅ 已实测 |
| `pre-deploy-check.sh:89-96` | python `json.dumps` + 环境变量传值 | ✅ 已实测 |

`pre-commit-check.sh` 当前不 source `_os-detect.sh`，也没有 `PYTHON`/`PY_CMD` 变量。如果采用 python 方式发射 additionalContext（类似 pre-plan-check），需要先加 2 行 python 探测。如果采用裸 `echo` 方式（类似 pre-write-check），则无需 python 依赖——但需要对 WARNINGS 内容做转义。

**推荐**：加 python 探测 + 用 python json.dumps（安全转义），替代裸 echo（特殊字符风险）。成本 2 行 python 探测 + 3 行 JSON 发射。

### 3. L52 的 REMOVE_PERM_BLOCK 独立变量方案正确

**问题确认**：
```
L43  REMOVED_PERM=$(git diff ...)
L48  if [ -n "$REMOVED_PERM" ]; then
L52    QUALITY_GATE_BLOCK=1    ← 设阻断标记
L53  fi
...
L138 QUALITY_GATE_WARN=0
L139 QUALITY_GATE_BLOCK=0     ← 🔴 抹掉了 L52 的阻断标记！
L140
L141 # 后续质量门控 P0 检查（硬编码密钥/SQL拼接/XML ${}）重新设 QUALITY_GATE_BLOCK
```

**时序分析**：L52 在质量门控段之前设置 `QUALITY_GATE_BLOCK=1`，L139 将其重置为 0，然后 L171/L179/L190 可能重新设回 1。但如果**只有移除 @RequiresPermissions 触发**（无其他 P0），阻断会被无声抹掉——`@RequiresPermissions` 移除检测形同虚设。

**方案「独立变量 REMOVE_PERM_BLOCK + 最终合并」**：正确的解耦方案。将移除注解检测的阻断标记与质量门控的阻断标记分开，在最终判定处合并。这也方便未来增加其他前置检测。

**替代方案比较**：

| 方案 | 优点 | 缺点 |
|------|------|------|
| A. 移 L138-139 到 L40 之前 | 最简单，1 行改动 | 初始化远离使用点，后人可能重新插入 |
| B. 删除 L138-139（已无用） | 干净 | L138-139 本身在质量门控段有意义（初始化该段的变量） |
| **C. REMOVE_PERM_BLOCK 独立变量** | **解耦清晰，未来可扩展** | 多一个变量名 |
| D. 在 L195 之前统一 `QUALITY_GATE_BLOCK=$((QUALITY_GATE_BLOCK || REMOVE_PERM_BLOCK))` | 兼顾 | 变量在 L138-139 被重置前需先保存 |

**推荐**：方案 C（REMOVE_PERM_BLOCK）+ 在 L195 处合并：`QUALITY_GATE_BLOCK=$((QUALITY_GATE_BLOCK || REMOVE_PERM_BLOCK))`。

---

## 二、遗漏 ⚠️

### 漏-1 (P0)：pre-commit-check.sh 无 PYTHON 探测——additionalContext 发射需要 python

脚本全文无 `source _os-detect.sh`、无 `PYTHON`/`PY_CMD` 定义。如果照搬 pre-plan-check 的 `$PYTHON -c "..."` 模式发射 additionalContext，会因 `$PYTHON` 未定义而报错。

**修复**：在脚本顶部（L4 附近）加 2 行 python 探测：
```bash
PYTHON=$(command -v python3 || command -v python || echo python)
$PYTHON --version >/dev/null 2>&1 || PYTHON=$(command -v python || echo python)
```

**注意**：如果 python 最终也不可用（`PYTHON=python` 字面量），additionalContext 发射会失败但不应阻断提交——此时退化为旧行为（提醒不送达 AI）。实现上应在 python 不可用时跳过 additionalContext 输出。

### 漏-2 (P1)：L265 管道 while read 的子 shell — `/verify 提醒框`的提示语不准确

L265 提示文本写的是 `printf "[Super Harness] ║    %-36s ║n" "$f"`（注意：`║n` 而非 `║\n`），缺少反斜杠导致 `n` 被当成字面字符输出。对比 L127 的正确写法 `printf "[Super Harness] ║    %-40s ║\n"`。虽然这不属于"提醒不送达"问题，但属于同一终态提醒的 bug。

### 漏-3 (P1)：方案未覆盖"python 不可用"的退化路径

如果 python3 是 stub + python 也不存在，`PYTHON=python` 字面量，执行 `$PYTHON -c "..."` 会报错。方案需要守卫：`command -v "$PYTHON" >/dev/null 2>&1` 或 `type "$PYTHON" >/dev/null 2>&1` 检查后才尝试发射 additionalContext。

pre-plan-check 和 pre-deploy-check 的相同风险也未被守卫（因为它们 source 了 python 探测，但没检查最终 PYTHON 是否可执行）。

### 漏-4 (P2)：compat-check 需要追加 stub 检测规则

本次修复暴露的 `python3 stub` 是跨平台兼容性问题。`compat-check/SKILL.md` 的 P0 级检测项缺少：

| # | 检测项 | grep 模式 |
|---|--------|----------|
| 新 | 裸 python3 调用无 stub 检测 | `grep -rn 'python3' --include='*.sh' hooks/` 排除含 `--version` 实测的行 |

---

## 三、建议 💡

### 建议-1：通过/遗漏/建议 三段式，写到 hermes/reviews/2026-07-28/orca-review-precommit-warnings-fix.md

### 建议-2：回答待评审的 5 个问题

**Q1: WARNINGS 累加器在 while read 管道中有作用域陷阱吗？**

当前方案的 7 处追加点都在顶层（不在管道 while 内），不受影响。但如果未来在 L127 或 L265 的管道内追加，需要改为 `< <(echo "$VAR")` 进程替换。**建议在脚本注释中标记这两处管道，防止后人踩坑。**

**Q2: L52 bug 修法是否最优？**

方案 C（REMOVE_PERM_BLOCK 独立变量）是最优的。不推荐直接删除 L138-139，因为那两行对质量门控段本身有意义（初始化该段变量）。也不推荐移动 L138-139 到 L40，因为重复初始化是防御性编程的好实践——问题不在于有初始化，而在于初始化抹掉了前置逻辑的写入。

**Q3: /verify 提醒（#4 L122-131 和 #7 L261-270）应合并吗？**

不完全重叠。L122-131 是 `/verify` **证据缺失**（.last-verify 过期或不存在），L261-270 是 `/verify` **完成提醒**（仅提示该做了）。前者是前者的事实判断（文件过期），后者是通用提示。但两者共享相同的条件（Java/Vue 变更 + 8080 在线），确实有冗余。**建议**：保留 L122-131（有事实依据），将 L261-270 简化为一条 WARNINGS 行（去掉重复的盒子画框）。合并后的 WARNINGS 可以是一条 "后端在线 + 代码变更 → 建议运行 /verify"。

**Q4: additionalContext 有长度限制吗？**

已查 pre-plan-check 的 additionalContext 包含 ~20 行带框文本（约 1500 字符），实测送达正常。7 条精简 WARNINGS（每条约 80-120 字符）总计 < 1000 字符，远在安全范围内。Claude Code 2.1.218 对 additionalContext 没有已知的长度截断。

**Q5: 有无遗漏的提醒点？**

已读全文 273 行，发现以下额外提醒输出（全部走 stdout，当前 AI 看不到）：

| 行号 | 内容 | 严重度 |
|:--:|------|:--:|
| L44-46 | 移除 @Transactional 提醒 | P1 ⚠️ |
| L48-52 | 移除 @RequiresPermissions 提醒 + QUALITY_GATE_BLOCK | P0 🔴 |
| L117 | .last-verify 过期提醒 | P1 ⚠️ |
| L122-131 | /verify 证据缺失框 | P0 🔴 |
| L159-161 | 新方法缺 @RequiresPermissions | P1 ⚠️ |
| L202-203 | 质量门控 WARN 判定 | P1 ⚠️ |
| L237-242 | c_mes_ 表字典反模式提醒 | P1 ⚠️ |
| L261-270 | /verify 完成提醒框 | P2 🟡 |

共找到 **8 处**（比用户报的 7 处多 1 处：L202-203 质量门控 WARN 判定）。

**遗漏的 L202-203**：
```bash
echo "[Quality Gate] 🟡 判定：WARN — 建议运行 /quality-gate 检查"
```
这条在 `QUALITY_GATE_BLOCK=0 && QUALITY_GATE_WARN=1` 时输出。当前 `additionalContext` 方案只计划在 WARNINGS 累加器中追加，文末统一发射。但 L202-203 已经在 exit 之前——如果 exit 2 走阻断分支（L200），则不会到 WARN 分支。如果走 WARN 分支（L201-203），这行同样不会被 AI 看到。应该也加入 WARNINGS 或改为 additionalContext。

### 建议-3：简化 additionalContext 发射——用裸 echo 而非 python

对比 pre-write-check.sh 的做法（L62），最简单的 additionalContext 发射无需 python：

```bash
if [ -n "$WARNINGS" ]; then
  # WARNINGS 是单行汇总（合并为一行，避免 JSON 转义问题）
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"[Super Harness] 提交前检查提醒: ${WARNINGS}\"}}"
fi
exit 0
```

前提是 WARNINGS 内部控制为单行（用 `; ` 分隔，而非换行）。这样：
- 零额外依赖（不需要 python）
- 零 stub 风险
- 比 python json.dumps 的 3 行模式更轻

**但**：如果有中文或特殊字符，需要验证 double-quote 在 JSON 中的转义。pre-write-check 已经证明裸 echo 可行（even with emoji ⚠️）。

### 建议-4：L138-139 应加注释说明初始化范围

```bash
# 质量门控段变量初始化（注意：不重置 QUALITY_GATE_BLOCK，因为前置的移除-注解检测可能已设置）
QUALITY_GATE_WARN=0
```

或者将 L138-139 改为：
```bash
# 仅初始化质量门控段特有变量（QUALITY_GATE_BLOCK 可能已被前置检查设置）
QUALITY_GATE_WARN=0
```

---

## 总结

| 维度 | 判定 |
|------|:--:|
| WARNINGS 累加器方案 | ✅ 通过 — 7 处都在顶层，无子 shell 陷阱 |
| L52 独立变量修复 | ✅ 通过 — 解耦优于移初始化 |
| additionalContext 机制 | ✅ 通过 — 三个兄弟钩子已实证 |
| python 探测缺失 | ⚠️ 遗漏 — pre-commit-check 无 PYTHON，需补 2 行探测或改用裸 echo |
| 提醒点盘点 | ⚠️ 遗漏 — L202-203 质量门控 WARN 未列入（实为 8 处非 7 处） |
| python 退化路径 | ⚠️ 遗漏 — python 不可用时需 skip additionalContext |
