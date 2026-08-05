# harness 主动测试命令必须 .claude/commands 化，禁止写死平台专属命令

**触发条件：** 给业务人员、客户端开发者写"启动回归/布置环境"的说明时；或看到 `mvn.cmd` / `nohup` / `taskkill` / `netstat` / `localhost:3100` 出现在命令文档时。

**处理方式：**
1. **必须新增 .claude/commands/test/*.md**，AI 执行的是命令文件而不是 bash 块。
2. **测试命令三件套**：
   - `/test-environment --check | --local | --client | --remote <url>`：跨平台环境检查/布置。
   - `/test-regression --scope full | --scope change --base <commit>`：全量 or 变更感知回归。
   - `/test-regression --resume | --status | --stop | --dashboard`：会话崩溃后人工接管的入口。
3. **`--scope` 必须人工指定**，不要"自动选择"。业务人员决定"PR 验还是发版验"比 AI 默认选更安全，避免无关切片失败被错记为产品 Bug。
4. **绝对不要写死在 .claude/commands 里**：`mvn.cmd`（Windows）、`nohup mvn spring-boot:run &`、`taskkill /F /PID`、`netstat -ano | grep 8080`、`http://100.122.125.106:3100`。
5. **统一约定环境变量**：`HARNESS_BASE`（API）、`E2E_UI_BASE` / `E2E_API_BASE`（E2E）、`PLAYWRIGHT_BASE_URL`（Playwright 专用）；spec 内部用 `BASE` / `API_BASE` 注入。
6. **runner 命令必须 Python-only**：`subprocess.Popen(..., creationflags=DETACHED_PROCESS|CREATE_NEW_PROCESS_GROUP, start_new_session=os.name!='nt')`，禁止依赖 `bash` 专属语法。
7. **可恢复设计**：进程中断后 `resume` 优先复用 `state.json` + `state.json.fallback`，而不是从头开始；用 `recover_interrupted_state` 把 `running` 状态纠正为 `interrupted` 后再走正常 resume。

**实证：** 2026-08-04 新增 `.claude/commands/test/test-environment.md` + `test-regression.md` + `test-all.md`，以及对应 `test-environment` / `test-all` 两个 SKILL.md 后，业务人员用三行命令就能跑完整套测试；以前要看懂 6 个 shell 脚本还要切 Windows/PowerShell。

**配套：** harness 改造的 `harness/scripts/resilient_regression.py` 是命令底座，命令文件只是让 AI 选择并执行正确的 runner 子命令，不要把 shell 重写到命令里。
