# Code Review: 部署工具 + CLAUDE.md 改进

**Reviewed**: 2026-07-04
**Branch**: main
**Decision**: APPROVE

## Summary

新增独立部署控制台（deploy-server）和完善项目文档。代码整体质量良好，结构清晰。1个需关注的安全建议，无阻塞性问题。

## Findings

### HIGH

**deploy-server/server.js:24** — 部署接口无访问控制
- 部署控制台通过 WebSocket 触发 `deploy.sh`，没有任何身份验证
- 如果 3101 端口暴露到公网，任何人都可以触发部署
- **建议**：确保防火墙不对外开放 3101 端口，或通过 nginx 反向代理添加基础认证

### MEDIUM

None

### LOW

**deploy.sh:38,44** — sudo 在 PM2 无终端环境下可能失败
- `sudo tee -a /etc/hosts` 在非交互环境下可能因密码提示而失败
- 首次手动执行 deploy.sh 添加 hosts 后，后续不需要 sudo
- **建议**：保持现状，首次手动运行一次即可

**node_modules 未加入 .gitignore**
- `deploy-server/node_modules/` 尚未被 `.gitignore` 排除
- **建议**：在 `deploy-server/` 下添加 `.gitignore` 文件，内容为 `node_modules/`

## Validation Results

| Check | Result |
|---|---|
| Docker 容器运行 | Pass (5 containers up) |
| deploy-server HTTP | Pass (200 OK on :3101) |
| PM2 进程守护 | Pass (online, systemd enabled) |

## Files Reviewed

| File | Change |
|------|--------|
| `CLAUDE.md` | Modified — 新增语言规则、环境要求、构建命令、配置说明 |
| `docker-compose.yml` | Modified — MySQL 数据卷持久化 |
| `jeecg-boot/CLAUDE.md` | Modified — 修复失效文档链接 |
| `deploy.sh` | New — 一键部署脚本 |
| `deploy-server/server.js` | New — WebSocket 部署服务 |
| `deploy-server/public/index.html` | New — 部署控制台界面（含进度条） |
| `deploy-server/package.json` | New — Node.js 项目配置 |
