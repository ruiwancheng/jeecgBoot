# Pi 评审报告 — Harness 工程优化（规则合并 + 归档 + 新增命令/技能）

- **评审人**: pi
- **日期**: 2026-07-28
- **范围**: `git status --short` 全部变更（38 modified/deleted + 20 untracked）
- **关联评审**: `hermes/reviews/2026-07-28/orca-review-harness-optimization.md`（orca 视角，本报告为独立第二意见）

---

## 总结论

**🟡 有条件通过 — 核心合并工作质量高，但留下 3 个 P1 断链/状态泄漏问题需修复后再提交。**

合并与归档本身做得扎实：6 个规则文件逐字节核对无内容丢失，24 篇 learnings 归档可逆，新技能跨平台模式统一。**主要风险不在"合并"，而在"合并后没收尾"** —— CLAUDE.md 规则清单、review 技能、cleanup-context 命令仍指向已归档的旧文件路径，多客户端按图索骥会扑空。

---

## 维度 1：数据完整性 — ✅ 通过

逐条比对了归档源文件与合并目标的约束覆盖：

| 合并目标 | 源文件 | 核对结果 |
|---------|--------|---------|
| code-style.md §后端优先 | backend-first.md | ✅ 4/4 条逐字保留 |
| code-style.md §安全规范 | security.md | ✅ 4/4 条逐字保留（呼应 orca 评审 P1-5 疑虑：无 `.env` 示例丢失，原文本就无示例） |
| code-style.md §平台保护与覆盖 | no-platform-modify.md + override-mechanism.md | ✅ 4 步流程+记录格式+Bean/路由/页面/manifest/扩展表全覆盖。仅丢一句过渡引言（"需要修改标品已有功能时…"），无约束力损失 |
| boundary.md §文件系统 | file-scope.md | ✅ 2 项目录 + 2 公共注册点 + 8 条禁止写入路径全保留；原文重复两遍的 blockquote 被清理为一条（属于修复原文 bug） |
| boundary.md §数据库 | data-scope.md | ✅ 4 条可做 + 5 条禁做全覆盖 |

**次要观察**（不影响判定）：
- boundary.md 作为新文件 version 直接标 3.0（继承 file-scope 2.0 语义），合理但建议在 description 注明版本跳跃原因——已注明"合并自"，可接受。
- MEMORY.md 中"等效: delegate.md preamble"只**部分成立**：delegate.md:58/78 有"每30秒轮询 check"指令，但归档学习的核心根因（TUI 截胡邮件导致 `check --wait` 必然查空、**禁止 --wait**）在 delegate.md 中没有显式 prohibition。新 agent 读 delegate.md 知道"要轮询"，但不知道"为什么不能用 --wait"，可能在其他场景重新踩坑。建议在 delegate.md preamble 补一句 prohibition。

## 维度 2：引用完整性 — ❌ 不通过（3 P1 + 3 P2）

**MEMORY.md 本身：✅ 完美。** 30 条链接逐一验证全部有效，3 条归档条目正确指向 `.archived/` 并标注 `[ARCHIVED]` + 等效出处。

**但仓库其余位置存在指向已归档文件的断链：**

| 级别 | 位置 | 问题 |
|:--:|------|------|
| **P1** | `CLAUDE.md:125-126,131` | 规则清单仍列 `file-scope`/`data-scope`/`override-mechanism`/`backend-first`/`security`/`no-platform-modify` 为活跃规则；131 行"详见 `file-scope.md`"直接断链。**CLAUDE.md 是 Claude Code 的主入口文件**，影响面最大 |
| **P1** | `.claude/skills/review/SKILL.md:42,51` | 引用 `.claude/rules/file-scope.md` 和 `.claude/rules/data-scope.md`——**本次变更改了这个文件（加了双轴审查段落）却没同步修引用**，属于改动同一文件时的连带遗漏 |
| **P1** | `.claude/commands/util/cleanup-context.md:54-55` | `@rules/file-scope.md`、`@rules/no-platform-modify.md` @ 提及断链 |
| P2 | `.claude/memory/methodology-index.md:28,41` | 2 条链接指向已归档 learnings（`2026-07-05-command-skill-split`、`2026-07-04-hook-testing`）——MEMORY.md 更新了，这个姊妹索引漏了 |
| P2 | `.claude/skills/harness-check/SKILL.md:20` | 健康检查期望清单仍含 6 个旧规则文件名，下次跑 harness-check 会误报"规则缺失" |
| P2 | `.claude/rules/quality-gates.md:94` | 行文中引用 `file-scope.md`，应改指 `boundary.md` |

历史文件（plans/、既往 reviews/、learnings/ 内部行文）中的旧名字出现属于历史快照，**不需要改**。

## 维度 3：操作安全性 — ✅ 通过

- **全部归档为 mv 非 rm**：6 个规则归档文件与 HEAD 逐字节一致（仅 CRLF/LF 换行差异，属 Windows 环境正常噪音）；24 篇 learnings 删除数与 `.archived/` 新增数相等，抽查 2 篇内容一致；2 个归档 skills 完整保留在 `.claude/skills/.archived/`。
- `.claude/skills/.archived/README.md` 有归档台账（日期+原因），可溯可恢复。
- git 历史完整保留，即使误删 `.archived/` 也可从 HEAD 恢复。**双重可逆**。
- `.last-deploy-commit` 已在 `.gitignore:31` ✅。

## 维度 4：跨平台兼容 — 🟡 基本通过（1 个实锤事故 + 2 处不一致）

**做得好的**：新技能统一使用 `PY_CMD=$(command -v python3 || command -v python)` 探测、`${TMPDIR:-/tmp}` 回退、`date` 三种格式兜底，跨平台意识一致。local-dev 的 Windows 专段（netstat/taskkill/C:/ 路径探测）与 POSIX 段分离清晰。

**发现的问题：**

| 级别 | 问题 |
|:--:|------|
| **P1** | **仓库根目录出现 `nul` 空文件**（untracked）——这是某次在 Git Bash 中执行 `> nul` 或 `2> nul`（cmd 语法）的实锤事故。bash 里 `nul` 不是空设备而是普通文件名。说明本次优化过程中有命令混用了 Windows cmd 习惯。**应删除该文件**，并检查是哪个脚本产生的 |
| P2 | `.mcp.json` 硬编码 `"command": "python"`——macOS/Linux 默认只有 `python3`，与各技能内部精心做的 PY_CMD 探测**自相矛盾**。多客户端在 Mac 上 MCP server 会启动失败。另 `${workspaceFolder}` 是 VS Code/Cursor 变量，Claude Code 端展开行为需实测确认 |
| P3 | local-dev mysqld 拉起循环缺 `break`：`for d in 8.4 8.0; do test -f ... && mysqld &; done`——两版本并存时会尝试启动两个 mysqld 实例（第二个抢端口失败但日志脏乱） |

## 维度 5：多客户端场景 — 🟡 2 个一致性问题

| 级别 | 问题 |
|:--:|------|
| **P1** | `.claude/.client-start-initialized` **未被 gitignore**。这是机器本地状态文件（内容含 `MINGW64_NT-10.0-22631` 等机器指纹），一旦被提交，其他客户端拉代码后会**跳过阶段 0 首次接入**（工具链核查/MCP 安装/图谱构建全部跳过），多客户端环境直接不一致。应加入 `.gitignore` |
| P2 | 维度 2 的断链在多客户端下被放大：Claude Code 读 CLAUDE.md、pi 读 AGENTS 类入口、harness-check 按清单校验——三个客户端对"当前有哪些规则"会得出**三个不同答案**。修复维度 2 断链后此问题自然消除 |

**正面**：合并后的 code-style.md / boundary.md 保留了标准 frontmatter（name/description/glob/version），description 中注明合并来源与日期，任何客户端都能理解文件血缘。human-gate 技能的"禁止 AI 自己 resolve gate"等约束用自然语言写死，不依赖特定客户端机制。

---

## 修复清单（按优先级）

**提交前必须（P1）：**
1. `CLAUDE.md:125-131` — 规则清单更新为合并后的文件名，`file-scope.md` 引用改指 `boundary.md`
2. `.claude/skills/review/SKILL.md:42,51` — `file-scope.md`→`boundary.md`、`data-scope.md`→`boundary.md`
3. `.claude/commands/util/cleanup-context.md:54-55` — 同上改指 `boundary.md`（no-platform-modify 内容现属 `code-style.md` §平台保护）
4. 删除根目录 `nul` 文件，溯源产生它的命令（改用 `> /dev/null`）
5. `.gitignore` 增加 `.claude/.client-start-initialized`

**建议同步修（P2）：**
6. `methodology-index.md:28,41` — 2 条链接指向 `.archived/` 或标注 [ARCHIVED]
7. `harness-check/SKILL.md:20` — 期望规则清单更新为合并后现状
8. `quality-gates.md:94` — `file-scope.md`→`boundary.md`
9. `.mcp.json` — 评估 `python`→`python3` 或按客户端文档确认变量展开

**可选（P3）：**
10. delegate.md preamble 补"禁止 `check --wait`（TUI 截胡邮件）"显式 prohibition
11. local-dev mysqld 拉起循环加 `break`
12. client-start 技能的标记文件 echo 命令补文档化的 Orca 字段（实际文件含 `| Orca orca`，文档没有）

---

## 核对方法（可复现）

```bash
# 归档内容一致性（全部 6 个规则文件）
for f in backend-first data-scope file-scope no-platform-modify override-mechanism security; do
  git show HEAD:.claude/rules/$f.md | tr -d '\r' | diff - <(tr -d '\r' < .claude/rules/.archived/$f.md)
done

# MEMORY.md 断链扫描
grep -oP '\]\(\K[^)]+' .claude/memory/MEMORY.md | while read l; do
  [ -f ".claude/memory/$l" ] || echo "BROKEN: $l"
done

# 全仓旧规则名引用扫描
grep -rn -E "(file-scope|data-scope|backend-first|no-platform-modify|override-mechanism)" \
  CLAUDE.md .claude/ --include="*.md" | grep -v "\.archived"
```
