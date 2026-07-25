# compat-check 检测矩阵评审报告

**评审日期**: 2026-07-26 | **评审对象**: `.claude/skills/compat-check/SKILL.md` v1.0.0 | **评审人**: orca-review (Claude)

## 评审结论

检测矩阵覆盖了 60+处修复中约 85% 的问题类型，P0/P1/P2 分级基本合理，但存在 **4 处遗漏**（2 个缺失检测模式 + 1 个目标目录不对称 + 1 个排除规则盲区），建议补齐后可达 95%+ 覆盖率。

---

## ✅ 思路对齐

1. **三级分级逻辑正确**：P0=直接报错（`date -j`、`/tmp/`、`lsof`），P1=特定环境出问题（DB密码、包管理器），P2=可移植性改进（`seq`、OS检测缺失）。与 41b921b 实际修复的 26 P0 + 18 P1 + 5 P2 完全对应。

2. **排除规则设计精巧**：用上下文关键词（`command -v`、`if.*date -j`、`MYSQL_ROOT_PASSWORD`）而非简单排除整行，避免漏报。Pattern #5 的"多 OS 表格行"排除逻辑尤为精确。

3. **报告模板 + 判定逻辑完整**：PASS/NEEDS WORK/BLOCKED 三级判定清晰，BLOCKED 条件（P0>0）合理——P0 问题确实会在其他 OS 上直接报错。

4. **修复指引实用**：每个检测项都有对应的修复方法，且修复示例与 `_os-detect.sh` 中实际采用的方法一致。

5. **15 个检测模式覆盖了修复中的主导问题类型**：`/tmp/` 硬编码、`date -j`、`lsof`、`pkill -f`、`brew`、`timeout`、绝对路径、WSL 路径、DB 密码、包管理器、npm 全局安装全部命中。

---

## ⚠️ 遗漏或风险

### 1. 🔴 目标目录不对称 — 6 个 P0 模式只扫描单侧目录

| 模式 | 当前目标 | 实际出现位置 | 风险 |
|------|---------|-------------|------|
| #2 `date -j` | hooks/ | session-start.sh ✅ | 若有 skill 引用日期命令 → 漏报 |
| #3 `lsof` | hooks/ | hooks ✅ + **local-dev/SKILL.md** | local-dev 仍有 `lsof` 引用（虽已加 fallback，但若未来修改移除 fallback 不会触发告警）|
| #4 `pkill -f` | hooks/ | hooks ✅ + **local-dev/SKILL.md** + **restart-backend/SKILL.md** | 同上，skills 中的 `pkill -f` 变更不可感知 |
| #5 `brew` | skills/ | local-dev/SKILL.md ✅ | hooks/ 出现 `brew` 不会被检测（如未来 hook 调用 `brew services start`）|
| #6 `timeout` | hooks/ | pre-commit-check.sh ✅ | skills 中 `timeout` 引用不受监控 |
| #13 `seq` | hooks/ | — | skills/ 中的非 POSIX `seq` 不会被检测 |

**根因**：修复时发现 OS 专有命令同时出现在 hooks 和 skills 中（如 `lsof` 在 `pre-commit-check.sh` 和 `local-dev/SKILL.md`），但检测矩阵按文件类型做了人为分割。这导致另一侧目录的**回归风险**不可见。

**建议**：将 #2–#6、#13 的扫描目标扩展为 `hooks/, skills/` 双向。排除规则已经足够精确，扩展目标目录不会显著增加误报。

### 2. 🟡 缺失检测模式：`sed -i`（BSD vs GNU）

`sed -i ''`（macOS BSD sed）vs `sed -i`（GNU sed）是 Unix 生态中最常见的跨平台陷阱之一。macOS 的 `sed -i` 会将 `-e` 后的表达式解释为备份扩展名，导致语法错误或静默创建备份文件。

当前矩阵未覆盖此模式。

**建议**：新增 P0 检测：
```
grep -rn 'sed -i ' --include='*.sh' hooks/ skills/ | grep -v "sed -i ''"
```
排除规则：已使用 `sed -i ''` 的行（空字符串备份扩展名 = 跨平台兼容）。

> 当前代码库中 hooks/ 和 skills/ 暂未使用 `sed -i`，但添加此规则可**预防未来引入**。

### 3. 🟡 缺失检测模式：`brew services`（非安装类 brew 子命令）

Pattern #5 用 `\bbrew\b` + 排除"macOS 表格行/多 OS 表格"覆盖了 skills/ 中的 brew 引用。Pattern #11 覆盖 `brew install`。但 `brew services start/stop/list` 是**运维类命令**，与 `brew install` 的安装类语境不同：

- `local-dev/SKILL.md:40` — `brew services list | grep mysql`（运维）
- `local-dev/SKILL.md:49` — `brew services list | grep redis`（运维）
- `onboard/SKILL.md:95` — `brew install mysql && brew services start mysql`（安装+运维）

Pattern #5 在 skills/ 中能捕获这些（`\bbrew\b` 匹配所有 brew 子命令），但如果 brew 引用在**排除规则范围内**（如出现在多 OS 表格行中），则会被跳过。反过来，如果 hooks/ 中出现 `brew services`，Pattern #5 不扫描 hooks/ 而 Pattern #11 只匹配 `brew install`，就会漏报。

**建议**：确认 Pattern #5 的目标目录扩展为 `hooks/, skills/`（同遗漏 #1），`\bbrew\b` 已足够宽泛，无需新增单独模式。

### 4. 🟡 排除规则盲区：`MYSQL_ROOT_PASS` vs `MYSQL_ROOT_PASSWORD`

Pattern #9 的排除规则匹配 `MYSQL_ROOT_PASSWORD`，但实际修复中使用的变量名是 `MYSQL_ROOT_PASS`（无 WORD 后缀）：

```bash
# local-dev/SKILL.md 实际代码
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASSWORD:-root}"
```

这意味着：如果有人写了 `mysql -uroot -proot`（裸密码）但同时在同一行使用了 `$MYSQL_ROOT_PASS` 变量，该行的 `-proot` 字符串不会触发 Pattern #9 的 grep（因为 `-proot` 不出现在含 `$MYSQL_ROOT_PASS` 的行中）。**这不是漏报**——实际上该行没有硬编码密码。

但反向场景有问题：如果某个 skill 用 `MYSQL_ROOT_PASS` 变量但**忘记定义**它（没有 `MYSQL_ROOT_PASS="${MYSQL_ROOT_PASSWORD:-root}"` 这行），Pattern #9 的排除规则 `MYSQL_ROOT_PASSWORD` 不会匹配，但 grep 模式 `-uroot.*-proot` 也不会匹配（因为行中是 `-uroot -p"$MYSQL_ROOT_PASS"`）。此时**硬编码密码的替代模式（使用变量）不会被检测为"变量未定义"的隐患**。

**建议**：排除规则从 `MYSQL_ROOT_PASSWORD` 扩展为 `MYSQL_ROOT_PASS\|MYSQL_ROOT_PASSWORD`。这是低风险改进，当前无害但防御性不足。

### 5. 🟢 低风险遗漏（可选的 P2 级别检测）

| 检测项 | 风险 | 建议 |
|--------|------|------|
| `readlink -f` | macOS 不支持，需改用 `realpath` 或 `perl` | P2，当前 hooks/ 无此用法 |
| `$TMPDIR` 无 fallback | `$TMPDIR` 在某些最小化环境未设置 | P2，与 #1 互补（检测"矫枉过正"） |
| 文件路径大小写 | Linux 大小写敏感，macOS 不敏感 | P3，难以自动化检测 |
| `curl` 作为唯一 fallback | Windows Git Bash 可能无 curl | P2，local-dev 用 curl 做三级 fallback 的最后一级，风险极低 |

---

## 💡 优化建议

### 高优先级（建议立即修复）

1. **扩展 6 个 P0 模式的目标目录**：将 #2、#3、#4、#5、#6、#13 的扫描范围从单侧（hooks/ 或 skills/）扩展为双侧（hooks/, skills/），消除回归盲区。

2. **新增 `sed -i` 检测模式**（P0）：防御 macOS/Linux 最经典的 sed 兼容性陷阱，即使当前代码库无此用法。

3. **修复 Pattern #9 排除规则**：`MYSQL_ROOT_PASSWORD` → `MYSQL_ROOT_PASS\|MYSQL_ROOT_PASSWORD`。

### 中优先级（可在下一版迭代）

4. **新增 `brew services` 子检测**（P0）：或在 Pattern #5 的注释中明确说明 `\bbrew\b` 已覆盖所有 brew 子命令，确保 hooks/ 也被扫描。

5. **新增 Pattern #14 的交叉验证**：不仅检查 hook 有无 OS 检测，还检查该 hook 是否实际 source 了 `_os-detect.sh`（而非内联重复实现）。

### 低优先级（建议列入 backlog）

6. 增加 `readlink -f` / `realpath` 检测（P2）
7. 增加 `$TMPDIR` 无 fallback 检测（P2，与 #1 互补）
8. 考虑增加 `.md` 代码块中的 `curl` 单一依赖检测

---

## 评分

| 维度 | 得分 | 说明 |
|------|:--:|------|
| P0/P1/P2 分级合理性 | 9/10 | 分级准确，仅缺 `sed -i` 和 `brew services` 细化 |
| 检测覆盖完整性 | 8.5/10 | 覆盖 85% 修复类型，缺 ~4 个模式 |
| 排除规则准确性 | 8/10 | 整体精准，MYSQL_ROOT_PASS 变量名不一致有盲区 |
| 目标目录覆盖 | 6/10 | **主要短板** — 6 个模式只扫单侧，与实际问题分布不匹配 |
| 可维护性 | 9/10 | 结构清晰，报告模板完整，修复指引实用 |

**综合判定**: NEEDS WORK（目标目录不对称为主要扣分项，修复后可达 PASS）
