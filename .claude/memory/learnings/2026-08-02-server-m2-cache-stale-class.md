# 服务端 m2/target 缓存——本地编译过但服务端报"缺类/方法"

**触发条件：** 服务端部署控制台报 `package does not exist` 或 `cannot find symbol`，但本地 `mvn install` 100% BUILD SUCCESS 确认代码 OK。

**处理方式：**
1. **确认两端代码一致**：`git log` 看 commit hash 一致；`git status` 看是否有 untracked 未推送文件
2. **看服务端部署脚本**——是用 `mvn install`（增量编译）还是 `mvn clean install`（全量重编）？增量编译会保留老 class
3. **强制全量重编**：服务端加 `mvn clean install -pl <module> -am -DskipTests`，或部署控制台点"重置状态"清 target/
4. **验证后端实际用的 class**：本地 `strings <file>.class | grep <feature>` 看字段是否在；或看后端启动日志确认用的是哪个 jar
5. **后端进程没真正重启时**：用 `netstat -ano | grep :8080` 看 PID；`taskkill /F /PID` 后用新 jar 启

**实证：** 2026-08-02 排查 1 小时——服务端报"package mes.system.service does not exist"，本地 `mvn install` 100% SUCCESS，`git status` 显示未推送的 untracked 文件。补 commit 后服务端仍报同样错——原因：服务端 `mvn install` 增量编译保留老 class（target/ 里是 commit 5b58a29 时代的 class，没含新加的 IMesGlobalSwitchService）。修复：服务端加 `mvn clean install` 或 `taskkill` 杀老进程 + `java -jar` 重启新 jar。

**配套检查：** 部署脚本里建议加 `mvn clean` 或保留 `target/clear` 钩子；本地 debug 完确认新 class 在 jar 里（`unzip -p fat.jar BOOT-INF/lib/mes.jar | strings | grep feature`）。
