# 3 轮 Codex 评审闭环：每轮都对应实质性修复

**日期**：2026-08-07
**上下文**：v3 孤儿行清理方案经历了 3 轮独立 Codex 评审 + 2 轮 Slice 复评审
**经验**：多轮评审不是"重复"，每轮都发现前轮未识别的实质问题

## TL;DR

| 轮次 | 评分 | 关键发现 |
|---|---|---|
| v1 评审 | 7.5/10 | P0-1 SQL 注入 / P0-2 HTTP 414 / P0-3 守卫漏洞 |
| v2 评审 | 8.7/10 | P0 守卫覆盖不完整（19 vs 16 张表）/ CRITICAL bug / 性能 |
| v3 评审 | 9.2/10 | 综合判定通过 |
| Slice 1+2 复评审 | 8.6/10 | 通过（修复闭环） |
| Slice 3 复评审 | 6.3/10 | P0：removeByIds bypass 守卫（实现者漏改方法重载） |

**5 轮评审合计**：找 4 P0 + 6 P1 + 1 CRITICAL bug，全部修复。

## 每轮评审的独特价值

### v1 评审（7.5/10）

**发现 P0 设计缺陷**：
- SQL 注入风险（Mapper 用 `${ids}` 字符串插值）
- HTTP 414 风险（DELETE + query string 传大批 ID）
- 守卫逻辑漏洞（qty=0 inventory 行仍产生新孤儿）

**修复后**：v2 方案文档引入 foreach + POST + body + 守卫语义升级

### v2 评审（8.7/10）

**发现 v1 评审遗漏**：
- 守卫覆盖表清单 16 vs 19 张（v1 说 19 但只列 16）
- v2 评审自己说"v2 实际覆盖率 100%"（v1 评审扣分应归还）
- CRITICAL bug：JdbcTemplate 参数绑定（19 个 `?` 但只传 1 个值）
- 性能问题（19 次 round-trip → UNION ALL 一次聚合）

**修复后**：v3 方案引入 MaterialReferenceAggregator + CoverageAssertor + SysDictCache + CriticalTableLockService 4 个新组件

### Slice 1+2 复评审（8.6/10）

**发现修复引入的新问题**：
- P0：后端 `selectInventoryWithMaterial` 没返回 `isOrphan` 字段（前端 UI 全静默失效）
- P0：export xlsx 外衣但 body 是 plain text
- P1：batchDeleteOrphan 无 FOR UPDATE（TOCTOU）
- P1：operator 写死 'system'

**修复后**：commit `372500f` 加 isOrphan 字段 + 移除 LEFT JOIN 的 del_flag 过滤（实现者自查发现）

### Slice 3 复评审（6.3/10）

**发现实现者重写时遗漏方法重载**：
- P0：`MesMaterialServiceImpl.removeByIds(Collection)` 完全 bypass 19 checker 守卫
- `/deleteBatch` 端点直接走这个方法

**关键教训**：实现者重写 `removeById` 时只改了单条方法，忘了 `removeByIds(Collection)` 重载。

**修复后**：commit `3daaa57` 加守卫循环

## 关键洞察

### 1. 评审不是"找茬"，是"互补视角"

- v1 评审员：刚看 plan 文档 → 找 P0 设计缺陷
- v2 评审员：看了 v1 评审 → 找 v1 漏判的覆盖表 + 性能
- 复评审员：看了实现 → 找实现引入的回归 bug

### 2. 实现者自查能发现更深层 bug

codex 修复 v2 评审的 P0-1 时，自查发现：
```sql
-- 原 SQL 有过滤 bug
LEFT JOIN c_mes_material m ON i.material_id = m.id AND m.del_flag = 0
-- 这个 AND m.del_flag = 0 会让软删物料的 m.id NULL → isOrphan CASE 永远 '0'
```

**修复**：移除 `AND m.del_flag = 0`，让 LEFT JOIN 不再过滤。

这种深层 bug 评审员不一定能发现，但实现者在改代码时能注意到。

### 3. 多轮评审的 ROI

| 轮次 | 评分提升 | 时间成本 | 价值 |
|---|---|---|---|
| v1 → v2 | +1.2 | 30min | 高（找 P0） |
| v2 → v3 | +0.5 | 20min | 中（找遗漏 + 性能） |
| Slice 1+2 复评 | +1.5 | 15min | 高（找修复引入 bug） |
| Slice 3 复评 | +3.3 | 10min | **极高**（找方法重载遗漏） |

**结论**：每轮评审都"值回票价"，尤其复评审能找实现引入的回归。

### 4. 复评审必须有独立 terminal

派 codex 评审时，必须用**全新独立终端**（不要用实现者同一终端）。否则：
- 实现 terminal 的 context 偏见会影响评审
- 评审 terminal 看不到自己刚写的代码

**做法**：
```bash
# 创建新 codex terminal
orca terminal create --command "codex" --json
# 拿到新 handle，dispatch 评审任务
orca terminal send --terminal <new_handle> --text "<评审 prompt>" --enter
```

## 不推荐做法

- ❌ 单轮评审就发布（v1 评分 7.5 仍有 P0）
- ❌ 不做复评审（修复可能引入新 bug）
- ❌ 用实现者同一终端做评审（context 偏见）
- ❌ 跳过 v2/v3 评审（每轮都有独特价值）
