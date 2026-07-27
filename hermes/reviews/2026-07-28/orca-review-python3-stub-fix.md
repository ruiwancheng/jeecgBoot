# Orca 评审：python3 stub 修复方案

**评审对象**：5 个 SKILL.md 共 7 处 `PY_CMD` 探测的 2 行实测过滤修复方案
**评审日期**：2026-07-28
**评审人**：Claude Opus（Orca 独立终端 dispatched worker）

---

## 一、通过 ✅

### 1. 方案逻辑正确，与钩子修复一致

7 处统一替换为：
```bash
PY_CMD=$(command -v python3 || command -v python || echo python)
$PY_CMD --version >/dev/null 2>&1 || PY_CMD=$(command -v python || echo python)
```

已读全部 5 个 SKILL.md 完整上下文（human-gate L83-95、chain-test L44-52+L86-91、test-loop L27-49+L56-63、deploy-verify L77-89、visual-check L122-148），确认：

- **每处用法相同**：都是 `$PY_CMD -c "import sys,json; ..."` 模式，python 被用于 JSON 解析/脚本执行
- **风险面相同**：stub 产生空输出 → 下游语义被扭曲（"无数据""无差异""PENDING"）
- **修复已证明有效**：同款 2 行模式在 `session-start.sh`、`pre-plan-check.sh`、`pre-deploy-check.sh`、`post-tool-failure.sh` 四个钩子上跑过 exit code + JSON 合法性逐分支验证

### 2. 两行过滤模式边界行为可接受

| 边界场景 | 行为 | 结果 |
|----------|------|------|
| python3 真实可用 | `$PY_CMD --version` 成功 → 不触发 fallback | ✅ python3 |
| python3 是 stub | `--version` 退出 49 → fallback 到 `command -v python` | ✅ python (真实) |
| python3 stub + python stub | `--version` 两次失败 → `PY_CMD=python` 字面量 | ✅ 后续 `$PY_CMD -c` 报 "python: command not found"，**AI 可见错误** |
| 两个都真实不存在 | `command -v` 全失败 → `PY_CMD=python` → 报错 | ✅ 同上，可见 |
| 只有 python 真实（无 python3） | 第一行 `command -v python3` 失败 → `PY_CMD=python` → `--version` 成功 | ✅ python |

关键设计优点：**fail-loud 而非 fail-silent**。最坏情况 `PY_CMD=python`（字面量），执行时报 bash 错误，AI 必然看到。对比当前的单行 `command -v ||` 模式——stub 通过存在性检查后静默产出空 JSON → AI 误读。

### 3. human-gate 注释修正正确

```diff
-# Windows: python3 → python（Git Bash 下 python3 不存在）
+# Windows: python3 可能是 WindowsApps 商店占位 stub（command -v 能找到但不可执行）
```

旧注释归因错误（暗示 Git Bash 缺少 python3），新注释描述真实根因（stub 存在但不可执行）。对 AI 理解上下文有帮助。

---

## 二、遗漏 ⚠️

### 漏-1 (P0)：orca-review/SKILL.md:67 — 裸 `python3` 无任何探测

```bash
orca terminal list --json | python3 -c "
```

这是 `.claude/skills/orca-review/SKILL.md` 第 67 行。**没有任何 `command -v` 或 `PY_CMD` 包装**，直接硬编码 `python3`。Windows stub 场景下：
- `python3` → stub 退出 49，stdout 空 → `orca terminal list` 的 JSON 输出被丢弃
- AI 拿到空输出会认为"没有终端可用"，误判 Orca 未运行
- orca-review 是 `/plan` 后的关键评审环节，阻塞会导致整个工作流停滞

**建议**：纳入本轮修复范围，统一改为 2 行 `PY_CMD` + 过滤模式。

### 漏-2 (P1)：github-harness-scan/SKILL.md — 3 处裸 `python3` 调用脚本

第 59、66、73 行：
```bash
python3 hermes/tasks/scripts/github_harness_scan.py
python3 hermes/tasks/scripts/github_harness_scan.py 3
```

这些调用独立 Python 脚本（非内联 `-c`）。stub 场景下：
- `python3 script.py` → 退出 49，stdout/stderr 空
- AI 看到"脚本执行完成，无输出" → 误判扫描结果为空（"未找到仓库"）
- 不同于内联模式的 JSON 解析失败，这里是整个脚本静默失败

**建议**：改为 `$PY_CMD hermes/tasks/scripts/github_harness_scan.py` 并在前加入 2 行探测。

### 漏-3 (P2)：jimubi-bigscreen & jimubi-dashboard — 多处裸 `python3` + 文档说明依赖人工切换

这些技能在代码块中直接写 `python3 references/scripts/xxx.py`，并在文档中注明"Windows 用户改为 `py`"。这是**文档级降级**（依赖人记得切换），而非**代码级降级**（自动探测）。

jimubi-dashboard 的 `references/pitfalls.md:106` 已记录了这个问题：
> Windows 无 python3 命令，必须用 `py`

但记录在 pitfall 文档中不等于修复在代码块中。用户/Windows AI 执行这些技能时仍需人工注意。**属于低优先级，因为这些技能直接执行的是磁盘上的 .py 脚本（有 shebang `#!/usr/bin/env python3`），且 Windows 上 `py` launcher 是更可靠的方案。**

### 漏-4 (P2)：compat-check 的检测矩阵缺 python3 stub 条目

`compat-check/SKILL.md` 定义了 15 条跨平台检测规则（P0 8 项 + P1 4 项 + P2 3 项），但**没有一条检测 `python3`/`python` 硬编码或 stub 模式**。修复完这批 skill 后，应追加一条规则以防止回归：

| # | 检测项 | grep 模式 | 说明 |
|---|--------|----------|------|
| 16 | 裸 `python3` 调用无探测 | `grep -rn 'python3 -c\|python3 ' --include='*.md' skills/` | 排除含 `PY_CMD\|PYTHON` 或 `command -v python` 的行 |

---

## 三、建议 💡

### 建议-1：内联两行是最佳选择，不需要抽取公共片段

**结论：内联是正确的。**

理由：Skills 通过 `Skill` 工具独立加载，每次只加载被触发的那个 SKILL.md。不存在跨 skill 的"共享运行时"。

两种替代方案分析：

| 方案 | 可行性 | 问题 |
|------|:--:|------|
| **A. source _os-detect.sh** | ❌ | SKILL.md 是 AI 执行的指令文档，不是 shell 脚本。`source` 在独立的 `bash -c` 块中生效范围仅限该块。即使 source 了，下一个代码块也需要重新 source。且 _os-detect.sh 不导出 PY_CMD 变量 |
| **B. session-start hook 预设环境变量** | ⚠️ | 可在 `session-start.sh` 中 `export PY_CMD`，然后 skills 文档中直接用 `$PY_CMD`。优点是一处定义全局生效。缺点是创建了隐藏依赖——读 SKILL.md 的 AI 看不到 PY_CMD 从哪来，未来维护者可能困惑 |
| **C. 每个 SKILL.md 顶部定义一次，全文复用** | ✅ | **推荐作为优化**。chain-test 已经在两处分别定义了 PY_CMD（L47+L88），如果合并为顶部一次 + 全文复用，可以减少重复。但这只是代码整洁度的改进，不影响正确性 |

**推荐方案**：本次用内联两行（方案当前形态），后续可考虑在 skill 文档头部加 "环境准备" 段落一次性定义。但**不在本次修改范围**——本次目标是修复 stub 陷阱，不是重构代码组织。

### 建议-2：通过/遗漏/建议 三段式，写到 hermes/reviews/2026-07-28/orca-review-python3-stub-fix.md

### 建议-3：`pip3` 模式当前安全，但保持警觉

审查了 5 个目标 skill 中的 `pip3`/`pip` 用法：

- `visual-check L129`：`pip3 install Pillow 2>/dev/null || pip install Pillow` — ✅ 安全。`pip3` 是命令执行（非 `command -v` 探测），stub 也会失败触发 `||` 回退到 `pip`
- `client-start`：`pip3 show <pkg>` — ✅ 安全。同样是命令执行，失败有明确的非零 exit code
- 按任务描述的"pip3 已验证是真实安装不受影响"结论

### 建议-3：`pip3` 模式当前安全，但保持警觉

审查了 5 个目标 skill 中的 `pip3`/`pip` 用法：
- `visual-check L129`：`pip3 install Pillow 2>/dev/null || pip install Pillow` — 安全，命令执行失败有 `||` 回退
- 不需要对 pip3 做同类修复

### 建议-4：修 7 处不嫌多，只修 human-gate 不够

**风险矩阵**：

| 位置 | 行号 | 失败模式 | 危害 | 是否必须修 |
|------|:--:|------|:--:|:--:|
| human-gate | L86 | 轮询 gate 状态 → 空输出 → "PENDING" → 死等 5 分钟 | 🔴 P0 | ✅ |
| chain-test | L88 | curl 响应解析 → 空输出 → 无 PASS/FAIL 输出 | 🟡 P1 | ✅ |
| deploy-verify | L80-82 | task-create JSON 解构 → 空 → `dispatch --task ""` 报错 | 🟡 P1 | ✅ |
| test-loop | L28 | 失败日志提取 → 空 → "未发现失败用例" | 🔴 P0 | ✅ |
| test-loop | L57 | 终端列表解析 → 空 → "无可用的 agent 终端" | 🟡 P1 | ✅ |
| chain-test | L47 | 链路匹配 → 空 → "未命中任何链路" | 🟡 P1 | ✅ |
| visual-check | L126 | 像素对比 → 空 → "无差异"（假阴性） | 🟡 P1 | ✅ |

> 判定标准：**静默空输出 ∈ P0**（AI 无法区分"无数据"和"命令失败"），**可见错误 ∈ P1**（AI 看到异常可以介入）。

human-gate L86 和 test-loop L28 都是 P0 级（静默空输出 → AI 误判"无数据"），仅修 human-gate 会遗漏 test-loop 的同等严重问题。其他 5 处虽然是 P1（可见错误），但一致性原则和低修改成本也支持统一修复。

### 建议-5：追加遗漏的 orca-review 和 github-harness-scan

修复范围应从 7 处扩展到至少 11 处（+orca-review L67, +github-harness-scan L59 L66 L73）。这两个遗漏如果不在本轮修复，建议至少在此评审报告中标注并在下一轮处理。

---

## 总结

| 维度 | 判定 |
|------|:--:|
| 方案正确性 | ✅ 通过 — 2 行过滤模式逻辑正确，边界行为 fail-loud |
| 修复范围 | ⚠️ 遗漏 — orca-review(1) + github-harness-scan(3) 未纳入 |
| 内联 vs 抽取 | ✅ 通过 — 内联是正确选择，skill 独立加载无共享运行时 |
| 是否过度修复 | ✅ 不过度 — test-loop L28 与 human-gate 同属 P0 静默空输出 |
| 其他探测遗漏 | ⚠️ 发现 4 处额外裸 python3 + compat-check 缺检测规则 |
