# CLAUDE.md

## 基础工作流（核心）

```
/brainstorm → /plan → [orca-review] → 写代码 → /verify → 分级测试 → /done
  需求澄清     实施方案    交互验证      编码实现    自验证     提交部署     完成检查
                                          ↑
                                    /debug 修复方案也触发
```

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
子项目规范见 `jeecg-boot/CLAUDE.md` 和 `jeecgboot-vue3/CLAUDE.md`。

### 关键规则

| # | 规则 | 说明 |
|---|------|------|
| 1 | **先分析再改** | 收到任务 → 输出根因+方案+影响面 → 等用户确认 → 再改代码 |
| 2 | **改完必验证** | 写完代码自动跑 /verify，不要等用户提醒 |
| 3 | **验证必实测** | 本地后端在线 → /verify 必须 curl 实测，禁止只跑 `mvn compile` |
| 4 | **简单精准** | 只写必要代码、不顺手改邻居、困惑就问。详见 `karpathy-guidelines.md` |

### orca-review 触发规则

| 触发场景 | 触发方式 |
|----------|:--:|
| /plan 后 — full 级（Entity/Mapper/SQL/≥5文件） | **自动触发** |
| /plan 后 — 标准级（Controller/Service/Vue/≤3文件） | **提示用户确认** |
| /plan 后 — 轻量级（文案/样式/注释） | 跳过 |
| /debug 诊断后 — 修复方案 ready | **自动提示** |
| 用户说"帮我审查下这个方案" | 手动 |

### 自动 delegate 判定

- 单文件 → **直接做**（先输出分析，等确认后动手）
- ≥3文件且跨模块 / 新功能开发 → **/delegate 派工人**

### /verify 标准

| 改动类型 | 验证方式 |
|----------|---------|
| 后端 Java | `mvn compile` + `curl` 实测 |
| 前端 Vue | dev server 200 + `orca computer` 自动验证 |
| 配置 .md | 内容一致性检查 |

### 分级测试

| 级别 | 触发条件 | 执行内容 |
|:--:|------|------|
| 轻量 | 文案/样式/注释 | /verify |
| 标准 | Controller/Service/Vue（≤3文件） | /verify + /test-api |
| 全量 | Entity/Mapper/SQL/≥5文件 | /verify + /test-api + /test-e2e + /test-all |

步骤清单：/brainstorm → /plan → orca-review → 写代码 → /verify → /quality-gate → 提交推送 → 部署 → 分级测试 → /done（遇报错用 /debug）

> ⚠️ 写完代码必须自动 /verify。verify 通过必须 commit+push。本地后端在线必须 curl 实测。
> 完整防失忆触发表见 `.claude/rules/workflow.md`。

## Delegate 门控（工人执行约束）

> 以下协议是 **delegate 模式下约束工人终端**的。直接模式只需遵守上方基础工作流。

```
收到任务 → 判定模式 → 输出分析 → 等确认 → 再改代码 → /verify
             │                              ↑
             │  delegate: 等Claude评审       │ 直接: 等用户确认
             │______________________________↑
             跳过分析或未等确认就改 = 违规
```

| 步骤 | 门控 | 豁免 |
|:--:|------|------|
| ① | **判定模式：** ≥3文件/跨模块 → delegate；否则直接做 | — |
| ② | **输出分析：** 根因+方案+影响面（必须可见） | — |
| ②.5 | **orca-review：** 非纯文本改动 → Claude 外部评审 | 文案/注释/样式免评 |
| ③ | **等确认：** delegate=等Claude评审回复；直接=等用户确认 | — |
| ④ | **验证门：** 改完后编译+curl | — |

> 违规后回退重来。详细规则见 `.claude/rules/workflow.md` 和 `.claude/commands/orca/delegate.md`。

## 沟通风格

> 用户群体是业务人员，使用业务语言描述。**Bash 描述必须用中文业务语言**（如"重启后端应用"而非"kill java进程"）。先说结论再说细节。具体规范见 `.claude/skills/i-have-adhd/SKILL.md`。

## Project Overview

JeecgBoot 3.9.2 — enterprise AI low-code platform.

| Directory | Description |
|-----------|-------------|
| `jeecg-boot/` | Java backend, Spring Boot 3.5.5 + Java 17, Maven |
| `jeecgboot-vue3/` | Vue 3 + Vite 6 + Ant Design Vue 4 + TypeScript, pnpm |

Default credentials: `admin` / `123456`

## Super Harness — KA 定制开发规则（强制）

**基座 + 覆盖层** 策略。标品代码共享，客户定制放专属目录。

> 完整可执行规则见 `.claude/rules/` 目录：
> `file-scope` `data-scope` `override-mechanism` `code-style` `backend-first` `security`
> `no-platform-modify` `engineering-artifacts` `workflow` `frontend` `testing` `debugging`
> `karpathy-guidelines` `skill-command-boundary` `audit-classification` `tiequan-report-retention` `tiequan-report-scope`
> `deep-inspect-schedule` `quality-escalation` `quality-gate-criteria` `security-gate-checklist` `deploy-quality-gate`
> 链路注册表 → `hermes/business-chains.json`
> 链路审计 → `.claude/skills/jeecg-chain-audit/SKILL.md`

**读操作：** 可读任意文件。**写操作：** 仅客户专属目录（详见 `file-scope.md`）。**新建客户模块：** `/new-project <客户名>`。
