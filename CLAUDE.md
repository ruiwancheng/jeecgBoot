# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **工作流（强制）：** `/brainstorm → /plan → 写代码 → /verify → 分级测试 → /done`
> 
> ⚠️ **防失忆规则：** 写完代码后必须自动跑 `/verify`；不要等用户提醒。每次回复末尾检查是否遗漏了流程步骤。
>
> 🤖 **自动 delegate 判定：** 用户给任务时，自动判断复杂度——单文件直接做，≥3文件且跨模块走 `/delegate` 派工人。新功能开发自动走 `/delegate`。**工人完成后强制校验：** 检查工作流阶段是否完整、git diff 是否合理、/verify 是否通过，任何异常立即报告。
>
> 用户不需要每次说 `/orca:delegate`。
>
> 🛑 **本地验证铁律：** 本地后端在跑时（8080端口），改代码后必须 `curl localhost:8080` 实测核心逻辑——`mvn compile` 只证明语法正确，不证明逻辑正确。这是 /verify 的硬要求。
> 
> /done 后可选择性调用 铁拳团审计 或 鹰眼团测试 做兜底质量检查。审计和测试的具体规范见 `workflow.md`。

> You should always answer questions in Simplified Chinese first, unless the user explicitly requests another language.
>
> **沟通风格：本项目的用户群体是业务人员（售前、项目经理、产品经理等），回复时必须使用业务语言描述问题和方案，避免使用技术术语。** 只有在业务语言确实无法准确表达时，才可以使用技术描述。比如：说"把代码推送到仓库"而不是"git push"；说"重启应用"而不是"重启 Docker 容器"；说"网页控制台"而不是"WebSocket 前端页面"。
> 
> **Bash 描述（操作确认提示）：同样适用上述规则。** 业务人员会在权限确认弹窗中看到 Bash 命令的描述文字，必须用中文业务语言，让他们能看懂要做什么。格式：做什么事 + 为什么目的。例如：
> ```
> # 正确：中文描述，业务人员能看懂
> 列出所有已创建的项目
> 重启后端应用并确认启动成功
> 
> # 错误：技术黑话，业务人员一脸懵
> ls jeecg-boot/jeecg-boot-module/ | grep '^project-'
> Check if gen-tests-rules.json is tracked
> ```
>
> **输出格式（业务人员友好）：** 面向业务用户的回复遵循以下习惯——
> - 先说结论/动作，再说细节。开篇不写"好的，让我来分析一下"
> - 多步骤任务编号，每步一件事
> - 时间估算用具体分钟数（"约5分钟"），不用"一会儿""很快"
> - 报错直接说"原因 + 修法"，不用"Uh oh""看起来有问题"
> - 列表超过5项拆为"现在做 vs 以后做"
> - 减少"总结一下""希望帮到你"等填充语
>
> ⚠️ 以上不覆盖工作流提示（如"确认无误就进入 /plan""/verify 通过"等流程必需输出）。
>
> 需要极致简洁输出时，可使用 `/i-have-adhd` 切换完整版（详见 `.claude/skills/i-have-adhd/SKILL.md`）。

## 本文档的角色

**CLAUDE.md 是项目入口文档，只做索引和摘要，不重述 Rules/Skills 的具体内容。**

| 层级 | 文件 | 职责 | 示例 |
|------|------|------|------|
| **入口** | `CLAUDE.md` | 全局约束 + 指向 Rules 的索引 | "详见 `file-scope.md`" |
| **规则** | `.claude/rules/*.md` | 可执行的行为约束，有 glob 匹配 | 写操作边界、覆盖机制 |
| **技能** | `.claude/skills/*/SKILL.md` | 领域知识、配置值、模板 | Playwright 配置、Maven 路径 |

**铁律：** CLAUDE.md 不内联 Rule 的具体内容。如果某条规则需要修改，只改对应的 Rule 文件，CLAUDE.md 不需要同步。反过来，新增 Rule 时只需在 CLAUDE.md 的索引区加一行引用。

## Project Overview

JeecgBoot 3.9.2 — enterprise AI low-code platform. Monorepo with two subprojects:

| Directory | Description |
|-----------|-------------|
| `jeecg-boot/` | Java backend, Spring Boot 3.5.5 + Java 17 (also supports 21, 24), Maven |
| `jeecgboot-vue3/` | Vue 3 + Vite 6 + Ant Design Vue 4 + TypeScript frontend, pnpm |

Default credentials: `admin` / `123456`

**Detailed guidance for each subproject is in their respective CLAUDE.md files:**
- `jeecg-boot/CLAUDE.md` — backend build, modules, code conventions, DB setup
- `jeecgboot-vue3/CLAUDE.md` — frontend build, architecture, routing, theming

## Prerequisites

- **Backend:** Java 17+ (also tested on 21, 24), Maven 3.6+, MySQL 8.0+ (or compatible), Redis
- **Frontend:** Node.js 20.19+ or 22.12+ (Vite 6 dropped EOL Node 18), pnpm 9+
- **IDE:** IDEA with Lombok plugin (backend); IDEA / VS Code / WebStorm (frontend)

## Quick Start (Docker)

```bash
# Monolithic mode (MySQL + Redis + app on port 8080)
./start-docker-compose.sh

# Microservices mode
./start-docker-compose-cloud.sh
```

## 部署架构（客户端-服务端分离）

本项目采用**客户端开发 + 服务端部署**的分离架构，业务人员在客户端改代码，服务端统一部署。

### 网络拓扑

```
客户端(Win/Mac) ──Tailscale VPN──> 服务端(WSL2)
   │                                  │
   ├─ pnpm dev (热更新)              ├─ Nginx :80 (前端)
   ├─ git push (提交代码)            ├─ Java :8080 (后端 API)
   └─ 网页控制台 :3101               ├─ MySQL :3306 (数据库)
                                      └─ 部署控制台 :3101 (PM2 管理)
```

### 客户端日常开发（无需部署）

```bash
# 客户端只跑前端开发服务器，后端直连服务端
cd jeecgboot-vue3
pnpm dev   # 改代码即时热更新，秒级生效
```

`.env.development` 已配置指向服务端 `100.122.125.106:8080`。前端改动即时生效，后端/数据库改动提交后走部署控制台。

### 部署控制台

地址：`http://100.122.125.106:3101`

| 按钮 | 触发条件 | 耗时 | 说明 |
|------|------|:--:|------|
| **开始部署（自动检测）** | 默认 | 3-8分钟 | 分析变更自动选模式 |
| 仅前端 | 手动指定 | ~3分钟 | 跳过 Maven 编译 |
| 仅后端 | 手动指定 | ~5分钟 | 跳过前端编译 |
| 强制全量 | 手动指定 | ~8分钟 | 前后端全部重建 |

**自动检测逻辑：** `git pull` 后分析变更，仅 `jeecgboot-vue3/` 有变更时自动降级为"仅前端"，仅 `jeecg-boot/` 有变更时降级为"仅后端"。

### 部署流程（7 步）

```
1. 检查工具 → 2. 拉取代码 → 3. 配置 Hosts → 4. 编译后端(Maven)
  → 5. 编译前端(Vite) → 6. 启动容器(Docker) → 7. 初始化数据库(SQL)
```

- 步骤 4：仅后端/全量模式执行（`mvn clean package`，约 4-5 分钟）
- 步骤 5：仅前端/全量模式执行（`pnpm build:docker`，有 3 次重试机制）
- 步骤 7：SQL 基于文件校验码去重，已执行的脚本自动跳过

### 部署稳定性保障

| 问题 | 措施 |
|------|------|
| Less 编译超时 | Less 锁定 4.4.2，3 次重试 + 清理缓存 |
| SQL 重复执行 | 文件校验码去重，排除 target/ 目录 |
| 编译权限错误 | 自动修复 node_modules 权限并重建 |
| 部署超时 | 15 分钟超时自动重置状态 |

## Backend (jeecg-boot) at a Glance

```
jeecg-boot/
├── jeecg-boot-base-core/       # Core framework: Shiro/JWT, MyBatis-Plus, common utils, AOP
├── jeecg-module-system/        # System management (users, roles, menus, dicts, etc.)
│   ├── jeecg-system-api/       # API interfaces (local vs cloud for mono/micro switch)
│   ├── jeecg-system-biz/       # Business logic (entities, mappers, services)
│   └── jeecg-system-start/     # Main entry point (JeecgSystemApplication), configs
├── jeecg-boot-module/          # Business feature modules
│   ├── jeecg-module-demo/      # Demo/example code
│   └── jeecg-boot-module-airag/ # AI/RAG integration
└── jeecg-server-cloud/         # Microservices (Gateway:9999, Nacos:8848) — needs -P SpringCloud
```

Default ports: App 8080, context-path `/jeecg-boot`. API docs at `/jeecg-boot/doc.html` (Knife4j).

### Common Backend Commands

```bash
# Full build (tests skipped by default)
mvn clean package

# Build with tests
mvn clean package -DskipTests=false

# Run standalone app (port 8080)
cd jeecg-boot/jeecg-module-system/jeecg-system-start && mvn spring-boot:run

# Run a single test class
mvn test -DskipTests=false -pl jeecg-module-system/jeecg-system-biz -Dtest=TestClassName

# Build specific module with dependencies
mvn clean package -pl jeecg-boot-base-core -am

# Build with microservices modules
mvn clean package -P SpringCloud
```

### Configuration Profiles

Main configs in `jeecg-system-start/src/main/resources/`:
- `application.yml` — profile selector (active: dev/test/prod/docker, set via Maven)
- `application-dev.yml` — dev (port 8080, lazy-init, debug logging)
- `application-test.yml` — test environment
- `application-prod.yml` — production
- `application-docker.yml` — Docker deployment
- `application-{oracle,postgresql,sqlserver,dm8,kingbase8}.yml` — alternative DB backends

Dev requires running MySQL and Redis. Optional: MongoDB, RabbitMQ.

### Database Setup

1. Import initial schema: `jeecg-boot/db/jeecgboot-mysql-5.7.sql`
2. Flyway runs incremental migrations from `jeecg-system-start/src/main/resources/flyway/sql/mysql/` (organized by version folders)

Other DB scripts in `db/`: `tables_nacos.sql`, `tables_xxl_job.sql`, plus a `其他数据库脚本/` directory for non-MySQL databases.

## Frontend (jeecgboot-vue3) at a Glance

Default dev server port 3100. Proxies `/jeecg-boot` to backend. Mock enabled in dev mode. Permission mode: BACK (routes/perms fetched from backend API). Router uses HTML5 history mode.

```bash
cd jeecgboot-vue3
pnpm dev       # Dev server (port 3100)
pnpm build     # Production build
pnpm preview   # Build + preview
```

## Cross-Project Development Notes

**When working on backend + frontend simultaneously**, start both dev servers:
```bash
# Terminal 1: backend
cd jeecg-boot/jeecg-module-system/jeecg-system-start && mvn spring-boot:run

# Terminal 2: frontend
cd jeecgboot-vue3 && pnpm dev
```

Frontend dev proxy forwards `/jeecg-boot` requests to `localhost:8080/jeecg-boot`. No CORS issues in dev.

**API response format** (both sides must agree): `{ code: 200, success: true, result: <data>, message: "<msg>" }`

**Code modification markers** (backend only): All added/modified Java code must be wrapped with `update-begin`/`update-end` comments. See `.claude/rules/code-style.md` for the summary and `jeecg-dev` skill for the full specification.

**JeecgBoot Skills:** This project has a rich set of AI Skills for natural-language-driven development (form designer, BPMN, code generation, reports, dashboards, big screens). When the user asks to create forms, workflows, reports, or generate code, invoke the relevant Skill tool rather than hand-coding. Available skills are listed in the system prompt — key ones include `jeecg-desform`, `jeecg-bpmn`, `jeecg-codegen`, `jeecg-onlform`, `jimureport`, `jimubi-dashboard`, `jimubi-bigscreen`, `jeecg-system`.

## Super Harness — KA 定制开发规则（强制）

本项目的 KA 定制采用 **基座 + 覆盖层** 策略。标品代码所有客户共享，客户定制代码放在专属目录中。

> 以下为摘要。完整可执行规则见 `.claude/rules/` 目录：
> - 文件边界 → `file-scope.md`
> - 数据库边界 → `data-scope.md`
> - 覆盖机制 → `override-mechanism.md`
> - 代码规范 → `code-style.md`
> - 后端优先 → `backend-first.md`
> - 安全 → `security.md`
> - 平台保护 → `no-platform-modify.md`
> - 工程产物 → `engineering-artifacts.md`
> - 开发流程 → `workflow.md`
> - 前端组件 → `frontend.md`
> - 测试标准 → `testing.md`
> - 调试规范 → `debugging.md`
> - 命令技能边界 → `skill-command-boundary.md`
> - 铁拳团审计留存 → `tiequan-report-retention.md`
> - 铁拳团审计范围 → `tiequan-report-scope.md`
> - 部署质量门控 → `deploy-quality-gate.md`
> - 业务链路注册表 → `hermes/business-chains.json`
> - 链路审计（铁拳团第11视角） → `.claude/skills/jeecg-chain-audit/SKILL.md`

### 读操作（不限）
你可以阅读项目中任意文件。重点参考：
- `jeecg-boot/CLAUDE.md` — 后端开发规范
- `jeecgboot-vue3/CLAUDE.md` — 前端开发规范
- `jeecg-boot-module/jeecg-module-demo/` — 已有业务模块参考

### 写操作（限制）
**只能在客户专属目录下新建或修改文件。** 详见 `file-scope.md`。

### 新建客户模块
使用 `/new-project <客户名>` 命令，自动创建脚手架。
