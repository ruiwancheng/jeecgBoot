---
name: test-all
description: 全量测试聚合，扫描/生成/运行所有测试并汇总报告 — Full test aggregation: scan, generate, run all tests, and produce summary report
version: 2.0.0
---

# 全量测试 (Test All) — 鹰眼团 v2

## 测试聚合逻辑

### 步骤 0：智能范围判断

使用 code-review-graph MCP 工具判断测试范围，避免不必要的全量跑。

| 条件 | 动作 |
|------|------|
| `get_minimal_context_tool(task="test-all")` → risk=low + 变更 ≤2 个文件 | 仅测试受影响模块（轻量模式） |
| risk=medium/high 或变更 ≥5 个文件 | 全量测试（标准模式） |

### 步骤 0.5：鹰眼团工作树隔离（推荐，全量模式）

对于全量测试或大型模块（≥10 个 API 端点），建议使用 Orca 工作树隔离环境：

```bash
# 创建鹰眼团专用隔离工作树
orca worktree create --name eagleeye/{模块名}

# 在隔离工作树中执行后续步骤
# 测试完成后清理：
orca worktree rm --worktree branch:eagleeye/{模块名}
```

**收益：** 测试数据写入不影响开发环境，测试配置（如 `enableLoginCaptcha: false`）不污染主配置。

> 降级策略：Orca 不可用时 → 直接在开发目录运行（标准行为）

### 步骤 1：扫描测试目录

扫描以下目录，列出已有的测试文件：

```
harness/tests/<项目名>/     — API 测试
harness/e2e/<项目名>/       — E2E 测试
```

**扫描命令：**
```bash
ls harness/tests/<项目名>/*.spec.ts 2>/dev/null
ls harness/e2e/<项目名>/*.spec.ts 2>/dev/null
```

### 步骤 2：生成缺失的测试文件

如果某模块缺少测试文件，自动调用 gen-tests 技能生成。

**判定依据：** 对比项目后端模块目录和测试目录，缺失对应测试文件的模块标记为"待生成"。

### 步骤 3：三路并行测试执行（Orca 增强）

> **v2 改进：** test-api、test-e2e、test-frontend 三者互不依赖，改为三路并行执行，总耗时从 T1+T2+T3 降为 max(T1,T2,T3)。

```
gen-tests (产出测试用例)
     │
     ├────────────────┬────────────────┐
     ▼                ▼                ▼
  test-api        test-e2e        test-frontend
  (vitest)       (playwright)     (tsc + build)
     │                │                │
     └────────────────┴────────────────┘
                      ▼
                步骤 4: 汇总报告
```

#### 3a. 运行 API 测试

```bash
npx vitest run harness/tests/<项目名>/<模块名>.spec.ts
```

**失败处理：**
1. 分析报错，定位失败原因
2. 自动修复（测试代码问题）或标记（被测代码问题）
3. 重跑，最多 3 次
4. 3 次仍未通过 → 标记为"需人工排查"，记录报错详情

#### 3b. 运行 E2E 测试（与 3a 并行）

```bash
npx playwright test harness/e2e/<项目名>/<模块名>.spec.ts
```

**失败处理同 API 测试（最多重试 3 次）。**

#### 3c. 运行前端静态检查（与 3a/3b 并行）

```bash
cd jeecgboot-vue3
pnpm run typecheck 2>/dev/null || npx vue-tsc --noEmit
pnpm build
```

检查项：TypeScript 类型、Vue 组件完整性、Vite 构建是否通过。

### 步骤 4：汇总报告 + 趋势追踪（Orca 增强）

#### 4a. 生成当次报告

```
<项目名> 测试报告：

  API 测试：
    功能A：5/5 全部通过
    功能B：3/5 通过（自动修复 1 处，已通过）

  E2E 测试：
    功能A：2/2 全部通过
    功能B：1/2 通过（1 个失败需人工排查，详见报错）

  前端检查：
    类型检查：✅ 通过
    构建：✅ 通过

  总计：
    API：8/10 通过
    E2E：3/4 通过
    前端：2/2 通过
    自动修复：1 处
    需人工：1 处
```

#### 4b. 保存报告到鹰眼团目录（趋势追踪）

```bash
# 创建日期目录
mkdir -p hermes/eagle-eye/reports/YYYY-MM-DD/

# 保存当次报告
# 文件名: {模块名}-test-report.md
```

#### 4c. 趋势对比（如果存在上次报告）

对比本次和上次测试结果，输出变化：

```markdown
## 通过率对比

| 指标 | 本次 | 上次 (YYYY-MM-DD) | 趋势 |
|------|:--:|:--:|:--:|
| API 测试 | 25/25 (100%) | 24/25 (96%) | ↑ +1 |
| E2E 测试 | 6/6 (100%) | 6/6 (100%) | → |
| 前端构建 | ✅ | ✅ | → |
| 总通过率 | 31/31 (100%) | 30/31 (97%) | ↑ +3% |

## 新增失败
（如有）列出本次新出现的失败项

## 已修复
（如有）列出上次失败本次通过的项
```

## 测试目录结构

```
harness/
├── tests/
│   └── <项目名>/
│       ├── <功能A>.spec.ts    — API 测试
│       └── <功能B>.spec.ts
├── e2e/
│   └── <项目名>/
│       ├── <功能A>.spec.ts    — E2E 测试
│       └── <功能B>.spec.ts
└── fixtures/
    └── <项目名>/
        └── test-data.json    — 测试数据

hermes/eagle-eye/reports/
└── YYYY-MM-DD/
    └── {模块名}-test-report.md  — 趋势追踪报告
```

## 测试完成后动作

1. 输出汇总报告
2. 保存报告到 `hermes/eagle-eye/reports/YYYY-MM-DD/`
3. 如果有上次报告，输出趋势对比
4. 如果有"需人工排查"的项，详细列出：
   - 测试文件路径
   - 失败步骤
   - 报错信息
   - 建议排查方向
5. 建议是否可以进行 /done
6. 如果使用了工作树隔离 → 提示 `orca worktree rm --worktree branch:eagleeye/{模块名}` 清理

### 步骤 4.5：趋势聚合（每周自动）

每周自动聚合 `hermes/eagle-eye/reports/` 下的单次报告为趋势数据：

**聚合维度：**
| 维度 | 数据源 | 告警阈值 |
|------|------|:--:|
| API 测试通过率 | 各次报告 API 通过/总数 | < 90% 标记 P2 |
| E2E 测试通过率 | 各次报告 E2E 通过/总数 | < 80% 标记 P1 |
| 前端构建成功率 | 各次报告构建结果 | 任何失败标记 P0 |
| 自动修复次数 | 各次报告修复计数 | 连续增长标记 P2 |
| 需人工排查项 | 各次报告 pending 计数 | 连续不下降标记 P2 |

**趋势报告模板：**
```markdown
# 测试趋势 — 2026-W30

## 通过率趋势
| 日期 | API | E2E | 前端 | 总计 | 趋势 |
|------|:--:|:--:|:--:|:--:|:--:|
| 07-20 | 100% | 100% | ✅ | 100% | → |
| 07-21 | 100% | 83% | ✅ | 95% | ↓ |

## 告警
- 07-21 E2E 通过率降至 83%，需排查

## 建议
- E2E 失败用例集中在 XX 页面，建议优先修复
```

**连续下降告警：** 如果任一维度连续 2 周下降 → 标记 P0，阻止新功能开发，优先修测试。

> 降级策略：Orca 不可用 → 手动运行 `/test-all --trend` 生成趋势报告。

## 铁律

> 自动修复只修测试代码，不修被测业务代码。
> 若怀疑是被测代码的 bug，标记为"需人工排查"而非自动修改。
> 重试上限 3 次，超过则停止，不再修复。
> 三路并行执行，彼此失败不阻断对方——一个模块的 E2E 挂了不影响 API 测试继续。
> 报告必须留存到 hermes/eagle-eye/reports/，否则下次无法趋势对比。

## Orca 编排 DAG（v3 升级，可选）

当 Orca orchestration 可用时，test-all 可升级为真正的多 Agent 编排 DAG：

```yaml
# Orca orchestration DAG: test-all pipeline
dag:
  - id: gen_tests
    dispatch: "使用 gen-tests 技能为变更模块生成测试用例"
    
  - id: test_api
    dispatch: "使用 test-api 技能运行 API 测试"
    depends_on: [gen_tests]
    
  - id: test_e2e
    dispatch: "使用 test-e2e 技能运行端到端测试"
    depends_on: [gen_tests]
    
  - id: test_frontend
    dispatch: "使用 test-frontend 技能运行类型检查和构建"
    # 不依赖 gen_tests，前端检查独立执行
    
  - id: aggregate
    dispatch: "汇总三个测试通道结果，生成趋势对比"
    depends_on: [test_api, test_e2e, test_frontend]
    decision_gate:
      - condition: "all_pass" → mark_ready_for_done
      - condition: "partial_failure" → flag_for_manual_review
      - condition: "critical_failure" → block_deploy
```

**编排命令：**
```bash
orca orchestration task-create --spec "test-all {模块名}" --json
# 对三个测试通道分别 dispatch --inject
orca orchestration check --wait --types worker_done --timeout-ms 900000 --json
```

**收益：** 每个测试通道独立 Agent、独立 Token 预算、独立失败处理。决策门自动判定通过/需人工/阻断。

> 降级策略：Orca orchestration 不可用 → 回退到 v2.0.0 进程内三路并行（标准行为）。

## 标准格式报告输出（JUnit XML + SARIF）

测试完成后，同时输出三种格式的报告，满足不同消费场景：

### 输出文件

```
hermes/eagle-eye/reports/YYYY-MM-DD/
├── {模块名}-test-report.md    # 人类可读（现有）
├── {模块名}-test-report.xml   # JUnit XML（CI 标准）
└── {模块名}-test-report.sarif # SARIF JSON（安全扫描标准）
```

### JUnit XML 模板

```xml
<testsuites name="JeecgBoot Harness" tests="31" failures="2" time="45.2">
  <testsuite name="API Tests" tests="25" failures="1" time="30.1">
    <testcase name="mes-sales-queryAll" classname="harness.tests.mes.sales" time="1.2"/>
    <testcase name="mes-sales-add" classname="harness.tests.mes.sales" time="2.1">
      <failure message="Expected 200, got 500">
        NullPointerException at SalesService.java:42
      </failure>
    </testcase>
  </testsuite>
  <testsuite name="E2E Tests" tests="6" failures="1" time="15.1">
    <testcase name="smoke-login" classname="harness.e2e.smoke" time="3.5"/>
    <testcase name="smoke-user-list" classname="harness.e2e.smoke" time="4.2">
      <failure message="Timeout waiting for table">selector: .ant-table-tbody</failure>
    </testcase>
  </testsuite>
</testsuites>
```

### SARIF JSON 模板

```json
{
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [{
    "tool": {
      "driver": {
        "name": "JeecgBoot Harness",
        "version": "3.9.2",
        "informationUri": "https://github.com/ruiwancheng/jeecgBoot"
      }
    },
    "versionControlProvenance": [{
      "repositoryUri": "https://github.com/ruiwancheng/jeecgBoot",
      "revisionId": "<git rev-parse HEAD>",
      "branch": "<git branch --show-current>"
    }],
    "results": [{
      "ruleId": "test-failure",
      "level": "error",
      "message": { "text": "API测试失败: mes-sales-add" },
      "locations": [{
        "physicalLocation": {
          "artifactLocation": { "uri": "harness/tests/mes/sales.spec.ts" },
          "region": { "startLine": 42 }
        }
      }],
      "properties": {
        "module": "mes-sales",
        "testType": "api",
        "errorType": "NullPointerException",
        "statusCode": 500
      }
    }]
  }]
}
```

> 降级策略：非 CI 环境 → 仅输出 Markdown。CI 环境（检测到 `CI=true`）→ 同时输出 XML + SARIF。

## 测试失败智能去重

同一根因的多个测试失败合并为一条，减少干扰。

### 去重键规则（确定性，不依赖 LLM）

| 测试类型 | 去重键构成 | 示例 |
|------|------|------|
| API 测试 | `{statusCode}:{errorType}:{topStackFrame}` | `500:NullPointerException:SalesService.java:42` |
| E2E 测试 | `{errorMessage}:{selector}` | `Timeout:button[type=submit]` |
| 前端构建 | `{errorCode}:{filePath}` | `TS2322:src/views/mes/List.vue` |

### 去重流程

```
新失败 → 计算去重键 → 查找已有失败列表
  ├── 键匹配 → 合并（标注 "出现 N 次"，附加首次出现信息）
  └── 键不匹配 → 新增独立条目
```

### 报告中展示

```
失败汇总（去重后）:
  1. [API] 500:NullPointerException:SalesService.java:42 (出现 3 次)
     首次: mes-sales-add, 其他: mes-sales-update, mes-sales-delete
     建议: 检查 SalesService.java:42 行空值处理
  
  2. [E2E] Timeout:button[type=submit] (出现 1 次)
     首次: smoke-login
     建议: 检查登录按钮渲染条件

  去重统计: 原始 6 条 → 去重后 2 条独特失败
```

## 原子写入 + 测试状态快照

### 原子写入

所有测试报告使用原子写入防止中断损坏：

```bash
write_atomic() {
  local target="$1"
  local tmp="${target}.tmp.$$"
  cat > "$tmp"
  mv "$tmp" "$target"  # 同文件系统内 rename 是原子操作
}

# 使用示例
write_atomic "hermes/eagle-eye/reports/2026-07-20/mes-sales-test-report.md" << 'EOF'
...报告内容...
EOF
```

### 测试状态快照

长时间测试中途保存状态，支持跨会话恢复：

```json
// hermes/eagle-eye/state.json
{
  "runId": "2026-07-20-mes-sales",
  "phase": "test-api",
  "module": "mes-sales",
  "completed": ["mes-sales-queryAll", "mes-sales-add"],
  "pending": ["mes-sales-update", "mes-sales-delete"],
  "failed": [],
  "startedAt": "2026-07-20T15:00:00Z",
  "lastHeartbeat": "2026-07-20T15:05:30Z",
  "commit": "e005809"
}
```

### 恢复机制

session-start 钩子检测未完成的 `state.json`：

```
⚠️ 检测到未完成的测试运行:
  Run ID: 2026-07-20-mes-sales
  阶段: test-api (3/5 完成)
  最后心跳: 15:05 (12 分钟前)
  
  输入 /test-all --resume 恢复，或忽略则重新开始。
```

> 降级策略：测试 < 30 秒 → 不保存快照。会话意外中断 → session-start 提示恢复。
