---
name: github-push-rules
description: GitHub推送规则 — 推送流程、故障处理、分支收敛标准操作
metadata:
  type: reference
---

# GitHub 推送规则（固化版）

## 标准推送流程

```bash
# 1. 确认无分支分叉
git fetch origin main
git log origin/main..HEAD --oneline  # 本地领先的提交
git log HEAD..origin/main --oneline  # 远程领先的提交

# 2. 如果有分叉 → rebase
git rebase origin/main

# 3. 推送
git push origin main
```

## 故障处理

| 现象 | 可能原因 | 处理 |
|------|------|------|
| HTTP 408 / curl 56 | 服务端代理问题 | 终端手动 `git push origin main` |
| Permission denied (403) | Token 权限不足 | 确认 PAT 含 `Contents: write` |
| branch diverged | 远程有新提交 | `git rebase origin/main` |

## 推送前检查（每次必做）

1. **确认 `git status` 干净**（工作区无未暂存变更）
2. **确认远程无新提交**（`git fetch` + `git log HEAD..origin/main`）
3. **确认无合并冲突**（如 rebase 失败，逐文件 `Read` 检查冲突后手动修复）

## 服务端联动

- 推送后，服务端 `git pull` 自动拉取
- 部署控制台 `http://100.122.125.106:3101` 执行部署
- 发现服务端有改动 → 先 `git rebase origin/main` 再推

## 禁止事项

- 禁止 `git push --force`（已在 `block-dangerous.sh` 中拦截）
- 禁止跳过 `git fetch` 直接 rebase
- 禁止在有未推送提交时丢弃本地修改（`git reset --hard`）
