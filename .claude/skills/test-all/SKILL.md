---
name: test-all
description: 全量测试聚合，扫描/生成/运行所有测试并汇总报告 — Full test aggregation: scan, generate, run all tests, and produce summary report
---

# 全量测试 (Test All)

## 测试聚合逻辑

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

### 步骤 3：运行 API 测试

逐模块运行 API 测试：

```bash
npx vitest run harness/tests/<项目名>/<模块名>.spec.ts
```

**失败处理：**
1. 分析报错，定位失败原因
2. 自动修复（测试代码问题）或标记（被测代码问题）
3. 重跑，最多 3 次
4. 3 次仍未通过 → 标记为"需人工排查"，记录报错详情

### 步骤 4：运行 E2E 测试

逐模块运行 E2E 测试：

```bash
npx playwright test harness/e2e/<项目名>/<模块名>.spec.ts
```

**失败处理同 API 测试（最多重试 3 次）。**

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
```

## 汇总报告格式

```
<项目名> 测试报告：

  API 测试：
    功能A：5/5 全部通过
    功能B：3/5 通过（自动修复 1 处，已通过）

  E2E 测试：
    功能A：2/2 全部通过
    功能B：1/2 通过（1 个失败需人工排查，详见报错）

  总计：
    API：8/10 通过
    E2E：3/4 通过
    自动修复：1 处
    需人工：1 处
```

## 测试完成后动作

1. 输出汇总报告
2. 如果有"需人工排查"的项，详细列出：
   - 测试文件路径
   - 失败步骤
   - 报错信息
   - 建议排查方向
3. 建议是否可以进行 /done

## 铁律

> 自动修复只修测试代码，不修被测业务代码。
> 若怀疑是被测代码的 bug，标记为"需人工排查"而非自动修改。
> 重试上限 3 次，超过则停止，不再修复。
