---
name: delegate
description: 任务委派领域知识 — Orca CLI 命令、preamble 模板、agent 选择矩阵、强制校验清单、降级策略。被 /delegate 命令加载。
version: 1.0.0
---

# delegate — 任务委派领域知识

## Agent 策略（2026-08 起统一为 pi）

**所有任务类型都用 pi**。原"按任务类型挑选 agent"矩阵已废弃，原因：

- pi 响应快、token 消耗低，适合绝大多数 MES 日常开发
- 高风险改动（Entity/SQL/状态机）的质量风险由 **orca-review 独立评审** 兜底，不靠选 agent
- 避免"Claude 调 Claude / pi 调 pi"自检测带来的链路复杂度

```bash
# 唯一命令
orca terminal create --command "pi" --json
```

> 历史说明：曾按任务类型分 `pi`（日常）/ `Claude`（高风险）/ `pi`（文档），2026-08 调研后统一为 pi。详见 learnings/2026-07-24-multi-ai-orchestration.md。

## Orca CLI 命令参考

```
orca terminal create --command "<agent>" --json  # 创建工人终端
orca terminal wait --for tui-idle                 # 等待终端就绪
orca terminal send --terminal <handle> --text "..."  # 注入 preamble + 任务
orca terminal close --terminal <handle>           # 关闭工人终端
```

## Preamble 模板（v4.0 对齐版）

派发给工人时必须注入以下 preamble，确保工人不跳过工作流步骤：

```markdown
<记忆卡片>

## ⚙️ 必须遵守的工作流（工人端 v4.0）

⚠️ 你不是"直接写代码"的工具——你必须按以下流程执行，不得跳过任何步骤：

### 0. 大任务前置切片
- **触发条件（满足任一）：** 变更涉及 ≥3 页面 / ≥10 文件 / 用户主动要求切片
- **动作：** 调用 /decompose 切片 → 按子切片逐个跑后续流程
- 不触发则跳过此步

### 1. /brainstorm：分析问题→根因→影响面→方案选项
**必须先输出分析结论，再进入下一步。禁止跳过。**

### 2. /plan：输出文件清单+步骤+验证命令
**必须列出每个文件的完整路径和改动内容，并在 plan 末尾标注"分级测试级别"（轻量/标准/全量）。**

### 3. ⚠️ orca-review（强制执行，不可跳过）
- **免评（直接实现）：** 纯文本修改、注释修改、CSS/样式调整、列宽/标签修改
- **必评（发 decision_gate 等评审结果）：** Java/Vue/TS/SQL 任何非免评改动，无论文件数量
- 具体做法：
  - 用 `orca orchestration send --to <协调者handle> --subject "请求 orca-review" --body "<你的完整plan>" --type decision_gate` 发送评审请求
  - **只发一次 decision_gate**，不要重复发送。之后每30秒用 `orca orchestration check --terminal <你的handle>` 检查是否有该消息的回复
  - **主动轮询等待评审结果**：收到回复前禁止进入实现阶段
  - 等待协调者指派独立评审终端（不限 agent 类型）并返回结果
  - 吸收评审意见后调整 plan，再进入实现
  - **禁止跳过此步骤直接写代码**，即使你觉得"风险低"也不行
  - **禁止将 /plan 和 orca-review 合并成一个步骤**

### 4. 实现：按评审后的 /plan 逐文件修改

### 5. /verify：compile + curl 实测
- 🚫 **禁止 mvn clean**——用 `mvn compile`，devtools 会自动热加载
- ✅ curl 前先确认后端存活：`curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/jeecg-boot/sys/getEncryptedString`
- ⚠️ **如果 curl 返回非200**：不要尝试重启后端。再试一次 `mvn compile`（不加clean），等5秒后再curl。如果还是失败，在 worker_done 中报告 verify 状态为 partial，不要无限重试

### 6. 分级测试（按 /plan 标注的级别）
- **轻量**（文案/样式/注释）：仅 /verify
- **标准**（Controller/Service/Vue ≤3 文件）：/verify + /test-api
- **全量**（Entity/Mapper/SQL/≥5 文件）：/verify + /test-api + /test-e2e + /test-all
- **前端有改动：** + /test-frontend（任何级别都加）

### 7. 收尾自检（/quality-gate 等价项，因 /quality-gate 命令尚未独立建文件，以下列表为准）
- 所有新增/修改文件 `update-begin`/`update-end` 对账（成对出现）
- `git diff` 改动范围合理（不该改的没改）
- 推送前依赖检查：boot-module/pom.xml 声明的模块目录存在 + system-start/pom.xml 对应依赖已加
- 任何异常立即报告协调者

### 8. git commit + push
- commit message 格式：`<type>(<scope>): <desc>`（如 `feat(mes-batch): ...`、`fix(mes-purchase): ...`）
- 推送：`git push origin <branch>`
- 🚫 **禁止 `git push --force` / `git reset --hard`** 等破坏性命令

### 9. /done：完成检查清单
- 走完 /done 命令的检查项（update-begin/end 对账、ESLint、mvn compile、引用一致性等）

### 10. **无论如何必须发送 worker_done**：即使 verify 不完全通过，也要发送 worker_done 报告结果
- 成功：worker_done + filesModified + commit hash
- 部分成功（代码改了但 verify 失败）：worker_done + filesModified + phase=verify_failed + 说明

## 📡 你必须发送的编排消息（每个阶段都要报告，缺一不可）
- 开始 brainstorm 时：发 heartbeat，phase="investigating"
- **输出 /plan 后**：发 heartbeat，phase="planning"
- 发出 orca-review 时：发 decision_gate，附完整 plan
- 等待评审时：发 heartbeat，phase="等待评审"
  - ⚠️ **每30秒主动轮询检查回复**：`orca orchestration check --terminal <你的handle>` 或 `orca orchestration inbox` 查找来自协调者的 Re: 消息
  - **收到回复前禁止进入实现阶段**，即使觉得"风险低"也不行
- 开始实现时：发 heartbeat，phase="implementing"
- 开始 verify 时：发 heartbeat，phase="verifying"
- 开始分级测试时：发 heartbeat，phase="testing"
- 开始 commit + push 时：发 heartbeat，phase="committing"
- **完成（或遇到无法恢复的错误）时：必须发 worker_done**，附 filesModified + commit hash
  - 成功：worker_done + phase=completed
  - verify失败但代码已改：worker_done + phase=verify_failed + 错误说明
  - 无论如何都要发，禁止不发消息就退出
```

## 任务派发消息格式

```markdown
<记忆卡片>

---

## 当前任务
<用户输入的任务描述>

要求：
- 严格遵循上述硬规则
- 完成后按 preamble 回报 worker_done，payload 包含更新后的记忆卡片作为 body
- 如果 Memory Card 中有硬规则的 ID 字段，完成后更新状态信息
- 只读代码/规则，修改代码前先确认文件在允许的边界内
```

## 强制校验清单

工人完成后，协调者执行以下校验（不可跳过）：

- [ ] 工作流阶段完整（v4.0 全 10 步：0 大任务切片 → 1 brainstorm → 2 plan → 3 orca-review → 4 实现 → 5 verify → 6 分级测试 → 7 收尾自检 → 8 commit+push → 9 /done → 10 worker_done）
- [ ] orca-review 由独立评审终端完成（非降级手工）
- [ ] 分级测试级别与变更影响面匹配（轻量/标准/全量）
- [ ] /quality-gate 等价自检项全部通过（update-begin/end 对账、git diff 范围、推送前依赖）
- [ ] git commit + push 已执行（worker_done 含 commit hash）
- [ ] /done 完成检查清单已走完
- [ ] git diff 改动合理（不该改的文件改了？遗漏了文件？）
- [ ] /verify 结果（编译通过？curl 返回正确？）
- [ ] 任何异常立即报告用户，不要默默放行

## 协调者侧最佳实践（2026-08 沉淀）

### 轮询——不用 `check --wait`、不用 timeout 阻塞

**反模式**：用 `orca orchestration check --wait` 阻塞等待 worker_done。

**原因**（learnings/2026-07-21-orca-coordinator-no-check-wait）：pi 终端 TUI 会**自动把编排邮件投递进会话并标记已读**，CLI `check --wait` 查的是未读消息 → 必然查空/卡死。

**正确做法**（分段轮询 + 非阻塞，v5 改造：sequence 替代 timestamp）：

```bash
# 1) 从状态文件初始化 LAST_SEQ（派工时状态文件已记初始 0）
LAST_SEQ=$(python .remember/tmp/sync-state.py get-seq --id "$TASK_SLUG" 2>/dev/null || echo 0)

# 2) 每 30s 看 preview + 按 sequence 过滤 inbox（每段 5 min，分段 bash）
# ⚠️ v5 改造 (2026-08-03): 换 sequence > LAST_SEQ 替代 timestamp 过滤
#    原因: timestamp 跨会话会失效/inbox FIFO 丢失，sequence 单调递增更可靠
#    状态文件 .remember/state/delegated-tasks.json 持久化 LAST_SEQ，跨 session 跟踪
#    务必在派工时用 sync-state.py add 初始化任务，否则脚本 fallback 0
TASK_KEYWORDS="<kw1>,<kw2>"  # 逗号分隔多关键词 OR 匹配
SUBJECT_PREFIX="[$TASK_SLUG]"  # 精确前缀匹配优先级最高

for i in $(seq 1 10); do
  sleep 30
  # 看 preview（判断工人状态）
  orca terminal show --terminal $HANDLE --json > /tmp/s.json
  # 按 sequence 过滤 worker_done（避免历史消息误判）
  # v5 改造: 删 from_handle == $COORDINATOR_HANDLE 检查（语义错误，worker 不会自己发 worker_done）
  # v5 改造: 用 SUBJECT_PREFIX 精确 + BODY_KEYWORDS 模糊 OR 匹配
  HAS=$(orca orchestration inbox --json | python -c "
import json, sys
d = json.load(sys.stdin)
msgs = d['result']['messages']
matched = [m for m in msgs if isinstance(m, dict) and
           m.get('type')=='worker_done' and
           m.get('sequence',0) > $LAST_SEQ and (
               m.get('subject','').startswith('$SUBJECT_PREFIX') or
               any(kw.strip() in m.get('subject','') + m.get('body','') for kw in '$TASK_KEYWORDS'.split(','))
           )]
if matched:
    max_seq = max(m.get('sequence',0) for m in matched)
    print(f'{len(matched)} {max_seq}')
else:
    print('0 $LAST_SEQ')
")
  COUNT=$(echo $HAS | cut -d' ' -f1)
  NEW_SEQ=$(echo $HAS | cut -d' ' -f2)
  if [ "$COUNT" != "0" ]; then
    LAST_SEQ=$NEW_SEQ
    # 持久化 LAST_SEQ 到状态文件（跨会话跟踪关键）
    python .remember/tmp/sync-state.py update-seq --id "$TASK_SLUG" --seq $LAST_SEQ
    break
  fi
done
```

> **v5 改造背景**：session #10 session #10 worker 完成但协调者未及时发现。真实根因是 worker_done 进了已死 handle，新会话看不到。状态文件持久化 + sequence 跟踪 + 启动扫描才是可靠兑底。详见 `.claude/plans/2026-08-03-fix-delegate-coordinator-detection.md`。

### inbox 抓 payload——防御性解析

```bash
PYTHONIOENCODING=utf-8 python << 'PYEOF'
import json
with open(r'<win-path-to-inbox.json>', encoding='utf-8') as f:
    d = json.load(f)
msgs = d['result']['messages']
# messages 可能混 dict/str（如失败项），必须 isinstance 检查
done = [m for m in msgs if isinstance(m, dict) and m.get('type')=='worker_done']
done.sort(key=lambda m: m.get('createdAt',''), reverse=True)
PYEOF
```

### TUI 状态字符 ≠ 终态信号

- TUI 字符 `⠙⠧⠇⠋⠸` 只是 busy 指示符（worker 在执行任务）
- 判断终态必须看 `preview` 实际内容（"WORKER_DONE"/commit hash/总结性句子）
- 或直接看 `inbox` 是否出现新 worker_done

### 超时控制——5 分钟分段

- bash 默认 timeout 5 min，复杂任务（多文件 + SQL + 编译 + curl）需 20+ 分钟
- 按 5 分钟分段轮询，到点用户决定是否续跑
- 跑过 3 段仍未收到 worker_done → 主动 `terminal read --limit 200` 看完整输出判断是否僵死

### 工人僵死兑底（2026-08 联合模式坑）

**场景**：工人 commit 了但 coordinator 未收到 worker_done，或 TUI busy 但 buffer 空、预览仅轮换状态字符 `⠦⠧⠇⠋⠸`。

**判僵死信号（任一）**：

1. `preview` 只显示 TUI busy 字符，无实际内容 > 5 分钟
2. `terminal read --limit 200` 返回 `output=""`（buffer 空）
3. `terminal send "ping" --enter` 30 秒后 preview 仍无变化

**兑底流程**：

```bash
# Step 1: Ping 测试
orca terminal send --terminal $HANDLE --text "ping" --enter
sleep 30
orca terminal show --terminal $HANDLE --json | grep preview

# Step 2: 仍有僵死信号 → 杀工人，重派（精简 preamble，跳过 orca-review）
orca terminal close --terminal $HANDLE
orca terminal create --command "pi" --json
# 新 preamble：明示跳过 orca-review、直接 commit、必须 worker_done
```

**防僵死 preamble 补充要求**：

- 每个阶段发 heartbeat（已存在），僵死工人必然缺 heartbeat → 可反推
- 重派时 preamble 精简到 < 1000 字节（避免工人再 TUI 假死）
- 重派 preamble 明确 `不进行 orca-review，直接 commit`（跳过独立评审减少交互面）

**commit 兑底**：

- 即使 worker_done 未到，协调者也可走 git 兑底：`git log --oneline -5 | grep <slice-id>` 看是否出现新 commit
- 新 commit 出现 → 判完成（不严格依赖 worker_done 消息）
- 出现 commit + 超 5 分钟无 worker_done → 判僵死 + 兑底重派

## 🚨 worker_done 硬约束（2026-08-02 强化）

> **连续 2 次派工中观察到工人完成所有工作但忘了发 worker_done → 必须升级为硬约束。**

### 工人端反模式（禁踩）

| 反模式 | 现象 |
|------|------|
| **"我完成了"陷阱** | 工人在自己终端打印"完成"总结，**以为这就够了**，实际没调 `orca orchestration send --type worker_done` |
| **"无需发送"陷阱** | 工人判断"任务轻量不需要回报"，直接进入 idle |
| **"protocol 略读"陷阱** | preamble 末尾的编排消息协议被工人忽略（特别是最后一条 worker_done） |

### 协调者侧主动补救（新增）

工人超时无 worker_done 但有产物时（5 分钟 polling 后触发）：

```bash
# Step 1：主动 ping 提醒
orca terminal send --terminal $HANDLE --text "你已完成任务吗？如有产物，请立即发 worker_done（含产物路径）。" --enter
sleep 30

# Step 2：仍无 worker_done → 看产物是否存在
#   - 产物存在 → 手动从终端 buffer 提取 worker_done 内容 → 补发
#   - 产物不存在 → 判真正卡住 → 重派

# Step 3：产物路径校验作为完成信号（不要求 commit 的任务）
delegate_is_complete() {
    local product_path="$1"
    [ -f "$product_path" ] && return 0
    return 1
}
```

### 跨会话状态持久化（v5 核心：2026-08-03 加固）

**问题**：session #10 协调者未及时发现 worker 完成。真实根因：worker_done 进了已死 handle（死信地址），新会话无法看到。

**机制**：3 条排骨组合

1. **状态文件** `.remember/state/delegated-tasks.json`（gitignored，跨会话）
   - 派工时 `sync-state.py add` 初始化
   - 收尾时 `sync-state.py complete` 标记
   - 轮询中 `sync-state.py update-seq` 跟新

2. **启动扫描** `.claude/scripts/check-delegated-tasks.sh`（session-start.sh 集成）
   - 有状态文件 → 跨会话捡回末完成任务的 worker_done
   - 三取二判定：inbox + git_log + output_files（任二为完）
   - baseline_lost 自愈：last_seq < inbox_min_seq 时重置

3. **轮询使用 sequence**（替代 timestamp）
   - `LAST_SEQ` 从状态文件读
   - 跨 session 跟踪可靠
   - 如 inbox FIFO 丢失，git_log 仍 PRIMARY

**脚本接口**：

```bash
# 派工时
python .remember/tmp/sync-state.py add \
  --id "vite-config-preview" \
  --task-title "vite preview proxy 修复" \
  --worker-handle "$WORKER_HANDLE" \
  --coordinator-handle "$COORD_HANDLE" \
  --match-rules '{"subject_prefix":"[vite-config-preview]","body_keywords":["vite","preview"]}' \
  --expected-files "jeecgboot-vue3/vite.config.ts"

# 轮询中
python .remember/tmp/sync-state.py update-seq --id "$TASK_SLUG" --seq $LAST_SEQ

# 收尾时
python .remember/tmp/sync-state.py complete --id "$TASK_SLUG" --payload '{"commit":"abc1234"}'
```

详见 `.claude/plans/2026-08-03-fix-delegate-coordinator-detection.md`。

### 轮询循环里加主动 ping（不再被动等）

```bash
for i in $(seq 1 5); do
  sleep 60
  # ... 现有 inbox 检测 ...
  # 新增：每 2 段（120s）主动 ping
  if [ $((i % 2)) -eq 0 ]; then
    orca terminal send --terminal $HANDLE --text "[ping] 你在吗？完成后请发 worker_done。" --enter
  fi
done
```

### preamble 模板必须 🚨🚨🚨 视觉警告（已在 2026-08-02 补充）

```markdown
## 🚨🚨🚨 必须发 worker_done（硬约束，非可选）🚨🚨🚨

完成任何工作（commit / 报告生成 / 命令跑完）后，**第一步**就调：
\`orca orchestration send --to <协调者handle> --type worker_done --subject "<任务名>" --body "<产物路径 + 关键结果>"\`

🚫 禁止：在自己终端打印"完成"就 idle（这是最大反模式）
🚫 禁止：认为"任务轻量不需要回报"
🚫 禁止：忘记最后一步就退出
```

### worker_done 完整命令模板（v4 观察：减少工人写错）

**问题**：连续 3 次 pi 工人看完警告后仍未发 worker_done。

**解决**：preamble 里**嵌入完整可复制命令字串**，工人只需复制粘贴：

```bash
# 任务完成后，**复制并修改下面这条命令后执行**：
orca orchestration send \
  --to term_a55b5d20-ef82-419c-b2da-f693c50eae32 \
  --type worker_done \
  --subject "[<任务名>] 完成" \
  --body "产物路径：<path1, path2>
关键结果：<p95=29ms / 0 P0 / PASS>

filesModified: <相对路径列表>
reportPath: <主报告路径>
phase: completed"
```

### 协调者代发兑底动作（v4 验证有效）

如 pi 工人 5 分钟未发 worker_done，但产物到位 → 协调者手动代发（不是脚本，是人工/Claude 代为补发）：

```bash
# 协调者侧手动补发
orca orchestration send \
  --to <协调者自己或主终端> \
  --type worker_done \
  --subject "[<任务名>] 协调者代发·产物到位" \
  --body "工人未发 worker_done，但产物已确认存在：<path1, path2>
关键结果：<从产物提取>"
```

**已知会工作的场景**（v4 实证）：Claude Code 协调者检测到产物后 → 自动代发。

## 降级策略

Orca 不可用时：退化为 `/cleanup-context`，输出卡片后提示用户手动开新终端粘贴。无空闲终端槽位时：提示用户关闭不需要的终端后重试。

---

## 🆕 2026-08-02 v5 优化（基于 P0 批次修复踩坑）

### 坑 1：Pi worker 卡死 = 10 分钟没动手（实际信号比理论短）

**现象**：Pi 工人收到详细 preamble 后，反复思考"什么是协调者 / 要不要发 decision_gate"，超过 10 分钟没有任何 tool call。

**判卡死信号（任一）**：

| 信号 | 阈值 |
|---|---|
| preview 只重复同一段思考文本（无新 tool call） | > **2 分钟**（不是 5 分钟） |
| preview 出现"但是我需要注意""让我仔细分析"等反复合 | > **3 次** |
| lastOutputAt 时间戳与当前时间差 | > **90 秒**（TUI 字符在动但内容没变） |

**正确做法**：

```bash
# 每 30 秒轮询（不是 60-90 秒）
for i in $(seq 1 10); do
  sleep 30
  LAST_TS=$(orca terminal show --terminal $HANDLE --json | python -c "import json,sys; print(json.load(sys.stdin)['result']['terminal'].get('lastOutputAt',0))")
  NOW_TS=$(date +%s%3N)
  GAP=$((NOW_TS - LAST_TS))
  if [ $GAP -gt 90000 ]; then
    echo "[卡死信号] lastOutputAt 距今 ${GAP}ms > 90s"
    # 主动 ping
    orca terminal send --terminal $HANDLE --text "[ping] 你卡住了吗？直接动手做，思考不要超过 1 轮。" --enter
  fi
  # 检查 worker_done
  HAS=$(orca orchestration inbox --json | python -c "...")
  [ "$HAS" != "0" ] && break
done
```

### 坑 2：orca-review 不要让 Pi worker 发（Pi 不支持）

**错误做法**（preamble v4.0 的旧规则）：
```markdown
# 让 Pi 工人主动发 decision_gate
orca orchestration send --to <协调者> --type decision_gate --body "<plan>"
```

**坑**：
- Pi 不知道"协调者"是谁 → 反复思考 → 卡死
- Pi 不会调 orca orchestration send → 即使思考完也不发

**正确做法**：**由协调者（当前 Pi/Claude）自己发 orca-review**

```bash
# 1. 协调者找到 Claude 评审终端
CLAUDE_HANDLE=$(orca terminal list --json | python -c "
import json,sys
d = json.load(sys.stdin)
for t in d['result']['terminals']:
    if 'Claude' in t.get('title','') and t.get('writable'):
        print(t['handle']); break
")

# 2. 协调者创建评审任务并 dispatch
orca orchestration task-create \
  --spec "<评审输入：背景 + 草案 + 待评审问题>" \
  --task-title "review-<任务名>-$(date +%H%M)"

# 3. 拿到 task_id 后 dispatch
orca orchestration dispatch \
  --task <task_id> \
  --to $CLAUDE_HANDLE \
  --inject

# 4. 等回报（最多 5 分钟）
# 检查 hermes/reviews/ 或 terminal preview
```

**关键认知**：
- orca-review 是**协调者侧**机制，不是工人侧
- Pi worker 只负责：brainstorm → plan → 实现 → verify → commit → push
- 评审在 worker 输出 plan 后，**由协调者发起**

### 坑 3：轮询节奏从 60-90s 缩到 30s

**原因**：Pi worker 卡死发现晚了 10+ 分钟，等用户提示才意识到。

**新节奏**：

```bash
# 30 秒轮询（不再是 60-90s）
for i in $(seq 1 20); do
  sleep 30
  # 1. 查 inbox worker_done
  # 2. 查 lastOutputAt gap（> 90s = 卡死信号）
  # 3. 查 buffer 增长（无变化 = 卡死信号）
done
```

### 坑 4：worker_done payload 必须含 commit hash + verify 结果

**模板**（preamble 嵌入）：

```bash
orca orchestration send \
  --type worker_done \
  --subject "[<任务名>] 完成" \
  --body "commit: <hash>
filesModified: <path1, path2>
verify: <mvn compile OK / curl 200 / test N/N pass>
risks: <P0/P1 列表，如无写 'none'>
phase: completed"
```

**协调者代发触发条件**（任一）：
- 5 分钟 polling 无 worker_done
- 但 git log 出现新 commit
- 或终端 preview 显示完成总结但没发消息

### 坑 5：派工前先 grep 代码（避免派过时任务）

**新增**：派工前先用 grep/browse 验证 bug 描述与代码一致。

```bash
# 示例：派 P0 修复前先看代码
grep -n "stockIn\|selectForUpdate" jeecg-boot/.../MesBatchInventoryServiceImpl.java
```

**避免**：
- progress.md 写过"未修" → 代码已修 → 工人找不到 bug → 卡死思考
- 描述与代码不符 → 工人反复对照 → 浪费时间

### 决策表：派工前必查

| 任务类型 | 是否要 orca-review | 评审方 | 是否要 commit+push |
|---|---|---|---|
| 纯文案/注释/样式 | ❌ | — | ✅ |
| Vue/TS ≤3 文件无新 Entity | ⚠️ 协调者自评 | — | ✅ |
| Java Service + Mapper | ✅ 必评 | Claude | ✅ |
| SQL 改表/Entity | ✅ 必评 | Claude | ✅ |
| 跨模块链路 | ✅ 必评 | Claude | ✅ |

### 优化 checklist（派工前 30 秒）

- [ ] 已 grep 代码确认 bug 描述准确（坑 5）
- [ ] preamble ≤ 1500 字节（避免 Pi TUI 假死）
- [ ] preamble 含完整 worker_done 命令模板（坑 4）
- [ ] orca-review 由协调者发起，不是 worker（坑 2）
- [ ] 30 秒轮询节奏就位（坑 3）
- [ ] 卡死信号检测就位：lastOutputAt gap > 90s（坑 1）
