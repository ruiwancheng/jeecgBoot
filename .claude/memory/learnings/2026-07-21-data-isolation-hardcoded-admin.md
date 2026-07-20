# [2026-07-21] [后端] 数据隔离硬编码admin用户名 — 多项目不兼容

## 触发条件
MES 项目管理员 `mes_admin` 登录后，客户管理页面数据为 0 条。
但 `admin` 账号登录能看到 31 条。

## 根因
Controller 数据隔离逻辑硬编码了用户名检查：
```java
// 错误：只认 admin
if (!"admin".equals(loginUser.getUsername())) {
    qw.eq("salesman_id", loginUser.getUsername());
}
```

MES 项目管理员是 `mes_admin` → 被当作普通业务员 → salesman_id 过滤 → 0 条。

## 正确处理
用 Shiro 角色判断替代用户名硬编码：
```java
// 正确：认角色，不管用户名
boolean isAdmin = SecurityUtils.getSubject().hasRole("mes_admin")
        || "admin".equals(loginUser.getUsername());
if (!isAdmin) {
    qw.eq("salesman_id", loginUser.getUsername());
}
```

## 适用范围
所有带数据隔离逻辑的 Controller，如果涉及用户名硬编码 `"admin"`，
在新项目（如 MES 用 `mes_admin`）都会出问题。
优先用 `hasRole()` 或查询 `sys_user_role` 表判断管理员身份。
