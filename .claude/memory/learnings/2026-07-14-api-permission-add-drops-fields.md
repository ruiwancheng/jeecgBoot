---
name: api-permission-add-drops-fields
description: sys/permission/add API 会静默忽略 parentId/route/isLeaf 等关键字段，菜单注册必须用 SQL 或 Java Runner
metadata:
  type: reference
---

# sys/permission/add API 静默丢弃关键菜单字段

## 问题

通过 `POST /sys/permission/add` 创建菜单时，`parentId`、`route`（is_route）、`isLeaf` 等字段会被 API 静默忽略。API 返回"添加成功"但实际存储的值是 NULL 或默认值 false。

## 根因

`SysPermissionController` 的 `add()` 方法对请求体做了字段过滤或使用了部分字段映射。实体中的 `parentId`、`isRoute`、`isLeaf` 等字段可能通过不同名称映射。

## 解决方案

**菜单注册只用两种方式：**
1. **Java Runner**（推荐）：`MesMenuAutoRegisterRunner` 通过 `sysPermissionMapper.insert()` 直接写入，所有字段正确
2. **SQL INSERT**：直接写 `sys_permission` 表，可控制所有列

**绝对不要用 `sys/permission/add` API 创建菜单**，只用于运行时通过 UI 手动操作。

## 修复方法

如果菜单已通过 API 创建但字段缺失，用 SQL UPDATE 直接修复：
```sql
UPDATE sys_permission SET parent_id = 'mes_menu_001', is_route = 1 WHERE id = 'mes_product';
UPDATE sys_permission SET is_route = 1 WHERE id = 'mes_basic_material';
```

**How to apply:** 新模块的菜单注册一律走 Java Runner（`MesMenuRegistry`）+ SQL 兜底。永远不要用 API 创建菜单。
