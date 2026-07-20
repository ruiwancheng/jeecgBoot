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

## 铁律

> 自动修复只修测试代码，不修被测业务代码。
> 若怀疑是被测代码的 bug，标记为"需人工排查"而非自动修改。
> 重试上限 3 次，超过则停止，不再修复。
> 三路并行执行，彼此失败不阻断对方——一个模块的 E2E 挂了不影响 API 测试继续。
> 报告必须留存到 hermes/eagle-eye/reports/，否则下次无法趋势对比。
