# Gitignore 单行多 pattern 全部失效（行格式硬约束）

**触发条件：** 任何 `.gitignore` 文件编辑，特别是批量添加忽略规则时。

**问题：**

```gitignore
# ❌ 错误写法——Git 只当作一个名为 "AGENTS.md CODEBUDDY.md ..." 的文件
AGENTS.md CODEBUDDY.md GEMINI.md QODER.md
cursorrules windsurfrules opencode.jsonc
.codebuddy/ .gemini/ .kiro/ .qoder/
```

**根因：** Git `.gitignore` 规范**每行只识别一个 pattern**。空格分隔的多文件名 = Git 视作"一个文件名"，所有规则**全部不生效**。

**修复：每行一个 pattern**

```gitignore
# ✅ 正确写法
AGENTS.md
CODEBUDDY.md
GEMINI.md
QODER.md
.cursorrules
.windsurfrules
opencode.jsonc
.codebuddy/
.gemini/
.kiro/
.qoder/
```

**配套验证（必须跑）：**

```bash
# 验证规则真的生效（不只是写入文件）
git check-ignore -v <文件或目录路径>

# 批量验证（CI 集成）
for f in AGENTS.md CODEBUDDY.md .cursorrules; do
  result=$(git check-ignore -v "$f" 2>&1)
  [ -z "$result" ] && echo "$f: ✗ NOT ignored" || echo "$f: ✓ $result"
done
```

**隐藏文件陷阱：** `.cursorrules` ≠ `cursorrules`。如果实际文件是隐藏的（带点的 `.cursorrules`），gitignore 规则也必须带点。

```bash
# 看真实文件名（git status 简写可能去掉前导点）
ls -la | grep -iE "cursorrules|windsurf"
# 看到 .cursorrules 但 git status 显示 cursorrules（无点）—— 规则必须写 .cursorrules
```

**关联踩坑：** 2026-08-07 fixup commit `3c1202f` 修复 T1 commit `24ee564` 的错误。T1 gitignore 写了 12 项规则全部不生效，导致仓库从"派工后零污染"退化到"15 项 untracked"。fixup 拆分单行后 0 项 untracked。

**派工/AI 工作流：** 任何 gitignore 规则批量新增/修改后，**必须 `git check-ignore` 验证**，不要相信 "我写了"。尤其当派工 preamble 让 worker "批量加规则"时——worker 容易复制粘贴 T1 同样的错误。

详见 `learnings/2026-08-07-coordinator-git-status-fallback.md`（协调者兜底判断模式）。