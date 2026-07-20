# [2026-07-20] [运维] 部署服务端有改动时的Git分支收敛

## 触发条件
本地有多个未推送提交，远程也有新提交（如服务端直接做的修复），`git pull` 报分支分叉。

## 处理流程

```bash
# 1. 查看各自有什么
git log HEAD..origin/main --oneline  # 远程新增
git log origin/main..HEAD --oneline  # 本地新增

# 2. 确认无冲突 → rebase
git rebase origin/main

# 3. 推送
git push origin main
```

## 为什么用 rebase 而非 merge
- 本地提交是独立的 Harness 增强/功能开发
- 远程提交是部署脚本修复
- 两者改动目录不重叠（`.claude/` vs 部署脚本）
- rebase 保持历史线性，避免无意义的 merge commit

## 关键教训
- 部署 404 先检查 `git status -sb` 看本地是否领先远程
- 服务端 `git pull` 只能拉到已推送的代码
- `ahead N` = 还有 N 个提交没推送 = 服务端看不到
