# Claude 外部评审 — 跨平台兼容 + hooks 硬约束方案（深度审查）

## 评审结论

**通过，但有两个结构性漏洞需补。** 当前设计方向正确（软约束→hook弹窗），但覆盖面和闭环机制不足。

---

## 一、已落地改动回顾

### Round 1: 跨平台兼容（4 hooks）✅
```
python3 硬编码 → $PYTHON=$(command -v python3 || command -v python || echo python)
post-tool-failure.sh appRunning 旧格式修复
```
**评价：** 简洁有效，无新增依赖。command -v 回退链覆盖了 macOS/Linux/Windows(Git Bash)。

### Round 2: 硬约束下沉到 hooks（2 hooks）

| Hook | 触发条件 | 行为 |
|------|---------|------|
| `pre-plan-check.sh` | `PreToolUse(Skill)` + `skill=plan` | 5项依赖查证 + Delegate强制判定横幅 |
| `pre-commit-check.sh` | `PreToolUse(Bash=git commit)` | `.last-verify` 时间戳检查 + 质量门控 |

---

## 二、三个核心问题的逐一分析

### 问题 1: .last-verify 鸡生蛋问题

**现状：**
- `pre-commit-check.sh:86-104` 检查 `.last-verify` 文件是否存在
- 不存在 → 显示阻断横幅，提示 `touch .last-verify`
- **没有任何自动化机制写入此文件**

**根因链：**
```
/verify 命令不会自动写 .last-verify
  → 第一次提交时 .last-verify 不存在
    → pre-commit 横幅弹出
      → 用户手动 touch .last-verify（绕过验证）
        → 从此以后 .last-verify 时间戳停留在第一次 touch 的时刻
          → 后续提交永远"通过"（文件存在即通过）
            → 机制退化为一纸空文
```

**严重度：P1** — 当前实现不仅解决不了问题，还会产生虚假安全感。文件只要被 touch 过一次就永久"通过"，比没有检查更危险（开发者以为有保护，实际没有）。

**修复方案（三选一，推荐方案 C）：**

#### 方案 A: verify/SKILL.md 补写入（上一轮评审的建议）
```bash
# /verify 完成最后一步
date '+%Y-%m-%d %H:%M:%S' > .last-verify
```
- ✅ 简单
- ❌ 依赖 AI 不跳过这一步（AI 可以不执行）
- ❌ 没有解决"AI 不跑 /verify 直接 commit"的问题

#### 方案 B: pre-commit 检查改为"时间戳 vs 文件 mtime"
```bash
# 比较 .last-verify 时间戳与最新变更文件的 mtime
LATEST_CHANGE=$(git diff --cached --name-only | xargs stat -f '%m' 2>/dev/null | sort -rn | head -1)
LAST_VERIFY_TS=$(stat -f '%m' .last-verify 2>/dev/null || echo 0)
if [ "$LAST_VERIFY_TS" -lt "$LATEST_CHANGE" ]; then
  # .last-verify 早于最新变更 → 未验证
fi
```
- ✅ 解决了"touch 一次永久通过"的问题
- ❌ 仍需要某物写 `.last-verify`
- ❌ stat 跨平台兼容性问题（macOS `stat -f '%m'` vs Linux `stat -c '%Y'`）

#### 方案 C: pre-commit 不依赖外部文件，直接检查 git diff 时间
```bash
# 检查最近一次 git commit 的时间 vs 暂存区文件最后修改时间
LAST_COMMIT_TIME=$(git log -1 --format='%at')
LATEST_STAGED_TIME=$(git diff --cached --name-only | xargs stat -f '%m' 2>/dev/null | sort -rn | head -1)
# 如果最后一次 commit 晚于文件修改时间 → 意味着文件改了但没提交过
# （即这轮改动尚未经过 verify → 没有 commit 记录的改动不应直接提交）
```
- ❌ 逻辑复杂、跨平台 stat 不兼容
- ❌ 没解决根本问题

#### **推荐方案 C+: 两步闭环**

```
Step 1: /verify 完成时自动写 .last-verify（时间戳 + HEAD commit hash）
        echo "$(date '+%Y-%m-%d %H:%M:%S') $(git rev-parse HEAD)" > .last-verify

Step 2: pre-commit 检查改为三态判断
        a) .last-verify 不存在 → 阻断（从未验证）
        b) .last-verify 存在但 HEAD 变了 → .last-verify 记录的 commit != 当前 HEAD
           → 说明有新改动但未重新 verify → 阻断
        c) .last-verify 存在且 HEAD 匹配 → 通过
```

**为什么这样更好：**
- `.last-verify` 记录了"哪个 commit 通过了 verify"
- 新改动（HEAD 变化）自动使旧 `.last-verify` 失效
- 不需要跨平台的 stat 命令
- 首次写入由 `/verify` 命令负责（一次性解决鸡生蛋）

**但还有一个缺口：** `/verify` 命令谁来保证一定会执行？

---

### 问题 2: pre-plan-check 只在 Skill=plan 时触发，AI 跳过 plan 时怎么拦截？

**现状：**
```
settings.json:
  PreToolUse(Skill) → pre-plan-check.sh
    → 脚本内部: if [ "$IS_PLAN" != "plan" ]; then exit 0

触发链: AI 调 /plan → PreToolUse hook 触发 → 脚本运行 → 检查+横幅
盲区:   AI 不调 /plan，直接 Edit/Write 写代码 → hook 不触发 → 零拦截
```

**实际影响：** 今天的 20 个提交中 0 次 delegate 触发——AI 收到任务后直接读文件→写代码，从未调用 `/plan`。pre-plan-check 的 delegate 横幅一次都没显示过。

**严重度：P0** — 这是硬约束方案的核心盲区。如果 AI 不走 plan 流程，delegate 判定永远不会触发。

**修复方案：**

#### 方案 A: 加 PreToolUse(Edit|Write) 轻量检查（上一轮评审的建议）
```json
// settings.json 新增
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pre-edit-check.sh\""
  }]
}
```
- ✅ 覆盖所有代码编辑路径
- ❌ 太频繁——每次 Edit/Write 都触发，大量噪音
- ❌ Edit|Write 在 Claude Code 中已经被 pre-write-check.sh 占用（文件边界检查）
- ⚠️ 两个 hook 在同一 matcher 上可能冲突或让用户体验极差

#### 方案 B: 合并到 pre-write-check.sh（推荐）
```bash
# pre-write-check.sh 已有：受保护目录检查
# 新增：delegate 判定
# 
# 逻辑：
# 1. 受保护目录 → 阻断（已有）
# 2. 检测未提交代码文件 → delegate 提醒横幅（新增）
# 3. 两者独立、互不阻塞
```

**优势：**
- 不新增 hook 触发频率（Edit|Write 本来就会触发 pre-write-check.sh）
- delegate 横幅在每次编辑时显示，AI 第一次写代码就会看到
- 可以和受保护目录检查共用同一个 hook

**需要解决的问题：**
- 横幅在每次 Edit 时都弹 → 太吵。加频率限制：**同一会话只显示一次**
  ```bash
  SESSION_FLAG="/tmp/claude-delegate-reminded-$$"
  if [ ! -f "$SESSION_FLAG" ]; then
    # 显示横幅
    touch "$SESSION_FLAG"
  fi
  ```
- Edit 触发时 stdin 是什么格式？需要确认 Claude Code 的 PreToolUse hook 在 Edit 时传入的 JSON 结构

#### 方案 C: 双保险——Edit 轻量提醒 + Skill 深度检查
```
PreToolUse(Edit|Write)  → pre-write-check.sh
  ├─ 受保护目录 → 阻断
  ├─ 检测代码变更 → 轻量提醒 "请确认是否已在 /delegate 模式下工作"
  └─ 同一会话只提醒一次

PreToolUse(Skill=plan)  → pre-plan-check.sh
  └─ 5项依赖查证 + Delegate 强制判定 + 文件清单
```

**推荐：方案 C（双保险）。** 原因：
- 覆盖面最全：AI 调 plan → 深度检查；AI 不调 plan → 首次编辑时轻量提醒
- 不增加噪音：编辑提醒用会话级去重
- 不改动现有 hook 结构：只需扩展 pre-write-check.sh

---

### 问题 3: 是否有更好的硬约束设计？

**当前设计的约束层级：**

| 层级 | 机制 | 约束力 | 可绕过？ |
|:--:|------|:--:|:--:|
| L1 | CLAUDE.md 文本规则 | 软 | ✅ AI 随意忽略 |
| L2 | PreToolUse hook 横幅 | 中 | ✅ 看到后无视即可 |
| L3 | pre-commit hook (exit 1) | 硬 | ✅ `--no-verify` |
| L4 | pre-commit hook (exit 0) | 中 | ✅ 看到后无视即可 |

**核心矛盾：** 真正需要硬约束的检查（如"有没有 curl 实测"）在 hook 层面无法做到真正的"硬"——hook 只能检查文件/时间戳/静态特征，无法判断"AI 是否真的调了 curl 并理解了返回值"。

**替代方案对比：**

#### 方案 A: pre-commit 阻断 + 证据链（当前方向改进）
```
pre-commit 不检查 .last-verify 是否存在
而是检查"证据文件"是否包含：
  1. mvn compile 输出（最后一行是否 BUILD SUCCESS）
  2. curl 响应体（result.success = true）
  3. 时间戳（证据时间 > 最后文件修改时间）

证据文件由 /verify 命令自动生成
格式: .verify-evidence.json
{
  "timestamp": "2026-07-24T20:30:00",
  "commit": "fb328ef",
  "compile": "BUILD SUCCESS",
  "endpoints": [
    {"method": "POST", "url": "/mes/sales/order/add", "code": 200, "success": true}
  ]
}
```
- ✅ 证据可验证、可审计
- ✅ 不是简单的"文件存在=通过"
- ❌ 依赖 /verify 命令忠实执行
- ❌ AI 可以生成假证据（但需要刻意为之，比单纯 touch .last-verify 门槛高）

#### 方案 B: post-commit hook 回滚
```
post-commit 检查：
  如果 .last-verify 不存在或过期
  → git reset --soft HEAD~1（撤销提交）
  → 显示："提交未通过验证门控，已自动撤销。请先运行 /verify。"
```
- ✅ 真正的硬约束
- ❌ 太激进——可能丢失工作
- ❌ post-commit hook 在 Claude Code 中不直接支持（只有 PreToolUse）

#### 方案 C: 会话级状态机（最推荐）
```
session-start.sh 写入初始状态:
   echo "pending_verify" > .claude/.session-state

pre-commit-check.sh:
   读取 .claude/.session-state
   if state == "pending_verify":
     阻断（exit 1）
     提示: "本次会话尚未完成 /verify，请先验证"

/verify 命令完成后:
   写入 .claude/.session-state ← "verified"
   + 写入 .last-verify（时间戳+commit）

pre-commit-check.sh:
   if state == "verified":
     检查 .last-verify 是否匹配当前 HEAD
     匹配 → 通过
     不匹配 → 阻断

session-end.sh:
   清理 .claude/.session-state
```

**状态机流转图：**
```
session-start → pending_verify
     │
     ├─ AI 写代码（无限制）
     │
     ├─ AI 调 /verify → state=verified + 写 .last-verify
     │    │
     │    └─ AI commit → pre-commit 检查 → state=verified + .last-verify 有效 → 通过
     │
     └─ AI commit（未调 /verify） → state=pending_verify → exit 1 阻断
           │
           └─ 紧急旁路: git commit --no-verify
```

**优势：**
- 状态机逻辑简单，不依赖外部时间戳比较
- "会话"是自然的验证粒度单位——一次会话 = 一轮改动 = 一次 verify
- session-start/session-end 提供自然的初始化和清理时机
- `--no-verify` 保留紧急旁路

**缺点：**
- 依赖 Claude Code 的 SessionStart/SessionEnd hook（已有）
- 如果 AI 在同一个会话中做多轮改动，需要支持"多次 verify"
  - 解决：commit 后不清理状态，允许 AI 再次 /verify 更新状态
  - session-end 才清理

---

## 三、推荐实施方案（优先级排序）

### P0（立即修复 — 结构性问题）

| # | 问题 | 方案 | 涉及文件 |
|---|------|------|---------|
| 1 | pre-plan 盲区：AI 不调 plan 时无 delegate 拦截 | 方案 C 双保险：Edit hook 轻量提醒 | `pre-write-check.sh`, `settings.json` |
| 2 | .last-verify 鸡生蛋 + 一次 touch 永久通过 | 方案 C+：记录 commit hash，HEAD 变化失效 | `pre-commit-check.sh` |
| 3 | /verify 命令不写证据 | verify/SKILL.md 补写入逻辑 | `.claude/skills/verify/SKILL.md` |

### P1（本周修复 — 增强约束力）

| # | 问题 | 方案 | 涉及文件 |
|---|------|------|---------|
| 4 | 没有会话级验证状态追踪 | 方案 C：session-start 初始化状态机 | `session-start.sh`, `session-end.sh`, `pre-commit-check.sh` |

### P2（观察后决定）

| # | 问题 | 方案 |
|---|------|------|
| 5 | 证据链可伪造 | 先用方案 C（状态机），观察实际效果。如果 AI 开始伪造状态，再升级到证据文件 JSON |
| 6 | pre-commit 阻断太频繁影响 hotfix | 当前 `--no-verify` 设计合理，不需要改 |

---

## 四、总体评价

### 方向 ✅
- "CLAUDE.md 软约束 → hook 弹窗 → pre-commit 阻断"的三层递进正确
- python3 兼容方案简洁优雅
- delegate 横幅设计合理（提醒不阻断）

### 盲区 ⚠️
1. **pre-plan 覆盖率不足**：当前 delegate 判定只在 `/plan` 调用时触发，但 AI 经常跳过 `/plan` 直接编码。这是 P0 盲区。
2. **.last-verify 退化**：文件存在即通过，一次 touch 永久有效。机制不仅无效，还有虚假安全感。
3. **验证闭环未形成**：`/verify` 命令没有写 `.last-verify` 的步骤，整个链条在最后一步断裂。

### 建议的行动顺序
```
1. 修复 .last-verify 退化（commit hash 校验）        ← 30min
2. 在 verify/SKILL.md 补写入步骤                       ← 10min
3. 在 pre-write-check.sh 加 delegate 轻量提醒          ← 20min
4. 引入会话级状态机（session-state）                   ← 30min
5. 观察 1 周，收集数据，决定是否升级到证据文件 JSON
```

---

## 五、附录：hook 覆盖矩阵

| 场景 | pre-write | pre-plan | pre-commit | 覆盖？ |
|------|:--:|:--:|:--:|:--:|
| AI 调 /plan → 编码 → commit | — | ✅ delegate判定 | ✅ verify门控 | ✅ 完整 |
| AI 不调 /plan → 直接 Edit 编码 → commit | ❌ 无提醒 | ❌ 未触发 | ✅ verify门控 | ⚠️ 缺 delegate |
| AI 编码 → 不 commit（多轮累积） | ❌ | ❌ | ❌ 未触发 | ❌ 零覆盖 |
| AI 只读不改 → commit | — | — | ❌ 无 Java/Vue | ✅ 豁免 |
| 文案/样式改动 | — | ✅ 豁免判定 | ❌ 无 Java/Vue | ✅ 豁免 |

**盲区最大的场景：** 行 3 — AI 多轮编码不提交，所有 hook 都不触发，silent failure。

**建议：** 在 session-start 或 Edit hook 中加入"编了码但还没 commit"的追踪（会话状态机已覆盖此场景）。

---

*评审人：Claude（Orca worker 降级手工评审）*
*日期：2026-07-24*
*审查范围：.claude/hooks/ 全部 6 个脚本 + settings.json + CLAUDE.md*
