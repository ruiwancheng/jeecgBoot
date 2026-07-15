---
name: menu-route-false-404
description: sys_permission.is_route=0 导致前端路由不生成，直接返回404
metadata:
  type: reference
---

# 菜单 route=False 导致前端 404

## 问题

菜单在数据库中存在，权限检查也通过，但访问菜单 URL 时前端返回 404 "页面不存在"。

## 根因

JeecgBoot 的 BACK 权限模式下，前端根据后端返回的菜单数据动态生成路由。`sys_permission` 表的 `is_route` 字段控制是否生成路由：

- `is_route = 1` → 前端生成对应的 Vue Router 路由
- `is_route = 0` → 前端不生成路由，URL 无法访问

当菜单的 `is_route = 0`（false）时，即使权限正确，前端也没有对应的路由条目，直接 404。

## 修复

```sql
UPDATE sys_permission SET is_route = 1 WHERE id = 'mes_basic_material';
```

菜单注册时 `is_route` 必须设为 1（菜单类型 0 和 1 都需要）。

**How to apply:** 排查前端 404 时，首先检查 `sys_permission` 表中对应菜单的 `is_route` 是否为 1。
