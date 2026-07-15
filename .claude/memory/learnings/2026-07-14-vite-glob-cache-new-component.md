---
name: vite-glob-cache-new-component
description: 新增 Vue 组件后 Vite 可能缓存旧的 import.meta.glob 结果，需重启或清理缓存
metadata:
  type: reference
---

# 新增 Vue 组件后 Vite 缓存导致组件加载失败

## 问题

新增模块的 Vue 组件文件（如 `index.vue`）已正确部署，菜单和权限都正确，但访问页面时前端报组件加载错误或空白。

## 根因

JeecgBoot 前端使用 Vite 构建，`import.meta.glob` 在首次启动时扫描并缓存组件路径。新增的组件文件不在缓存中，导致动态导入失败。

## 修复

- **开发模式**：重启 Vite dev server（`pnpm dev`）
- **生产模式**：重新构建（`pnpm build`）或强制全量部署
- **清理缓存**：`pnpm clean:cache` 后重新构建

**How to apply:** 每次新增 Vue 页面组件后，必须重启 Vite 或清理缓存。完整部署流程已包含前端重新构建，如果部署后仍然不行，检查是否是缓存问题。
