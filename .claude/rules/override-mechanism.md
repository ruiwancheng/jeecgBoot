---
name: override-mechanism
description: 覆盖机制——标品功能定制不直接改源码，用 Bean/路由/页面覆盖
glob: "**/*.java,**/*.vue,**/*.ts"
version: 1.0
---

# 覆盖机制

需要修改标品已有功能时，不直接修改标品文件：

## Bean 替换
客户模块中创建同名 Service Bean，标记 `@Primary`：
```java
@Service
@Primary
public class ProjectXxxServiceImpl extends XxxServiceImpl {
    // 覆盖标品方法
}
```

## 路由覆盖
客户目录下注册同名路由，路径加客户前缀：
```typescript
// project/{项目名}/xxx.ts
path: '/project/{项目名}/xxx'
```

## 页面覆盖
客户目录下创建同名 Vue 组件，通过菜单配置指向客户版本。

## 记录追踪
所有覆盖操作记录在 `project-{项目名}/.manifest.yml`：
```yaml
project: {项目名}
overrides:
  - type: bean
    original: XxxServiceImpl
    replacement: ProjectXxxServiceImpl
  - type: route
    path: /system/xxx
    replacement: /project/{项目名}/xxx
```

## 扩展表
不能修改标品表结构。在客户目录下创建扩展表（如 `c_{项目名}_order_ext`），通过外键关联标品表。
