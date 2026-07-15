---
name: self-invoke-proxy-failure
description: Service 内部 this.xxx() 自调用绕过 Spring AOP 代理，@Transactional 失效
metadata:
  type: reference
---

# Service 自调用绕过 Spring AOP——this.removeById() 事务失效

## 问题

```java
@Override
@Transactional
public boolean removeByIds(Collection<?> list) {
    for (Object id : list) this.removeById((Serializable) id);
    return true;
}
```

`this.removeById()` 是内部自调用，不走 Spring AOP 代理，`removeById` 上的 `@Transactional` 完全失效。批量删除中某条失败时，已执行的 N-1 条不回滚。同时产生 N 条独立 UPDATE，退化为 N+1 性能问题。

## 根因

Spring AOP 基于 JDK 动态代理（接口代理）或 CGLIB 子类代理。`this` 指向原始对象，不是代理对象。直接调用绕过了整个切面链：事务拦截器、日志拦截器等全部不会触发。

## 修复

```java
@Override
@Transactional
public boolean removeByIds(Collection<?> list) {
    if (list == null || list.isEmpty()) return false;
    return super.removeByIds(list); // 用 super 调基类，基类内部用 baseMapper.deleteBatchIds
}
```

MyBatis-Plus 的 `ServiceImpl.removeByIds()` 基类默认调用 `baseMapper.deleteBatchIds(list)`，生成一条 `UPDATE ... WHERE id IN (...)`，批量且事务完好。

**How to apply:** 任何 Service 方法中需要调用同类的另一个 `@Transactional` 方法时，**禁止用 `this.xxx()`**。改用：① `super.xxx()`（调基类）、② `AopContext.currentProxy()` + `((Self) proxy).xxx()`、③ 注入自己的代理 Bean。
