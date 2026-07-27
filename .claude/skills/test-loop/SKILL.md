---
name: test-loop
description: 自愈测试循环 — 测试失败 → 自动 debug → 修复 → 重跑 → 人工确认，/test-loop 命令的领域知识
version: 1.0.0
---

# test-loop — 自愈测试循环

## 铁律

- **只修源码，不修测试代码** — 测试是真理，代码是实现
- **最多 3 轮** — 超限停止，标记"需人工排查"
- **不修改测试数据** — 测试数据可能是测试专用的边界值，改了会掩盖问题
- **修复后必须 human-gate** — 禁止 AI 擅自确认修复正确

## 步骤 1：提取失败信息

### 运行测试获取失败日志

```bash
# 运行测试获取失败日志（Windows Git Bash 下 /tmp 映射到 %TEMP%）
npx vitest run <测试文件路径> --reporter=verbose 2>&1 | tee ${TMPDIR:-/tmp}/test-loop-output.log
```

### 从输出中提取

```bash
PY_CMD=$(command -v python3 || command -v python || echo python)
LOG_FILE="${TMPDIR:-/tmp}/test-loop-output.log"
$PY_CMD -c "
import re

with open('$LOG_FILE') as f:
    text = f.read()

# 提取失败用例
failures = re.findall(r'FAIL\s+(.+)', text)
# 提取错误栈中的项目文件
project_files = re.findall(r'(jeecg-boot/.*\.java:\d+)|(jeecgboot-vue3/src/.*\.(vue|ts):\d+)', text)

print('=== 失败用例 ===')
for f in failures:
    print(f'  {f}')
print('=== 涉及文件 ===')
for pf in project_files:
    print(f'  {pf[0] or pf[1]}{pf[2]}')
print('=== 完整错误 ===')
print(text[-5000:])  # 最后 5000 字符
"
```

## 步骤 2：Orca dispatch debug agent

### 找到可用的 agent 终端

```bash
PY_CMD=$(command -v python3 || command -v python || echo python)
orca terminal list --json | $PY_CMD -c "
import json,sys
data = json.load(sys.stdin)
for t in data.get('result',{}).get('terminals',[]):
    print(f'{t[\"handle\"]} | {t.get(\"title\",\"?\")} | writable={t.get(\"writable\",False)}')
"
```

### 创建 debug 任务

```bash
orca orchestration task-create \
  --spec "## 测试失败修复任务

**测试文件**: <测试路径>
**失败用例**: <列表>
**错误信息**: 
<完整堆栈>

## 修复规则（铁律）
1. 只修源码，不修测试代码
2. 最小化修复，不顺手改邻居
3. 修复后说明根因和影响面

## 步骤
1. 读取报错涉及的源码文件
2. 分析根因
3. 修复代码（加 update-begin/end 标记）
4. 输出: 根因 + 修复内容 + 修改文件列表" \
  --task-title "test-loop-<模块名>-$(date +%H%M%S)" \
  --json
```

### dispatch

```bash
orca orchestration dispatch \
  --task <task_id> \
  --to <agent_terminal_handle> \
  --inject
```

### 等待完成

每 30 秒检查 `orca orchestration dispatch-show --task <task_id>`。
配置超时 5 分钟。

## 步骤 3：提取修复结果

从 agent 的 worker_done 消息中提取：
- `filesModified`: 修改的文件列表
- `rootCause`: 根因分析
- `fixSummary`: 修复摘要

## 步骤 4：重跑测试

```bash
npx vitest run <测试文件路径> --reporter=verbose 2>&1
```

### 判定

| 结果 | 动作 |
|------|------|
| 全部通过 | 进入步骤 5 (human-gate) |
| 仍有失败 + 轮次 < 3 | 回到步骤 2（下一轮） |
| 仍有失败 + 轮次 = 3 | 停止，标记"需人工排查" |

## 步骤 5：human-gate

修复成功后：

```
✅ 自动修复完成 — <模块名>

  根因：<rootCause>
  修复：
<git diff>

  测试结果：<N>/<M> 通过

  选项：
  [1] 接受修复 → 可以提交
  [2] 拒绝修复 → 回滚改动
  [3] 我需要看更多细节
```

用 `human-gate` 技能发 `auto-fix` 类型的 decision_gate。

gate resolved 后：
- `accept_fix` → 输出 "✅ 修复已确认，可以 git commit"
- `reject_fix` → `git checkout -- <files>` 回滚

## 3 轮后仍失败

```
⚠️ 自动修复未成功 — 3 轮后仍有 <N> 个失败

  失败用例：
  ├─ <用例1> — <错误>
  └─ <用例2> — <错误>

  修复尝试记录：
  ├─ 轮1: <修复内容> → 未解决
  ├─ 轮2: <修复内容> → <进展>
  └─ 轮3: <修复内容> → 未解决

  建议人工排查方向：<基于 3 轮尝试的分析>

  日志：hermes/logs/test-loop-YYYY-MM-DD-HHmmss.md
```

不触发 human-gate（代码未被修改）。

## 降级

Orca 不可用 → 退化为当前 `/debug` 模式：AI 手动读错误 → 分析 → 展示修复方案 → 等人确认。
