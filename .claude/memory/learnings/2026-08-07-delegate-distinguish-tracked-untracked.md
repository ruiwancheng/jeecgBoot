# 派工前必须先 `git ls-files` + `git ls-files --error-unmatch` 区分已跟踪/未跟踪

**触发条件：** 派工任务涉及 git 工作区状态整理（commit 整理、INDEX 更新、批量 add）。

**问题（2026-08-07 实证）：**

派工时假设 `hermes/plan/` 全部未跟踪入仓——但实际：

```bash
# 错误假设
"hermes/plan/ 全部未跟踪，需要 add"

# 实际情况（grep 后才发现）
$ git ls-files hermes/plan/
hermes/plan/2026-08-01-batch-no-manual-entry.md  # 已跟踪
hermes/plan/INDEX.md                              # 已跟踪
hermes/plan/coverage-improvement.md               # 已跟踪
... (10 个已跟踪)

$ for f in hermes/plan/*.md; do
    git ls-files --error-unmatch "$f" >/dev/null 2>&1 || echo "? $f"
  done
? hermes/plan/features-business-chains-cross-validation.md
? hermes/plan/independent-issues-slice-cde.md
? hermes/plan/large-function-refactoring-slice-b.md
? hermes/plan/regression-system-consolidation-phase{1,2,3,4}.md
# 仅 7 个未跟踪！
```

如果如果不在 preamble 里指定"仅这 7 个 add"，worker 可能 `git add hermes/plan/` 全部添加，**覆盖已跟踪文件**（如 `INDEX.md` 已有 5 条记录，粗暴 add 会保留旧版还是冲突？）。

**强制流程（派工前 grep 验证）：**

```bash
# 1. 列出已跟踪文件
git ls-files <目录>

# 2. 列出未跟踪文件（pattern: 已跟踪的不打印）
for f in <目录>/*; do
  git ls-files --error-unmatch "$f" >/dev/null 2>&1 || echo "? $f"
done

# 3. 用一句话告诉 worker：仅 add 这 N 个，不要 add 其他
# preamble 示例：
# "仅入仓这 7 个未跟踪文件（不要 add 其他）：
#  - path/to/file1.md
#  - path/to/file2.md
#  ..."
```

**INDEX.md 已有内容的处理：**

如果目录有跟踪的 INDEX.md，新增条目必须**追加追加**，不要覆盖：

```bash
# 错误：直接覆盖（丢失历史记录）
echo "| 2026-08-08 | new.md | 新增 |" > INDEX.md

# 正确：先读原内容，保留 + 追加
old_content=$(cat INDEX.md)
new_row="| 2026-08-08 | new.md | 新增 |"
{
  echo "$old_content" | head -n -1  # 原内容去掉最后一行的"最后更新"
  echo "$new_row"
  echo ""
  echo "*最后更新: 2026-08-08*"
} > INDEX.md
```

**派工 preamble 必须显式区分**：

1. **"仅 N 个未跟踪文件"** —— 列出具体路径
2. **"N 个 Modified"** —— git status 报的 ` M` 文件
3. **"X 个 INDEX.md 追加"** —— 已有跟踪，需追加而非覆盖
4. **"Y 个 .gitignore 修改"** —— 改规则

**关联 learnings：**

- `2026-08-07-gitignore-one-pattern-per-line.md`（派工 verify 必须 `git check-ignore`）
- `2026-08-07-coordinator-git-status-fallback.md`（git log 兜底判断完成）

**实证：** 2026-08-07 派工"仓库健康度维护"任务：
- 派工时假设 hermes/plan 全部未跟踪 → 实际只有 7 个未跟踪
- 工人正确处理（只 add 这 7 个 + 追加 INDEX.md），但协调者必须提前在 preamble 明确"仅这 7 个"
- 如不明确，工人可能 `git add hermes/plan/` 全量 add，触发 `.gitignore` 冲突或覆盖已跟踪文件