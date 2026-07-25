---
name: compat-check
description: 多客户端兼容性检测 — 扫描 hooks/skills 中的 OS 专有命令、硬编码路径、平台假设，P0/P1/P2 分级报告 + 修复指引。Multi-client compatibility scanner.
version: 1.0.0
---

# compat-check — 多客户端兼容性检测

## 检测矩阵

### P0 级（阻断 — 直接在其他 OS 上报错）

| # | 检测项 | grep 模式 | 目标目录 | 排除规则 |
|---|--------|----------|---------|---------|
| 1 | `/tmp/` 硬编码 | `grep -rn '/tmp/' --include='*.sh' --include='*.md'` | hooks/, skills/ | 排除含 `TMPDIR` 或 `${TMPDIR` 的行 |
| 2 | macOS 专属 `date -j` | `grep -rn 'date -j' --include='*.sh'` | hooks/ | 排除含 OS 检测分支的行（`if.*date -j` 上下有 else） |
| 3 | macOS 专属 `lsof` | `grep -rn '\blsof\b' --include='*.sh'` | hooks/ | 排除含 fallback 的行（上下有 `ss\|netstat\|command -v lsof`） |
| 4 | macOS 专属 `pkill -f` | `grep -rn 'pkill -f' --include='*.sh'` | hooks/ | 排除含 `taskkill\|killall` fallback 的行 |
| 5 | macOS 专属 `brew` | `grep -rn '\bbrew\b' --include='*.md'` | skills/ | 排除含 "macOS" 表格行、多 OS 表格、或 "Linux\|Windows\|WSL" 备选的行 |
| 6 | macOS 专属 `timeout` | `grep -rn '\btimeout\b' --include='*.sh'` | hooks/ | 排除含 `command -v timeout` 检测的行 |
| 7 | 硬编码绝对路径 | `grep -rn '/Users/\|/home/\|/mnt/' --include='*.sh' --include='*.md'` | hooks/, skills/ | 排除 `${CLAUDE_PROJECT_DIR}` 和文档示例路径 |
| 8 | 硬编码 WSL 路径 | `grep -rn '/mnt/[a-z]/' --include='*.sh' --include='*.md'` | hooks/, skills/ | — |

### P1 级（警告 — 特定 OS 或配置下出问题）

| # | 检测项 | grep 模式 | 目标目录 | 排除规则 |
|---|--------|----------|---------|---------|
| 9 | 硬编码 DB 密码 | `grep -rn 'mysql.*-uroot.*-proot\|-u root.*-p root\|-u root.*-proot' --include='*.md'` | skills/ | 排除含 `MYSQL_ROOT_PASSWORD` 或 `${MYSQL` 的行 |
| 10 | Linux 发行版假设 (apt only) | `grep -rn 'apt install' --include='*.md'` | skills/ | 排除含 `dnf\|yum\|pacman\|zypper\|发行版` 的行 |
| 11 | 包管理器假设 (brew only) | `grep -rn 'brew install' --include='*.md'` | skills/ | 排除多 OS 表格行（同时含 `apt\|winget\|dnf` 的行） |
| 12 | npm 全局安装 | `grep -rn 'npm install -g' --include='*.sh' --include='*.md'` | hooks/, skills/ | 排除含 `sudo\|nvm\|权限` 说明的行 |

### P2 级（建议 — 可移植性改进）

| # | 检测项 | grep 模式 | 目标目录 | 排除规则 |
|---|--------|----------|---------|---------|
| 13 | 非 POSIX `seq` 命令 | `grep -rn '\bseq\b.*1.*30\|\bseq\b.*1.*10' --include='*.sh'` | hooks/ | — |
| 14 | 新增 hook 无 OS 检测 | 检查 hooks/ 下 .sh 文件（排除 _os-detect.sh 自身）是否有 `uname\|IS_MAC\|IS_LINUX\|OS_NAME\|TMPDIR` | hooks/ | _os-detect.sh |
| 15 | Windows 专有命令无标注 | `grep -rn 'clip.exe\|taskkill\|powershell' --include='*.md'` | skills/ | 排除含 "Windows" 或 OS 表头标记的行 |

## 报告模板

```
## 多客户端兼容性检测报告

### 扫描范围
- hooks/: N 个文件
- skills/: N 个文件

### P0 阻断 (N 项)
| # | 检测项 | 文件:行号 | 问题内容 |
|---|--------|-----------|---------|
| 1 | /tmp/ 硬编码 | xxx.sh:15 | `echo > /tmp/foo` |
| ... | | | |

### P1 警告 (N 项)
| # | 检测项 | 文件:行号 | 问题内容 |
|---|--------|-----------|---------|
| ... | | | |

### P2 建议 (N 项)
| # | 检测项 | 文件:行号 | 问题内容 |
|---|--------|-----------|---------|
| ... | | | |

### 总结
- P0 阻断: N 项 (需立即修复，否则 Windows/Linux 报错)
- P1 警告: N 项 (特定配置下可能出问题)
- P2 建议: N 项 (可移植性改进)

判定: PASS / NEEDS WORK / BLOCKED
```

## 判定逻辑

- **PASS**: P0=0, P1≤2, P2 任意
- **NEEDS WORK**: P0=0, P1>2
- **BLOCKED**: P0>0 (不建议合入，其他 OS 会直接报错)

## 修复指引

每个检测项对应的修复方法：

| 问题 | 修复 |
|------|------|
| `/tmp/` 硬编码 | 改为 `${TMPDIR:-/tmp}/` |
| `date -j` | 加 OS 检测：`if date -j ... >/dev/null 2>&1; then ... else date -d ... fi` |
| `lsof` | 改为 `command -v lsof && lsof ... \|\| ss ... \|\| netstat ...` |
| `pkill -f` | 改为 `command -v pkill && pkill ... \|\| taskkill ... \|\| killall ...` |
| `brew` 单独出现 | 加 OS 表格或多 OS 备选命令 |
| `-uroot -proot` | 改为 `-u root -p"${MYSQL_ROOT_PASSWORD:-root}"` |
| `apt install` 单独出现 | 加发行版适配说明 (dnf/yum/pacman/zypper) |
| `npm install -g` | 加 `sudo` 或 nvm 权限说明 |
| 无 OS 检测的 hook | source `_os-detect.sh` 或加内联 OS 检测 |
