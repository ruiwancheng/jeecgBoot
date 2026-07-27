# [2026-07-28] [跨平台] netstat -tlnp 是 Linux 语法——"portable"检查在 Windows 静默死亡

## 触发条件
pre-commit-check 的 8080 端口检测写 `lsof → ss → netstat -tlnp` 三级 fallback，看似 portable。

## 现象
Windows 上 lsof/ss 不存在，netstat 存在但**没有 -tlnp 参数**（Windows 是 -ano）→ 命令失败 → PORT_UP=false → /verify 门控整条静默失效（从未触发，无人察觉）。

## 根因
"命令存在 ≠ 参数兼容"。跨平台检查只验证了命令存在性，没验证参数语法在该 OS 可用。与 python3 stub（存在但不可执行）是同族陷阱：**存在性检查必须升级到可用性实测**。

## 正确处理
```bash
{ netstat -tlnp 2>/dev/null | grep -q ':8080 ' || netstat -ano 2>/dev/null | grep -q ':8080 '; } && PORT_UP=true
```
**规则：凡写"portable/fallback"检测链，必须在每个目标 OS 实测该分支真的会命中**——本次就是写了 Linux 分支却没在 Windows 跑过。

## 关联
- 同族: 2026-07-28-claude-code-hook-protocol.md §python3 stub
- 修复实证: pre-commit-check.sh 2026-07-28
