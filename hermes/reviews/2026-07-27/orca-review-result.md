# Orca 外部评审结果 — 5 命令 + 1 框架 + client-start 更新

> 评审日期：2026-07-27
> 评审维度：完整性 / 一致性 / 安全性 / 可操作性 / 冗余 / 遗漏
> 被审文件：13 个（5 命令 + 5 技能 + 1 框架 + client-start 命令+技能）

---

## ✅ 通过项

1. **命令/技能边界清晰** — 命令文件定义步骤+流程，技能文件存放代码模板+常量+实现细节。`skill-command-boundary.md` 规则被严格遵守。5 条命令的 .md 文件均不含 bash 命令、文件路径常量、数据库信息。

2. **human-gate 框架设计扎实** — 基于真实踩坑经验（`orca-review-false-sense`、`rule-condition-blind-spot`），用 decision_gate 硬阻断替代 AI 自觉。超时日志 + 上下文保存 + 禁止事项明确。与 5 条命令的集成点映射清晰。

3. **降级策略完整** — 所有命令均定义 Orca 不可用时的回退路径：
   - visual-check → ❌ 直接退出（依赖 Orca browser）
   - test-loop → 退化为 `/debug` 手动模式
   - chain-test → 降级为纯 curl API 验证
   - deploy-verify → 退化为 `deploy-quality-gate.md` 串行模式
   - pre-commit-gate → 退化为纯安全检查
   - client-start → 各组件独立降级（不阻塞启动）

4. **上下文膨胀保护一致引用** — 5 条命令的步骤 1 均引用 `human-gate` 技能的上下文膨胀保护，消除重复定义。

5. **变更分级统一来源** — 所有需要分级的命令（deploy-verify、pre-commit-gate）均引用 `hermes/business-chains.json` 的 `changeClassification` 作为单一真相源。

6. **client-start 自愈设计** — 标记文件/依赖/图谱被误删均可自动检测并重建，三级依赖检测（显式清单→MCP 自动发现→运行时兜底）覆盖深度合理。

7. **traceability 完备** — human-gate 设计原则表中的每条教训均有 `learnings/` 目录下的对应 .md 文件可追溯。

---

## ⚠️ 发现（P1 — 建议修复）

### P1-1: visual-check 命令 usage 区块格式错误

**文件**: `.claude/commands/dev/visual-check.md:13-16`

```markdown
/visual-check purchase           # 指定模块
    
    # 指定模块                              ← 多余缩进 + 重复注释
/visual-check --page http://...  # 指定页面 URL
```

第 14 行含多余空行+缩进，且 `# 指定模块` 注释重复出现（第 13 行已标注）。**建议**：删除第 14 行，将 `--page` 示例紧随其后。

### P1-2: client-start 使用 Unix-only 临时文件路径

**文件**: `.claude/skills/client-start/SKILL.md:230-231`

```markdown
| 后端启动失败 | 输出 `tail -50 /tmp/jeecg-local-backend.log` | ✅ |
| 前端启动失败 | 输出 `tail -20 /tmp/jeecg-local-frontend.log` | ✅ |
```

`/tmp/` 是 Unix 路径，Windows 上 `tail` 不可用（Git Bash 中可用但 `/tmp/` 映射到 Git Bash 的虚拟路径，与 Spring Boot 的工作目录不重合）。且 `local-dev` 技能在 Windows 上的实际日志路径可能不同。**建议**：引用 `local-dev` 技能中的日志路径而非硬编码，并在降级表格中标注"详见图谱 local-dev 技能的日志路径"。

### P1-3: `python3` 命令假设不跨平台

**影响文件**（3 处）：
- `.claude/skills/human-gate/SKILL.md:85` — `orca orchestration gate-list --json | python3 -c "..."` 
- `.claude/skills/chain-test/SKILL.md:49` — `for chain in $(python3 -c "...")`
- `.claude/skills/visual-check/SKILL.md:119` — `python3 -c "from PIL import Image..."`

Windows 上 `python3` 通常不存在，标准命令为 `python`；Python 在 Windows 上也可能通过 `py -3` 启动。**建议**：在 skill 文件中统一使用 `${PYTHON:-python3}` 模式，或引用 `_os-detect.sh` 中的 Python 检测结果。或在 human-gate 技能头部添加 "Windows 上 `python3` 替换为 `python`" 的提示。

### P1-4: `orca orchestration gate-create` 子命令未验证存在

**文件**: `.claude/skills/human-gate/SKILL.md:53`

```bash
orca orchestration gate-create \
  --task <当前任务ID> \
  --title "<问题标题>" \
  ...
```

技能中虽写了"如果 `gate-create` 不可用，回退到 `orchestration send` + `--type decision_gate`"（第 61 行），但未说明如何检测 `gate-create` 是否存在（`orca orchestration gate-create --help` 返回非零？）。**建议**：补充检测命令示例，和回退触发条件。

### P1-5: chain-test `--page` 参数未定义

**文件**: `.claude/commands/dev/chain-test.md:12`

```
/chain-test --all                # 验证所有已注册链路
```

命令只定义了 `--all` 参数，但 chain-test 技能中的 Orca browser 操作使用了 `orca goto --url` 直接导航——这与 visual-check 的 `--page` 参数在概念上重叠但未在 chain-test 命令接口中暴露。如果用户想对特定页面做链路测试，目前只能指定链路名。**建议**：明确 chain-test 的参数设计（是否需要 `--page`？还是始终从链路注册表推断 URL？），并在技能中补充"如何从链路名推导页面 URL"的映射规则——目前 chain-test 技能中直接使用 `localhost:3100/project/mes/<模块路径>` 但未说明映射逻辑。

### P1-6: visual-check 首次基线建立后缺少 INDEX.md 回写

**文件**: `.claude/skills/visual-check/SKILL.md:97-112`

首次截图建立基线后直接结束，但基线目录结构定义了 `INDEX.md`（第 20 行），却未在"首次检查"流程中要求回写 INDEX.md。**建议**：在首次基线建立步骤后追加 `更新 hermes/visual-baselines/INDEX.md` 步骤。

### P1-7: pre-commit-gate P1 检查项列表与 deploy-quality-gate 规则不一致

**文件对比**:
- `.claude/skills/pre-commit-gate/SKILL.md:42-55` — 安全检查清单（9 项：5 P0 + 4 P1）
- `.claude/rules/quality-gates.md` — P1 检查项中 `文件上传无类型校验` 有，但 `移除 @Transactional` 在规则中标注为 P1

pre-commit-gate 技能的检查清单是完整的（覆盖了 quality-gates.md 的全部 P0/P1），但 `deploy-quality-gate.md` 的安全检查只列了 STRIDE 映射表，未逐项对齐。**建议**：在 deploy-verify 技能中添加交叉引用 "安全检查清单见 pre-commit-gate 技能步骤 2"，避免未来单边更新导致漂移。

---

## 💡 建议（P2 — 优化建议）

### P2-1: human-gate context 膨胀检测方法可加强

**文件**: `.claude/skills/human-gate/SKILL.md:22-31`

当前检测依赖"估算值"（对话轮数 + 文件读取次数），这在长会话中偏主观。"搜索 `<system-reminder>` 中的 token 信息"依赖系统提醒是否包含该信息。**建议**：如果运行时环境支持（如 Claude Code 的 `/token-usage` 命令），优先用确定性检测；估算值作为回退。

### P2-2: visual-check 像素对比脚本缺少 Pillow 依赖检测

**文件**: `.claude/skills/visual-check/SKILL.md:119-136`

`python3 -c "from PIL import Image..."` 直接 import，Pillow 未安装时会抛 `ModuleNotFoundError`，但技能中未提示安装命令。**建议**：在脚本运行前加 `pip3 show Pillow > /dev/null 2>&1 || pip3 install Pillow`。

### P2-3: test-loop 中 "自动找最近失败的测试" 无实现

**文件**: `.claude/commands/dev/test-loop.md:13`

```
/test-loop                                       # 自动找最近失败的测试
```

命令定义了无参数模式，但技能中跳过了"如何找到最近失败的测试"的实现细节。如果测试输出日志在 `/tmp/test-loop-output.log`，那需要之前运行过且有持久化。**建议**：至少给一个查找策略（如 `ls -t harness/test-results/*.log | head -1` 或 `git diff --name-only | grep test`）。

### P2-4: chain-test 技能中 `$TOKEN` 变量来源未说明

**文件**: `.claude/skills/chain-test/SKILL.md:87-89`

```bash
RESP=$(curl -s -X PUT "http://localhost:8080/jeecg-boot/mes/purchase/apply/audit?id=$ID" \
  -H "X-Access-Token: $TOKEN")
```

`$TOKEN` 和 `$ID` 变量在脚本示例中出现但未定义来源。虽然读者可推断 token 来自登录步骤、ID 来自上一步的输出解析，但完整脚本中应包含 token 获取和 ID 提取的逻辑。**建议**：在技能头部加一段"token 获取"的注释或引用现有登录 curl 命令。

### P2-5: deploy-verify 并行编排的实现命令可能被 Shell 行连续符干扰

**文件**: `.claude/skills/deploy-verify/SKILL.md:78-81`

```bash
orca orchestration dispatch --task $TASK_API --to <agent_terminal_1> --inject &
orca orchestration dispatch --task $TASK_VISUAL --to <agent_terminal_2> --inject &
orca orchestration dispatch --task $TASK_CHAIN --to <agent_terminal_3> --inject &
wait
```

使用 shell 的 `&` + `wait` 做并行——如果 `orca orchestration dispatch` 本身是异步的（即返回后任务在后台运行），这个模式有效。但如果 `--inject` 是同步注入并等待，则 `&` 是正确做法。**建议**：用注释标注 `dispatch` 的同步/异步行为假设。

### P2-6: client-start 标记文件内容格式在 Windows 上 `date -Iseconds` 不存在

**文件**: `.claude/skills/client-start/SKILL.md:138`

```bash
echo "$(date -Iseconds) | $(uname -s) | ..." > .claude/.client-start-initialized
```

`date -Iseconds` 是 GNU date 语法（Linux），Windows Git Bash 不支持。`uname -s` 在 Windows Git Bash 中返回类似 `MINGW64_NT-10.0-22631` 的字符串——这其实可以用但不够精确。**建议**：用 `date +%Y-%m-%dT%H:%M:%S%z`（GNU date 兼容）或 `powershell -Command "Get-Date -Format o"`（Windows PowerShell）。

### P2-7: `hermes/visual-baselines/` 目录不存在于仓库中

文件系统中 `hermes/visual-baselines/` 目录不存在。visual-check 技能首次运行时需要 `mkdir -p`，虽然技能写了这个命令（`visual-check/SKILL.md:91`），但如果人工首次手动触发 `/visual-check` 前该路径不存在，会造成困惑。**建议**：在 visual-check 技能头部或 `.claude/skills/visual-check/SKILL.md` 的"截图基线目录"节加一句"目录首次运行时自动创建"。

### P2-8: human-gate 超时日志写入路径 `hermes/logs/gate-timeout-*.md` 未做目录预检

**文件**: `.claude/skills/human-gate/SKILL.md:106`

```
上下文已保存到：hermes/logs/gate-timeout-YYYY-MM-DD-HHmmss.md
```

`hermes/logs/` 目录虽已存在（含 `tool-failures.log`），但 human-gate 超时写入前未做 `mkdir -p`。**建议**：在超时处理步骤中加 `mkdir -p hermes/logs`。

---

## 📊 评审统计

| 统计项 | 数值 |
|--------|:--:|
| 被审文件数 | 13 |
| 命令文件 | 6（visual-check, test-loop, chain-test, deploy-verify, pre-commit-gate, client-start） |
| 技能文件 | 7（同上 6 个 + human-gate 框架） |
| **P0 阻断** | **0** |
| **P1 发现** | 7 |
| **P2 建议** | 8 |

### P1 摘要

| # | 问题 | 影响 |
|---|------|------|
| P1-1 | visual-check 命令 usage 格式错误 | 渲染混淆 |
| P1-2 | client-start `/tmp/` 路径 Windows 不兼容 | Windows 客户端日志读取失败 |
| P1-3 | `python3` 硬编码，Windows 上不存在 | 跨平台执行失败 |
| P1-4 | `gate-create` 子命令存在性未验证 | 运行时可能静默失败 |
| P1-5 | chain-test `--page` 参数语义不清 | 用户困惑 |
| P1-6 | visual-check 首次基线后缺少 INDEX.md 回写 | 基线索引过期 |
| P1-7 | deploy-verify 与 pre-commit-gate 安全清单可能漂移 | 未来不一致 |

### 各命令质量评分

| 命令 | 完整性 | 降级 | 跨平台 | 总评 |
|------|:--:|:--:|:--:|:--:|
| `/visual-check` | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 良好 |
| `/test-loop` | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 可用 |
| `/chain-test` | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 良好 |
| `/deploy-verify` | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 优秀 |
| `/pre-commit-gate` | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 良好 |
| `/client-start` | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 良好 |
| `human-gate` 框架 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 优秀 |

---

*评审人：Claude Code (Opus 4.8) — Orca 外部评审模式*
*归档：hermes/reviews/2026-07-27/orca-review-result.md*
