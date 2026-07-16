---
date: 2026-07-16
category: 基础设施
tags: [Runner, 菜单注册, parentId, fixIfNeeded, 自修复]
---

# Runner 自修复 detect 逻辑需检测"不一致"而非仅"为空"

## 触发条件
菜单 parentId 从 `mes_sales` 改为 `mes_warehouse`，部署后菜单位置没变。Runner 的 `fixIfNeeded` 日志显示"跳过"。

## 根因
`fixIfNeeded` 的 parentId 检测逻辑是：
```java
if (isEmpty(exist.getParentId()) && !isEmpty(def.getParentId())) { // 修复 }
```
只修 parentId 为空的情况，不修 parentId 不一致的情况。当菜单已存在且 parentId 已设置时，即使定义变了也不会自动修正。

## 正确做法
```java
if (!isEmpty(def.getParentId()) && !def.getParentId().equals(exist.getParentId())) { // 修复 }
```
检测定义值与当前值是否不同，而非仅判空。此原则同样适用于 name/url/component 等可能变更的字段。
