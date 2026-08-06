<!--
MES 回归测试报告模板（v2）
基于 2026-08-04 Sprint Review 风格（CLAUDE.md 工作流 + SKILL.md 标准）

输出位置：
  harness/.regression-runs/<run-id>/regression-report.md  （本次运行的详细分析报告）
  hermes/eagle-eye/reports/<YYYY-MM-DD>/regression-report.md  （每日归档）

要求：用真实数据填充占位符 {{...}}，不允许保留模板标记。

v2 (2026-08-07) 更新：
  - 第四节「失败切片逐条分析」新增两个固定字段：
    · 复现步骤（自动从 issues/*.md 抽取）
    · 复核结果（业务人员手工填写：真实BUG / 误判 + 原因）
  - 任何后续回归报告必须包含这两段，业务人员才能完成核实
-->
# MES 可恢复回归报告 — {{date}}

> **报告时间**：{{datetime}}
> **运行 ID**：`{{run_id}}`
> **任务**：{{task_name}}
> **范围**：{{scope}}（{{slice_count}} 个切片）
> **关联**：`harness/.regression-runs/{{run_id}}/summary.md` + `hermes/eagle-eye/reports/{{date}}/issues/`

---

## 一、通过率总览

| 指标 | 数值 |
|------|:--:|
| **总切片数** | {{total}} |
| **passed** | {{passed_count}} ✅ |
| **failed** | {{failed_count}} ❌ |
| **verdict** | {{verdict_count}} ⚖️ |
| **pending** | {{pending_count}} ⏸ |
| **通过率** | {{pass_rate}}% |
| **总耗时** | {{duration_total}} |

---

## 二、本次会话关键改动（commit 链）

| Commit | 类型 | 说明 |
|---|---|---|
{{commits_table}}

---

## 三、各切片结果

| 切片 | 名称 | 状态 | 耗时 | 备注 |
|---|---|:---:|:--:|---|
{{slices_table}}

---

## 四、失败切片逐条分析（按建议核实顺序）

> 每个失败切片包含 **状态 / 症状 / 关键错误 / 失败的测试 / 复现步骤 / 复核结果 / 修复建议** 七段。
> **复现步骤** 由报告生成器自动从 `hermes/eagle-eye/reports/{{date}}/issues/` 抽取；
> **复核结果** 是 AI 根据业务人员口头反馈记录的（业务人员不直接编辑报告）。
> 当业务人员核完一条后，给 AI 一句中文描述（例：「这条是 dev DB 残留数据导致的误判」），AI 会填入对应小节。

{{failure_sections}}

---

## 五、E2E 失败复核证据

- 复核目录：`hermes/eagle-eye/reports/{{date}}/issues/`
- 复核文件：{{issue_count}} 个（每个失败 spec 包含 .md + .json + runtime-diagnostics.json）

{{issue_summary}}

---

## 六、技术债务与遗留风险

### 6.1 已修复

| 问题 | 修复 commit | 验收方式 |
|---|---|---|
{{fixed_issues}}

### 6.2 剩余风险

| 风险 | 严重度 | 说明 | 建议 |
|---|:--:|---|---|
{{remaining_risks}}

---

## 七、用户待办（AI 记录复核结果）

> 工作流：**业务人员口头复核 → 通知 AI → AI 用 edit 工具填入对应小节**
>
> 业务人员不需要懂技术，不需要操作 markdown，只需要用中文口头反馈给 AI。
> 反馈模板：
>   「4.X <切片id> 是真实 BUG / 误判，因为<原因>，严重度 P0/P1/P2，负责人 XXX」
>
> AI 收到后会在第四节对应小节填入以下结构：
> ```markdown
> **复核结果**：
> - 判定：真实 BUG / 误判
> - 严重度：P0 (阻塞) / P1 (主流程) / P2 (次要)
> - 业务侧原因：...
> - 跟进负责人：...
> - 复核人 / 时间：业务人员名 / YYYY-MM-DD
> ```

{{user_todo}}

---

## 八、后续选项

- **选项 A**：跟进剩余 failed 切片
- **选项 B**：前端 Bug 修复（移交前端工程师）
- **选项 C**：覆盖率维护 + 新增 slice
- **选项 D**：其他指示

---

报告生成完毕。请用户手工核实第 1-5 项 + 失败逐条分析（第四节，每条须含「复核结果」）。确认无误后告知选哪个选项。
