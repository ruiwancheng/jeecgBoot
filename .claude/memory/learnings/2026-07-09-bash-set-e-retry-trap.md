---
name: bash-set-e-retry-trap
description: set -e 导致 bash 重试循环失效——编译命令前后需 set +e/set -e
type: learning
---

# set -e 杀死重试循环

脚本顶部 `set -e` 时，重试循环中的编译命令失败会直接退出脚本，`$?` 捕获和重试逻辑永远不会执行。

```bash
# 错误：set -e 下 pnpm build 失败直接退出
pnpm build; BUILD_EXIT=$?

# 正确：临时关闭 set -e
set +e; pnpm build; BUILD_EXIT=$?; set -e
```
