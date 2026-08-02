# `/plan → /decompose` 自动衔接（plan 缓存机制）

**场景**：用户在 `/plan` 确认完整大任务的实施计划后，**立即**调 `/decompose` 把大任务切成小切片。这是用户的核心高频工作流，但两个命令原本是**独立运行**的——用户得在 `/plan` 和 `/decompose` 中两次描述同一任务（如"销售订单模块"），体验差且信息不复用（plan 输出的文件清单、风险点 decompose 看不到）。

**核心洞察**：用户工作流已经是"plan → decompose"，应让命令**自动衔接**而不是让用户重复劳动。

**解决方案：plan 缓存机制**

1. **缓存文件**：`.claude/.last-plan.json`（gitignored，不污染仓库）
   ```json
   {
     "task": "销售订单模块",
     "plan_output": "完整 plan 内容（文件清单+步骤+风险+测试三件套）",
     "timestamp": "2026-07-31T19:30:00+0800"
   }
   ```

2. **`/plan` 命令末尾追加"6.5 写入 plan 缓存"步骤**——plan 完成后自动写缓存

3. **`/decompose` 命令开头追加"步骤 0 检测 plan 缓存"**——自动复用：

| 情况 | 行为 |
|------|------|
| 缓存存在且新鲜（< 30 分钟） | 自动读取 `task` 和 `plan_output`，提示"✅ 检测到 /plan 输出（X 分钟前），自动复用..." |
| 缓存过期（≥ 30 分钟） | 提示"⚠️ 最近的 /plan 输出已过期（X 分钟前），请重新描述大任务"，走正常流程 |
| 缓存不存在 | 走正常流程，要求用户输入大任务描述 |
| `--no-cache <任务>` | 显式忽略缓存，使用输入参数 |
| `--restart <任务>` | 备份旧状态（`.decompose-state.json` → `.decompose-state.json.bak`），重新切片 |

**关键设计点**：
- **30 分钟时效窗口**：平衡"复用便利"和"过期风险"——超过则提示重新描述，避免基于过期 plan 切片
- **缓存失效不删文件**：保留供用户参考，下次 `/plan` 自动覆盖
- **显式覆盖 flag**：`--no-cache` 和 `--restart` 让用户保留完全控制权
- **gitignore 已配置**：`.claude/.last-plan.json` 和 `.claude/.decompose-state.json` 都在根 `.gitignore` 中

**实现要点**（bash 检测逻辑）：
```bash
CACHE_FILE=".claude/.last-plan.json"
CACHE_MAX_AGE_MIN=30

if [ -f "$CACHE_FILE" ] && [[ "$*" != *"--no-cache"* ]] && [[ "$*" != *"--restart"* ]]; then
  CACHE_TIMESTAMP=$(python -c "import json; print(json.load(open('$CACHE_FILE', encoding='utf-8'))['timestamp'])" 2>/dev/null)
  if [ -n "$CACHE_TIMESTAMP" ]; then
    CACHE_AGE_MIN=$(python -c "...")
    if [ "$CACHE_AGE_MIN" -lt "$CACHE_MAX_AGE_MIN" ]; then
      TASK=$(python -c "import json; print(json.load(open('$CACHE_FILE', encoding='utf-8'))['task'])")
      echo "[OK] detected /plan output ($CACHE_AGE_MIN min ago), auto-reuse task='$TASK'"
    fi
  fi
fi
```

**避免**：
- 缓存永远不过期（用户可能基于过期 plan 切片，引入风险）
- 缓存失效就删除文件（失去参考价值，下次还要重新输入）
- 让用户每次都手动加 flag 才能复用（体验差，违背自动衔接初衷）
- 不 gitignore 缓存文件（污染仓库）

**关联命令工作流**：
```
/brainstorm 大任务
  ↓
/plan 大任务  ← 自动写入 .claude/.last-plan.json
  ↓
/decompose 大任务  ← 自动复用 plan 输出
  ↓ 输出切片清单 + .claude/.decompose-state.json
/brainstorm 切片1.1 → /plan → orca-review → 写代码 → /verify → /done
  ↓
git commit slice-1.1-... → 更新状态文件
  ↓
/decompose  ← 检测状态文件 → 提示继续切片1.2
```

**实证**：2026-07-31 `/decompose` 命令落地。集成测试 5/5 通过：
- ✅ 新鲜缓存 + `decompose` → 自动复用 task
- ✅ `--no-cache` → 忽略缓存
- ✅ `--restart` → 备份状态后重启
- ✅ 过期缓存 → 提示重新描述
- ✅ 无缓存 → 走正常流程

**判断信号**：
- 用户连续调用 `/plan` + `/decompose` → 应实现自动衔接（不必让用户手动描述两次）
- 多阶段工作流（如 plan→decompose→execute）→ 中间产物可缓存复用
- 命令间信息冗余（用户需重复描述同一任务）→ 加缓存机制

**适用场景扩展**（不限于 plan→decompose）：
- `/brainstorm` 输出 → `/plan` 自动读取（防止 brainstorm 结论丢失）
- `/verify` 输出 → `/done` 自动读取验证证据
- 多命令工作流中可设计类似的"中间产物缓存"，降低用户重复输入成本