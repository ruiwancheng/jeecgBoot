# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 基础工作流

```
/brainstorm → /plan → [orca-review] → 写代码 → /verify → /done
  需求澄清     实施方案    外部评审      编码实现    自验证     完成检查
```

遇报错用 `/debug`，看不懂技术回复用 `/business-description`。步骤清单见 `workflow.md`。

### 关键规则

| # | 规则 |
|---|------|
| 1 | **先分析再改** — 输出根因+方案+影响面 → 等用户确认 |
| 2 | **改完必验证** — 写完代码执行 `/verify` |
| 3 | **验证必实测** — 本地后端在线时 `/verify` 会 curl 实测 |
| 4 | **简单精准** — 只写必要代码、不顺手改邻居、困惑就问 |
| 5 | **信任结果不信任过程** — 功能对+数据对是最硬证据，不纠结 AI 有没有跳步。结果验证 > 过程验证 |
| 6 | **验证派 worker 而非自己跑** — `/verify` 阶段改派 subagent worker 在独立 terminal 实测（避免主对话 context 污染 + 漏掉 P0 bug）。PI 静态检查漏掉的 4 个 P0 都是 worker 跑测发现的。 |

---

## 活跃项目

当前项目：**mes**（`jeecg-boot-module/project-mes/` + `src/views/project/mes/`）

---

## 常用命令

### 后端 (Java, jeecg-boot/)

```bash
# 编译（必须先 install，不能只 compile——新模块需要 JAR 进本地仓库）
cd jeecg-boot && mvn clean install -DskipTests

# 编译单个模块（只读/快速检查用）
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am

# 启动后端（端口 8080，context-path: /jeecg-boot）
cd jeecg-boot/jeecg-module-system/jeecg-system-start && mvn spring-boot:run

# 运行单个测试类
cd jeecg-boot && mvn test -DskipTests=false -pl jeecg-boot-module/project-mes -Dtest=MesXxxControllerTest

# 构建完整包
cd jeecg-boot && mvn clean package -DskipTests
```

### 前端 (Vue 3, jeecgboot-vue3/)

```bash
cd jeecgboot-vue3

pnpm dev              # 开发服务器 (端口 3100，mock 启用，代理 → localhost:8080/jeecg-boot)
pnpm build            # 生产构建 → dist/
pnpm build:docker     # Docker 生产构建
pnpm clean:cache      # 清除 Vite 缓存（新增 Vue 组件后需重启 Vite）
pnpm reinstall        # 清空依赖重装

# 代码检查
npx eslint src/path/to/file.vue          # ESLint 检查单文件
npx stylelint "src/**/*.{vue,less,css}"  # 样式检查
pnpm batch:prettier                       # 格式化全部 src 文件
```

### Docker 服务

```bash
# 启动开发环境 Docker 服务（MySQL:13306, Redis, PostgreSQL+pgvector, MongoDB）
./start-docker-compose.sh   # Windows: start-docker-compose.bat

# 应用容器（端口 8080）
docker compose up -d jeecg-boot
```

---

## Project Overview

JeecgBoot 3.9.2 — enterprise AI low-code platform. 标品基座 + KA 定制覆盖层。

| Directory | Description |
|-----------|-------------|
| `jeecg-boot/` | Java backend, Spring Boot 3.5.5 + Java 17, Maven |
| `jeecgboot-vue3/` | Vue 3 + Vite 6 + Ant Design Vue 4 + TypeScript, pnpm |

默认凭证：`admin` / `123456`

### 模块架构

```
jeecg-boot/
├── jeecg-boot-base-core/           # 核心框架：Shiro/JWT、MyBatis-Plus、通用工具
├── jeecg-module-system/
│   ├── jeecg-system-api/           # API 接口（local-api 单体 / cloud-api 微服务）
│   ├── jeecg-system-biz/           # 系统管理业务逻辑
│   └── jeecg-system-start/         # 主入口 JeecgSystemApplication + 全部配置
└── jeecg-boot-module/              # 业务模块
    ├── project-mes/                # ★ 当前 KA 项目
    ├── customer-demo/              # 客户示例项目
    ├── project-template/           # KA 项目模板
    ├── jeecg-module-demo/          # 演示示例
    └── jeecg-boot-module-airag/    # AI/RAG 集成
```

### 关键配置位置

| 文件 | 用途 |
|------|------|
| `jeecg-system-start/src/main/resources/application-dev.yml` | 开发环境：端口 8080、数据源、Redis |
| `jeecg-system-start/src/main/resources/application.yml` | Profile 选择器 (dev/test/prod/docker) |
| `jeecgboot-vue3/.env.development` | 前端开发配置：端口 3100、代理目标、mock 开关 |
| `jeecgboot-vue3/vite.config.ts` | Vite 构建配置、路径别名、预构建依赖 |

---

## Super Harness — KA 定制开发规则

**基座 + 覆盖层** 策略。标品代码共享，客户定制放专属目录。

> 完整规则见 `.claude/rules/`：
> `code-style` `boundary` `debugging` `deploy-quality-gate`
> `engineering-artifacts` `workflow` `frontend` `testing`
> `karpathy-guidelines` `skill-command-boundary` `audit-classification` `quality-gates` `tiequan-reports`
> 链路注册表 → `hermes/business-chains.json`

**读操作：** 可读任意文件。**写操作：** 仅客户专属目录（详见 `boundary.md`）。**新建客户模块：** `/new-project <客户名>`。

### 代码修改标记（强制）

所有新增/修改代码必须包裹：

```java
//update-begin---author:作者 ---date:YYYY-MM-DD  for：【需求号】修改说明-----------
// 新增或修改的代码
//update-end---author:作者 ---date:YYYY-MM-DD  for：【需求号】修改说明-----------
```

- 新增方法：`update-begin` 在方法声明前，`update-end` 在方法结束 `}` 后
- 修改已有方法：只包裹被修改的代码段，不包裹整个方法

### 关键踩坑提醒

- **新 Maven 模块** 需注册三处：`boot-module/pom.xml`(module) + `system-start/pom.xml`(dependency) + **`mvn install`**（不能只 compile）
- **SQL 迁移脚本** 放 `project-mes/db/V{版本号}__{描述}.sql`，MySQL 5.7 兼容（禁止 `DROP INDEX IF EXISTS`），字典项用 `DELETE+INSERT` 保证幂等
- **菜单注册** 走 Java Runner（`MesMenuRegistry`），不在 SQL 中写中文菜单名
- **权限码** 必须同时设 `id` 和 `perms`（Shiro 匹配 `perms` 列，不是 `id` 列）
- **新增 Vue 组件** 后必须重启 Vite（`import.meta.glob` 缓存）
- **禁止** 硬编码用户名 `"admin"` 做数据隔离，用 `hasRole("mes_admin")`

---

## 沟通风格

用户群体是业务人员，使用业务语言描述。**Bash 描述用中文业务语言**（如"重启后端应用"而非"kill java进程"）。先说结论再说细节。

## 会话记忆

`.remember/` 目录持久化会话上下文。文件：`now.md`（当前缓冲）、`today-*.md`（每日）、`recent.md`（7 天）、`archive.md`（旧记录）、`core-memories.md`（关键事件）。`/learn` 命令结束时捕获经验写入。

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes_tool` or `query_graph_tool` instead of Grep
- **Understanding impact**: `get_impact_radius_tool` instead of manually tracing imports
- **Code review**: `detect_changes_tool` + `get_review_context_tool` instead of reading entire files
- **Finding relationships**: `query_graph_tool` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview_tool` + `list_communities_tool`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
| ------ | ---------- |
| `detect_changes_tool` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context_tool` | Need source snippets for review — token-efficient |
| `get_impact_radius_tool` | Understanding blast radius of a change |
| `get_affected_flows_tool` | Finding which execution paths are impacted |
| `query_graph_tool` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes_tool` | Finding functions/classes by name or keyword |
| `get_architecture_overview_tool` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes_tool` for code review.
3. Use `get_affected_flows_tool` to understand impact.
4. Use `query_graph_tool` pattern="tests_for" to check coverage.

### Degradation transparency (hard requirement)

**Silent degradation is forbidden.** If code-review-graph MCP tools are unavailable (not in the tool list, or calls return errors), you MUST output the following degradation notice verbatim before falling back:

```
⚠️ 降级：code-review-graph MCP 不可用 → 改用 Grep/Read（影响：失去架构感知能力，代码探索/审查质量下降。诊断：/capability-check）
```

Then proceed with the fallback. The user must see this notice.

### MCP 不可用降级策略（mcp-downgrade-policy）

**触发条件：** code-review-graph MCP 在当前会话不可用（不在工具列表 / capability_hash revoked / server 挂）。

**处理方式：**
1. **禁止静默降级到 Grep/Read**（违反 project instructions）
2. **改派 Claude subagent**：用 `orca orchestration task-create + dispatch --inject` 把调研任务派给 Claude 终端（如 `term_20ea31ad-*`），Claude 自带 MCP 可深度分析
3. **subagent 工具失败时降级**：`subagent` 工具偶尔"成功但未注入" → 改用 `orca terminal send --text "..." --enter` 直接 inject 到 Claude 终端
4. **回报机制**：subagent 通过 `orca orchestration send --task <id> --to run:<id> --type worker_done` 回报；用 inbox 轮询拿结果
5. **如 MCP 仍报不可用**：subagent 内部也用 Read/Grep，但报告时明确标注"MCP 调用次数 = 0（不可用）"

**用户偏好（2026-08-06）：** "派发子任务可参考 orca-review 命令"——`orca terminal list` 找 Claude 终端 → `task-create` → `dispatch --inject`。

详见 `learnings/2026-08-06-mcp-downgrade-policy.md`。
