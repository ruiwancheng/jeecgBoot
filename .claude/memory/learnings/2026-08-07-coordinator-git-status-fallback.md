# [2026-08-07] [orchestration] 协调者 git status 兜底 — 派工协议失败时的工作进度验证

**触发条件**：派发任务给独立 AI 工人后，worker_done 因协议层原因（缺 taskId / 工人没 commit / 工人被中断）无法正常回报时，协调者需要**自己判断任务真实进度**。

**处理方式**：

## 1. 核心原则：git 工作区 = 真实工作进度

派工协议失败时（worker_done 被拒、工人超时、工人发不出回报），**不要相信任何"状态"消息**。直接看 git：

```bash
# 1. 看 worker 创建的分支有没有新 commit
git fetch origin
for BRANCH in <worker-branches>; do
  echo "=== $BRANCH ==="
  git log --oneline $BRANCH -3
  echo "本地 vs 远端："
  LOCAL=$(git rev-parse $BRANCH)
  REMOTE=$(git ls-remote --heads origin $BRANCH | awk '{print $1}')
  if [ "$LOCAL" = "$REMOTE" ]; then
    echo "  ✅ 已同步"
  else
    echo "  ⚠️ 不同步"
  fi
done

# 2. 看 main 工作区有没有未提交改动（关键！）
# 工人可能改完代码但忘记 commit
git status --short

# 3. 看 untracked / modified 文件是不是 worker 的任务范围
git diff --stat
```

**判断规则**：
- ✅ 分支有新 commit + 已 push → 任务完成
- ⚠️ main 工作区有大量 modified/untracked → 工人改完代码但没 commit 到正确分支
- ❌ 完全没有改动 → 工人没做（或做了没保存）

## 2. 实战案例：2026-08-07 B4 inventoryAlert 修复

**事件流**：
1. 派工给后端 + 前端 pi 工人（用 `terminal send`，错误协议）
2. 15 分钟轮询，worker_done 一直 0
3. 监听 17 分钟，工人都在 "Working..." 状态
4. **关键发现**：`git status` 列出 `jeecgboot-vue3/src/views/project/mes/basic/inventoryAlert/index.vue | 384 ++++++`（B4 任务实际完成！）
5. 切到 `feat/inventory-alert-enhancement` 分支
6. `git add` + `git commit` + `git push` → B4 成功完成

**没有 git status 兜底**的话，B4 会被误判为 FAILED，B4 代码改动会丢失（下次 `git checkout .` 或 worker 重启会清空）。

## 3. 兜底工具集

### 3.1 监听 worker 时的兜底检查（每 30s 轮询）

```bash
for i in $(seq 1 30); do
  sleep 30
  
  # 1. 首选：worker_done（依赖协议）
  WORKER_DONE=$(orca orchestration inbox --json | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(sum(1 for m in d.get('result', {}).get('messages', [])
    if m.get('type') == 'worker_done' and
       ('[后端 cleanup]' in m.get('subject', '') or
        '[前端 cleanup]' in m.get('subject', ''))))
")
  
  # 2. 兜底：git 工作区状态
  NEW_COMMITS=$(git log --oneline -5 2>&1 | wc -l)
  UNCOMMITTED=$(git status --short 2>&1 | wc -l)
  NEW_BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/heads/ 2>&1 | grep -E "fix/|feat/|hotfix/" | wc -l)
  
  echo "[轮询 #$i] worker_done: $WORKER_DONE | new_commits: $NEW_COMMITS | uncommitted: $UNCOMMITTED | new_branches: $NEW_BRANCHES"
  
  # 3. 兜底判定（worker_done 不到时）
  if [ "$WORKER_DONE" -eq 0 ]; then
    if [ "$NEW_COMMITS" -gt 0 ] || [ "$NEW_BRANCHES" -gt 5 ]; then
      echo "  ⚠️ 工人有 git 活动但没发 worker_done → 协议可能失败，准备 git status 兜底"
    fi
    if [ "$UNCOMMITTED" -gt 5 ]; then
      echo "  ⚠️ main 工作区有未提交改动 → 工人可能忘了 commit"
    fi
  fi
done
```

### 3.2 发现未提交改动时的补救流程

```bash
# Step 1: 切回 main 拉最新
git checkout main
git pull origin main 2>/dev/null

# Step 2: 看工作区状态
git status --short
git diff --stat

# Step 3: 判断这是哪个 worker 的任务（看改动内容）
git diff <filepath> | head -50

# Step 4: 切到正确分支 + 提交
git checkout -b <expected-branch-name>
git add <files>
git commit -m "..."
git push origin <expected-branch-name>

# Step 5: 状态文件更新
echo "✓ BUG-X 兜底提交成功，commit: $(git rev-parse HEAD)"
```

## 4. 适用场景

| 场景 | 兜底检查 |
|---|---|
| 派工协议失败（worker_done 被拒）| git log + git status 看实际进展 |
| 工人超时（30+ 分钟无活动）| git log 看有没有新 commit，没动 → 杀工人重派精简版 |
| 工人说"做完了"但没发 worker_done | git log 验证 commit + push 状态 |
| 多个 worker 并行（后端 + 前端）| 区分各自分支 + main 工作区 |
| worker 提交到错分支（如 B3 提交到 B4 分支）| git for-each-ref 对比各分支最新 commit 是否与任务匹配 |

## 5. 与 worker_done 协议的关系

| 维度 | worker_done 协议 | git status 兜底 |
|---|---|---|
| 实时性 | 协议层消息 | git 状态（准实时，毫秒级）|
| 准确性 | 依赖工人自觉 | **git 是事实来源**（worker 不撒谎）|
| 协议依赖 | 强（需要 taskId）| 无（只看 git）|
| 适用 | 协议正常时 | **协议失败时 + 任何时点的兜底** |

**核心原则**：worker_done 是"信号"，git status 是"事实"。永远以事实为准。

## 6. 复盘改进

派工协议失败教训（2026-08-07）：
- ❌ 直接 `terminal send`（缺 taskId）→ worker_done 全部被拒
- ❌ 协调者代发 worker_done（也缺 taskId）→ 也被拒
- ✅ 协调者用 git status 兜底 → 4/4 任务完成

**下次派工必须用**：
```bash
# 正确流程（task-create + dispatch）
TASK_ID=$(orca orchestration task-create --spec "..." --task-title "..." --json | jq -r .result.task.id)
orca orchestration dispatch --task $TASK_ID --to $WORKER --inject
# 工人完成后正确发 worker_done
```

详见 `2026-08-07-orchestration-taskid-required.md` learning。

## 7. 协调者必备检查清单

派工后**每 5 分钟**至少做一次 git status 兜底：

```bash
# 快速检查（5 秒）
git status --short | head -10
git log --oneline -5 | grep -E "fix:|feat:|hotfix:" 
```

**判定**：
- ✅ `git log` 看到 fix:/feat:/hotfix: 新 commit → 任务进行中
- ⚠️ `git status` 看到大量 modified → 工人可能忘了 commit（紧急联系）
- ❌ `git log` + `git status` 都没变化 → 工人卡死，杀 + 重派

## 关联

- `2026-08-07-orchestration-taskid-required.md` — 派工协议 taskId 必填
- `2026-08-07-regression-double-review.md` — 3 步流程 + 状态文件
- `2026-08-07-regression-review-workflow.md` — 业务人员复核工作流
- `.claude/commands/orca/delegate.md` — /delegate 完整协议
