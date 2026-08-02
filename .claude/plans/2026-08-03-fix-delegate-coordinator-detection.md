# 实施计划：协调者 worker_done 检测修复（方案 D + Claude 评审加固）

> 日期：2026-08-03
> 触发：session #10 vite.config.ts 修复协调者未及时发现 worker 完成
> 方案：D（持久化 + 启动扫 + sequence 轮询）+ Claude 评审 8 项加固
> 工期：3 批分阶段实施（步骤 1-2 → 验收 1 → 步骤 4-5 → 验收 2-3 → 步骤 3+6 → 验收 4）

---

## 🎯 目标

解决 session 跨度的协调者失联问题：
- A. 死信地址（worker_done 进了已死 handle）
- B. 新会话零状态（启动时不知道有任务在跑）
- C. 轮询脚本 bug（timestamp 不如 sequence 可靠）

加固后达到 3 个目标：
- PRIMARY 完成信号 = git log（不可丢失）
- SECONDARY 完成信号 = inbox + 产物路径
- 启动扫描自动恢复到跨 session 任务

---

## 📁 实施批次（重要！分批验证）

### 批次 1：状态文件基础（独立验证）

| # | 路径 | 类型 | 改动 |
|---|---|---|---|
| 1 | `.remember/state/delegated-tasks.json` | 新建 | schema |
| 2 | `.remember/tmp/sync-state.py` | 新建 | 原子读写 + 乐观锁 |
| 3 | `remember/INDEX.md` | 修改 | 加一行说明 state/ 用途 |

**独立验收：** 验收测试 1（读写）

### 批次 2：启动扫描 + 注入（依赖批次 1）

| # | 路径 | 类型 | 改动 |
|---|---|---|---|
| 4 | `.claude/scripts/check-delegated-tasks.sh` | 新建 | 启动扫描 + 三取二判定 |
| 5 | `.claude/hooks/session-start.sh` | 修改 | 追加 check-delegated-tasks.sh 调用 |

**独立验收：** 验收测试 2、3

### 批次 3：派工流程 + SKILL 轮询（依赖批次 2）

| # | 路径 | 类型 | 改动 |
|---|---|---|---|
| 6 | `.claude/skills/delegate/SKILL.md` | 修改 | sequence 轮询 + 状态写入 |
| 7 | `.claude/commands/orca/delegate.md` | 修改 | 派工嵌入状态文件 |

**独立验收：** 验收测试 4

---

## 📋 详细步骤

### 批次 1（步骤 1-3）

#### 步骤 1: 创建状态文件 schema

**文件：** `.remember/state/delegated-tasks.json`

```json
{
  "version": "1.0",
  "tasks": [
    {
      "id": "<slug>",
      "task_title": "<人读名>",
      "worker_handle": "term_xxx",
      "coordinator_handle": "term_yyy",
      "dispatched_at": "2026-08-02T22:00:00Z",
      "last_seq": 0,
      "match_rules": {
        "subject_prefix": "[<slug>]",
        "body_keywords": ["<kw1>", "<kw2>"]
      },
      "expected_files": ["<相对路径 1>", "<相对路径 2>"],
      "output_paths": [],
      "status": "dispatched",
      "baseline_lost": false,
      "completed_at": null,
      "worker_done_payload": null
    }
  ]
}
```

**注意（Claude 评审加固）：**
- `match_rules` 替代 `keywords`，支持 subject_prefix 精确 + body_keywords 模糊
- `expected_files` 改为 PRIMARY 完成信号（git log 交叉验证）
- `output_paths` 用于报告类任务（无 commit 也可验证）
- `baseline_lost` 标记 inbox FIFO 丢失

#### 步骤 2: 创建同步辅助脚本

**文件：** `.remember/tmp/sync-state.py`

**接口：**
```python
python sync-state.py add --id <slug> --task-title <title> --worker-handle <h> --coordinator-handle <h> --match-rules <json> --expected-files <csv>
python sync-state.py list
python sync-state.py get --id <slug>
python sync-state.py get-seq --id <slug>
python sync-state.py update-seq --id <slug> --seq <n>
python sync-state.py complete --id <slug> --payload <json>
python sync-state.py mark-abandoned --id <slug> --reason <text>
```

**关键实现（Claude 评审加固：乐观锁）：**
```python
def update_task(task_id, **kwargs):
    state = read_state()
    task = find_task(state, task_id)
    if task.get('baseline_lost') and kwargs.get('last_seq'):
        # 乐观锁：检查上次读取时间
        pass
    # 原子写
    tmp = STATE_FILE + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(state, f, ensure_ascii=False, indent=2)
    os.replace(tmp, STATE_FILE)
```

#### 步骤 3: 文档说明

**文件：** `remember/INDEX.md`（如果不存在则新建）

```markdown
# remember/ 目录索引

| 子目录 | 用途 | 持久化 |
|---|---|---|
| `state/` | 跨会话任务状态持久化（worker_done 跟踪） | 是 |
| `tmp/` | 临时辅助脚本（sync-state.py 等） | 否（git 可追踪） |
| `now.md` | 当前会话缓冲 | 否 |
| `today-*.md` | 每日记录 | 否 |
| `core-memories.md` | 关键事件 | 是 |
```

---

### 批次 2（步骤 4-5）

#### 步骤 4: 启动扫描脚本

**文件：** `.claude/scripts/check-delegated-tasks.sh`

**Claude 评审关键加固：**
1. **PRIMARY/SECONDARY 翻转** —— git log 优先
2. **三取二判定** —— 3 信号至少 2 个才判完成
3. **baseline 自愈** —— inbox FIFO 丢失时重置 LAST_SEQ
4. **输出限长** —— stdout 一行摘要，详细 JSON 写文件

```bash
#!/bin/bash
# check-delegated-tasks.sh
# 协调者启动时跑一次，扫描未完成任务的 worker_done
# 用法：bash check-delegated-tasks.sh

STATE_FILE=".remember/state/delegated-tasks.json"
INBOX_LIMIT=100
REPORT_FILE=".remember/state/delegated-scan-$(date +%Y%m%d-%H%M%S).json"

# 1. 读状态文件
if [ ! -f "$STATE_FILE" ]; then
  echo "✅ 委托任务：0 个待跟进"
  exit 0
fi

# 2. 拉 inbox 全量
INBOX=$(orca orchestration inbox --limit $INBOX_LIMIT --json 2>/dev/null)

# 3. Python 评估（PRIMARY: git_log, SECONDARY: inbox, FALLBACK: output_paths）
python3 - <<PYEOF
import json
import subprocess
import os

state = json.load(open('$STATE_FILE', encoding='utf-8'))
inbox = json.loads('''$INBOX''')

# inbox baseline
seqs = [m.get('sequence', 0) for m in inbox['result']['messages'] if isinstance(m, dict)]
inbox_min_seq = min(seqs) if seqs else 0

results = []
for task in state['tasks']:
    if task['status'] != 'dispatched':
        continue

    task_id = task['id']
    rules = task.get('match_rules', {})
    subject_prefix = rules.get('subject_prefix', '')
    body_keywords = rules.get('body_keywords', [])

    # 1. PRIMARY: git log 匹配
    git_signal = False
    git_evidence = []
    for f in task.get('expected_files', []):
        try:
            log = subprocess.check_output(['git', 'log', '--oneline', '-10', '--', f], text=True)
            commits = [l.split()[0] for l in log.splitlines() if l]
            if commits:
                git_signal = True
                git_evidence.append({'file': f, 'commits': commits[:3]})
        except subprocess.CalledProcessError:
            pass

    # 2. SECONDARY: inbox 匹配
    inbox_signal = False
    inbox_evidence = []
    inbox_match = []
    for m in inbox['result']['messages']:
        if not isinstance(m, dict) or m.get('type') != 'worker_done':
            continue
        subject = m.get('subject', '')
        body = m.get('body', '')
        # subject_prefix 精确 OR body_keywords 模糊
        if (subject_prefix and subject.startswith(subject_prefix)) or \
           any(kw in subject + body for kw in body_keywords):
            inbox_signal = True
            inbox_match.append(m)
            inbox_evidence.append({
                'sequence': m.get('sequence'),
                'subject': subject[:60],
                'created_at': m.get('created_at')
            })

    # 3. FALLBACK: output_paths 产物
    output_signal = False
    output_evidence = []
    for p in task.get('output_paths', []):
        if os.path.exists(p):
            output_signal = True
            output_evidence.append(p)

    # 三取二判定
    score = sum([git_signal, inbox_signal, output_signal])
    if score >= 2:
        verdict = 'completed'
    elif score == 1:
        verdict = 'suspected'
    else:
        verdict = 'in_progress'

    # baseline 自愈
    baseline_lost = task['last_seq'] > 0 and task['last_seq'] < inbox_min_seq

    results.append({
        'task_id': task_id,
        'task_title': task['task_title'],
        'score': score,
        'verdict': verdict,
        'baseline_lost': baseline_lost,
        'signals': {
            'git_log': {'match': git_signal, 'evidence': git_evidence},
            'inbox': {'match': inbox_signal, 'evidence': inbox_evidence},
            'output_files': {'match': output_signal, 'evidence': output_evidence}
        }
    })

# 写报告
report = {'scanned_at': '$(date -Iseconds)', 'results': results}
with open('$REPORT_FILE', 'w', encoding='utf-8') as f:
    json.dump(report, f, ensure_ascii=False, indent=2)

# stdout 输出一行摘要
completed = [r for r in results if r['verdict'] == 'completed']
suspected = [r for r in results if r['verdict'] == 'suspected']
in_progress = [r for r in results if r['verdict'] == 'in_progress']

if results:
    summary = f"🔍 委托扫描: {len(completed)} 完成 / {len(suspected)} 疑似 / {len(in_progress)} 进行中"
    if completed:
        items = ','.join([f"{r['task_id']} (git={'+' if r['signals']['git_log']['match'] else '-'} inbox={'+' if r['signals']['inbox']['match'] else '-'})" for r in completed])
        summary += f" — 完成: {items}"
    print(summary)
    print(f"📄 详细: {REPORT_FILE}")
else:
    print("✅ 委托任务：0 个待跟进")
PYEOF
```

#### 步骤 5: 集成到 session-start.sh

**修改：** `.claude/hooks/session-start.sh`

**位置：** 末尾追加（保留原有 session-start 逻辑）

```bash
# 委托任务扫描（2026-08-03 集成）
if [ -f ".claude/scripts/check-delegated-tasks.sh" ]; then
  bash .claude/scripts/check-delegated-tasks.sh
fi
```

---

### 批次 3（步骤 6-7）

#### 步骤 6: 改 SKILL.md 轮询

**关键修改（Claude 评审加固）：**
- 改 `sequence > LAST_SEQ` 替代 timestamp 过滤
- 修正过滤逻辑（删除 `from_handle == COORDINATOR_HANDLE` 这个 bug）
- 用动态 `current_coordinator_handle()` 函数

**位置：** `.claude/skills/delegate/SKILL.md` 轮询脚本段

**修改：**
```python
# 旧（删除）
m.get('created_at','')>='$START_TS' and (
    m.get('to_handle','') == '$COORDINATOR_HANDLE' or
    m.get('from_handle','') == '$COORDINATOR_HANDLE' or
    '$TASK_KEYWORD' in m.get('subject','') + m.get('body','')
)

# 新（替换）
m.get('sequence',0) > $LAST_SEQ and (
    (m.get('subject','').startswith('$SUBJECT_PREFIX')) or
    any(kw in m.get('subject','') + m.get('body','') for kw in $BODY_KEYWORDS)
)
```

#### 步骤 7: 派工流程嵌入状态写入

**修改：** `.claude/commands/orca/delegate.md`

**Step 2 后新增：**
```bash
# 派工完成后立即写入状态
TASK_SLUG="<任务 slug>"
python .remember/tmp/sync-state.py add \
  --id "$TASK_SLUG" \
  --task-title "<人类可读名>" \
  --worker-handle "$HANDLE" \
  --coordinator-handle "<协调者 handle>" \
  --match-rules "{\"subject_prefix\":\"[$TASK_SLUG]\",\"body_keywords\":[\"<kw1>\",\"<kw2>\"]}" \
  --expected-files "<file1,file2>"
```

**Step 5 末尾新增：**
```bash
# 收到 worker_done 并完成校验后，标记完成
python .remember/tmp/sync-state.py complete \
  --id "$TASK_SLUG" \
  --payload "<from inbox>"
```

---

## 🧪 验收测试

### 验收测试 1：状态文件读写（批次 1）

```bash
# 写入
python .remember/tmp/sync-state.py add \
  --id "test-001" \
  --task-title "测试任务" \
  --worker-handle "term_test" \
  --coordinator-handle "term_coord" \
  --match-rules '{"subject_prefix":"[test-001]","body_keywords":["test"]}' \
  --expected-files "test.txt"

# 读取
python .remember/tmp/sync-state.py list
# 期望：id=test-001, status=dispatched

# 标记完成
python .remember/tmp/sync-state.py complete --id "test-001" --payload '{"test":true}'

# 验证
python .remember/tmp/sync-state.py list | grep "test-001"
# 期望：status=completed
```

### 验收测试 2：启动扫描脚本（批次 2）

```bash
# 1. 手动发 worker_done
orca orchestration send \
  --to "term_db1f27a1-1f16-4eaf-a978-12252cc04d0f" \
  --type worker_done \
  --subject "[test-scan] 完成" \
  --body "commit: e69f2f5
verify: test OK"

# 2. 写状态
python .remember/tmp/sync-state.py add \
  --id "test-scan" --task-title "scan-test" \
  --worker-handle "term_test" \
  --coordinator-handle "" \
  --match-rules '{"subject_prefix":"[test-scan]","body_keywords":["test-scan"]}' \
  --expected-files ".remember/state/delegated-tasks.json"

# 3. 跑扫描
bash .claude/scripts/check-delegated-tasks.sh
# 期望 stdout：🔍 委托扫描: 1 完成 / 0 疑似 / 0 进行中 — 完成: test-scan (git=+ inbox=+)
```

### 验收测试 3：跨会话模拟（批次 2）

```bash
# 模拟：手动写状态文件，标记 last_seq 为高序号（模拟 inbox FIFO 丢失）
python .remember/tmp/sync-state.py add \
  --id "test-baseline" --task-title "baseline-test" \
  --worker-handle "term_test" \
  --coordinator-handle "" \
  --match-rules '{"subject_prefix":"[test-baseline]","body_keywords":["test"]}' \
  --expected-files "non-existent.txt"

# 手动 update last_seq = 9999
python .remember/tmp/sync-state.py update-seq --id "test-baseline" --seq 9999

# 跑扫描
bash .claude/scripts/check-delegated-tasks.sh
# 期望 baseline_lost: true, verdict: in_progress (因无 git_sign + 无 inbox match + 无 output)
```

### 验收测试 4：sequence 轮询（批次 3）

```bash
# 派一个简单 worker（10s 内完成）
# 启动轮询脚本
# 观察：
#   - 30s 内检测到 worker_done
#   - 时序：worker_done created_at 之后 30s 内 break
#   - 状态文件 last_seq 已更新
```

---

## 📊 风险评估（评审加固后）

| 风险 | 等级 | 缓解 |
|---|---|---|
| inbox FIFO 丢失 | P0 | git_log PRIMARY + baseline_lost 自愈 |
| worker 模板不合规 | P1 | 三取二判定（不依赖单信号） |
| 多协调者竞争写 | P1 | 乐观锁 `--if-unmodified-since` |
| 关键词冲突 | P1 | subject_prefix 精确 + body_keywords 模糊 |
| 启动扫描性能 | 低 | 100 条 inbox 足够 |
| status schema 演化 | 低 | version 字段 + 兼容读取 |

---

## 🚫 不做范围

- orca CLI `--address-alias` 改造（记入 `hermes/research/orca-roadmap-suggestions.md`，中期）
- 实际跨 session 找回已死 session #10 的 vite.config.ts worker_done（如果 inbox 已被清空）
- 端到端压测（派工 + 死协调者 + 重启恢复完整链路）

---

## ✅ 完成标准

批次 1：
- [ ] 状态文件 schema 文档化
- [ ] sync-state.py 单元测试通过（含并发写测试）
- [ ] remember/INDEX.md 加 state/ 说明
- [ ] 验收测试 1 通过

批次 2：
- [ ] check-delegated-tasks.sh 跑通
- [ ] session-start.sh 集成并实测
- [ ] 验收测试 2、3 通过

批次 3：
- [ ] SKILL.md 轮询代码改 sequence 校验
- [ ] delegate.md 嵌入状态写入步骤
- [ ] 验收测试 4 通过

全部：
- [ ] orca-review 派评 + 集成意见
- [ ] /verify 跑完整验收
- [ ] /done 检查清单走完
- [ ] commit + push
