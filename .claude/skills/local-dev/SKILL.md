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

以下工具必须在 Mac 上安装好（AI 没有 sudo 权限，需要人工完成）：

```bash
# 一次性安装（业务人员不需要记住，运维/技术初始化时做一次）
brew install mysql redis node@22 openjdk@17
brew services start mysql redis
```

## 启动流程（5 步，每步幂等）

### 步骤 1：环境检查

检查并自动启动需要的服务：

```bash
# 检查 MySQL
brew services list | grep mysql | grep started || brew services start mysql

# 检查 Redis
brew services list | grep redis | grep started || brew services start redis

# 检查 Java（版本 ≥17）
java --version | head -1

# 检查 Node（版本 ≥20）
node --version

# 检查 pnpm
pnpm --version || npm install -g pnpm
```

**任何一个缺** → 提示"请先运行：<brew install 命令>"，不继续。

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
# 检查端口是否被占用
lsof -i :8080 | grep LISTEN > /dev/null 2>&1

if [ $? -ne 0 ]; then
  # 端口空闲，启动后端（后台运行，DevTools 热重载）
  cd jeecg-boot/jeecg-module-system/jeecg-system-start
  nohup mvn spring-boot:run -Dspring-boot.run.profiles=dev -Dspring.flyway.enabled=false \
    > /tmp/jeecg-local-backend.log 2>&1 &
fi

# 等待后端就绪（最长 90 秒）
for i in $(seq 1 30); do
  sleep 3
  curl -s "http://localhost:8080/jeecg-boot/sys/getEncryptedString" | grep -q "success" && break
done
```

### 步骤 5：启动前端

```bash
# 检查端口是否被占用
lsof -i :3100 | grep LISTEN > /dev/null 2>&1

if [ $? -ne 0 ]; then
  # 检查前端 proxy 配置（确保指向本地后端而非服务端）
  grep -q "localhost:8080" jeecgboot-vue3/.env.development.local 2>/dev/null || \
    echo 'VITE_PROXY = [["/jeecgboot","http://localhost:8080/jeecg-boot"],["/upload","http://localhost:3300/upload"]]
VITE_GLOB_DOMAIN_URL=http://localhost:8080/jeecg-boot' > jeecgboot-vue3/.env.development.local

  # 端口空闲，启动前端
  cd jeecgboot-vue3 && nohup pnpm dev > /tmp/jeecg-local-frontend.log 2>&1 &
fi

# 等待前端就绪（最长 30 秒）
for i in $(seq 1 10); do
  sleep 3
  curl -s -o /dev/null -w "%{http_code}" "http://localhost:3100" | grep -q "200" && break
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

```
pkill -f "spring-boot:run"
pkill -f "vite"
# MySQL/Redis 通常不停止（系统服务，低资源常驻）
```

## 降级策略

| 情况 | 处理 |
|------|------|
| MySQL 未安装 | 提示 brew install mysql（AI 不能代劳，需 sudo） |
| 端口被占用 | 提示哪个进程占用了端口，问是否杀掉 |
| Java/Node 版本过低 | 提示升级命令 |
| 初始化 SQL 导入失败 | 输出具体 SQL 错误，建议用户检查 |

## 文件约定

- 后端日志：`/tmp/jeecg-local-backend.log`
- 前端日志：`/tmp/jeecg-local-frontend.log`
- 前端代理配置：`jeecgboot-vue3/.env.development.local`（不会被 git 提交）
