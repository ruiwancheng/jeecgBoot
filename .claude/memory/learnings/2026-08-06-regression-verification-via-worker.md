# 回归测试体系验证必须派 worker 实测，静态检查会漏掉 P0

**触发条件：** 任何 harness/ 路径/报告/配置 重构后（Phase 1+2+3+4 整合类任务）。

**处理方式：**
1. **静态验证不够**：grep 字面量、JSON 合法性、Node 语法检查只能抓 trivial 问题。
2. **必须跑实际回归**：`python3 harness/scripts/resilient_regression.py start --manifest ...` 端到端跑一次，验证 3 路径报告均写入 + 行数一致 + 8 章节齐全。
3. **PI 自己跑会污染 context**：用户明确要求"你又没监控到"——subagent worker 在独立 terminal 跑，PI 主对话保持干净。
4. **subagent 派发两种方式**：
   - `subagent` 工具（agent=worker，model=deepseek-v4-pro）— 适合短任务
   - `orca terminal send` 直接 inject — 适合长任务（如回归 10-15 分钟）
5. **轮询策略**：每 90s 查一次 terminal tail，找关键词（"MATCH: Phase X"、"22 passed"、"无新问题"），命中即停。**最多 15 分钟超时**，避免死等。

**实证：** 2026-08-06 Phase 1+2+3+4 共发现 4 个 P0 bug，全部由 worker 跑测发现而非 PI 静态检查：
- Phase 1: slice 1.4 blocked_environment + 6 模块测试静默跳过
- Phase 3: L436 PROJECT 未定义（重构漏改）
- Phase 4: L369 路径双重嵌套（Python 传绝对路径）

**教训：** "代码改动 = 跑一次实测" 不是可选，是 mandatory。验证失败 = bugfix commit 接力，不能直接进 Phase N+1。

**配套：** 用户偏好（2026-08-06）"你又没监控到" → 用 90s 轮询 + 关键词检测主动捕获 worker 完成信号，而非被动等用户报告。