# 回归测试失败必须按"执行结果"和"复核结果"两层处理

**触发条件：** 写任何 E2E 或 API 回归测试、做 8.2 财务/生产/盘点大套件 runner、看到 `exit_code=1` 想算"产品 Bug 数"时。

**处理方式：**
1. **退出码 1 不等于产品 Bug**。runner 退出码只表示命令非零，必须叠加两层判定。
2. **第一层：runner 状态**（机器判定，不写产品报告）：`passed / failed / timeout / blocked_environment / interrupted`。
3. **第二层：复核分类**（要进 `issues/`）：`pending_review → suspected_bug → false_positive → confirmed_bug / test_defect / data_precondition / environment_issue / test_design_issue`。
4. **只有人工确认后的 `confirmed_bug` 才进产品问题列表**。其它都进 `hermes/eagle-eye/reports/YYYY-MM-DD/issues/`，不污染业务。
5. **每个失败必须生成路径化报告**（`scenario-metadata.json` + 自定义 Playwright reporter）：页面路径、复现步骤、预期结果、截图、视频、runtime-diagnostics（当前 URL、console error、pageerror、失败请求）。
6. **大套件必须按页面切片**：一个财务页面卡住 60 秒就 timeout，会拖垮所有页面；8.2 → 8.2-manufacturing / 8.2-finance / 8.2-stocktake。
7. **test 自身地址不能写死远程 IP**：把 `BASE_URL = 'http://100.122.125.106'` 这类硬编码统一替换为 `E2E_UI_BASE` / `E2E_API_BASE` / `HARNESS_BASE` 环境变量；否则会得到大量"远程访问失败"的假阳性。

**实证：** 2026-08-04 把 E2E 测试地址从硬编码 100.122.125.106 改为可配置环境变量后，原本"采购订单/入库/销售订单"等页面加载超时全部消失；没有改任何业务代码。
