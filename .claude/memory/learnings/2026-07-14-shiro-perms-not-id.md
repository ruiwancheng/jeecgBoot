---
date: 2026-07-14
category: 权限
tags: [Shiro, @RequiresPermissions, perms, sys_permission, 权限注册]
---

# Shiro 权限匹配的是 perms 列不是 id 列

## 触发条件
在 JeecgBoot Controller 上加 `@RequiresPermissions("mes:warehouse:add")` 后，接口始终返回 "Subject does not have permission"。

## 根因
Shiro 的 `doGetAuthorizationInfo` → `getUserPermissionSet` → `queryByUser` 查询 `sys_permission` 后，取的是 **`permission.perms`** 列的值加入权限集，不是 `permission.id` 列。

```java
// SysBaseApiImpl.java:1248
if (oConvertUtils.isNotEmpty(po.getPerms())) {
    permissionSet.add(po.getPerms());  // ← perms 列，不是 id！
}
```

如果 `INSERT INTO sys_permission` 只设了 `id='mes:warehouse:add'` 而 `perms` 列为空，Shiro 权限集里就没有这个权限字符串，`@RequiresPermissions` 永远匹配不上。

## 正确做法
注册权限码时 **同时设置 `id` 和 `perms`**，两者通常相同：

```sql
INSERT INTO sys_permission (id, perms, ...) VALUES ('mes:warehouse:add', 'mes:warehouse:add', ...);
```

Java 侧：
```java
p.setId(def.getId());
p.setPerms(def.getPerms()); // ← 必须设，通常 perms = id
```

## 诊断方法
```sql
SELECT id, perms FROM sys_permission WHERE id LIKE 'mes:%';
```
如果 `perms` 列为 NULL 或空，就是这个问题。
