# 客户端-服务端分离架构方案

## 问题背景

业务人员（客户端）使用个人电脑开发，本机作为服务端运行 Docker 部署。当前问题：

1. 客户端和服务端各有独立 MySQL，数据库配置数据不同步
2. 菜单、角色、字典在客户端 UI 上操作入库，SQL 脚本经常漏写
3. 代码推送后服务端部署，因缺失配置数据导致菜单不显示、功能不可用

## 目标架构

```
客户端(个人电脑)                  服务端(本机 172.24.40.82)
┌──────────────────┐             ┌──────────────────────┐
│ jeecgboot-vue3   │ ──API代理──▶│ Docker Nginx   :80   │
│ pnpm dev  :3100  │             │ Docker 后端    :8080  │
│                  │             │ Docker MySQL   :13306 │
│ 只需: Node.js    │             │                       │
│       pnpm       │             │ 数据库 = 唯一数据源    │
│       git        │             └──────────────────────┘
└──────────────────┘
```

**核心变化：** 客户端不再运行本地后端和数据库。Vite dev server 通过代理直连服务端 API。所有配置数据（菜单、角色、字典）存在服务端 MySQL，不存在同步问题。

## 实施步骤

### 第一阶段：客户端环境搭建

**1.1 安装基础工具**

```bash
# Node.js 20+ (推荐 nvm-windows)
nvm install 20 && nvm use 20

# pnpm
npm install -g pnpm
```

**1.2 克隆代码**

```bash
git clone git@github.com:ruiwancheng/jeecgBoot.git
cd jeecgBoot/jeecgboot-vue3
pnpm install
```

**1.3 修改代理配置**

文件：`.env.development`

```diff
- VITE_PROXY = [["/jeecgboot","http://localhost:8080/jeecg-boot"],...]
+ VITE_PROXY = [["/jeecgboot","http://172.24.40.82:8080/jeecg-boot"],...]
```

**1.4 启动开发**

```bash
pnpm dev
# 访问 http://localhost:3100，登录 admin/123456
```

### 第二阶段：开发工作流

| 改动类型 | 客户端做什么 | 服务端做什么 |
|---------|------------|------------|
| 改前端 Vue/TS | `pnpm dev` 即时预览 | 无需操作 |
| 新增前端页面 | 写完 `git push` | 部署控制台重新部署 |
| 改后端 Java | `git push` | 部署控制台重新部署 |
| 改 SQL 脚本 | `git push` | 部署控制台重新部署（自动执行 SQL） |
| 改菜单/角色/字典 | 直接在服务端 UI 操作 | 不需要重新部署 |

### 第三阶段：SQL 完整性保障

菜单等配置数据直接在服务端 UI 操作，需归档到 SQL 文件提交 Git。

**当前方案：** 改完菜单后告诉 AI"导出菜单为 SQL"，AI 从服务端 MySQL 查询生成 SQL。

**后续迭代：** git push 前 AI 自动检测差异并提示导出。

## 客户端需求

| 需求 | 说明 |
|------|------|
| 操作系统 | Windows / macOS |
| Node.js | 20.x 或 22.x |
| 内存 | 8GB+ |
| 网络 | 能访问 172.24.40.82:8080 |
| Git | 配置 SSH Key |

## 服务端端口

| 端口 | 服务 | 用途 |
|------|------|------|
| 80 | Nginx 前端 | 生产环境 |
| 8080 | Spring Boot | 客户端 dev 代理目标 |
| 3101 | 部署控制台 | 部署操作 |

## 注意事项

1. 客户端和服务端需同一局域网或 VPN 互通
2. 新增 Vue 组件后需重启 Vite（`import.meta.glob` 缓存）
3. Vite 代理模式无 CORS 问题
