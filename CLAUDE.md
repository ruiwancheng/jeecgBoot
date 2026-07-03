# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JeecgBoot 3.9.2 — enterprise AI low-code platform. Monorepo with two subprojects:

| Directory | Description |
|-----------|-------------|
| `jeecg-boot/` | Java backend, Spring Boot 3.5.5 + Java 17, Maven |
| `jeecgboot-vue3/` | Vue 3 + Vite 6 + Ant Design Vue 4 + TypeScript frontend, pnpm |

Default credentials: `admin` / `123456`

**Detailed guidance for each subproject is in their respective CLAUDE.md files:**
- `jeecg-boot/CLAUDE.md` — backend build, modules, code conventions, DB setup
- `jeecgboot-vue3/CLAUDE.md` — frontend build, architecture, routing, theming

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

## Frontend (jeecgboot-vue3) at a Glance

Default dev server port 3100. Proxies `/jeecg-boot` to backend. Mock enabled in dev mode. Permission mode: BACK (routes/perms fetched from backend API). Router uses HTML5 history mode.

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

**Code modification markers** (backend only): All added/modified Java code must be wrapped with `update-begin`/`update-end` comments. See `jeecg-boot/CLAUDE.md` for the exact format.

**Database:** Initial schema at `jeecg-boot/db/jeecgboot-mysql-5.7.sql`. Flyway handles incremental migrations from `jeecg-system-start/src/main/resources/flyway/`.

**JeecgBoot Skills:** This project has a rich set of AI Skills for natural-language-driven development (form designer, BPMN, code generation, reports, dashboards, big screens). When the user asks to create forms, workflows, reports, or generate code, invoke the relevant Skill tool rather than hand-coding. Available skills are listed in the system prompt — key ones include `jeecg-desform`, `jeecg-bpmn`, `jeecg-codegen`, `jeecg-onlform`, `jimureport`, `jimubi-dashboard`, `jimubi-bigscreen`, `jeecg-system`.
