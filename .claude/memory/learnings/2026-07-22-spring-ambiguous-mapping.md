# [2026-07-22] [Spring] Controller同名路径方法冲突导致启动失败

## 触发条件
MesCustomerController 中两个 `selectPage` 方法映射到同一个URL `/mes/basic/customer/selectPage`，但方法签名不同（一个多参数用于分页，一个单参数用于下拉选择）。Spring Boot 启动时抛出 `Ambiguous mapping` 异常，导致整个后端无法启动。

## 现象
- 部署后服务端报"网络错误"
- 本地日志: `java.lang.IllegalStateException: Ambiguous mapping. Cannot map 'mesCustomerController' method`
- 无任何HTTP响应，8080端口连接被拒

## 修复
将下拉专用的方法改名为 `selectDropdown`，路径改为 `/selectDropdown`：
```java
// 修改前
@GetMapping("/selectPage")
public Result<List<Map<String,String>>> selectPage(@RequestParam String keyword)

// 修改后
@GetMapping("/selectDropdown")
public Result<List<Map<String,String>>> selectDropdown(@RequestParam String keyword)
```

## 教训
- 同一Controller内不同用途的方法必须使用不同URL路径
- 编译通过不代表运行时正常——`mvn compile` 无法检测Spring映射冲突，需要启动后才能发现
- project-mes 作为JAR加载到本地Maven仓库，修改源码后需 `mvn install`（非 `mvn compile`）才能让主应用加载到新版本

## 关联
- MesCustomerController.java (line 82 vs line 149)
- 部署: `mvn clean install -pl jeecg-boot-module/project-mes -am`
- ✅ 已覆盖: `code-style.md` Java → Controller 规则
