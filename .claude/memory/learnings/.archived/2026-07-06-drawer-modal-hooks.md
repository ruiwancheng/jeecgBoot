---
name: drawer-modal-hooks
description: BasicDrawer 配 useDrawer，BasicModal 配 useModal，混用会报 setModalProps 错误
metadata:
  type: reference
---

# Drawer/Modal 组件与 Hooks 的配对规则

## 问题

点击新增按钮弹窗时报错：
```
Uncaught TypeError: getInstance(...)?.setModalProps is not a function
```

## 根因

`useModal` hook 只能用于 `BasicModal` 组件，`BasicDrawer` 必须使用 `useDrawer` hook。

## 正确配对

| 表单容器组件 | Hook 导入 | 解构方式 |
|------------|----------|---------|
| `<BasicModal>` | `import { useModal } from '/@/components/Modal'` | `const [register, { openModal }] = useModal()` |
| `<BasicDrawer>` | `import { useDrawer } from '/@/components/Drawer'` | `const [register, { openDrawer }] = useDrawer()` |

**Why:** Modal 实例有 `setModalProps` 方法，Drawer 实例有 `setDrawerProps` 方法。Hook 内部调用 `getInstance()?.setModalProps(...)` 时，如果实例是 Drawer 则不存在该方法。

**How to apply:** 写页面时先确认表单容器类型，再用对应的 Hook。一个页面可能同时有 Drawer 和 Modal，需要分别用 `useDrawer()` 和 `useModal()`。
