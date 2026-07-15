---
name: mask-sensitive-copy
description: 脱敏操作必须操作副本，禁止直接修改ORM分页结果中的实体引用
metadata:
  type: reference
---

# 脱敏数据回写——列表脱敏污染编辑保存

## 问题

Controller 在分页查询后对 `page.getRecords().forEach(this::maskSensitive)` 直接修改 `@TableName` 实体对象的字段。前端编辑抽屉用 `setFieldsValue({...data.record})` 回填脱敏后的值，用户保存时 `****` 后缀写回数据库，覆盖真实数据。

## 根因

Java 对象是引用类型。`page.getRecords()` 返回的是 MyBatis-Plus 分页结果中实体的**原引用**。`setBankAccount("6222****")` 修改的就是这个引用。前端拿到脱敏值后，编辑表单再提交，后端接收到的就是脱敏后的脏数据。

## 修复方案

**方案A（推荐）：新增 queryById 接口**
```java
@GetMapping("/queryById")
public Result<MesSupplier> queryById(@RequestParam String id) {
    return Result.ok(service.getById(id)); // 不脱敏，返回完整数据
}
```
编辑时调 queryById 拿真实值，列表仍用脱敏展示。

**方案B：脱敏在副本上操作**
```java
List<MesSupplier> masked = page.getRecords().stream()
    .map(s -> { MesSupplier copy = new MesSupplier(); BeanUtils.copyProperties(s, copy); mask(copy); return copy; })
    .collect(Collectors.toList());
page.setRecords(masked);
```
太重了，不推荐。

**How to apply:** 任何对 API 响应内容做脱敏的场景，要么提供独立的非脱敏查询接口供编辑使用，要么在副本上操作。**永远不要直接修改 MyBatis-Plus 实体引用。**
