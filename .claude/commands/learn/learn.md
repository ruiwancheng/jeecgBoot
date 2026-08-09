---
description: 自有命令 — 经验捕获：回顾会话、提取1-3条可复用模式、写入经验库
---

# /learn

从会话提取可复用经验。

## 流程
1. 回顾会话，识别可复用模式
2. 提取 1-3 条高价值经验
3. 写入 `.claude/memory/learnings/`
4. **判断是否需同步 MEMORY.md**（2026-08-09 升级）：
   - 模块缩写变更（新业务模块、新表前缀）→ 追加到 MEMORY.md "模块缩写表"
   - 状态机变更（新增/重命名状态、转移条件）→ 同步到 MEMORY.md "状态机速查"
   - 术语变更（业务人员使用的术语改变）→ 更新 MEMORY.md 对应条目或新建索引
   - 不是上述类别 → 仅写 learnings/，跳过 MEMORY.md

**格式规范**：`[日期] [类别] 标题 | 触发条件 | 处理方式`

### 5. 同步 features.json（2026-08-09 升级）

新增业务模块时，**必须**同步 `hermes/features.json`：
- 模块缩写变更 → `features.json` 追加 `modules[]` 条目
- MEMORY.md 模块缩写表 与 features.json 保持一致

> 判定优先级：模块缩写 > 状态机 > 术语 > 其他（仅 learnings/）。**强制触发**（前三类必须同步 MEMORY.md）。

### 6. 同步 business-chains.json（2026-08-09 升级）

状态机转移条件变更时，同步 `hermes/business-chains.json`：
- 新增/重命名状态 → 更新对应 chain 节点
- 转移条件变更 → 更新 `criticalPaths`
