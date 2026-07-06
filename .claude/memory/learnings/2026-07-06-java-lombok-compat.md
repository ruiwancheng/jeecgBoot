# Java 版本与 Lombok 兼容性

**触发条件：** Maven 编译报 `找不到符号 变量 log`，`@Slf4j` 注解不生效。

**处理方式：**
1. 检查 `mvn -version` 显示的 Java 版本
2. JeecgBoot 3.9.2 仅支持 Java 17/21/24，Java 26 下 Lombok 注解处理器失效
3. 切换到项目支持的 Java 版本编译：
```bash
export JAVA_HOME=/path/to/jdk-17/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
mvn clean install -DskipTests -pl ...
```
4. 用 `mvn spring-boot:run` 启动时也必须使用 Java 17，否则 `customer-demo` 等模块依赖解析也会失败
