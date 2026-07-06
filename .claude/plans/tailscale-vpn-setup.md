# Tailscale VPN 组网方案

## 目标

客户端（Windows/macOS）通过 VPN 网络访问服务端后端，前端 dev 代理直连服务端。

## 架构

```
客户端(Win/Mac)  ──Tailscale──▶  服务端(Linux WSL)
100.100.x.x                      100.100.y.y:8080
     │                                  │
     └── .env.development 指向 ─────────┘
```

## 步骤

### 1. 服务端安装

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# 提示浏览器登录 → 用 Google/微软账号
tailscale ip -4
# 记录这个 IP，例如 100.87.xxx.xxx
```

### 2. 客户端安装

| 系统 | 方式 |
|------|------|
| Windows | https://tailscale.com/download/windows 下载 .msi 安装 |
| macOS | App Store 搜 Tailscale，或 `brew install tailscale` |

安装后登录同一个 Google/微软账号，自动组网。

### 3. 验证

```bash
# 客户端命令行
ping <服务端Tailscale IP>
curl http://<服务端Tailscale IP>:8080/jeecg-boot/sys/login
# 返回 JSON = 通
```

### 4. 前端代理

`.env.development`：

```
VITE_PROXY = [["/jeecgboot","http://<服务端Tailscale IP>:8080/jeecg-boot"],["/upload","http://<服务端Tailscale IP>:3300/upload"]]
```

### 5. 开发

```bash
git clone git@github.com:ruiwancheng/jeecgBoot.git
cd jeecgBoot/jeecgboot-vue3
pnpm install
pnpm dev
```

## 注意

- Tailscale 免费版 3 用户
- 开机自启，无需手动连接
- `.env.development` 不提交 Git，每个客户端配自己的 IP
- 服务端 8080 端口需对 Tailscale 网卡开放
