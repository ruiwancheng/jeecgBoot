---
name: vite-worker-deadlock
description: Vite 7 CSS worker Atomics.wait 死锁导致 Less timed-out 的诊断和修复
type: learning
---

# Vite CSS Worker 死锁

## 触发条件

Vite 7 构建时偶发 `[less] timed-out`，总出现在 config.less 等被全局注入的 Less 文件末尾阶段。

## 根因

Vite 7 CSS worker 使用 `Atomics.wait(lockState, 0, 1, 5000)` 做线程同步。Less 编译大文件时持锁超过 5 秒 → 其他 worker 超时 → 检查 event loop utilization ≤ 90% → 抛 `timed-out`。

## 修复

1. **Patch Vite timeout**：`sed 's/5 \* 1e3/60 * 1e3/'` 将 5s 改为 60s（部署时自动执行）
2. **3 次重试 + 清缓存**：首次失败清 `.vite/.cache` 重试
3. **Less 锁定 4.4.2**：4.5.1 的 `@import(reference)` 有性能退化
4. **`set -e` 陷阱**：编译命令前后需 `set +e` / `set -e`，否则重试循环被跳过
