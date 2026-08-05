# 回归测试体系设计方案（待 Claude 评审）

> **生成时间**：2026-08-04
> **作者**：pi（开发 AI）
> **目的**：派 Claude 做第二意见评审
> **状态**：草案（v0.9）

## 1. 体系组成

```
回归测试体系
├── 命令层（业务人员触发）
│   ├── /add-tests <项目> <模块> [页面]   # 新增测试
│   ├── /add-tests <项目> 链路 <名>     # 链路测试
│   └── /coverage [gap] [...]           # 覆盖率查询
├── 测试代码层
│   ├── harness/tests/modules/basic-*.test.js   # 9 个 API 模块测试
│   ├── harness/e2e/mes/basic-*.spec.ts        # 9 个 E2E UI 测试
│   └── harness/tests/chains/*.test.js         # 9 个链路测试
├── 运行层（本地 + CI）
│   ├── harness/scripts/run-regression.sh       # Linux 一键脚本
│   ├── harness/scripts/run-regression.bat      # Windows 一键脚本
│   └── harness/package.json scripts section    # npm test:api/e2e/chains/smoke/all
├── CI 门禁
│   └── .github/workflows/functional-regression.yml  # 3 job（api-test/e2e-test/typecheck）
└── 文档
    ├── harness/tests/README.md               # 使用指南（4739 字）
    ├── .claude/commands/test/add-tests.md    # /add-tests 命令定义
    └── .claude/commands/test/coverage.md      # /coverage 命令定义
```

## 2. 关键设计决策

| 决策 | 选择 | 理由 |
|---|---|---|
| **测试文件位置** | `harness/tests/modules/` | 跟现有 `chains/` 同级 |
| **命名规范** | `basic-<scope>.test.js` | 业务人员易识别（按项目+模块）|
| **测试运行器** | Node.js 原生（无 jest/mocha）| 零依赖、CI 轻量 |
| **E2E 工具** | Playwright（已有）| 项目已配置 |
| **CI 触发** | push to main/fix/** + PR | 覆盖主流程 |
| **必填校验** | pre-commit hook（未启用）| 暂用 CI 门禁 |
| **dbCleanup 策略** | `DELETE WHERE code LIKE 'PATTERN_%'` | 测试卫生 |

## 3. 验收记录

| 维度 | 数值 |
|---|---|
| 新增测试文件 | 18 个（9 module + 9 spec）|
| API 测试用例 | 167 个 |
| E2E 测试用例 | 49 个 |
| 端点覆盖率 | 57/57 = 100%（0 调用子模块）|
| 链路测试通过率 | 17/17 = 100%（sales-receipt-flow 修复后）|
| commit 数 | 11 个 + 2 文档 = 13 个 |

## 4. 已识别风险

| 风险 | 缓解 |
|---|---|
| **CI workflow 路径错误**（W2 收尾时修复）| 已改 `tests/mes/` → `tests/{modules,chains}/` |
| **dbCleanup 需 MySQL root** | CI 已配 `MYSQL_ROOT_PASSWORD: root` |
| **Playwright 在 CI 需装 chromium** | `npx playwright install --with-deps chromium` |
| **e2e-test 软门禁**（continue-on-error）| 灰度阶段逐步修复 |

## 5. 待 Claude 评审问题

1. **完整性**：
   - 哪些业务场景/边界没覆盖？
   - 并发/性能/跨浏览器测试？
   - 错误处理路径？

2. **可行性**：
   - 现有 CI workflow 的服务配置（mysql 8.0 + redis 7）够用吗？
   - 9 个 spec 一起跑要多久（CI timeout 20 分钟够吗）？
   - fork 环境跑过吗？

3. **安全性**：
   - `dbCleanup` 用 `LIKE 'PATTERN_%'` 是否安全（SQL 注入风险）？
   - package.json 有无暴露敏感信息？
   - 测试文件是否泄露生产 token？

4. **可优化**：
   - 测试可以并行/分布式跑吗？
   - 报告可以聚合输出（不只单文件）？
   - 覆盖率统计可以自动化吗？

5. **更好方案**：
   - 是否应该用 jest/mocha 替代裸 Node？
   - 是否应该加 mutation testing？
   - 是否应该加 visual regression（截图对比）？