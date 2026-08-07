# [2026-08-07] [regression] 「复核记录员」工作流 + 复核标注就地逐条

**触发条件**：业务人员对 AI 生成的回归测试报告做复核时，AI 应该作为「复核记录员」接收口头反馈，并按结构化模板填入报告。

**处理方式**：

## 1. 「复核记录员」工作流（避免 AI 误判 + 业务人员友好）

**关键原则**：
- ✅ 业务人员**不懂技术**，口头反馈（"4.X 是真实 BUG / 误判，因为 XXX"）
- ✅ AI 接收反馈 → 查技术根因（grep / 读测试代码 / 读前端代码）→ 用 edit 工具填入结构化标注
- ❌ 不要让业务人员直接编辑 markdown
- ❌ 不要让 AI 一次性自动填所有（容易误判）

**工作流 3 步**：

```
1. 业务人员口头反馈：「4.X <slice_id> 是真实 BUG / 误判，因为 <原因>，严重度 P0/P1/P2/P3，负责人 XXX」
       ↓
2. AI 主动核实（grep 关键错误 / 读测试代码 / 读前端代码）
   - 找到根因（如 setScale 截断 / v-if 屏蔽 / drawOnClose 时序）
   - 区分业务误判 vs 真实 BUG
       ↓
3. AI 用 edit 工具填入「复核结果」section（结构化模板）
   - 判定 / 严重度 / 业务侧原因 / 跟进负责人 / 复核人 / 时间
```

**结构化模板**（必含字段）：

```markdown
> 📋 **复核结果**：✅/⏳ **<判定>** | 严重度 <P> | <业务侧原因> | 跟进：<负责人> | 复核人 <业务人员+AI> / <YYYY-MM-DD>
```

## 2. 复核标注必须就地逐条显示（业务人员要"一个个核实"）

**业务人员明确要求**（2026-08-07 原话）：
> "复核结果在具体问题点也标注下，比如：MES 批次追溯 V10.0.3 批次级 E2E › 5. 导出按钮可见 + 点击触发下载 在 测试位置：171:7 记录下，参考：测试位置：171:7。这个也固化下，方便我一个个核实问题点"

**实现方式**：
- ❌ 不能只把复核结果放在 4.X 顶部的「复核结果」section（汇总里）
- ✅ 必须在每个具体「测试位置：`X:Y`」行旁加复核标注（就地）
- ✅ 每条标注格式：`> 📋 **复核结果**：...`

**对应代码模式**（已固化到 20260807-032053 报告）：

```markdown
- 测试位置：`171:7` 标题：›  ... › 5. 导出按钮可见 + 点击触发下载
  操作步骤：
    ...
  预期结果（业务描述）：...
  实际结果：...
  > 📋 **复核结果**：✅ **误判**（报告生成器归类错误） | 严重度 P3 | 业务人员实测... | 跟进：regression-report.js 修复 issue 归类逻辑 | 复核人 业务人员 / 2026-08-07
```

**好处**：
- 业务人员能"逐条核实"，不用跳来跳去
- 报告交付给 PM/leader 时，每条失败都有完整「判定 + 原因 + 跟进」
- 后续 AI 复盘（retro）时可直接 grep 抽取误判

## 3. edit 工具的"oldText 必须唯一"陷阱（4.2/4.8 traceabilityBatch 段处理）

**陷阱**：
- 4.2 和 4.8 中的 traceabilityBatch 段（8 个测试位置）**完全相同**（同一 spec 文件的同一组测试）
- 用 `edit` 工具的 oldText 必须 unique，否则 `Found N occurrences` 报错
- 解决方法：oldText 必须包含**足够上下文**（如前置的 `actual_result` 行）+ **后续不同部分**（如下一个 spec 标题）

**应对 3 招**：

```python
# 招 1：用前置/后置不同行做 anchor
# 4.2 前面是 other-stock-in "实际结果：断言失败【总金额 18.6765】"
# 4.8 前面是 sales-outbound "实际结果：Error: 销售出库 行操作按钮数"
# 在 oldText 里加入前置行做 unique

# 招 2：用 python 替换（最稳）
import re
content = content.replace(old, new)  # 自动替换所有

# 招 3：分多次 edit，每次只针对 1 处（用 oldText 的更大上下文做唯一）
```

**实际场景**：
- 4.2 / 4.8 traceabilityBatch 8 个测试位置同时更新 → 用招 2（python replace 一次完成）
- 4.2 复核结果 section（与 4.8 顶部略有不同）→ 用招 1（前置上下文区分）

## 4. 业务语言转换（让非技术业务人员能读懂）

**反向需求**（2026-08-07 业务人员经常问）：
- "ledger 字段是哪个字段？"
- "R005 搜索特殊字符：操作步骤里输入什么值报错的？"
- "批次级字段是指？"
- "这两个数字 18.6765 和 18.68 差 0.0035，是真 bug 还是测试期望问题？"

**应对**：
- AI 必须能**主动展开技术术语**（如 `bizType / bizNo / inQty / outQty / occurTime / remark` 是旧 ledger 字段）
- AI 必须能**主动解释业务背景**（如 V10.0.5 schema 重构，旧字段被替换）
- AI 必须能**主动算账**（如 18.6765 × 1 = 18.68，是后端 setScale(2) 截断）

**已固化到报告生成器**（`harness/scripts/regression-report.js` 的 `toBusinessLanguage()` + `FIELD_NAME_MAPPING`）。

## 5. 业务人员追问的"根因深挖"模式

**业务人员不会直接给根因**，但会问具体问题暴露线索。AI 必须能**串线索**：

```
业务："R005 搜索特殊字符不报错，操作步骤里输入什么值报错的？"
  → 暴露：业务不知道具体输入值
  → AI 查：traceabilityBatch.spec.ts:96 实际测试了 4 个特殊字符
  → 业务人员实测这 4 个：全部正常返回空数据 → 误判
```

```
业务："MES 批次追溯 V10.0.3 批次级 E2E › 4. 点击查看追溯 → 抽屉显示口径提示 + 流水表 真实bug"
  → 业务明确判定为真实 bug
  → AI 查：TraceabilityDrawer.vue 模板、listLedgerByBatchId 调用、5s timeout
  → 跟进：前端工程师排查 v-if/data 时序
```

**AI 必须做的**：
- 每次业务人员提问时，主动展开技术细节（不是回答完就走）
- 把"业务问题"映射到"技术根因"，让业务人员决定判定

## 关联命令 / 文档

- `.claude/commands/test/regression-review.md` — 双源复核
- `.claude/commands/test/regression-retro.md` — 误判复盘
- `harness/.regression-runs/20260807-032053/regression-report.md` — 30+ 条复核标注实例
- `.claude/rules/testing.md` L5 — 5 大误判模式规则
- `hermes/plan/regression-report-template-evolution.md` 第 12/13 章

## 参考

- 本次会话产出的回归报告：`harness/.regression-runs/20260807-032053/regression-report.md`
- 报告模板 v3.0 七段结构学习：`.claude/memory/learnings/2026-08-07-regression-report-field-evolution.md`
- 三步流程 + run-dir 记忆：`.claude/memory/learnings/2026-08-07-regression-double-review.md`
