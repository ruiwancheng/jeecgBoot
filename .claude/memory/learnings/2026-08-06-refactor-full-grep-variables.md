# 重构变量名时全文件 grep 验证（避免漏改引发的 P0 bug）

**触发条件：** 任何 "rename variable X → Y" 类重构（PROJECT → REPO、PATHS → HARNESS_PATHS、etc.）

**处理方式：**
1. **不要相信"我看了一遍"**：Phase 3 重构 PROJECT → REPO 漏改 L436 一行；Phase 4 Node 路径处理漏改 L369 一行。两个 P0 bug 都是同类错误。
2. **强制 grep 验证**：
   ```bash
   grep -n "\bOLD_VAR\b" harness/scripts/*.js harness/scripts/*.py
   grep -n "\bNEW_VAR\b" harness/scripts/*.js harness/scripts/*.py
   ```
   输出 0 行 OLD_VAR 引用才算完成（注释除外）。
3. **同步 commit 包含 grep 结果**：commit message 附 grep 输出，证明全文件无残留。
4. **跨语言调用特别注意**：Python 调 Node / Node 调 Python 时，参数语义变化（绝对路径 vs run-id）也会触发同类 bug，必须**双向验证**。
5. **静态 import 检查**：重构 import 后，旧变量名还在代码里被引用 → ImportError/NameError，必须搜全。

**实证：** 2026-08-06 Phase 3 bugfix (8d2ea4c): regression-report.js L436 `path.join(PROJECT, resolved)` 未改为 `path.join(REPO, resolved)` → 整个归档写入崩溃 → 用户笔记空间丢失 Node v2 报告。

**配套：** orca-review 评审 plan 时，行号（"L43-L45"）会漂移——评审必须 read 完整文件确认位置，不要凭 plan 描述做判断。