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

**正确做法**（分段轮询 + 非阻塞）：

```bash
# 1) 记录任务起始时间戳（任务派发后立刻执行）
START_TS=$(date -u +"%Y-%m-%dT%H:%M:%S")

# 2) 每 60s 看 preview + 按时间戳过滤 inbox（每段 5 min，分段 bash）
for i in $(seq 1 5); do
  sleep 60
  # 看 preview（判断工人状态）
  orca terminal show --terminal $HANDLE --json > /tmp/s.json
  # 按时间戳过滤 worker_done（避免历史消息误判）
  HAS=$(orca orchestration inbox --json | python -c "
import json, sys
d = json.load(sys.stdin)
msgs = d['result']['messages']
n = sum(1 for m in msgs if isinstance(m, dict) and m.get('type')=='worker_done' and m.get('createdAt','')>='$START_TS')
print(n)
")
  [ "$HAS" != "0" ] && { echo "done"; break; }
done
```

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

## 降级策略

Orca 不可用时：退化为 `/cleanup-context`，输出卡片后提示用户手动开新终端粘贴。无空闲终端槽位时：提示用户关闭不需要的终端后重试。
