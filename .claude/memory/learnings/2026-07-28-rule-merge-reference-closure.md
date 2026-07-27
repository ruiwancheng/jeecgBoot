# [2026-07-28] [Harness] 规则合并需做全仓引用闭包扫描

## 触发条件
Harness 优化 wave 1a: 6 个规则文件合并到 code-style.md 和 boundary.md，旧文件移至 .archived/。

## 发现
合并操作本身质量高（逐字节核对无丢失），但**合并后没收尾**：
1. CLAUDE.md 规则清单仍列出 22 个旧文件名 → 主入口断链 (P1)
2. review/SKILL.md 引用 `file-scope.md` 和 `data-scope.md` → 技能内断链 (P1)
3. cleanup-context.md 的 `@rules/file-scope.md` → 命令模板断链 (P1)
4. `.client-start-initialized` 未被 gitignore → 多客户端状态泄漏 (P1)
5. 根目录 `nul` 文件泄漏（`> nul` 是 cmd 语法，bash 下写成普通文件）(P1)

## 处理方式
- 任何规则文件重命名/合并/删除后，**必须跑全仓引用扫描**：
  ```bash
  grep -rn "旧文件名" CLAUDE.md .claude/ --include="*.md" | grep -v "\.archived\|learnings/\.archived"
  ```
- Pi 的"逐文件核对 + 闭包扫描"模式特别适合这个任务
- CLAUDE.md → skills → commands → cleanup-context 引用链是断链高危区
- 检查 `.gitignore` 中是否缺少新产生的本地文件
- 检查根目录和执行目录是否有误创建的文件（`nul`、`tmp` 等）

## 关联
- [[2026-07-28-dual-ai-audit-complement]] — pi 首次发现本问题
- [[2026-07-28-bulk-learning-archive-validation]] — 同类"操作后未验证"模式
