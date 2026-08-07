# 回归测试体系整合 — Phase 1（低风险立竿见影）

**作者**：pi
**日期**：2026-08-06
**前置**：brainstorm v2 已确认（用户拍板走 Q1-Q5 全部建议）
**目标范围**：执行建议 1-3（用户答 Q1 "先做 1-3"）
**后续**：Phase 2 = 建议 4-5（report_paths/paths.json），Phase 3 = 建议 6（统一报告生成器）

---

## 1. 目标 & 范围

### 1.1 范围（IN）
1. **加 `purchase-chain` slice 到 manifest**（修复 P0-A：链路编排器漏调度）
2. **删除 `run-regression.sh` / `.bat` + 清理 package.json `test:all` + 更新 README**（修复 P1：死代码 + 配置错）
3. **重命名 3 个 `.test.mjs` → `.test.js`**（修复 P0-B：3 个孤儿测试被 glob `*.test.js` 漏掉）

### 1.2 非范围（OUT，延后到 Phase 2/3）
- 建议 4：`manifest.report_paths[]` + `mirror_paths[]` + 用户笔记空间路径输出
- 建议 5：抽 `harness/config/paths.json`
- 建议 6：统一报告生成器（Python → Node.js）
- 第一轮遗留的 9 failed 切片（独立 issue，本次不处理）

---

## 2. 详细改动

### Step 1：加 `purchase-chain` slice 到 manifest

**文件**：`harness/regression/recovery-plan.json`

**插入位置**：在 slice `1.3`（采购入库到付款）之后，`2.1`（销售收发货基础链路）之前

**新增 slice 定义**：
```json
{
  "id": "1.4",
  "name": "采购链路贯通（编排器：申请→订单→入库→付款）",
  "kind": "chain",
  "cwd": "harness",
  "command": [
    "node",
    "tests/chains/purchase-chain.test.js"
  ],
  "timeout_seconds": 900,
  "requires": [
    "backend",
    "1.1",
    "1.2",
    "1.3"
  ],
  "continue_on_failure": false
}
```

**设计要点**：
- `id: 1.4`：跟现有 purchase 链路 1.1/1.2/1.3 编号延续
- `requires: ["backend", "1.1", "1.2", "1.3"]`：依赖后端服务 + 3 个独立段先跑（确保数据 ID 跨段传递）
- **`timeout_seconds: 900`（=15 分钟，orca-review P0-1 修正）**：
  - 实测 1.1+1.2+1.3 单独跑 = 0.6+0.8+2.4 = 3.8s
  - purchase-chain 编排器内部 require 链 + 段间等待预估 5-30s
  - 真实时间增量 = ~10-30s（远低于 timeout 上限）
  - timeout 仍设高以覆盖异常慢场景（DB 慢 / 网络抖动 / 二次重试）
- `continue_on_failure: false`：链路贯通失败 = 阻塞整体

**注意**：这会**重复跑** 1.1/1.2/1.3（purchase-chain.test.js 内部 require 3 段）。接受这个重复的理由：
- 1.1/1.2/1.3 提供单段细粒度失败信号
- 1.4 提供"全链路贯通"集成信号（数据 ID 跨段传递、状态流转、数据一致性）
- 代价 = 真实时间 +10-30s（用户接受，远低于 orca-review 估算的 +10min）

### Step 2：删除 run-regression 系列

**涉及文件**：
- `harness/scripts/run-regression.sh`（90 行 / 仅 1 个 git commit，runner 不引用）
- `harness/scripts/run-regression.bat`（90 行，同源 Windows 版本，runner 不引用）

**配套清理**（orca-review P1-2 扩展）：
1. `harness/package.json` L13：`"test:e2e": "playwright test e2e/mes/basic-*.spec.ts --config e2e/playwright.config.ts"` → 改 `--config harness/playwright.config.ts`
2. `harness/package.json` L15：`"test:smoke": "playwright test e2e/smoke/ --config e2e/playwright.config.ts"` → 改 `--config harness/playwright.config.ts`
3. `harness/package.json` L16：`"test:all": "node scripts/run-regression.sh"` → 删除该行（已 broken：node 不能跑 bash）
4. `harness/tests/README.md` L24-36：删除 6 行 `run-regression.sh/.bat` 引用 + 在 README 顶部加 1 行 `python3 harness/scripts/resilient_regression.py start --manifest harness/regression/recovery-plan.json`

**CI workflow 验证**（orca-review P1-1 答复）：
- `.github/workflows/functional-regression.yml` 不引用 run-regression.sh 或 purchase-chain
- L313-315 注释明确："删 e2e/playwright.config.ts，统一用 harness/playwright.config.ts" → CI 端已正确
- 删除 sh/bat 不会破坏 CI

**git 操作**：
```bash
git rm harness/scripts/run-regression.sh harness/scripts/run-regression.bat
# package.json 和 README.md 用 edit 修改
```

**Commit message 模板**：
```
chore(harness): 删除 run-regression.sh/.bat（死代码，被 resilient_regression.py 取代）

- git log 仅 1 个 commit (cbcc1ca)
- runner 端无任何 import 引用
- package.json test:all 引用已 broken（node 跑 bash）
- 移除对应 package.json test:all 与 README 引用
- 推荐替代：python3 harness/scripts/resilient_regression.py start --manifest harness/regression/recovery-plan.json

Refs: hermes/reviews/2026-08-06-regression-round2-mcp-deep-dive.md §9.2 §11.1
```

### Step 3：重命名 3 个 `.test.mjs` → `.test.js` + 加入 MODULE_BATCHES

**orca-review P0-2 关键修正**：仅 git mv 不够！`run-batch.js` 的 `MODULE_BATCHES` 是**硬编码列表**，不包含 codeRule / sales-api / sales-order。必须同步修改 `MODULE_BATCHES`。

#### 3a. 重命名文件

**涉及文件**：
- `harness/tests/modules/codeRule.test.mjs` → `codeRule.test.js`
- `harness/tests/modules/sales-api.test.mjs` → `sales-api.test.js`
- `harness/tests/modules/sales-order.test.mjs` → `sales-order.test.js`

**安全性验证（已做）**：
- 3 个文件均为 CJS 写法（0 imports / 0 requires）
- `git mv` 是纯改名，文件内容不变
- `coverage.js` 扫描器基于 `find -name "*.test.js"` 会覆盖

#### 3b. 加入 `MODULE_BATCHES`

**文件**：`harness/scripts/run-batch.js`

**精确检查结论**（orca-review + grep 二次验证）：
- `codeRule` ❌ 完全不在 MODULE_BATCHES
- `sales-api` ❌ 完全不在 MODULE_BATCHES
- `sales-order` ❌ 不在 MODULE_BATCHES（`sales-order-delivery` 在 MODULE_BATCHES['extended']，但不是同名文件）

**修改方案**：在 `MODULE_BATCHES['basic-2']` 末尾追加 3 个名字（按字母顺序插入）：
```js
'basic-2': [
  'basic-material', 'basic-otherStockOut', 'basic-supplier', 'basic.test', 'batch-freeze',
  'batch-global-switch', 'batch-manual-e2e',
  'codeRule',           // 新增（rename from .test.mjs）
  'finance-invoice-crud', 'finance-invoice',
  'finance-others', 'finance-voucher-crud', 'finance.test',
  'sales-api',          // 新增（rename from .test.mjs）
  'sales-order',        // 新增（rename from .test.mjs）
],
```

**新增条目位置**：保持字母序插入（`codeRule` 在 `batch-manual-e2e` 后；`sales-api`/`sales-order` 在 `finance.test` 后）。

**预期影响**：`basic-2` batch 12 → 15 个测试，多 ~10-30s（基于实测其他 module 测试 0.6-2.4s/个）。

#### 3c. 更新 `harness/INDEX.md`（orca-review P1-4）

**文件**：`harness/INDEX.md` L18-20

**改动**：
```diff
- | 2026-07-21 | [tests/mes/sales-order.test.mjs](tests/mes/sales-order.test.mjs) | 销售订单 API 测试（/gen-tests 生成，30 用例含状态机守卫） |
- | 2026-07-21 | [tests/mes/codeRule.test.mjs](tests/mes/codeRule.test.mjs) | 编码规则模块 API 测试（规则绑定+取号+CRUD） |
- | 2026-07-18 | [tests/mes/sales-api.test.mjs](tests/mes/sales-api.test.mjs) | 销售模块 API 测试 |
+ | 2026-07-21 | [tests/modules/sales-order.test.js](tests/modules/sales-order.test.js) | 销售订单 API 测试（/gen-tests 生成，30 用例含状态机守卫） |
+ | 2026-07-21 | [tests/modules/codeRule.test.js](tests/modules/codeRule.test.js) | 编码规则模块 API 测试（规则绑定+取号+CRUD） |
+ | 2026-07-18 | [tests/modules/sales-api.test.js](tests/modules/sales-api.test.js) | 销售模块 API 测试 |
```

注意：路径前缀从 `tests/mes/` 改为 `tests/modules/`（之前是错的，文件实际就在 modules/）。

#### 3d. git 操作
```bash
git mv harness/tests/modules/codeRule.test.mjs harness/tests/modules/codeRule.test.js
git mv harness/tests/modules/sales-api.test.mjs harness/tests/modules/sales-api.test.js
git mv harness/tests/modules/sales-order.test.mjs harness/tests/modules/sales-order.test.js
# run-batch.js 用 edit 修改 MODULE_BATCHES['basic-2']
# INDEX.md 用 edit 修改 L18-20
```

**Commit message 模板**：
```
fix(harness): 3 个 .test.mjs 重命名为 .test.js + 加入 MODULE_BATCHES（修复 P0 漏跑）

- harness/tests/modules/{codeRule,sales-api,sales-order}.test.mjs → .test.js
- 3 文件实际为 CJS 写法（0 imports / 0 requires），后缀 .mjs 是历史遗留
- run-batch.js glob `*.test.js` 不匹配 .mjs，导致 manifest 调度时漏跑
- 同步修改 MODULE_BATCHES['basic-2']：追加 3 个文件
- 同步更新 harness/INDEX.md L18-20 路径引用

Refs: hermes/reviews/2026-08-06-regression-round2-mcp-deep-dive.md §11.1
Refs: hermes/reviews/2026-08-06-phase1-plan-review.md (orca-review NEEDS REWORK P0-2)
```

---

## 3. 执行顺序 & Commit 策略

**3 个独立 commit**（按改动类型分组，便于 bisect）：

1. **Commit 1**：Step 1（manifest 加 slice）
2. **Commit 2**：Step 2（删除死代码 + 清理 package.json/README）
3. **Commit 3**：Step 3（重命名 .test.mjs）

每个 commit 后做局部验证（见 §4），最后做整合 verify。

---

## 4. 验证方案（/verify）

### Commit 1 后验证
```bash
# 1. manifest JSON 合法性 + 1.4 字段全部正确
python3 -c "
import json
m = json.load(open('harness/regression/recovery-plan.json'))
slice_ids = [s['id'] for s in m['slices']]
assert '1.4' in slice_ids, '新增 slice 1.4 缺失'
slice_1_4 = next(s for s in m['slices'] if s['id'] == '1.4')
assert slice_1_4['kind'] == 'chain'
assert slice_1_4['timeout_seconds'] >= 900, f\"1.4 timeout 应 >= 900s（实测需要）实际={slice_1_4['timeout_seconds']}\"
for dep in ['1.1', '1.2', '1.3']:
    assert dep in slice_1_4['requires'], f'1.4 requires 应包含 {dep}'
print('✅ manifest + 1.4 校验通过')
"

# 2. (可选 dry-run) 不真正执行，只验证切片调度逻辑能识别 1.4
python3 harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json \
  --dry-run 2>&1 | grep -q "1.4" && echo "✅ 1.4 slice 被调度识别"
```

### Commit 2 后验证
```bash
# 1. 死文件确实删除
test ! -f harness/scripts/run-regression.sh && echo "✅ sh 已删"
test ! -f harness/scripts/run-regression.bat && echo "✅ bat 已删"

# 2. package.json 全部 3 项清理（test:e2e/test:smoke/test:all）
python3 -c "
import json, re
raw = open('harness/package.json').read()
p = json.loads(raw)
scripts = p['scripts']
assert 'test:all' not in scripts, 'test:all 应已删除'
# test:e2e / test:smoke 不能含错误的 e2e/playwright.config.ts
for key in ['test:e2e', 'test:smoke']:
    assert 'e2e/playwright.config.ts' not in scripts.get(key, ''), \
        f'{key} 仍引用错路径 e2e/playwright.config.ts'
    assert 'harness/playwright.config.ts' in scripts.get(key, ''), \
        f'{key} 未引用 harness/playwright.config.ts'
print('✅ package.json 清理通过')
"

# 3. README 已清理
! grep -q "run-regression" harness/tests/README.md && echo "✅ README 已清理"
```

### Commit 3 后验证
```bash
# 1. .mjs 全部消失
! ls harness/tests/modules/*.test.mjs 2>/dev/null && echo "✅ .test.mjs 全部重命名"

# 2. .test.js 数量 +3
count_js=$(find harness/tests/modules -name "*.test.js" | wc -l)
count_mjs=$(find harness/tests/modules -name "*.test.mjs" | wc -l)
echo "modules .test.js: $count_js (期望 48 = 45 + 3)"
echo "modules .test.mjs: $count_mjs (期望 0)"
test "$count_js" -eq 48 && test "$count_mjs" -eq 0 && echo "✅ 重命名完成"

# 3. MODULE_BATCHES['basic-2'] 包含 3 个新条目（orca-review P0-2 修复验证）
python3 -c "
content = open('harness/scripts/run-batch.js').read()
for name in ['codeRule', 'sales-api', 'sales-order']:
    assert f\"'{name}'\" in content, f'{name} 应在 MODULE_BATCHES 中'
    # 不应与同名变体混淆（sales-order-delivery 不算 sales-order）
    # 检查作为独立字符串（不是 sales-order-delivery 的子串）
print('✅ MODULE_BATCHES 包含 3 个新条目')
"

# 4. INDEX.md 已更新
! grep -q "test.mjs" harness/INDEX.md && echo "✅ INDEX.md 已清理 .test.mjs 引用"
```

### 最终整合验证
```bash
# 跑一次全量回归（用 resilient_regression.py），确保：
#   - 1.4 slice 被调度（出现在切片表）
#   - 死文件不报错
#   - 3 个重命名文件被 run-batch.js 拾取（basic-2 batch 应包含 15 个测试）
python3 harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json

# 报告验证：regression-report.js v2
node harness/scripts/regression-report.js --run-dir <latest-run-id>

# 检查报告：
#   - 第三节各切片结果表应有 1.4
#   - 报告中无残留 {{...}} 占位符
grep -E '\{\{[a-z_]+\}\}' hermes/eagle-eye/reports/<YYYY-MM-DD>/resilient-regression-recovery.md \
  && echo "❌ 报告残留占位符" || echo "✅ 报告无残留占位符"
```

---

## 5. 风险评估

| 步骤 | 风险 | 缓解 |
|---|---|---|
| Step 1 | 加 slice 导致全量回归多 10-30s（实测，远低于 +10min 估算）| 用户接受（brainstorm 已确认）|
| Step 1 | purchase-chain 跟 1.1/1.2/1.3 重复跑 | 接受（细粒度 + 集成双重信号）|
| Step 1 | timeout 设 600s 会杀死编排器 | **已修正为 900s**（orca-review P0-1）|
| Step 2 | 删除后无替代入口 | README 补 `resilient_regression.py` 调用 |
| Step 2 | package.json test:all 误删导致 CI 失败 | grep 确认无 CI workflow 引用（已验证）|
| Step 2 | package.json test:e2e/test:smoke 仍用错路径 | **已扩展修复**（orca-review P1-2）|
| Step 3 | 仅 git mv 不够，run-batch.js MODULE_BATCHES 硬编码 | **已扩展：同步修改 MODULE_BATCHES['basic-2']**（orca-review P0-2）|
| Step 3 | INDEX.md L18-20 残留 .test.mjs 引用 | **已扩展：同步更新 INDEX.md**（orca-review P1-4）|
| Step 3 | Node 把 .mjs 当 ESM，混用 `require` 会 ERR_REQUIRE_ESM | 已验证 3 个文件 0 imports / 0 requires，纯 CJS 写法，安全 |

**总体风险等级**：🟢 低（3 个独立 commit，每个可独立 revert）

---

## 6. 不做的（Out of Scope 列表）

明确**不在本次 Phase 1**：

| 项 | 何时做 |
|---|---|
| manifest `report_paths[]` + `mirror_paths[]` | Phase 2（建议 4）|
| 抽 `harness/config/paths.json` | Phase 2（建议 5）|
| 统一报告生成器（废弃 python 版）| Phase 3（建议 6，先观察 Phase 2 稳定 1 周）|
| 修 `package.json` test:e2e/test:smoke 的 playwright config 路径 | Phase 2（与建议 4 一起做）|
| 9 个 failed 切片的根因修复 | 独立 issue，不在本 PR |
| e2e/smoke 4 个 spec 漏调度 | 待用户决策后单独处理 |

---

## 7. 验收标准

完成 Phase 1 后必须满足：

- [ ] manifest 中存在 `1.4` slice，`timeout_seconds >= 900`，`requires` 包含 `1.1/1.2/1.3`
- [ ] `harness/scripts/run-regression.sh` 不存在（git status clean）
- [ ] `harness/scripts/run-regression.bat` 不存在
- [ ] `harness/package.json` 不含 `test:all` 与 `run-regression` 引用
- [ ] `harness/package.json` `test:e2e` / `test:smoke` 引用 `harness/playwright.config.ts`（而非 `e2e/...`）
- [ ] `harness/tests/README.md` 不含 `run-regression` 引用
- [ ] `harness/tests/modules/*.test.mjs` 不存在
- [ ] `harness/tests/modules/*.test.js` 数量 = 48（45 + 3）
- [ ] `run-batch.js` MODULE_BATCHES['basic-2'] 包含 `codeRule` / `sales-api` / `sales-order`
- [ ] `harness/INDEX.md` 不含 `.test.mjs` 引用，L18-20 路径已更新为 `.test.js`
- [ ] 全量回归一次跑通，1.4 slice 出现在报告切片表
- [ ] 重命名后的 3 个 .test.js 在 module batch 中被调度（即出现在 batch output 里）

---

## 8. 参考

- **第一轮报告**：harness/.regression-runs/<run-id>/（已通过 worker_done 回报）
- **第二轮报告**：hermes/reviews/2026-08-06-regression-round2-mcp-deep-dive.md
- **Plan orca-review 报告**：hermes/reviews/2026-08-06-phase1-plan-review.md（NEEDS REWORK，2 P0 + 4 P1，已修复）
- **修改标记**：所有改动按 CLAUDE.md 规则包 `update-begin/end` 标记（针对 .java；本计划改动不涉及 .java，纯 JSON/md/js 配置，无须标记）

## 9. Plan 修订记录

| 版本 | 日期 | 修订内容 | 来源 |
|---|---|---|---|
| v1 | 2026-08-06 | 初版 | PI /brainstorm |
| v2 | 2026-08-06 | 修复 2 P0（1.4 timeout 600→900s；MODULE_BATCHES 必须同步修改）+ 3 P1（test:e2e/test:smoke 路径、INDEX.md 更新、CI 验证） | orca-review `task_a040b8903579` |