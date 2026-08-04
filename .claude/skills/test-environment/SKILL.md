---
name: test-environment
description: 回归测试环境检查与布置 — 跨 Windows、Ubuntu、macOS、本地服务端、客户端和远程服务模式
version: 1.0.0
---

# 回归测试环境技能

## 目标

在回归测试开始前明确回答：

```text
当前客户端是什么系统？
测试跑在哪台机器？
前端访问哪台机器？
API 访问哪台机器？
后端/数据库由谁负责？
```

环境未明确时，不启动回归测试。

## 三种拓扑

### 1. 本地服务端模式

```text
当前客户端
├─ 前端 :3100
├─ 后端 :8080
├─ MySQL :3306
└─ Redis :6379
```

适用：开发机或独立测试机拥有完整代码和服务。

### 2. 客户端模式

```text
当前客户端                  远程服务端
├─ 前端 :3100   ───────────▶ API :8080
├─ Node/pnpm                 MySQL :3306
└─ Tailscale                 Redis :6379
```

适用：Windows/macOS/Ubuntu 客户端只运行前端和浏览器测试。

### 3. 远程检查模式

当前客户端不启动服务，只检查用户指定的 UI/API 地址。

## 工具探测顺序

所有系统统一优先使用 Python：

```text
1. python
2. python3
```

不要假定：

```text
mvn.cmd
/usr/local/bin/mvn
C:\apache-maven\bin\mvn.cmd
```

Maven、Node、pnpm 通过 PATH、MAVEN_HOME、JAVA_HOME、PNPM_HOME 和系统常见路径探测。

## Windows 规则

- Java：检查 `java -version`；
- Maven：查 `mvn.cmd` 或 `MAVEN_HOME`；
- Node/pnpm：查 `node.exe`、`pnpm.cmd`；
- 端口：Python socket 检查，不依赖 `netstat`；
- 后台进程：由 Python runner 使用独立进程组；
- 不主动 taskkill 非本次运行创建的进程。

## Ubuntu 规则

- Java/Node/pnpm/Maven 通过 PATH 探测；
- 服务状态优先用 TCP 健康检查；
- runner 使用独立 session/进程组；
- 不假设 systemd 一定存在；
- 缺依赖时输出 apt/nvm/corepack 建议，但未经用户确认不自动安装。

## macOS 规则

- 同时支持 Intel 和 Apple Silicon；
- 检查 `/opt/homebrew/bin`、`/usr/local/bin`；
- 不假设 Homebrew 已安装；
- runner 使用独立 session；
- 缺依赖时输出 brew/nvm/corepack 建议，但未经用户确认不自动安装。

## 健康检查顺序

```text
1. 解释器
2. 工具链
3. 依赖目录
4. MySQL/Redis（本地服务端模式）
5. 后端健康接口
6. 前端首页
7. 登录/加密接口
8. Playwright 浏览器
```

后端必须同时满足：

- TCP 端口可访问；
- `sys/getEncryptedString` 可访问；
- `/sys/login` 能返回有效 token 或明确的认证失败；
- 不能只看 HTTP 200。

## 地址规则

默认本地地址：

```text
UI：http://127.0.0.1:3100
API：http://127.0.0.1:8080/jeecg-boot
```

客户端/远程模式必须使用显式地址：

```text
E2E_UI_BASE
E2E_API_BASE
PLAYWRIGHT_BASE_URL
HARNESS_BASE
```

禁止测试文件自行写死远程 IP。

## 环境判定

| 状态 | 含义 | 后续动作 |
|---|---|---|
| READY | 依赖和服务全部可用 | 允许启动回归 |
| PARTIAL | 可运行部分测试 | 只执行明确不依赖缺项的范围 |
| BLOCKED | 登录、API、UI 或关键依赖不可用 | 停止回归，记录环境问题 |

## 产物

环境检查结果写入：

```text
harness/.regression-runs/<run-id>/environment-report.json
harness/.regression-runs/<run-id>/environment-report.md
```

环境问题不能写入产品问题列表，统一使用：

```text
environment_issue
blocked_environment
```
