---
name: client-setup
description: 客户端开发环境接入指南 — Tailscale VPN + Vite 代理直连服务端。当用户问"怎么接入""新电脑怎么配置开发环境""客户端连接"时自动触发。
version: 1.0.0
---

# 客户端开发环境接入指南

业务人员客户端只需 Node.js + pnpm + Tailscale，不跑后端和数据库。

## 架构

```
客户端(Win/Mac)                 服务端
┌──────────────────┐         ┌──────────────────────┐
│ jeecgboot-vue3   │ Tailscale│ Spring Boot   :8080  │
│ pnpm dev  :3100  │────────▶│ MySQL          :3306  │
│                  │  VPN    │ (唯一数据源)          │
│ 只需: Node.js    │         └──────────────────────┘
│       pnpm       │
│       Tailscale  │
└──────────────────┘
```

## 接入步骤

### 1. 安装基础工具

```bash
# Node.js 20+（推荐 nvm）
nvm install 20 && nvm use 20
# pnpm
npm install -g pnpm
```

### 2. 安装 Tailscale VPN

| 系统 | 方式 |
|------|------|
| Windows | https://tailscale.com/download/windows 下载 .msi |
| macOS | App Store 搜 Tailscale，或 `brew install tailscale` |

登录同一个 Google/微软账号后自动组网。

**验证联通：**
```bash
ping <服务端Tailscale IP>
curl http://<服务端Tailscale IP>:8080/jeecg-boot/sys/randomImage/check
# 返回 JSON = 通
```

### 3. 克隆代码 + 配置代理

```bash
git clone git@github.com:ruiwancheng/jeecgBoot.git
cd jeecgBoot/jeecgboot-vue3
pnpm install
```

**创建 `.env.development.local`**（gitignore，本机独立配置）：

```
VITE_PROXY = [["/jeecgboot","http://<服务端IP>:8080/jeecg-boot"],["/upload","http://localhost:3300/upload"]]
VITE_GLOB_DOMAIN_URL=http://<服务端IP>:8080/jeecg-boot
```

> 不修改 `.env.development`（仓库默认 localhost），用 `.env.development.local` 覆盖。Vite 自动合并，local 优先。

### 4. 启动

```bash
pnpm dev
# 访问 http://localhost:3100，登录 admin / 123456
```

#### 首次启动报 ERR_PNPM_IGNORED_BUILDS 的绕过方法

```bash
cd jeecgboot-vue3
npx vite --host
# 绕过 pnpm approve-builds 限制，直接启动 Vite
```

## 注意事项

- 服务端 Tailscale IP 通过 `tailscale ip -4` 获取，IP 可能变化
- 新增 Vue 组件后需重启 Vite（`import.meta.glob` 缓存）
- 菜单、角色、字典统一在服务端 UI 操作，不需要导出 SQL
- Tailscale 免费版 3 用户

## 日常开发流程

```
改Vue文件 → 保存 → 浏览器秒级热更新 → 确认OK
→ git commit + push → 部署控制台部署(一次性)
```

**铁律：先在本地 `npx vite` 验证，确认无误后再提交部署。** 不走"改→推→部署→验"的慢循环。
