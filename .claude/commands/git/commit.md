# /git-commit

按项目规范提交代码。

## 流程
1. `git status` + `git diff --stat` 确认改动范围
2. 按 conventional commits 生成提交信息（type: feat/fix/perf/chore）
3. `git add` + 提交
4. 询问是否推送

引用: @rules/code-style.md
