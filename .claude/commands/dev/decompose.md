---
description: 自有命令 — 大任务拆分：按页面顶层+子功能细分，输出手工可验证的切片清单+状态文件
---

# /decompose <大任务描述>

把大型开发任务拆成**手工可验证**的小切片，每个切片都能在浏览器里走一遍验收。

## 与其他命令的关系

| 命令 | 何时用 |
|------|--------|
| `/brainstorm` | 需求澄清（先聊清楚做什么） |
| **`/decompose`** | 任务切片（聊清楚后，把大任务切成可验收的小片） |
| `/plan` | 单切片实施计划（每个小片自己再走标准工作流） |
| `/orca-review` | 单切片评审 |
| `/verify` | 单切片验证 |
| `/done` | 单切片完成 |

**铁律：** `/decompose` **只切片不执行**。每个切片自己再走 `/brainstorm → /plan → orca-review → 写代码 → /verify → /done`。

---

## 流程

### 0. 检测 plan 缓存（自动复用）

执行 `/decompose` 时，**先**检测 `.claude/.last-plan.json` 是否存在：

| 情况 | 行为 |
|------|------|
| **缓存存在且新鲜（< 30 分钟）** | 自动读取 `task` 和 `plan_output` 作为输入；提示 `✅ 检测到 /plan 输出（X 分钟前），自动复用...` |
| **缓存过期（≥ 30 分钟）** | 提示 `⚠️ 最近的 /plan 输出已过期（X 分钟前），请重新描述大任务`；走正常流程 |
| **缓存不存在** | 走正常流程，要求用户输入大任务描述 |
| **`--no-cache <任务>`** | 显式忽略缓存，使用输入参数 |
| **`--restart <任务>`** | 备份旧状态（`.decompose-state.json` → `.decompose-state.json.bak`），重新切片 |

**实现：**

```bash
CACHE_FILE=".claude/.last-plan.json"
CACHE_MAX_AGE_MIN=30

if [ -f "$CACHE_FILE" ] && [[ "$*" != *"--no-cache"* ]] && [[ "$*" != *"--restart"* ]]; then
  CACHE_TIMESTAMP=$(python -c "import json; print(json.load(open('$CACHE_FILE', encoding='utf-8'))['timestamp'])" 2>/dev/null || echo "")
  if [ -n "$CACHE_TIMESTAMP" ]; then
    CACHE_AGE_MIN=$(python -c "
import json, datetime
with open('$CACHE_FILE', encoding='utf-8') as f:
    ts = json.load(f)['timestamp']
for fmt in ('%Y-%m-%dT%H:%M:%S%z', '%Y-%m-%dT%H:%M:%S'):
    try:
        ct = datetime.datetime.strptime(ts, fmt)
        break
    except: continue
now = datetime.datetime.now(ct.tzinfo)
print(int((now - ct).total_seconds() / 60))
")
    if [ "$CACHE_AGE_MIN" -lt "$CACHE_MAX_AGE_MIN" ]; then
      TASK=$(python -c "import json; print(json.load(open('$CACHE_FILE', encoding='utf-8'))['task'])")
      echo "[OK] detected /plan output ($CACHE_AGE_MIN min ago), auto-reuse task='$TASK'"
      # 跳到步骤 1（已自动获取 task 和 plan_output）
    else
      echo "[WARN] plan output expired ($CACHE_AGE_MIN min ago), please re-describe task"
    fi
  fi
fi
```

> 缓存失效后**不删除**文件（保留供用户参考），下次 `/plan` 会覆盖。

### 1. 加载领域知识

使用 `decompose` 技能获取：
- 拆分原则（6 要素）
- 反模式清单（8 条）
- 粒度判断规则（页面复杂度、子功能粒度）
- 切片模板

### 2. 需求解析

- 提取模块名（如"销售订单"）
- 提取业务目标（如"实现订单的全生命周期管理"）
- 列出关键操作流（新建/编辑/作废/审核/导出等）

**复用 plan 缓存时：** 直接从 `plan_output` 中提取已识别的页面、文件清单、操作步骤（无需重新解析）。

### 3. 页面识别（顶层切片）

- 列出所有页面（路由路径）
- 每个页面标注复杂度：**simple**（每页 1 个功能，如字典） / **complex**（每页多个操作，如订单列表页含新建+编辑+作废+审核）
- 输出顶层切片清单

### 4. 子功能细分（仅 complex 页面）

- 每个 complex 页面内的子功能
- 每个子功能标注 **6 要素**（业务名+用户路径、验收标准、依赖、风险、工作量、Rollback）
- simple 页面：顶层 1:1 对应 1 个子功能（直接以页面为子切片）

### 5. 粒度自检（强制）

参考 `decompose` 技能中的"粒度自检清单"，逐项 ✓/✗：
- 首个切片能跑通最小闭环（打开页面 → 新建 → 列表显示）
- 每个子切片都有用户操作路径 + UI 验收标准
- 风险等级已标注（高/中/低）
- 工作量估算已标注（小/中/大）
- Rollback 策略已标注
- 依赖关系无循环
- 无 ≤5 行的过细子切片
- 无违反 8 条反模式的切法

### 6. 输出切片清单

按依赖顺序排序，输出：
- 每个切片的 **6 要素**
- **commit 命名规范**：`slice-<顶层ID>.<子ID>-<业务名-kebab>`
- **token 成本预估**（详见下方"Token 成本披露"表）
- **首个推荐切片**（最小闭环，能立刻动手）

### 7. 状态持久化

写入 `.claude/.decompose-state.json`：
```json
{
  "task": "<大任务>",
  "created_at": "<ISO 时间>",
  "updated_at": "<ISO 时间>",
  "slices": [
    {
      "id": "1",
      "name": "<页面名>",
      "page": "<路由>",
      "type": "page-level",
      "complexity": "simple | complex",
      "status": "pending | in_progress | done | blocked",
      "current_child": "1.2",
      "children": [
        {
          "id": "1.1",
          "name": "<子功能名>",
          "type": "feature",
          "status": "pending | in_progress | done | blocked",
          "commit": "<commit hash>",
          "user_path": "...",
          "acceptance": "...",
          "depends_on": ["..."],
          "risk": "low | medium | high",
          "effort": "small | medium | large",
          "files": [],
          "rollback": "..."
        }
      ]
    }
  ]
}
```

**状态恢复：** 下次输入 `/decompose`（不带参数）且状态文件存在 → 进入"继续模式"，提示上次进度。

---

## 反模式清单（必须主动警告）

| ❌ 反模式 | 为什么不能用 |
|-----------|-------------|
| 先做完所有 Entity | 用户看不到结果 |
| 先做完所有 Service | 没 Controller 调用 = 白做 |
| 先做完所有 Vue 列表 | 没增删改 = 花瓶页面 |
| 先做完所有后端接口 | 没前端 = 不可用 |
| 按代码文件类型分片 | 任何一片都跑不通 |
| 全建表（一次性建好所有 Entity） | 用户看不到结果 |
| 按菜单结构切 | 菜单层级 ≠ 业务场景 |
| 先做权限 | 权限依赖功能完成，先做权限 = 空中楼阁 |

---

## 粒度判断规则

| 页面复杂度 | 处理 |
|----------|------|
| **simple**（每页 1 个功能，如字典管理） | 顶层 = 子切片（1:1） |
| **complex**（每页多个操作，如订单列表页） | 顶层 + 子功能细分 |

子功能粒度：

| 代码行数 | 处理 |
|---------|------|
| **≤5 行** | 必须合并到相邻子功能 |
| **6-50 行** | 独立子功能 |
| **\>50 行** | 考虑再拆 |

---

## Token 成本披露

| 切片规模 | orca-review 模式 | Token 消耗 |
|---------|-----------------|----------|
| ≤3 文件 | 免评审 | 0 |
| 4-10 文件 | 轻量评审 | ~30K |
| \>10 文件 | 完整评审 | ~150K |

> 每个切片自带成本预估，让用户决策。

---

## 已知限制

- **命令文件膨胀**：随项目沉淀规则会越来越长 → 定期回顾
- **"端到端可手工验证"定义稀释**：执行中容易跑偏变成"按层切" → 输出前自检
- **plan 缓存依赖手动刷新**：超过 30 分钟不会自动失效，需重新 `/plan`

---

## 与后续工作流的衔接

```
/brainstorm 大任务
  ↓
/plan 大任务
  ↓ (写入 .claude/.last-plan.json)
/decompose 大任务  ← 自动复用 plan 输出
  ↓ 输出切片清单 + .claude/.decompose-state.json
用户确认首个切片
  ↓
/brainstorm 切片1.1 → /plan → orca-review → 写代码 → /verify → /done
  ↓
git commit slice-1.1-... → 更新状态文件
  ↓
/brainstorm 切片1.2 → ...
```

每片完成后强制：
1. `git commit slice-<ID>-<业务名-kebab>`
2. `/verify`（自动嵌入到 done 流程）
3. 后端健康检查（`curl getEncryptedString`）
4. 更新状态文件（status → done，记录 commit hash）

---

## 停止/恢复

- 随时说"停止" → 当前切片完成即可停（不留半成品）
- 重新进入 → 输入 `/decompose`（无参数）→ 检测状态文件 → 提示继续

---

## 复杂度自适应的快速通道

| 输入 | 处理 |
|------|------|
| `/decompose 销售订单` | 完整流程（需求解析 → 页面识别 → 子功能细分 → 自检 → 输出 → 状态文件）；自动复用 plan 缓存 |
| `/decompose`（无参数） | 检测 `.decompose-state.json` → 进入"继续模式" |
| `/decompose --no-cache 销售订单` | 忽略 plan 缓存，使用输入参数 |
| `/decompose --restart 销售订单` | 备份旧状态（`.decompose-state.json` → `.decompose-state.json.bak`），重新切片 |