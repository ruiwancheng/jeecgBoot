---
name: deployment-architecture
description: 客户端-服务端分离部署架构：网络拓扑、部署模式、控制台地址、故障处理
type: reference
---

# 部署架构

## 服务器

- 位置：WSL2 `/mnt/d/project/JeecgBoot`
- Tailscale IP：100.122.125.106
- 部署控制台：http://100.122.125.106:3101（PM2：deploy-server）
- 前端：http://100.122.125.106（Nginx Docker）
- 后端：http://100.122.125.106:8080/jeecg-boot（Spring Boot Docker）

## 客户端开发

- 客户端跑 `pnpm dev`（热更新），后端直连服务端 100.122.125.106:8080
- .env.development 已指向服务端，无需改配置
- 前端改动秒级生效，后端/SQL 改动用部署控制台

## 部署控制台按钮

| 按钮 | WebSocket消息 | 耗时 | 说明 |
|------|------------|:--:|------|
| 开始部署 | deploy | 3-8分钟 | 自动分析git diff选模式 |
| 仅前端 | deploy:frontend | ~3分钟 | 跳过Maven，只构建前端 |
| 仅后端 | deploy:backend | ~5分钟 | 跳过前端构建 |
| 强制全量 | deploy:full | ~8分钟 | 前后端+SQL全部重建 |

## 部署脚本 deploy.sh

- 参数：full（默认）/ frontend / backend
- 7 步流程：工具检查 → git pull → hosts → Maven → Vite → Docker → SQL
- 3 次前端编译重试机制
- SQL checksum 去重（.deploy-sql-checksums 记录已执行脚本MD5）

## 故障排查

| 症状 | 可能原因 | 处理 |
|------|---------|------|
| 部署控制台连不上 | Windows端口转发断开 | 管理员PowerShell重设portproxy |
| Less timed-out | Vite worker死锁 | 自动重试3次，通常第2次成功 |
| SQL Duplicate entry | 之前target/重复扫描 | 已修复（find排除target/） |
| pnpm EACCES | /mnt/d/权限问题 | deploy.sh自动修复权限 |
