---
name: gen-tests
description: 测试用例生成 — 根据后端 Controller 代码自动推导 API 测试和 E2E 测试用例。Generate test cases from backend Controller code.
version: 2.0.0
---

# gen-tests — 测试用例自动推导 v2

## 测试环境隔离（推荐，大型模块）

对于 ≥10 个 API 端点的模块，建议使用 Orca 工作树隔离测试环境：

```bash
# 创建鹰眼团测试隔离工作树
orca worktree create --name eagleeye/{模块名}

# 在隔离环境中生成和运行测试
# 测试完成后清理：
orca worktree rm --worktree branch:eagleeye/{模块名}
```

**收益：**
- 测试配置（如 `enableLoginCaptcha: false`）不污染开发配置
- 测试数据写入独立数据库，不影响开发数据
- 多模块可并行测试，利用 `eagleeye/模块A` + `eagleeye/模块B` 同时跑

> 降级策略：Orca 不可用 → 直接在开发目录生成测试（标准行为）。

## Playwright 配置模板

```ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  use: { headless: true },
});
```

## 环境初始化命令

```bash
mkdir -p harness/tests harness/e2e
cd harness
[ ! -f package.json ] && npm init -y
npm install @playwright/test
```

## API 测试推导规则

| 接口注解 | 必测场景 |
|---------|---------|
| `@GetMapping` | 正常查询 + 空数据 |
| `@PostMapping` | 新增成功 + 必填字段缺失 |
| `@PutMapping` | 更新成功 + 记录不存在 |
| `@DeleteMapping` | 删除成功 + 删除后查不到 |
| 自定义接口 | 验证返回结果（code/result/message） |

## E2E 测试推导规则

| 页面类型 | 必测场景 |
|---------|---------|
| 列表页 | 页面正常加载 + 列头正确显示 |
| 搜索表单 | 各搜索字段可用 |
| 新增弹窗 | 打开弹窗 + 填写必填项 + 保存成功 |
| 编辑弹窗 | 点击编辑 + 修改字段 + 保存成功 |
| 删除 | 点击删除 + 确认弹窗 + 列表刷新 |

## 测试目录结构

- API 测试输出：`harness/tests/<项目名>/<功能名>.test.js`
- E2E 测试输出：`harness/e2e/<项目名>/<功能名>.spec.ts`

## 自定义规则合并逻辑

1. 读取 `.claude/rules/gen-tests-rules.json`
2. 按 `trigger` + `httpMethod` 匹配当前 Controller 方法
3. 命中则追加对应 `addCase`（`api` 和 `e2e`）到内置推导结果
4. 自定义规则优先于内置规则 — 相同的场景描述以自定义规则为准

## 断言语义深度校验（R009，2026-08-04 新增）

**问题**：gen-tests 历史生成测试多为"不崩溃"断言（`code === 200`），未验证业务字段值。finance.test.js 有 50+ 断言但全是浅断言，导致业务 bug（如 P1-1 采购入库 supplier_id 缺失）漏检。

**强制流程**：

### 1. 生成时自检

每个 `describe/场景()` 块必须包含 ≥ 1 条**语义断言**（满足以下之一）：

| 类型 | 验证内容 | 示例 |
|------|---------|------|
| **(a) 字段值** | 返回数据具体字段值非空/符合预期 | `result.records[0].code.startsWith('MAT-')` |
| **(b) 状态流转** | 业务状态变化符合预期 | `auditResult.code === 200 && record.status === '3'`（草稿→审核） |
| **(c) 显示值** | UI 显示编码/名称非裸 ID（锚点 #4） | `page.getByText('MAT-001').isVisible()` |
| **(d) 数据传递** | 跨接口数据一致 | `afterStock === beforeStock + receiptQty` |

**禁止**：仅 `code === 200` / `code !== 500` / "不崩溃" 类断言。

## Controller endpoint set 驱动（TS-3，2026-08-05 新增）

**问题**：gen-tests 历史生成的 E2E 一律按 CRUD 模板（5/7 = 新增按钮/抽屉），未对照 controller 实际端点。结果对"只读 + 导出"页面（应收/应付/批次台账/批次库存/编码规则等）产生"新增按钮找不到"误判——浪费复核精力（2026-08-04 mes-2026-08-04-business-bugs.md #5/#6/#8/#10 同型）。

**强制流程**（生成 spec 前必做）：

1. **grep controller 端点**：`grep -E "@\(Get\|Post\|Put\|Delete\)Mapping" <Controller>.java` 列出实际暴露的端点
2. **判断 pageKind**：
   - **CRUD 页面**（有 add/edit/delete）→ 生成完整 CRUD 模板（5/7 测试保留）
   - **只读 + 导出页面**（仅 list/queryById/queryAll/exportXls）→ **跳过 5/7**，生成只读 + 导出断言
   - **聚合只读页面**（仅 list，无 add/edit/delete/export）→ 仅生成 1/2/6 测试
3. **同步识别**：
   - 若 controller 有 `@PostMapping("/add")` 但页面没"新增按钮"→ spec 标 🔴 真实 Bug（如 #9 收款管理、#11 付款管理）
   - 若 controller 无 `@PostMapping("/add")` 但 spec 期望"新增按钮"→ spec 标 ✅ 误判

**与 R009 的关系**：TS-3 是"生成侧契约对齐"，R009 是"断言侧语义深度"，互补不重叠。

**复核依据**：`hermes/eagle-eye/issues/mes-2026-08-04-business-bugs.md`（同型误判 5 个：B1/B2/B3 + #5/#6/#8）。

### 2. 写入前统计

gen-tests 在写入文件前扫描：

```bash
# 统计 c.check()/expect()/assert() 总数
ASSERT_COUNT=$(grep -cE "c\.check|\.check\(|expect\(|assert\(" "$OUTPUT_FILE")

# 统计语义断言数（验证字段值/状态流转/显示值/数据传递）
SEMANTIC_COUNT=$(grep -cE "\.code\s*[!=]|\.status\s*[!=]|startsWith\(|includes\(|\.length\s*[!=]|=== ['\"]\\w" "$OUTPUT_FILE")

# 场景数
SCENARIO_COUNT=$(grep -cE "^\s*(=== |场景[0-9])" "$OUTPUT_FILE")
```

**门控规则**：
- `ASSERT_COUNT < 2` → 拒绝写入（数量下限）
- `SEMANTIC_COUNT < SCENARIO_COUNT` → 警告但不阻塞（深度检查）
- 警告信息："⚠️ R009：建议增加语义断言覆盖所有场景"

### 3. CI 前置门控（已集成 functional-regression.yml）

`api-test` job 跑前先扫：
- 每个 .test.js 必须 ≥ 2 个断言（c.check/expect/assert）
- < 2 → 拒绝入库

### 4. 改造优先级

历史浅断言文件改造顺序（按业务关键性）：
1. finance.test.js（最关键，8 controller 浅断言集中）
2. batch-global-switch.test.js（4 Service 集成，缺状态流转断言）
3. 其余按链路关键性排序

### 5. 参考实现

- ✅ **good**：purchase-apply-order.chain.test.js（18 c.check 含状态流转断言）
- ✅ **good**：stocktake.test.js（28 c.check 涵盖盘亏/盘盈/守卫/回写）
- ❌ **bad**：finance.test.js（34 c.check 全是 code===200，不验证字段值）

## 调用链覆盖扩展（Call-Chain Coverage Extension）

在 API 测试生成前，使用 code-review-graph MCP 工具将测试目标从 Controller 表面延伸到 Service 内部调用链。

### 调用参数

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 1. 追踪调用链 | `query_graph_tool` | `pattern="callees_of"`, `target="<Controller方法>"`, `detail_level="minimal"` | 从 Controller 向下找到所有被调用的 Service 方法 |
| 2. 缺口检测 | `get_knowledge_gaps_tool` | 默认参数 | 提取未测试热点（untested hotspots） |
| 3. Hub 覆盖 | `get_hub_nodes_tool` | `top_n=10` | 对前 10 hub 节点逐个检查 `tests_for` |
| 4. 死代码排除 | `refactor_tool` | `mode="dead_code"` | 排除死代码，不浪费测试生成 |

### 处理规则

| 发现 | 动作 |
|------|------|
| Controller 调用的 Service 方法 | 为每个叶子 Service 方法生成单元级 API 测试 |
| 未测试热点（untested hotspot） | 优先生成测试，标注 `[GAP]` |
| Hub 节点零测试覆盖 | 输出 CRITICAL 警告："该 hub 节点（N 个调用者）无任何测试覆盖" |
| 死代码 | 跳过，不生成测试 |

### 降级策略

- MCP 服务不可用 → 仅覆盖 Controller 端点（标准行为）
- 部分工具失败 → 可用工具仍参与分析，失败项跳过

## 工作树隔离完整流程（v2 新增）

对于大型模块的完整测试流程：

```bash
# 1. 创建隔离工作树
orca worktree create --name eagleeye/mes-sales

# 2. 生成测试（在隔离环境中）
# gen-tests 产出 → harness/tests/{modules,chains}/sales*.test.js
#                  → harness/e2e/mes/sales.spec.ts

# 3. 初始化测试依赖
cd harness && npm install

# 4. 三路并行执行（由 test-all 驱动）
# test-api (vitest) | test-e2e (playwright) | test-frontend (tsc+build)

# 5. 报告归档
# → hermes/eagle-eye/reports/YYYY-MM-DD/mes-sales-test-report.md

# 6. 清理
orca worktree rm --worktree branch:eagleeye/mes-sales
```

> 注意：测试代码（`harness/tests/` 和 `harness/e2e/`）最终需要提交到主分支。工作树隔离只影响测试运行环境，不影响测试代码的提交。
