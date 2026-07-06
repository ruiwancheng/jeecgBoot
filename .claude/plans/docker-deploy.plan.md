# Plan: 本机 Docker 部署方案

**场景**: 本机开发验证，后期本机作为 Docker 服务器。代码推送到 GitHub 后，服务器拉取代码并构建部署。
**方案**: 部署脚本（git pull + 构建 + docker-compose）+ 可选 Webhook 自动触发
**复杂度**: Low

## 核心思路

现有 `start-docker-compose.sh` 已包含完整构建+启动流程（mvn build → pnpm build → docker-compose up -d），只需：
1. 前置 `git pull` 拉取最新代码
2. 处理容器已存在时的更新逻辑
3. 可选：通过 GitHub Webhook 实现推送自动部署

不需要 registry、不需要多阶段 Dockerfile、不需要 SSH 远程执行。

## Files to Change

| File | Action | Why |
|------|--------|-----|
| `deploy.sh` | CREATE | 一键部署脚本：git pull + 后端构建 + 前端构建 + docker-compose up -d |
| `docker-compose.yml` | UPDATE | 已有文件，需确认重启策略和数据卷持久化配置 |

## Tasks

### Task 1: 部署脚本 deploy.sh
- **Action**: 创建根目录 `deploy.sh`
  ```bash
  git pull origin main
  cd jeecg-boot && mvn clean install -Pdocker
  cd ../jeecgboot-vue3 && pnpm install && pnpm run build:docker
  cd .. && docker-compose up -d --build
  ```
- 用 `--build` 确保代码变更后重新构建镜像
- 已有 `start-docker-compose.sh` 的逻辑基本复用，只加 git pull 和 `--build` 参数

### Task 2: 数据卷持久化检查
- **Action**: 检查 docker-compose.yml 中 MySQL 是否挂载了数据卷，确保 `docker-compose down/up` 不丢数据
- 当前 compose 中 MySQL 服务没有 volumes 配置，需添加

### Task 3: 可选 — GitHub Webhook 自动部署
- **Action**: 如果不想每次手动 SSH 执行 `deploy.sh`，可以：
  - 方案A: GitHub Actions 触发时通过 SSH 远程执行 `deploy.sh`（简单，需要 GitHub Secrets 配 SSH 密钥）
  - 方案B: 本机运行简单的 webhook 接收服务，GitHub push 事件触发后自动执行 `deploy.sh`
  - 方案C: crontab 定时 `git pull && deploy.sh`（最简单，但有延迟）

## 部署流程

```
开发机 push 代码 → GitHub
                      ↓
本机服务器执行 ./deploy.sh
  ├── git pull origin main        # 拉取最新代码
  ├── mvn clean install -Pdocker  # 构建后端 JAR
  ├── pnpm build:docker           # 构建前端 dist
  └── docker-compose up -d --build # 重建并启动容器
```

## Validation

```bash
# 本地测试部署脚本
./deploy.sh

# 检查容器状态
docker-compose ps

# 检查后端日志
docker-compose logs -f jeecg-boot-system

# 浏览器验证
curl http://localhost
```

## Acceptance

- [ ] `./deploy.sh` 一键完成代码拉取、构建、部署
- [ ] `docker-compose up -d --build` 正确更新运行中的容器
- [ ] MySQL 数据在容器重建后不丢失
- [ ] 浏览器访问 `http://localhost` 正常显示登录页
