# 部署控制台「重置状态」+「强制全量」——解 mvn 增量编译缓存问题

**触发条件：** 服务端部署控制台报"package does not exist"或"cannot find symbol"，但本地 `mvn install` 100% BUILD SUCCESS、代码已 commit + push。

**处理方式：**
1. **先按"重置状态"再部署**：部署控制台通常有"重置状态"按钮——清 target/ 和 node_modules/.vite/ 等缓存
2. **不重置只点"强制全量"**：跳过变更检测，按 maven clean install 全量重编
3. **服务端手动 mvn clean**（如果有 shell 访问）：
   ```bash
   cd /mnt/d/project/JeecgBoot/jeecg-boot
   mvn clean install -pl jeecg-module-system/jeecg-system-start -am -DskipTests
   ```
4. **taskkill 杀老进程 + 重启**（如果后端 jar 已最新但内存是老的）：
   ```bash
   PID=$(netstat -ano | grep :8080 | grep LISTENING | awk '{print $5}' | head -1)
   taskkill /F /PID $PID
   nohup java -jar jeecg-system-start-3.9.2.jar --spring.profiles.active=dev &
   ```
5. **不要相信"重试"按钮**：服务端脚本通常是 `mvn install` 增量编译，3 次重试都失败说明缓存未清，必须 clean

**实证：** 2026-08-02 服务端连续 5 次部署失败 1568s+（3 次前端 + 2 次后端），本地 mvn 100% SUCCESS——原因：服务端 `mvn install` 增量编译保留老 class。修复：客户端点"重置状态"+ 后端 taskkill 重启 → 8 个 commit 全部生效。耗时从 1 小时排查（手动编译+查日志）降到 30 秒（点 2 个按钮）。

**配套建议：** 部署控制台脚本里加 `mvn clean install` 替代 `mvn install`；或加 "clean build" 选项按钮（用户可手动触发）；CI 日志里打印"全量重编"vs"增量编译"标识。
