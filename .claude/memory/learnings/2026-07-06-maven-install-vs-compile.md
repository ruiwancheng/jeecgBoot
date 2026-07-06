---
name: maven-install-vs-compile
description: 新增 Maven 模块必须 mvn install（非 compile），否则 spring-boot:run 找不到依赖
metadata:
  type: reference
---

# 新增 Maven 模块必须 install 而非只 compile

## 问题

新增 `project-mes` 模块后，`mvn compile` 通过，但后端启动后访问 API 返回 404 "路径不存在"。

## 根因

`jeecg-system-start/pom.xml` 中依赖声明：
```xml
<dependency>
    <artifactId>project-mes</artifactId>
    <version>${jeecgboot.version}</version>
</dependency>
```

`spring-boot:run` 从 Maven 本地仓库（`~/.m2/`）解析依赖，不直接读取源码 target 目录。`mvn compile` 只编译到 `target/`，不安装到仓库；`mvn install` 才会把 jar 安装到 `~/.m2/`。

## 解决

```bash
# ❌ 不够
mvn compile -pl jeecg-boot-module/project-mes -am

# ✅ 必须
mvn install -pl jeecg-boot-module/project-mes -am -DskipTests
```

**Why:** Maven 模块间依赖通过本地仓库传递，`compile` 产物在 target 目录但不在类路径上。这与修改已有模块不同——修改已有模块的代码，`spring-boot:run` 可以直接使用源码 target。

**How to apply:** 每次新增模块或新增外部依赖后，必须执行 `mvn install` 把 jar 安装到仓库，然后重启后端。
