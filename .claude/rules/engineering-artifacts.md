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
│   └── <项目名>/                # 按项目分组
│       ├── api/                # API 测试
│       └── e2e/                # E2E 测试
├── e2e/                        # E2E 测试工程
│   ├── demo/                   # 演示项目
│   └── <项目名>/                # 按项目分组
└── test-results/               # 测试运行结果（临时）
```

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

## 跨客户端协调

- `hermes/scans/INDEX.md` 和 `hermes/tiequan/*/index.md` 通过 git 共享（见 `.gitignore` 例外规则）
- 其他 hermes/ 和 harness/ 文件为本地私有，不同步
- 重要发现应通过 git commit 的代码变更传递，不依赖 hermes/ 文件传递
