---
description: 自有命令 — 深度巡检：定期执行性能基准+视觉证据+无障碍审计，输出趋势对比和修复建议
---

# /deep-inspect

对指定模块执行深度巡检，含性能基准测试、视觉回归检测和无障碍审计。

## 前置条件（2026-07-22 新增）

首次运行前需要初始化基线。以下检查清单在每次执行时自动验证：

- [ ] k6 已安装（`which k6`）或接受 curl 性能降级（无并发模拟，单请求延迟测试）
- [ ] Playwright 已安装（`npx playwright --version`）或接受手动截图降级（需人工打开浏览器截图）
- [ ] 后端在 8080 端口运行（性能测试需要）
- [ ] 前端在 3100 端口运行（视觉采集需要）
- [ ] 基线目录存在（`hermes/eagle-eye/benchmarks/`）——不存在则自动创建并标注"首次运行，建立基线，不作判定"

**首次运行行为：** 仅建立基线数据，不输出 PASS/FAIL 判定。输出提示"基线已建立，下次运行 /deep-inspect 时将进行趋势对比"。

## 流程

### 1. 加载领域知识

使用 `deep-inspect` 技能获取：
- 性能基准测试脚本模板（k6 + curl 降级方案）
- 视觉证据采集协议（Playwright 截图 + pixel-diff）
- 无障碍审计检查清单（WCAG 2.2 AA）
- 基线格式和趋势对比规则

### 2. 确定巡检范围

- 如果指定了模块名：只巡检该模块
- 如果未指定：巡检当前活跃项目（从 `features.json` 读取）
- 高风险模块优先（根据最近 git diff 频率和测试失败率）

### 3. 并行执行三步检查

**Step 1 — 性能基准：**
1. 检查 k6 是否可用
2. 从 `harness/tests/<module>/` 提取端点
3. 执行基准测试，与上次基线对比
4. 存储新基线（如果判定为"代表样本"）

**Step 2 — 视觉证据：**
1. 检查 Playwright 是否可用
2. 导航到模块关键页面（列表/新增/编辑/详情）
3. 截取桌面/平板/移动端三视口截图
4. 与上次截图做 pixel-diff 对比

**Step 3 — 无障碍审计：**
1. 运行 axe-core 扫描（通过 Playwright）
2. 解析违规项，按 WCAG 标准分类
3. 输出修复优先级排序

### 4. 输出报告

按 `deep-inspect` 技能中的报告模板输出，含：
- 三步各自的详细结果和判定
- 与上次巡检的趋势对比
- 按 P0-P3 分级的修复建议清单

### 5. 保存产物

- 报告：`hermes/eagle-eye/reports/YYYY-MM-DD/deep-inspect-<module>.md`
- 基线：`hermes/eagle-eye/benchmarks/<module>-baseline.json`
- 截图：`hermes/eagle-eye/evidence/<module>/YYYY-MM-DD/`
- 时间戳：更新 `hermes/eagle-eye/.last-deep-inspect`

## 建议触发频率

| 场景 | 频率 |
|------|------|
| 活跃开发中模块 | 每周 1 次 |
| 稳定维护模块 | 每 2 周 1 次 |
| 发布前 | 必须执行 |
| 全量级变更后（≥5 文件） | 建议执行 |
