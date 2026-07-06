---
name: route-menu-hierarchy
description: 前端路由层级必须与数据库菜单层级完全匹配，否则报"路径不存在"
metadata:
  type: reference
---

# 前端路由与数据库菜单层级必须一致

## 问题

打开页面报错"路径不存在，请检查路径是否正确"（来自后端 `JeecgBootExceptionHandler` 404 处理）。

## 根因

数据库菜单中的父级菜单（`component=layouts/default/index`）必须有对应的前端路由层级。层级不匹配时，前端无法生成正确的路由树。

**错误示例：**
数据库菜单：
```
MES (父级, component=LAYOUT)
  └── 基础设置 (父级, component=LAYOUT)  ← 需要中间路由
        └── 仓库管理 (叶子)
```
前端路由（缺中间层）：
```
/project/mes (LAYOUT)
  └── basic/warehouse  ← 直接挂载，无 basic 父路由！
```

**正确示例：**
```typescript
/project/mes (LAYOUT)
  └── basic (LAYOUT)     ← 必须存在
        └── warehouse    ← 正常
```

**Why:** JeecgBoot 按菜单树的 `parent_id` 和 `component` 逐层匹配路由。每一层有 `component=LAYOUT` 的父菜单都需要对应的路由中间节点。

**How to apply:** 新增菜单层级时，每增加一级中间菜单（component 为 LAYOUT），前端路由文件也必须新增对应层级。
