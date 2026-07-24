# CLAUDE.md

## 基础工作流

```
/brainstorm → /plan → [orca-review] → 写代码 → /verify → /done
  需求澄清     实施方案    外部评审      编码实现    自验证     完成检查
```

子项目规范见 `jeecg-boot/CLAUDE.md` 和 `jeecgboot-vue3/CLAUDE.md`。

### 关键规则

| # | 规则 |
|---|------|
| 1 | **先分析再改** — 输出根因+方案+影响面 → 等用户确认 |
| 2 | **改完必验证** — 写完代码建议 /verify |
| 3 | **验证必实测** — 本地后端在线时 /verify 会 curl 实测 |
| 4 | **简单精准** — 只写必要代码、不顺手改邻居、困惑就问（详见 `karpathy-guidelines.md`） |

步骤清单: `/brainstorm → /plan → orca-review → 写代码 → /verify → /done`（遇报错用 /debug）

## 沟通风格

用户群体是业务人员，使用业务语言描述。**Bash 描述用中文业务语言**（如"重启后端应用"而非"kill java进程"）。先说结论再说细节。

## Project Overview

JeecgBoot 3.9.2 — enterprise AI low-code platform.

| Directory | Description |
|-----------|-------------|
| `jeecg-boot/` | Java backend, Spring Boot 3.5.5 + Java 17, Maven |
| `jeecgboot-vue3/` | Vue 3 + Vite 6 + Ant Design Vue 4 + TypeScript, pnpm |

Default credentials: `admin` / `123456`

## Super Harness — KA 定制开发规则

**基座 + 覆盖层** 策略。标品代码共享，客户定制放专属目录。

> 完整规则见 `.claude/rules/`：
> `file-scope` `data-scope` `override-mechanism` `code-style` `backend-first` `security`
> `no-platform-modify` `engineering-artifacts` `workflow` `frontend` `testing` `debugging`
> `karpathy-guidelines` `skill-command-boundary` `audit-classification` `quality-gates` `tiequan-reports`
> `deploy-quality-gate`
> 链路注册表 → `hermes/business-chains.json`

**读操作：** 可读任意文件。**写操作：** 仅客户专属目录（详见 `file-scope.md`）。**新建客户模块：** `/new-project <客户名>`。
