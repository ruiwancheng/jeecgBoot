# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> You should always answer questions in Simplified Chinese first, unless the user explicitly requests another language.
>
> **沟通风格：本项目的用户群体是业务人员（售前、项目经理、产品经理等），回复时必须使用业务语言描述问题和方案，避免使用技术术语。** 只有在业务语言确实无法准确表达时，才可以使用技术描述。比如：说"把代码推送到仓库"而不是"git push"；说"重启应用"而不是"重启 Docker 容器"；说"网页控制台"而不是"WebSocket 前端页面"。

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

**Code modification markers** (backend only): All added/modified Java code must be wrapped with `update-begin`/`update-end` comments:

```java
//update-begin---author:张三 ---date:2026-07-04  for：【JIRA-1234】修改说明-----------
// modified or added code here
//update-end---author:张三 ---date:2026-07-04  for：【JIRA-1234】修改说明-----------
```

Rules:
- `author`: actual modifier name, `date`: YYYY-MM-DD, `for`: bug/requirement ID + brief description
- New methods: `update-begin` before method declaration, `update-end` after closing `}`
- Modified code within methods: wrap only the changed lines, not the whole method
- If user doesn't provide a bug/requirement ID, ask for it before writing markers

**JeecgBoot Skills:** This project has a rich set of AI Skills for natural-language-driven development (form designer, BPMN, code generation, reports, dashboards, big screens). When the user asks to create forms, workflows, reports, or generate code, invoke the relevant Skill tool rather than hand-coding. Available skills are listed in the system prompt — key ones include `jeecg-desform`, `jeecg-bpmn`, `jeecg-codegen`, `jeecg-onlform`, `jimureport`, `jimubi-dashboard`, `jimubi-bigscreen`, `jeecg-system`.
