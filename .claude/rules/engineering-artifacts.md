---
name: engineering-artifacts
description: 工程产物目录规范——hermes/ 和 harness/ 的子目录结构、命名规范、文件生命周期
glob: "**/*"
version: 1.0
---

# 工程产物目录规范

> **目的：** 统一所有客户端 AI 的产出物存放位置和命名，防止多客户端并行开发导致目录混乱。

## 核心原则

1. **hermes/** = AI 工程产物（分析、研究、报告、扫描、审计）
2. **harness/** = 测试产物（测试代码、测试结果、覆盖率、E2E 报告）
3. **两级索引：** 每个子目录必须有 `INDEX.md`（摘要 + 文件列表）
4. **日期前缀：** 所有含日期的文件统一 `YYYY-MM-DD-` 格式
5. **同名覆盖：** 同一模块的新报告直接覆盖旧报告，不保留历史版本（见 `tiequan-report-retention.md`）

## hermes/ 目录规范

```
hermes/
├── INDEX.md                    # 全局索引（必须维护）
├── scans/                      # GitHub 扫描结果
│   ├── INDEX.md                # 扫描索引（扫描脚本自动更新）
│   ├── archive/                # 历史扫描归档
│   └── tests/                  # 前端测试扫描（子类型）
│       └── INDEX.md
├── tiequan/                    # 铁拳团审计报告
│   └── YYYY-MM-DD/             # 按日期分组
│       └── <模块名>/            # 每个模块一个目录
│           ├── index.md         # 审计索引
│           ├── 01_风控总报告.md
│           ├── 02_成员产出统计.md
│           └── 03-12_*.md       # 10 份专项报告
├── eagle-eye/                  # 鹰眼团测试工程
│   ├── plans/                  # 测试计划
│   ├── reports/                # 测试报告
│   │   └── YYYY-MM-DD/         # 按日期分组
│   └── tests/                  # 生成的测试代码
├── prd/                        # 产品需求文档
│   └── <项目名>/                # 按项目分组
│       ├── modules/            # 模块设计
│       ├── research/           # 调研资料
│       └── assets/             # 图片/截图
├── research/                   # 技术调研（非项目特定）
├── sessions/                   # 会话记录和总结
├── logs/                       # 运行日志
├── tasks/                      # 任务脚本
│   └── scripts/                # 可执行脚本
├── templates/                  # 模板文件
└── standards/                  # 规范文档
```

### hermes/ 子目录用途

| 目录 | 用途 | 谁写入 | 生命周期 |
|------|------|--------|---------|
| `scans/` | GitHub 扫描结果 | 扫描脚本自动 | 新扫描覆盖旧报告，旧报告移到 `archive/` |
| `tiequan/` | 铁拳团审计 | `/jeecg-tiequan-audit` | 同模块再次审计时删除旧目录 |
| `eagle-eye/` | 鹰眼团测试 | 测试脚本自动 | 测试报告按日期保留，测试代码持续更新 |
| `prd/` | 产品文档 | AI 会话 | 持续迭代，不自动删除 |
| `research/` | 技术调研 | AI 会话 | 长期保留，过时可清理 |
| `sessions/` | 会话记录 | AI 会话 (/learn) | 按 `.remember/` 规则轮转 |
| `logs/` | 运行日志 | 脚本自动 | 保留最近 7 天 |
| `tasks/scripts/` | 可执行脚本 | AI 会话 | 长期保留，随代码演进 |
| `templates/` | 模板文件 | AI 会话 | 长期保留 |
| `standards/` | 规范文档 | 管理员 | 长期保留 |

## harness/ 目录规范

```
harness/
├── INDEX.md                    # 全局索引
├── docs/                       # 文档（列入 git，见 .gitignore）
├── tests/                      # 生成的测试代码
│   ├── <项目名>/                # 按项目分组
│   │   ├── api/                # API 测试
│   │   └── e2e/                # E2E 测试
│   ├── modules/                # 鹰眼团 API 测试 (test.js)
│   ├── chains/                 # 跨模块链路测试
│   ├── helpers/                # API/E2E 公共 helper
│   └── runner/                 # runner 自测 (test_resilient_regression.py 等)
├── e2e/                        # E2E 测试工程
│   ├── demo/                   # 演示项目
│   ├── <项目名>/                # 按项目分组
│   └── smoke/                  # 冒烟
├── test-results/               # 测试运行结果（临时）
├── scripts/                    # runner 与 dashboard 脚本（git 跟踪）
│   ├── resilient_regression.py # 可恢复回归 runner
│   ├── regression_dashboard.py # 本地只读看板
│   └── regression_plan.py      # 链路与质量合并器
├── regression/                 # 回归 manifest（git 跟踪）
│   └── recovery-plan.json      # 业务手工切片 + frontend-static + test-quality
├── dashboard/                  # 本地看板静态资源（git 跟踪）
│   ├── index.html
│   ├── dashboard.css
│   └── dashboard.js
└── .regression-runs/           # 运行时生成（gitignore）
    └── <run-id>/
        ├── state.json
        ├── manifest.json
        ├── summary.md
        ├── logs/
        └── services/
```

### harness/regression/recovery-plan.merged.json（gitignore）

由 `python harness/scripts/resilient_regression.py plan` 动态生成，将 `recovery-plan.json` + `business-chains.json` 的 `chainTests.segments` 合并为一份临时 manifest。**不得入仓**。

### harness/.regression-runs/（gitignore）

后台 runner 每次跑生成的运行目录。包含：

- `state.json`：原子落盘的进度状态。
- `state.json.fallback`：Windows 文件锁时的备份。
- `telemetry.jsonl`：心跳流。
- `summary.md`：本次汇总报告。
- `logs/<slice>.attempt-N.log`：原始执行日志。
- `services/backend.log`：本次 runner 启动的后端日志。
- `dashboard.url` / `dashboard.pid`：本地看板进程句柄。

### harness/ 与 jeecgboot-vue3/tests/ 的分工

| 位置 | 用途 | 跟踪 |
|------|------|:--:|
| `jeecgboot-vue3/tests/eagle-eye/` | 鹰眼团测试源码（手写 + 模板） | Git |
| `harness/tests/` | AI 自动生成的测试代码 | 本地 |
| `harness/e2e/` | 独立 E2E 工程（如 Playwright standalone） | 本地 |
| `harness/test-results/` | 测试运行产物（screenshots, videos, traces） | 本地 |

> **原则：** 手写的、可复用的测试代码放 `jeecgboot-vue3/tests/`（Git 跟踪）。AI 批量生成的一次性测试代码放 `harness/tests/`（本地）。

## 文件命名规范

### 日期文件
```
格式: YYYY-MM-DD-<描述>-<可选后缀>.ext
正确: 2026-07-14-warehouse-audit-report.md
正确: 2026-07-14-frontend-testing-improvement-plan.md
错误: 2026年07月14日-报告.md
错误: report-0714.md
```

### 扫描报告
```
格式: YYYY-MM-DD-<owner>_<repo>-stars<数字>.md
正确: 2026-07-14-piomin_claude-ai-spring-boot-stars1251.md
```

### 测试文件
```
格式: <模块>.<类型>.spec.ts
正确: warehouse.api.spec.ts
正确: customer.form.spec.ts
正确: location.e2e.spec.ts
```

### 模板文件
```
格式: <用途>.template.ts
正确: mes-crud.template.ts
```

## INDEX.md 规范

每个子目录必须有 `INDEX.md`，格式：

```markdown
# <目录名>

## 说明
<一句话描述本目录用途>

## 文件列表

| 日期 | 文件 | 说明 |
|------|------|------|
| 2026-07-14 | [xxx.md](xxx.md) | 说明 |

*最后更新: YYYY-MM-DD*
```

## AI 行为约束

### 写入时必须遵守
1. 先查 `INDEX.md` 确认不重复
2. 按本规范选择正确的子目录
3. 使用规范的文件名
4. 写完后更新对应 `INDEX.md`

### 禁止行为
- 禁止在 `hermes/` 或 `harness/` 根目录直接放文件（必须进子目录）
- 禁止使用中文日期或空格文件名
- 禁止用 `reports/` 替代 `eagle-eye/reports/` 存放测试报告
- 禁止把测试代码放 `hermes/`（应放 `harness/tests/` 或 `jeecgboot-vue3/tests/`）
- 禁止把分析报告放 `harness/`（应放 `hermes/`）

### 清理时机
- 每次 `/session-wrap` 时清理过期文件
- 每次扫描时旧报告自动归档（脚本处理）
- 临时文件（test-results, logs）保留不超过 7 天

### 业务文档写作规则（business-user-ai-collaboration）

**触发条件：** 给非工程用户（业务、测试、产品、运营）写工具使用指南。

**核心原则：业务人员不直接跑命令** —— 他们通过 AI 助手下指令，技术细节由 AI 处理。指南聚焦两件事：
1. **怎么让 AI 跑**（标准指令文案，复制即用）
2. **去哪里看报告**（业务友好的路径，含笔记空间镜像）

**写作规范：**
- **避免技术术语翻译**：
  - "manifest" / "slice" / "subprocess" → 隐藏或用业务词
  - "通过率 22/9/1" → "✅ 通过 22 个 / ❌ 失败 9 个 / ⚖️ 已知问题 1 个"
  - "exit 1" → "❌ 失败"
- **场景化 SOP**：按"发版前 / 月度 / 大促前 / 改代码后"分类，每类给一个标准指令
- **复制即用模板**：用代码块写"帮我跑一次 MES 全量回归"——业务人员复制粘贴即可
- **AI 回复解读模板**：教业务人员怎么读 AI 的简明结果（"通过率 ≥ 70% 可发版 / < 50% 不要发版"），不要让他们读 8 章节报告
- **报告章节取舍**：业务人员只看第 1 节（通过率总览）+ 第 4 节（失败分析），其他章节工程组看

**教训：** 写文档前先问"读者会真的动手吗？"——如果不会，就改成 AI 协作模式。

**实证：** 2026-08-06 第一版指南 248 行涵盖全流程（业务人员看不懂）；用户纠正后重写 211 行聚焦 AI 协作，业务版简洁清晰。

详见 `learnings/2026-08-06-business-user-ai-collaboration.md`。

## 跨客户端协调

- `hermes/scans/INDEX.md` 和 `hermes/tiequan/*/index.md` 通过 git 共享（见 `.gitignore` 例外规则）
- 其他 hermes/ 和 harness/ 文件为本地私有，不同步
- 重要发现应通过 git commit 的代码变更传递，不依赖 hermes/ 文件传递
