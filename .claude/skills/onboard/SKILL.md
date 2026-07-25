---
name: onboard
description: 交互式环境配置向导 — 检测 OS + 核对工具链 + 生成 OS 适配安装命令 + 逐项验证。支持 Windows/macOS/Linux。Interactive multi-OS environment setup wizard for business users.
version: 1.0.0
---

# onboard — 环境配置向导

AI 不装软件（无 sudo），只做"向导"：检测 → 核对 → 给命令 → 用户执行 → 验证 → 下一步。

## 工具清单（按需三级）

**推荐：业务人员（前端开发）用 `minimal`，服务端/全栈开发选更高级别。**

| 级别 | 工具 | 适用角色 |
|------|------|------|
| **minimal** | Git, Node.js(20+), pnpm, Tailscale | 业务人员 — 前端开发 |
| **standard** | + Java(17+), Maven(3.8+), MySQL(8.0), Redis(7.0) | 服务端 — 全栈开发 |
| **full** | + Python3, code-review-graph, Orca CLI | 服务端 — 完整 harness |

## OS 检测

| OS | 检测命令 | 输出特征 |
|----|---------|---------|
| macOS | `uname -s` | `Darwin` |
| Linux | `uname -s` | `Linux` |
| Windows (Git Bash) | `uname -s` | `MINGW64_NT-*` 或 `MSYS_NT-*` |
| Windows (WSL) | `uname -s` + `uname -r` | `Linux` + uname -r 含 `microsoft` 或 `WSL` |

**检测流程：**
```bash
uname -s
# 如果是 Linux，再检查是否为 WSL：
uname -r | grep -qi 'microsoft\|WSL' && echo "WSL" || echo "Native Linux"
```

## 逐工具检测与安装矩阵

### 1. Git

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `git --version` | `brew install git` 或已内置（运行 `xcode-select --install`） |
| Windows | `git --version` | `winget install Git.Git` 或 https://git-scm.com/download/win |
| Linux/WSL | `git --version` | `sudo apt install git -y` |

### 2. Node.js (≥20)

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `node --version` | `brew install node@20` 或 `nvm install 20 && nvm use 20` |
| Windows | `node --version` | `winget install OpenJS.NodeJS.LTS` |
| Linux/WSL | `node --version` | `curl -fsSL https://deb.nodesource.com/setup_20.x \| sudo -E bash - && sudo apt install nodejs -y` |

### 3. pnpm

| OS | 检测 | 安装 |
|----|------|------|
| 所有 | `pnpm --version` | `npm install -g pnpm` |

### 4. Java (≥17)

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `java --version \| head -1` | `brew install openjdk@17` |
| Windows | `java --version` | `winget install EclipseAdoptium.Temurin.17.JDK` |
| Linux/WSL | `java --version \| head -1` | `sudo apt install openjdk-17-jdk -y` |

**版本解析示例：**
```
java --version | head -1
# openjdk 17.0.9 2024-01-16 LTS  → 版本 17 ✅
# openjdk 11.0.9 2024-01-16 LTS  → 版本 11 ❌ (需要 ≥17)
```

### 5. Maven (≥3.8)

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `mvn --version \| head -1` | `brew install maven` |
| Windows | `mvn --version` | `winget install Apache.Maven.3`（或手动下载解压 + PATH） |
| Linux/WSL | `mvn --version \| head -1` | `sudo apt install maven -y` |

### 6. MySQL (≥8.0)

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `mysql --version` | `brew install mysql && brew services start mysql` |
| Windows | `mysql --version` | Docker 推荐（`winget install Docker.DockerDesktop` → `docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0`） |
| Linux/WSL | `mysql --version` | `sudo apt install mysql-server -y && sudo systemctl start mysql` |

**Windows 注意事项：**
- Windows 无原生 MySQL 服务，推荐 Docker Desktop 一键部署
- 替代方案：https://dev.mysql.com/downloads/installer/ 下载 .msi
- Docker 方式无需配置 my.ini，容器自动隔离

### 7. Redis (≥7.0)

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `redis-cli --version` | `brew install redis && brew services start redis` |
| Windows | `redis-cli --version` | Docker 推荐（`docker run -d --name redis -p 6379:6379 redis:7`） |
| Linux/WSL | `redis-cli --version` | `sudo apt install redis-server -y && sudo systemctl start redis` |

**Windows 注意事项：** Windows 无原生 Redis，Docker 是唯一推荐方案。

### 8. Tailscale VPN

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `tailscale version` | `brew install tailscale` 或 App Store 搜索 Tailscale |
| Windows | `tailscale version` | https://tailscale.com/download/windows 下载 .msi |
| Linux/WSL | `tailscale version` | `curl -fsSL https://tailscale.com/install.sh \| sh` |

**登录后验证联通：**
```bash
# 获取本机 IP
tailscale ip -4
# 测试到服务端的连通性（替换为实际服务端 IP）
curl http://<服务端Tailscale IP>:8080/jeecg-boot/sys/randomImage/check
# 返回 JSON = 通 ✅
```

### 9. Python 3 (MCP 依赖)

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `python3 --version` | `brew install python@3` |
| Windows | `python3 --version` 或 `python --version` | `winget install Python.Python.3` |
| Linux/WSL | `python3 --version` | `sudo apt install python3 python3-pip -y` |

### 10. code-review-graph MCP

| OS | 检测 | 安装 |
|----|------|------|
| 所有 | `pip3 show code-review-graph` | `pip3 install code-review-graph` |

**安装后验证：**
```bash
pip3 show code-review-graph | grep Version
# Version: x.x.x → ✅
```

**首次使用需构建图谱：**
```bash
/update-graph
```

### 11. Orca CLI

| OS | 检测 | 安装 |
|----|------|------|
| macOS | `orca --version` | `brew install orca` 或 https://orca.app 下载 dmg |
| Windows | `orca --version` | https://orca.app 下载 .exe |
| Linux/WSL | `orca --version` | https://orca.app 下载 .deb 或 AppImage |

## Windows Docker 兜底

Windows 上 MySQL + Redis 无原生支持，推荐 Docker Desktop：

```bash
# 1. 安装 Docker Desktop
winget install Docker.DockerDesktop
# 启动 Docker Desktop（开始菜单 → Docker）

# 2. 部署 MySQL
docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0

# 3. 部署 Redis
docker run -d --name redis -p 6379:6379 redis:7

# 4. 验证
docker ps | grep -E 'mysql|redis'
# 两个容器都在运行 → ✅
```

## 验证标准

每个工具判定：
- ✅ `command -v <tool>` 成功 + 版本 ≥ 最低要求
- ⚠️ 已安装但版本低于最低要求 → 提示升级命令
- ❌ `command -v <tool>` 失败 → 输出 OS 适配安装命令

## 报告模板

```
## 环境配置报告 — <OS名称>

### 检测结果
| 工具 | 状态 | 版本 | 说明 |
|------|:--:|------|------|
| Git | ✅ | 2.43.0 | |
| Node.js | ⚠️ | v18.17.0 | 需要 ≥20，请升级 |
| Java | ❌ | - | 未安装 |
| ... | | | |

### 需要操作
1. ⚠️ Node.js 版本过低：<OS适配升级命令>
2. ❌ Java 未安装：<OS适配安装命令>
...

### 就绪
- ✅ N/M 项已就绪
- ⚠️ N 项需要升级
- ❌ N 项需要安装

全部就绪后可以进入开发。
```

## 完成后的引导

按级别指引用户下一步：

**minimal 完成：**
```
✅ 前端环境就绪！
下一步：克隆代码 → pnpm install → pnpm dev
参考：/client-setup 技能中的详细步骤
```

**standard 完成：**
```
✅ 前后端环境就绪！
下一步：运行 /start 启动完整开发环境
```

**full 完成：**
```
✅ 完整 harness 环境就绪！
运行 /capability-check 确认 MCP 工具链正常
```
