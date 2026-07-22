# [2026-07-20] [运维] Claude Code沙箱无法git push HTTPS — Keychain隔离

## 触发条件
在 Claude Code Bash 中执行 `git push origin main` 反复失败（HTTP 408/curl 56/curl 16/curl 52）。

## 根因
macOS 上 git 使用 `osxkeychain` credential helper，凭证存储在系统 Keychain 中。
Claude Code 的 Bash 沙箱**可能受 Keychain 访问限制**，但实际验证发现 HTTP 408 主要原因是**服务端代理配置**问题，非沙箱硬限制。

## 诊断方法
```bash
git config --get credential.helper  # 确认: osxkeychain
git push origin main --verbose      # 观察: curl 56 Connection died / HTTP 408
```

## 解决方案（优先级排序）

### 方案 A: 终端手动推送（最简单）
```bash
cd /path/to/repo && git push origin main
```
终端有完整 Keychain 访问权限，不受沙箱限制。

### 方案 B: Personal Access Token
```bash
# 经典 PAT (repo scope) 或 Fine-grained PAT (Contents: read+write)
git push https://TOKEN@github.com/user/repo.git main
```
注意: Fine-grained PAT 必须选中目标仓库 + Contents: Read and write。

### 方案 C: SSH
```bash
git remote set-url origin git@github.com:user/repo.git
git push origin main
```
需要先配置 SSH key (`ssh-keygen` + GitHub Settings → SSH Keys)。

## 不生效的方案
- `git config http.postBuffer 524288000` — 无效（不是缓冲区问题）
- `git config --local http.version HTTP/1.1` — 无效（不是协议版本问题）
- `git -c credential.helper= push` — 无效（沙箱层面阻断）

## 关键教训
- 不要反复重试 git push — 换认证方式才是正解
- `gh` CLI 同样受 Keychain 限制 (`gh auth status` → keyring timeout)
- Token 方式推送成功一次不代表永久有效（Token 可能过期）
## 关联
- ✅ 已覆盖: CLAUDE.md 部署架构章节
