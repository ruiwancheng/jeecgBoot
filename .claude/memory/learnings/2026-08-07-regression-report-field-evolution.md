# 2026-08-07 回归测试报告字段优化（v3.0 七段结构）

## 用户反馈流程（6 轮迭代 → 6 commits）

| # | 用户原话 | commit | 解决 |
|---|---|---|---|
| 1 | "需注明操作步骤/路径/问题点" | 74cdc2b | 第四节新增「复现步骤」+「复核结果」固定字段 |
| 2 | "怎么复现，登陆系统 有问题？" | 3106829 | extractSection 正则 bug（贪婪吞换行） |
| 3 | "问题点呢？" | 33e11f6 | 复现步骤补全「问题点」段（actual_error） |
| 4 | "再增加 预期结果 和 实际结果，注意用业务语言" | d672b76 | toBusinessLanguage() 函数 + 6 种模式转换 |
| 5 | "著名具体是哪个字段 期望值 20，实际值 15" | 581eac5 | FIELD_NAME_MAPPING (40+ 字段) + stack 提取真实行号 |
| 6 | "复核结果 是 AI 根据业务人员口头反馈记录的" | a0ffb6a | 复核结果改由 AI 填充（业务人员不直接编辑） |

## 固化要点（避免回退）

### evidence-reporter.ts errorText()
- 必须用 `error.stack || error.message`，让 issues/*.md「实际错误」含 `at .../spec.ts:75:34`
- 否则 extractRealLineFromErrorStack 拿不到真实 expect 行号，字段名定位失效

### parseIssueMd lineGet()
- 必须去掉 markdown 反引号：`replace(/^`/, '').replace(/`$/, '')`
- 否则 `issue.test_name` 多出 backticks，specFile 路径错位 → 字段名为空

### extractSection()
- 不能用 `## ${header}\\s*\\n([\\s\\S]*?)(?=\\n## |$)` 正则，`\\s*` 贪婪吞换行
- 必须用 `txt.split(/^## /m)` + 字符串匹配

### FIELD_NAME_MAPPING + NOISE 过滤
- NOISE 必含：result/data/records/keys/code/id/name/type/value/date/time/costValue/expectedCost/accessToken/loginRes/apiRes
- 否则输出 "断言失败【总金额(totalAmount)、code(code)】" 噪音

## 业务人员 + AI 协作工作流

```
回归跑完 → 生成报告（v3 模板） → 业务人员口头反馈 → AI 用 edit 工具填复核结果
```

**反馈模板**：「4.X <slice_id> 是真实 BUG / 误判，因为 <原因>，严重度 P0/P1/P2，负责人 XXX」

**AI 填入格式**：
```markdown
**复核结果**：
- 判定：真实 BUG / 误判
- 严重度：P0 (阻塞) / P1 (主流程) / P2 (次要) / P3 (无需跟进)
- 业务侧原因：<业务人员原话>
- 跟进负责人：<姓名>
- 复核人 / 时间：<业务人员名> / 2026-MM-DD
```

## 数据流

```
evidence-reporter (Playwright 测试时自动跑)
   ↓ 输出 issues/*.md
parseIssueMd → issue.{test_name, code_location, page_path, actual_error, reproduction, expected}
   ↓
extractRealLineFromErrorStack(actualError, specFile) → 真实 expect 行号
extractFieldFromSpecFile(specFile, lineNumber) → 字段名 (item.bookQty)
FIELD_NAME_MAPPING[bookQty] = '盘点账面数量'
toBusinessLanguage() → '断言失败【盘点账面数量(bookQty)、批次单位成本(unitCost)】：期望值 20，实际值 15'
```

## 完整 plan 文档

`hermes/plan/regression-report-template-evolution.md`（包含 11 节：演进时间线/模板结构/数据流/关键修复/字段语义映射/toBusinessLanguage 规则/工作流/反馈模板/验收/未来可优化/参考）

## 验证命令

```bash
# 重新生成当前 run 的报告
node harness/scripts/regression-report.js --run-dir 20260807-032053
# 检查 4.1 8.2-stocktake 是否包含完整 7 段
grep -A 30 "4.1 \`8.2-stocktake" harness/.regression-runs/20260807-032053/regression-report.md
```

## 关键文件位置

- 模板：`harness/templates/regression-report.md`
- 生成器：`harness/scripts/regression-report.js`
- 数据源：`harness/e2e/reporters/evidence-reporter.ts`
- 输出：`harness/.regression-runs/<run-id>/regression-report.md`
- 双写归档：`hermes/eagle-eye/reports/<date>/resilient-regression-recovery.md`