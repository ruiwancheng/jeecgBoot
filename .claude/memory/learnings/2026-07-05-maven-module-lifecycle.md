[2026-07-05] [Maven] 新客户模块的完整注册链
触发：在 jeecg-boot-module 下新增 Maven 模块
处理：必须三处注册：boot-module/pom.xml(module) + system-start/pom.xml(dependency) + mvn install。漏 system-start 导致 DependencyResolutionException。/new-customer 已自动处理。
