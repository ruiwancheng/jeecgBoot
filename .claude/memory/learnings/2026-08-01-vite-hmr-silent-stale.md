# Vite HMR 静默失败：edit 成功后端没拿新代码

**场景**：edit 一个文件 → ESLint 通过 → Playwright 跑测试看到**老行为** → 排查浪费 5+ 分钟。

**根因**：
- Windows 下的 `mvn -q install` + `kill PID` + `nohup mvn spring-boot:run` 链路里，**有时 mvn 编译静默失败**（q 模式不输出），但 exit code 0
- 或者后端进程被 kill 后**端口被旧进程持有**但 PID 换了
- 真正运行的是更早的 java 进程（devtools 热加载了早的 class）

**症状**：
- 改完代码 ESLint OK
- API 调用返回**老结果**（仿佛代码没生效）
- 后端日志没有你刚加的 debug 输出
- 但 dev tools 里 `localhost:8080` 是连得上的

**自检三招**（5 秒内定位）：

1. **看后端实际跑的是哪个 class**
   ```bash
   ls -la jeecg-boot-module/project-mes/target/classes/.../ServiceImpl.class
   stat jeecg-boot-module/project-mes/target/classes/.../ServiceImpl.class
   ```
   → class 文件 mtime 应在你 edit 之后；若 mtime 是几分钟前**说明 mvn install 静默失败了**。

2. **看后端进程启动时间**
   ```bash
   ps -W 2>/dev/null | grep java
   # 或
   wmic process where "name='java.exe'" get processid,commandline
   ```
   → 对比你 `nohup` 启动的时间，应该是新的 PID + 新的 mvn 进程。

3. **强校验**（最稳）
   - **不用 `mvn -q install`**（q 静默），用 `mvn install 2>&1 | tail -20` 看到 BUILD SUCCESS
   - **先 `taskkill //PID 8080_owner //F`**（用 `netstat -ano | grep :8080` 找真正持端口的 PID），再用 `nohup mvn spring-boot:run` 启动
   - 启动后 `sleep 14`（spring boot 启动需要 10-15s）+ `curl http://localhost:8080/...` 确认 200

**预防**：
- `mvn` 永远用非 q 模式（要看到 BUILD SUCCESS 输出）
- 重启后端前一定 `netstat -ano | grep :8080` 找真实 PID
- 写脚本：每次改后端代码后，固化一段"restart-and-verify"流程

**实证**：
- 2026-08-01 调试批次流水重复时，edit 改完但 2 条 ledger——后端跑老 class（kill 错 PID 了）
- 之前好几次（特别是 /debug PR20260801-0008）也遇到"改了 SQL 但 DB 没变化"——mvn 静默失败
