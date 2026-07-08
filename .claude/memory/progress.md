# Harness 工程进度

## 工作流阶段追踪

| 字段 | 值 | 说明 |
|------|-----|------|
| phase | done | 部署优化完成 |
| last_verify | 2026-07-09 | 部署脚本审查通过 |
| last_test | 2026-07-09 | Vite patch + 重试验证通过 |
| pending_step | — | — |

## 当前状态
- 最后更新：2026-07-09
- 部署模式：客户端分离、Tailscale 组网、自动检测增量构建
- 部署速度：全量~4分钟、仅前端~2分钟、仅后端~3分钟、无变更~10秒

## 本次完成

### 部署稳定性修复
- Less 编译超时：Vite 7 worker Atomics.wait 5s 死锁→patch 60s+3次重试
- Less 4.5.1→4.4.2 锁定版本

### 部署加速（6项）
- Maven 增量编译（git diff→变更模块）
- Maven -T 1C 并行
- 前后端并行编译
- pnpm install 按需执行
- Docker 按模式重建
- 代码无变更时跳过全部编译

### 部署控制台
- 自动检测变更范围
- 日志持久化
- 界面耗时显示

### SQL 优化
- 排除 target/ 目录重复执行
- MD5 校验码去重

### Harness
- CLAUDE.md 部署架构章节
- learnings 新增 2 条
- 七轴评分 35/35
- system-start 补 airag 依赖

### 其他修复
- remember 插件 CRLF→LF（9文件）
- Windows 3101 端口转发
- 审查 4 项 bug 修复

## 待推进
- 代码生成器直写数据库（简单 CRUD 免编译）
- GateGuard 拦截频繁需优化

## 经验记录
- 2026-07-09: Vite worker 死锁 patch+重试根治
- 2026-07-09: set -e 杀死重试循环
- 2026-07-08: pnpm lockfile CRLF→LF
