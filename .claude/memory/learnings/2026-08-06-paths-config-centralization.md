# 路径配置集中化 ROI 极高：harness/config/paths.json 模板

**触发条件：** 任何有多个 driver 共享同一文件系统布局的项目（harness/scripts/、tools/、infra/ 等）。

**处理方式：**
1. **单一真相源**：新建 `harness/config/paths.json`（或 `<root>/config/paths.json`），所有路径常量集中。
2. **Python + Node 对称 API**：
   - Python: `_paths.py` 导出 `PATHS / REPO_ROOT / resolve() / load_paths() / reload_paths()`
   - Node: `_paths.js` 导出 `PATHS / REPO / resolve() / loadPaths()`（同名同语义）
3. **Fallback 设计**：缺文件时返回硬编码字典，保证向后兼容；环境变量 `HARNESS_PATHS_FILE` 可覆盖（CI 友好）。
4. **`${date}` 模板**：helper 函数 `resolve(path, date=None)` 自动展开，本地时间（与 Python `datetime.now()` 一致，避免 TZ 漂移）。
5. **REPO_ROOT 锚点保留**：cwd/relative_to 类用法仍需锚点，不要把所有路径都塞进 PATHS（如 `path.relative_to(REPO_ROOT)`、`cwd=REPO_ROOT`）。
6. **新字段加 fallback 同步**：每次 paths.json 加字段，_paths.py / _paths.js / FALLBACK 三处必须同步更新（避免漂移）。
7. **DETACHED runner 限制**：load_paths() 在 import 时执行，detached 长进程（>30 min）编辑 paths.json 不自动生效，需重启或调用 reload_paths()。

**实证：** 2026-08-06 Phase 3 一次完成 6 driver 切换（resilient_regression.py / regression-report.js / run-batch.js / coverage.js / regression_dashboard.py / regression_plan.py），后续 Phase 4 复用同一机制。

**配套：** report_delivery_error 等与 driver 状态相关的字段应单独存放，不混在 paths.json 里（paths.json 是只读配置）。