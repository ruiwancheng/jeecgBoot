<!-- update-begin---author:pi---date:2026-08-07---for:【REGRESSION-RETRO】新增误判复盘命令，固化误判模式+改测试用例 -->
---
description: 自有命令 — 误判复盘：跑完回归双重复核后，复盘所有误判模式，提取可复用规则+修改测试用例
---

# /regression-retro --run-dir <run-id>

回归测试双重复核**完成后**（`/regression-review` 已结束），复盘所有误判：
1. 提取误判模式（为什么 AI 误判 / 测试用例为什么错 / 业务页面为什么废弃）
2. 写规则到 `code-style.md` / `audit-classification.md` / `frontend.md`
3. 改测试用例（删错断言 / 改错 URL / 改错期望值）
4. 累积到 `.claude/memory/learnings/<date>-regression-false-positive.md`

> **为什么必要**：2026-08-07 回归发现 30+ 处误判，多为同类问题（报告生成器误归类 / URL 错位 / 业务页面废弃未清理 / 测试期望与业务设计不符）。如果不复盘，下次回归会**继续踩同样的坑**。

## 使用方法

```bash
/regression-retro                            # 自动用最近一次 run-dir
/regression-retro --run-dir 20260807-032053  # 显式指定
```

## run-dir 自动检测（复用 regression-review 的 RESOLVE_RUN_DIR）

> **v2 优化 2026-08-07**：与 `/regression-review` / `/regression-decompose` 复用同一套 4 级 fallback 自动检测（`--run-dir` 参数 > `.claude/.regression-state.json` > 目录最新 mtime > 报错）。

```bash
RESOLVE_RUN_DIR() {
  local EXPLICIT="$1"
  if [ -n "$EXPLICIT" ]; then echo "$EXPLICIT"; return; fi
  if [ -f ".claude/.regression-state.json" ]; then
    local STORED=$(python -c "import json; d=json.load(open('.claude/.regression-state.json')); print(d.get('last_run_dir',''))" 2>/dev/null)
    if [ -n "$STORED" ] && [ -d "harness/.regression-runs/$STORED" ]; then echo "$STORED"; return; fi
  fi
  if [ -d "harness/.regression-runs" ]; then
    local LATEST=$(ls -t harness/.regression-runs/ 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then echo "$LATEST"; return; fi
  fi
  echo "ERROR: 无法确定 run-dir" >&2; exit 1
}

RUN_ID=$(RESOLVE_RUN_DIR "$1")
echo "[run-dir] $RUN_ID"
```

## 必须加载

1. 当前回归报告：`harness/.regression-runs/<run-id>/regression-report.md`（自动检测 run-dir）
2. `.claude/rules/code-style.md` / `audit-classification.md` / `frontend.md`
3. `.claude/memory/learnings/` 历史经验库
4. 报告模板演进文档：`hermes/plan/regression-report-template-evolution.md`

## 工作流（5 步）

### 0. 解析 run-dir（自动）

```bash
RUN_ID=$(RESOLVE_RUN_DIR "$1")
```

### 1. 抽取所有误判切片

从报告第四节「复核结果」section 抽取所有判定为「误判」的切片：

```bash
# 抽取误判切片（含判定 / 严重度 / 业务原因）
grep -B 1 -A 4 "误判" harness/.regression-runs/$RUN_ID/regression-report.md | head -200
```

输出误判清单：

| 切片 | 误判类型 | 根因 | 跟进 |
|---|---|---|---|
| 4.2 #5 traceabilityBatch | 报告生成器误归类 | issue 目录 Connection Refused 标签被错配 | regression-report.js 修复 |
| 4.8 purchase-ledger × 7 | spec URL 错误 | 测试 PAGE_PATH 写错（业务上叫库存台账） | 重命名 spec + 改 URL |
| 4.7 batch-ledger × 5 | 业务页面废弃 | V8.0.0 注册的页面在 V10.0.3 已被 traceability 替代 | 删 spec + 删前端 + 移菜单 |
| 4.7 batch-inventory × 2 | 测试用例与业务设计不符 | 业务上批次库存无新增功能，测试加了新增断言 | 删断言 |
| 4.6 basic-codeRule #4 | 测试用例与业务设计不符 | 业务无导出功能，测试加了导出断言 | 删断言 |
| 4.8 sales-outbound #8 | 测试用例与业务设计不符 | 业务是工具栏审核/取消，测试期望行内按钮 | 删断言 |
| ... | ... | ... | ... |

### 2. 误判模式分类（5 大类）

按根因把误判归类：

| 类别 | 特征 | 处理 |
|---|---|---|
| **A. 报告生成器误归类** | issue 目录匹配错（如 traceabilityBatch 全打 Connection Refused）| 修 `harness/scripts/regression-report.js` issue 归类逻辑 |
| **B. spec URL/文件名错位** | 测试用旧 URL / 旧名字（如 purchase-ledger 应是 inventory-ledger）| 重命名 spec + 改 PAGE_PATH |
| **C. 业务页面废弃未清理** | spec/前端/菜单还在但业务已下线（如 batch-ledger 已被 traceability 替代）| 删 spec + 删前端 + 移菜单 |
| **D. 测试用例与业务设计不符** | 业务上没这功能 / 业务用工具栏，测试期望行内 | 删断言 / 改断言 |
| **E. dev DB 残留干扰** | 测试期望 X，实际 dev DB 已有 Y 数据（如 stocktake 期望 20 实际 15）| 改 setupFixture / 加清理 |

### 3. 写规则到 .claude/rules/

**针对每类误判，写一条规则到对应 rules 文件**：

```markdown
# code-style.md 新增章节
## 回归测试常见误判（2026-08-07 复盘）

### A. 报告生成器 issue 归类
**触发**：issue 目录中所有 traceabilityBatch / inventoryAlert 条目都被打上 Connection Refused 标签，被 regression-report.js 误匹配到 failed 列表
**处理**：issue 归类前先核对 Playwright 日志的 ✓/✘ 标志，仅当 spec 实际失败才列入「失败的测试」

### B. spec URL/文件名错位
**触发**：测试用 `/project/mes/purchase/ledger` 但业务上叫"库存台账"，URL 是 `/project/mes/warehouse/ledger`
**处理**：测试 spec 文件名 + PAGE_PATH 必须与 `router/routes/modules/mes.ts` + `MesMenuRegistry` 对齐
```

### 4. 改测试用例（cleanup 脚本任务）

按误判模式分批创建 cleanup 任务：

```bash
# 任务 1：报告生成器 issue 归类修复
git checkout -b fix/regression-report-issue-classification
# 修 harness/scripts/regression-report.js
git commit -m "fix(report): issue 归类前核对 Playwright 日志 ✓/✘ 标志"

# 任务 2：spec URL/文件名错位
git checkout -b fix/spec-url-naming
# 重命名 purchase-ledger.spec.ts → inventory-ledger.spec.ts
# 改 PAGE_PATH
git commit -m "fix(test): purchase-ledger URL 错位（业务叫库存台账）"

# 任务 3：业务页面废弃清理
git checkout -b cleanup/batch-ledger-deprecated
# 删 spec + 前端 + 菜单
git commit -m "cleanup: 删 batch-ledger 页面（V10.0.3 已被 traceability 替代）"
```

### 5. 累积到 learnings + 更新状态文件

写一条 learning 到 `.claude/memory/learnings/<date>-regression-false-positive.md`：

```markdown
# [2026-08-07] [regression] 回归测试误判复盘 5 大模式

**触发条件**：跑完 /regression-review 后，所有 4.X failed 切片已分类（真实 BUG / 误判）

**5 大误判模式**：
1. A. 报告生成器 issue 归类错（traceabilityBatch 全标 Connection Refused）
2. B. spec URL/文件名错位（purchase-ledger 业务上叫库存台账）
3. C. 业务页面废弃未清理（batch-ledger 已被 traceability 替代）
4. D. 测试用例与业务设计不符（basic-codeRule 导出 / batch-inventory 新增 / sales-outbound 行内按钮）
5. E. dev DB 残留干扰（stocktake 期望 20 实际 15）

**处理方式**：
- 必走 `/regression-review` 双重复核（业务 + 独立 AI）
- 必走 `/regression-retro` 误判复盘（避免下次踩坑）
- 必走 `/regression-decompose` 真实 BUG 切片处理
- 误判模式固化到 `.claude/rules/code-style.md` `audit-classification.md` `frontend.md`
```

## 验证清单（必走）

- [ ] 所有误判切片已分类（5 大类）
- [ ] 规则已写 `.claude/rules/`（按误判类型）
- [ ] cleanup 脚本任务已派发（按误诊类型拆任务）
- [ ] learning 已写 `.claude/memory/learnings/<date>-regression-false-positive.md`
- [ ] 下次回归跑前已 commit + push

## 禁止事项

- 不要只改 1 个误判就停（必须全量复盘）
- 不要把误判的 cleanup 任务和真实 BUG 混在一起（拆任务）
- 不要在改测试用例时不写规则（规则 + 用例必须一起）
- 不要把误判复盘和真实 BUG 切片混在一起（走 `/regression-decompose`）

## 关联命令

- `/test-regression` — 跑回归测试
- `/regression-review` — 双重复核（前序，共享 run-dir 自动检测）
- `/regression-decompose` — 真实 BUG 切片处理（后续，共享 run-dir 自动检测）
- `/auto-learn` — 累积 learnings 到 rules（自检）
- `/decompose` — 大任务切片（cleanup 任务可借用）

## 状态文件更新（retro 完成后）

```bash
# retro 完成后 → next_step = regression-decompose
UPDATE_STATE() {
  python -c "
import json, datetime
state_file = '.claude/.regression-state.json'
state = json.load(open(state_file, encoding='utf-8')) if __import__('os').path.exists(state_file) else {}
state['next_step'] = 'regression-decompose'
state['updated_at'] = datetime.datetime.now().isoformat()
json.dump(state, open(state_file, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
"
}
UPDATE_STATE
```

## 参考

- 起源：2026-08-07 回归复盘，30+ 处误判
- 详细误判清单：`harness/.regression-runs/20260807-032053/regression-report.md` 第四节
- 双重复核流程：`/regression-review`
- 真实 BUG 切片：`/regression-decompose`
<!-- update-end---author:pi---date:2026-08-07---for:【REGRESSION-RETRO】 -->
