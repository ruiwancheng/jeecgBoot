[2026-07-08] [网络] Tailscale DNS 劫持导致 git push HTTPS 失败，需切 SSH
触发条件：客户端安装了 Tailscale，git push GitHub 时报 SSL/TLS handshake 失败或连接超时
处理方式：
1. 现象：github.com 被 Tailscale MagicDNS 解析为 198.18.0.x（CGNAT 地址），导致 HTTPS 连接超时
2. 根因：Tailscale 接管 DNS 后，某些环境下 github.com 被解析到错误的虚拟地址
3. 解决方案：
   - 方案A（推荐）：git remote 改用 SSH（git@github.com:...），SSH 不受 DNS 劫持影响
   - 方案B：临时断开 Tailscale（Stop-Service Tailscale），推送后再重连
   - 方案C：使用 Tailscale split DNS 排除 github.com
4. 验证方法：`ssh-keyscan -t ed25519 github.com` 返回真实 GitHub 指纹说明 SSH 可用
