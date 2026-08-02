# orca-review 评审报告：协调者 worker_done 检测修复（方案 D）

> **评审方**：Claude（独立评审终端 term_2d7a42e9）
> **日期**：2026-08-03
> **评审对象**：`.claude/plans/2026-08-03-fix-delegate-coordinator-detection.md`
> **结论**：⚠️ 思路对齐，3 个薄弱环节需加固后再实施

---

## 一、5 个待评审问题的逐一回答

### Q1: 状态文件路径

**判定**：✅ `.remember/state/delegated-tasks.json` — **合适，但需加约束**

`remember/` 已有的 `tmp/` 子目录存 `last-save.json`、`last-ndc.ts`——这些都是"跨会话状态"。`state/` 是同一语义的扩展，不混乱。

替代方案对比：
| 路径 | 优点 | 缺点 |
|------|------|------|
| `.remember/state/` | 已有先例（`tmp/`）、git 可追踪 | 与"记忆"语义轻微偏离 |
| `.claude/state/` | 工程语义清晰 | `.claude/` 是 harness，放运行时状态不合适 |
| `.claude/orchestration/` | 语义最精确 | 多一层嵌套，过度设计 |

**建议**：用 `.remember/state/`，但在 `remember/INDEX.md` 中加一行说明 `state/` 子目录用途（"跨会话任务状态持久化，非会话记忆"），消除语义混淆。

---

### Q2: 启动扫描注入机制

**判定**：⚠️ **方向对，但实施细节需要修正**

计划的"pi SessionStart hook"描述有误——pi 没有 Claude Code 的 hook 系统。但方案正确的落地位置已经存在：

**正确机制**：在 Claude Code 的 `session-start.sh` hook（`.claude/hooks/session-start.sh`）中追加扫描调用。

证据：
- `session-start.sh` 已经在做同类启动检查：进度恢复（`progress.md` phase 检测）、深度巡检逾期提醒、测试状态恢复（`state.json` 检测）
- `check-delegated-tasks.sh` 的输出通过 stdout → Claude Code 将其注入系统提示 `<system-reminder>` 块 → 协调者首轮即可看到
- 这正是计划中"注入协调者首轮输出"的正确实现——不需要 pi 端改造

**修正**：计划步骤 6 "pi SessionStart" → 改为"Claude Code `session-start.sh` hook 中追加调用"。删除计划中关于"pi system prompt 注入"的讨论——pi 不参与这个链路。

**额外建议**：`check-delegated-tasks.sh` 的输出应该结构化到一句话（≤80 字符），因为 system-reminder 中长 JSON 会被截断。脚本 stdout 输出一行摘要（如 `⚠️ 检测到 1 个历史 worker_done：vite-preview-proxy (commit e69f2f5)`），详细 JSON 写入临时文件（路径在摘要中引用）。

---

### Q3: 跨会话 sequence 跟踪的可靠性

**判定**：⚠️ **方案 D 最薄弱的环节——需要加固**

**风险场景**：orca 清空旧 inbox 消息（FIFO 滚动窗口）。

当 `LAST_SEQ=68` 但 inbox 现在最早的消息是 `seq=75`（旧消息被清空），`sequence > LAST_SEQ` 会匹配 inbox 中所有消息——大量假阳性。

**计划中的缓解**（git log 交叉验证）**不够**：
- 只覆盖 commit+push 类任务
- 报告生成类任务（如 audit report）无 git log 可交叉验证
- 关键词匹配在假阳性洪水面前失去区分力

**建议加固**：

```python
# 在 check-delegated-tasks.sh 中加 baseline 自愈
inbox_min_seq = min((m['sequence'] for m in msgs if isinstance(m, dict)), default=0)
task_last_seq = task.get('last_seq', 0)

if task_last_seq > 0 and task_last_seq < inbox_min_seq:
    # 基线丢失：task 的 last_seq 指向的消息已被清空
    # 策略：重置 last_seq 为当前 inbox 最老 seq - 1（接受本任务可能漏检）
    task['last_seq'] = inbox_min_seq - 1
    task['baseline_lost'] = True
    # 同时把 expected_files git log 提升为 PRIMARY 信号
```

**修正后的优先级**：
1. **PRIMARY**：`expected_files` 的 git log 匹配（有 commit → 直接判完成，不依赖 inbox）
2. **SECONDARY**：inbox keyword + sequence 匹配（无 commit 但有 worker_done → 从 body 提取产物路径验证）
3. **FALLBACK**：inbox sequence 只看最近 50 条的 keyword 匹配（baseline 丢失时）

---

### Q4: 关键词冲突

**判定**：✅ **ID 前缀方案正确，但需要 worker 端强制执行**

计划中的 `[vite-preview-proxy]` 前缀思路正确。关键问题是：**worker 发 worker_done 时的 subject 格式没有强制机制**。

**建议**：
1. 在 preamble 的 worker_done 命令模板中，把 `subject` 字段设为**不可编辑的固定格式**：
   ```bash
   --subject "[${TASK_SLUG}] worker_done — ${PHASE}"
   ```
   其中 `TASK_SLUG` 在派工时由协调者注入 preamble（如 `vite-preview-proxy`），工人只需复制粘贴。

2. 在状态文件中，`keywords` 字段改为 `match_rules`，支持精确匹配（subject 前缀）和模糊匹配（body grep）：
   ```json
   "match_rules": {
     "subject_prefix": "[vite-preview-proxy]",   // 精确匹配，优先级最高
     "body_keywords": ["vite.config.ts", "proxy"]  // 模糊匹配，次优先级
   }
   ```

**无需 interim 方案**——当前 inbox 历史任务量小（68 条），ID 前缀已足够区分。

---

### Q5: 是否需要 orca 端改造

**判定**：💡 **建议提，但不应阻塞方案 D**

`--address-alias` 的核心价值：worker 发送到 `--to @coordinator`（alias），而非具体 handle `term_db1f27a1...`。这样协调者 session 切换后，新协调者仍能收到旧 worker 的消息——**从根本上解决死信地址问题**。

但这是 orca runtime 层改造，周期不可控。方案 D 的客户端方案是正确的前置步骤：
- 短期（现在）：方案 D（客户端 workaround）
- 中期（建议）：提 orca roadmap issue，要求 `--address-alias` 或 `--to @role:coordinator` 功能

**建议写入 roadmap**：在 `hermes/research/orca-roadmap-suggestions.md` 中记录此需求，附上方案 D 的实际运行数据（3 个月后用来论证优先级）。

---

## 二、方案 D 的 3 个最薄弱环节

### 🔴 薄弱点 1：inbox 不是可靠消息总线

**严重度**：P0（设计假设可能不成立）

- 3/4 历史消息 `delivered_at=null` → inbox 持久化有已知缺陷
- inbox 是 FIFO 滚动窗口，旧消息会被清空 → `sequence > LAST_SEQ` 在窗口滑过后失效
- 如果 orca 重启清空 inbox，整个扫描链路断掉

**缓解**：把 git log（`expected_files`）提升为 PRIMARY 完成信号，inbox 降为 SECONDARY。对于无 commit 的任务（报告生成），要求 worker 把产物路径写入状态文件（通过 `sync-state.py` 的 `--output-paths` 参数）。

### 🟡 薄弱点 2：worker 模板合规不可强制执行

**严重度**：P1（依赖工人自觉）

- preamble 中的 worker_done 命令模板是**建议**，不是**强制**
- 工人可能修改 subject、遗漏关键词、不写 commit hash
- 历史 2 次观察到工人忘了发 worker_done → 模板合规同样会忘

**缓解**：在 `check-delegated-tasks.sh` 中不做纯 inbox 匹配。同时检查 3 个独立信号（三取二判完成）：
1. inbox 中匹配的 worker_done
2. `expected_files` 的 git log 新 commit
3. 状态文件中的 `output_paths` 产物文件存在

任一信号独立触发不足以判完成，至少 2/3 才判。

### 🟡 薄弱点 3：单协调者假设

**严重度**：P1（当前适用，未来可能不适用）

- 状态文件无锁机制（计划中认为"单线程协调者场景不需要"）
- 但实际上：同一个 Claude Code session 中协调者可能在**多轮**中写状态文件（用户切话题后又回来），不是单线程
- 原子写（`.tmp` + `os.replace`）防并发损坏，但不能防**竞争写**（两个协调者同时写 → 后者覆盖前者）

**缓解**：当前只有 1 个协调者终端，短期内不会出现多协调者。但在 `sync-state.py` 中加 `--if-unmodified-since` 参数（乐观锁），为未来多协调者做准备。成本很低（+10 行 python），现在就加。

---

## 三、1-2 个可立即采纳的改进

### 💡 改进 1：把 git log 提升为 PRIMARY 完成信号（+ 三取二判定）

当前计划中 git log 是"交叉验证"辅助手段。应改为：

```
完成判定 = (inbox_match ? 1 : 0) + (git_log_match ? 1 : 0) + (output_files_exist ? 1 : 0)
if score >= 2 → 判完成
if score == 1 → 判"疑似完成，需人工确认"
if score == 0 → 判"仍在进行"
```

**具体改动**：在 `check-delegated-tasks.sh` 步骤 3 的输出 JSON 中，为每个 task 加 `completion_score` 和 `verdict` 字段。

### 💡 改进 2：session-start.sh 输出限长 + 结构化

`check-delegated-tasks.sh` 的完整 JSON 输出不应直接进 system-reminder（会被截断）。改为：

```bash
# 一行摘要（进 system-reminder）
echo "🔍 委托任务扫描：1/2 已完成（vite-preview-proxy ✓ e69f2f5, batch-audit ⏳）"
# 完整报告写入文件
REPORT=".remember/state/delegated-scan-$(date +%Y%m%d-%H%M%S).json"
```

这样协调者首轮看到摘要，需要细节时读取报告文件。

---

## 四、总体判定

| 维度 | 评级 | 说明 |
|------|:----:|------|
| 问题分析 | ✅ 准确 | A/B/C 三个根因抓得准 |
| 方案设计 | ✅ 合理 | 持久化+启动扫+sequence 是正确的三件套 |
| 实施细节 | ⚠️ 需修正 | 3 个薄弱点 + Q2/Q3 的修正 |
| 文件清单 | ✅ 完整 | 5 个文件覆盖面够 |
| 验证计划 | ⚠️ 验收 3 有硬伤 | "需要在真实场景下做一次"是对不可重现 bug 的妥协——应构造可重现的验收场景 |

**最终建议**：方案 D **可以实施**，但实施前必须：
1. 把上述 3 个薄弱点的缓解措施写入 plan（尤其是薄弱点 1 的 PRIMARY/SECONDARY 翻转）
2. 修正 Q2 的 hook 注入机制描述
3. 采纳改进 1（三取二判定）和改进 2（输出限长）

实施顺序建议：先做步骤 1（状态文件 schema）+ 步骤 2（sync-state.py）→ 独立跑验收测试 1 → 再做步骤 4（SKILL.md 轮询改造）→ 步骤 5（启动扫描脚本）→ 步骤 3+6（派工流程嵌入）。不要 5 个文件一起改——这是跨 4 个文件的协调改动，分批验证更安全。
