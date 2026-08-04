<!-- update-begin---author:pi---date:2026-08-04---for:【REGRESSION-COMMANDS】新增跨平台测试环境布置命令 -->
---
description: 自有命令 — 检查或布置回归测试环境，兼容 Windows、Ubuntu、macOS 和远程客户端
---

# /test-environment [--check|--local|--client|--remote <地址>]

测试环境命令只负责环境检查和布置，不直接执行业务回归测试。

## 用法

```text
/test-environment --check                 # 只检查，不启动、不安装、不改配置
/test-environment --local                 # 本机运行后端、前端和依赖服务
/test-environment --client                # 客户端模式：只运行前端，连接远程服务端
/test-environment --remote <服务端地址>    # 检查指定远程 API/UI 服务
```

## 必须加载

```text
.claude/skills/test-environment/SKILL.md
.claude/skills/local-dev/SKILL.md
.claude/skills/client-setup/SKILL.md
```

## 系统识别

先识别当前客户端：

```text
Windows → PowerShell / Windows 进程管理
Ubuntu/Linux → systemd/进程组
macOS → launchctl/Homebrew/进程组
```

测试命令本身统一使用 Python runner，不在命令中写死平台专属启动脚本。

## --check 只检查模式

必须检查并报告：

### 工具链

- Python：`python` 或 `python3`
- Java：17 或更高
- Node.js：20 或更高
- pnpm
- Maven（服务端模式）
- Playwright 浏览器（E2E 模式）

### 服务

- MySQL：本地服务端模式必需
- Redis：本地服务端模式必需
- 后端 API：默认 `http://127.0.0.1:8080/jeecg-boot`
- 前端 UI：默认 `http://127.0.0.1:3100`
- 登录接口和加密接口

### 输出格式

```text
测试环境检查
├─ 操作系统：Windows / Ubuntu / macOS
├─ Python：✅ / ❌
├─ Java 17：✅ / ❌
├─ Node.js：✅ / ❌
├─ pnpm：✅ / ❌
├─ Maven：✅ / ❌ / 客户端模式不需要
├─ MySQL：✅ / ❌ / 客户端模式不需要
├─ Redis：✅ / ❌ / 客户端模式不需要
├─ 后端 8080：✅ / ❌
├─ 前端 3100：✅ / ❌
└─ 测试环境：READY / BLOCKED
```

检查失败时必须输出：

- 缺少的工具或服务；
- 当前系统对应的安装/启动建议；
- 是否需要用户授权；
- 不继续启动回归测试。

## --local 本地服务端模式

加载 `local-dev` 技能并执行：

1. 检查 Java、Node、pnpm、Maven；
2. 检查 MySQL、Redis；
3. 初始化数据库前确认当前数据库连接目标；
4. 启动或复用后端 8080；
5. 启动或复用前端 3100；
6. 真实访问健康接口和登录接口；
7. 输出 READY 后才允许 `/test-regression`。

禁止：

- 未确认数据库目标就执行 SQL；
- 杀掉其他客户端正在使用的服务；
- 用固定 Windows 路径替代 Maven/Node 探测；
- 用 `localhost` 覆盖用户明确指定的远程地址。

## --client 客户端模式

加载 `client-setup` 和 `client-start` 技能：

客户端只需要：

- Node.js
- pnpm
- Tailscale/VPN
- 前端代码和依赖

客户端不启动：

- Java 后端
- MySQL
- Redis

必须要求用户提供或读取远程服务端地址，并检查：

```text
<服务端>:8080/jeecg-boot
<服务端>:3100
```

本机前端仍可使用 3100，但 API 必须代理到远程服务端。

## --remote 远程服务检查

示例：

```text
/test-environment --remote http://100.122.125.106
```

检查：

```text
API：<地址>:8080/jeecg-boot
UI：<地址>:3100
登录/加密接口是否可访问
```

远程模式不得：

- 启动本地后端；
- 初始化本地数据库；
- 杀本地 Java/Node 进程；
- 把远程连接失败当成产品 Bug。

## 环境报告

每次完整布置或检查后保存：

```text
harness/.regression-runs/<run-id>/environment-report.json
harness/.regression-runs/<run-id>/environment-report.md
```

报告必须记录：

- 操作系统；
- 工具版本；
- API/UI 地址；
- 端口和健康检查结果；
- 启动了哪些服务；
- 哪些服务是复用的；
- 未解决的环境风险。

## 与回归命令的衔接

```text
/test-environment --check
  ↓ READY
/test-regression --dashboard
```

如果环境状态为 BLOCKED，必须停止在环境阶段，不能继续跑测试。
<!-- update-end---author:pi---date:2026-08-04---for:【REGRESSION-COMMANDS】新增跨平台测试环境布置命令 -->
