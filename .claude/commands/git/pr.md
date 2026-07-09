# /git-pr

从当前分支创建 PR。

## 流程
1. `git log main..HEAD --oneline` 汇总提交
2. `git diff main...HEAD --stat` 统计变更
3. 生成标题(<70字) + 描述
4. `gh pr create` 创建并返回链接
