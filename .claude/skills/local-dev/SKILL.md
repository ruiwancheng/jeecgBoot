---
name: local-dev
description: 本地开发环境管理 — 启动/检查后端+前端+数据库，业务人员一句话 /start 即可
version: 1.0.0
---

# 本地开发环境 (local-dev)

## 概述

为 JeecgBoot 项目提供一键启动的本地开发环境。AI 自动检查 MySQL、Redis、Java、Node 是否就绪，首次运行自动初始化数据库，然后启动后端（DevTools 热重载）和前端。

**面向用户**：业务人员（售前、项目经理、产品经理），不需要理解 MySQL/Maven/npm，只需输入 `/start`。

## 前置依赖（运维一次性安装）

### Mac

```bash
brew install mysql redis node@22 openjdk@17
brew services start mysql redis
```

### Windows

```bash
# MySQL：安装 MySQL Server 或 MySQL Docker 容器
# Redis：安装 Redis for Windows 或 Redis Docker 容器
# Java：安装 JDK 17+
# Node：安装 Node 20+ + pnpm
```

两种平台都是纯本地服务，不经过 Docker（除非用户自己选择了 Docker 方式）。

## 启动流程（5 步，每步幂等）

### 步骤 1：环境检查

检查并自动启动需要的服务。**命令按平台选择：**

#### Mac 平台

```bash
brew services list | grep mysql | grep started || brew services start mysql
brew services list | grep redis | grep started || brew services start redis
java --version | head -1
node --version
pnpm --version || npm install -g pnpm
```

#### Windows 平台（Git Bash / WSL）

```bash
# MySQL — 端口检测
netstat -ano | grep ":3306 " | grep LISTEN || echo "⚠️ MySQL 未运行，请启动 MySQL 服务"

# Redis — 端口检测
netstat -ano | grep ":6379 " | grep LISTEN || echo "⚠️ Redis 未运行，请启动 Redis 服务"

# Java（要求 ≥17）
java --version 2>&1 | head -1

# Node（要求 ≥20）
node --version 2>&1

# pnpm
pnpm --version 2>&1 || npm install -g pnpm
```

> Windows 上用 `netstat -ano` 替代 `lsof -i`，`2>&1` 替代 `2>/dev/null`。端口检测只判断进程在不在监听，不做自动拉起（Windows 没有统一的 service manager）。

### 步骤 2：数据库初始化（幂等）

首次运行导入表结构，后续运行跳过：

```bash
# 建库（幂等：已存在则跳过）
mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS \`jeecg-boot\` DEFAULT CHARACTER SET utf8mb4;"

# 判断是否需要导入（检查表数量）
TABLE_COUNT=$(mysql -uroot -proot jeecg-boot -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='jeecg-boot';" 2>/dev/null | tail -1)

if [ "$TABLE_COUNT" = "0" ] || [ -z "$TABLE_COUNT" ]; then
  # 导入 JeecgBoot 平台基础表
  mysql -uroot -proot jeecg-boot < jeecg-boot/db/jeecgboot-mysql-5.7.sql 2>/dev/null

  # 导入 JeecgBoot 平台基础表
  mysql -uroot -proot jeecg-boot < jeecg-boot/db/jeecgboot-mysql-5.7.sql 2>/dev/null

  # 导入所有 MES 业务模块表（部署控制台扫描路径：**/sql/*.sql + **/db/*.sql）
  # 注意：必须同时扫描 db/ 和 src/main/resources/sql/ 两个目录，
  # 因为部分建表 SQL（如客户/供应商的基础 CREATE TABLE）在 resources/sql/ 中，
  # 后续 ALTER TABLE 的增量迁移在 db/ 中，按文件名字母序执行保证顺序正确
  find jeecg-boot/jeecg-boot-module/project-mes -path "*/target/*" -prune -o \( -path "*/sql/*.sql" -o -path "*/db/*.sql" \) -type f -print | sort | while read f; do
    mysql -uroot -proot --force jeecg-boot < "$f" 2>/dev/null
  done
fi
```

### 步骤 3：安装项目依赖（幂等）

```bash
# 前端依赖（首次：pnpm install；后续：跳过）
cd jeecgboot-vue3 && pnpm install
```

### 步骤 4：启动后端

```bash
# 端口检测（netstat 跨 Mac/Win 通用，Git Bash 下均可运行）
netstat -ano 2>/dev/null | grep ":8080 " | grep -q LISTEN
if [ $? -ne 0 ]; then
  # 端口空闲，启动后端（后台运行，DevTools 热重载）
  cd jeecg-boot/jeecg-module-system/jeecg-system-start
  nohup mvn spring-boot:run -Dspring-boot.run.profiles=dev -Dspring.flyway.enabled=false \
    > /tmp/jeecg-local-backend.log 2>&1 &
fi

# 等待后端就绪（最长 90 秒）
for i in $(seq 1 30); do
  sleep 3
  curl -s "http://localhost:8080/jeecg-boot/sys/getEncryptedString" 2>&1 | grep -q "success" && break
done
```

### 步骤 5：启动前端

```bash
# 端口检测
netstat -ano 2>/dev/null | grep ":3100 " | grep -q LISTEN
if [ $? -ne 0 ]; then
  cd jeecgboot-vue3 && nohup pnpm dev > /tmp/jeecg-local-frontend.log 2>&1 &
fi

# 等待前端就绪（最长 30 秒）
for i in $(seq 1 10); do
  sleep 3
  curl -s http://localhost:3100 2>&1 | head -1 | grep -q "<html\|<!DOCTYPE" && break
done
```

## 最终确认输出

```
✅ 本地开发环境就绪！

  前端：http://localhost:3100
  后端：http://localhost:8080/jeecg-boot/doc.html（接口文档）
  账号：admin / 123456

  修改代码：
  • Vue 文件 → 浏览器自动刷新（秒级）
  • Java 文件 → 后端自动热重载（2-5 秒）
  • SQL 文件 → 本地 mysql 命令直接执行

  部署到服务端：代码推送后到 100.122.125.106:3101 点击"开始部署"
```

**如果启动失败**，逐步骤输出具体错误和建议（如"MySQL 未安装 → 请运行 brew install mysql"），不继续。

## 停止本地环境

```bash
# Windows
taskkill /F /IM "java.exe" /T 2>nul
taskkill /F /IM "node.exe" /T 2>nul

# Mac
pkill -f "spring-boot:run"
pkill -f "vite"
# MySQL/Redis 通常不停止（系统服务，低资源常驻）
```

## 降级策略

| 情况 | Mac | Windows |
|------|-----|---------|
| MySQL 未安装 | `brew install mysql` | 安装 MySQL Server 或 Docker mysql 容器 |
| Redis 未安装 | `brew install redis` | 安装 Redis for Windows 或 Docker redis 容器 |
| 端口被占用 | `lsof -i :PORT` 查进程 → 问是否杀 | `netstat -ano | grep ":PORT "` 查 PID → 问是否杀 |
| Java/Node 版本过低 | 提示升级命令 | 提示下载地址 |
| 初始化 SQL 导入失败 | 输出具体 SQL 错误 | 输出具体 SQL 错误 |

> **核心区别**：Mac 用 `brew services` + `lsof`，Windows 用 `netstat -ano` + 端口检测。数据库初始化 SQL 和 Maven/npm 命令完全一致。

## 文件约定

- 后端日志：`/tmp/jeecg-local-backend.log`（Windows 上即 `C:\Users\Administrator\AppData\Local\Temp\jeecg-local-backend.log`）
- 前端日志：`/tmp/jeecg-local-frontend.log`（同理）
- 前端代理配置：`jeecgboot-vue3/.env.development.local`（不会被 git 提交）

## 平台适配要点（AI 执行时必读）

1. **端口检测**：优先用 `netstat -ano | grep ":PORT "`（Mac/Win 通用），Mac 也可用 `lsof -i :PORT`
2. **curl 输出重定向**：Win Git Bash 用 `2>&1` 替代 `2>/dev/null`
3. **进程管理**：Win 用 `taskkill /PID xxx /F`，Mac 用 `kill xxx` 或 `pkill -f xxx`
4. **环境检查**：不依赖 `brew`/`which`，以端口监听 + `--version` 输出为准
5. **`/tmp` 路径**：Git Bash 下 `/tmp` 可写，等价于 Windows `%TEMP%`
