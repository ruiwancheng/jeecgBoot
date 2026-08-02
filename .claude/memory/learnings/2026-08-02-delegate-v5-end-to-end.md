---
name: delegate-v5-end-to-end-pass
description: /delegate v5 优化（卡死检测 + 30s 轮询 + 协调者发 orca-review）首次端到端跑通——从 orca-review 到 push 完成 22 分钟
metadata:
  type: reference
---

# /delegate v5 端到端首次跑通（2026-08-02 22:11-22:33）

## 任务

采购入库页 Bug#1 选择订单回填供应商 + Bug#2 子表列宽失调。

## 时间线（22 分钟端到端）

| 阶段 | 时间 | 备注 |
|---|---|---|
| brainstorm → plan | 22:00 | 已知上下文，1 轮分析 |
| orca-review 派 Claude | 22:11 | **协调者发**（不是 Pi worker） |
| Claude 评审回报 | 22:20 | 5 维度分析 + 3 修正（warehouseId 不可行 / supplierId 走 selected.record / Drawer 不扩大） |
| plan 修正 | 22:21 | 5 文件 → 3 文件 |
| decompose 判定 | 22:22 | 任务小（≤5 文件），无需切片 |
| 派 pi worker | 22:23 | 精简 preamble 1263 字节 |
| worker commit + push | 22:29 | 5 分钟干活 |
| /verify 协调者补漏 | 22:31 | 发现 DTO orderNo 是死字段（service 没填） |
| 回退冗余字段 commit + push | 22:33 | d71d03f |

## v5 优化首跑实证

| 优化点 | 是否生效 | 证据 |
|---|---|---|
| orca-review 协调者发 | ✅ | Claude 终端 task_fc88258c6902 收到；Pi worker 没卡死 |
| 30s 轮询节奏 | ✅ | 发现 [git commit 已出现，兑底] 信号（首次 false alarm） |
| 卡死信号检测 | ✅ | 没卡死，没触发 ping |
| worker_done 模板 | ✅ | worker 主动发，phase=completed |
| preamble ≤ 1500 字节 | ✅ | 1263 字节 |
| 协调者补漏流程 | ✅ | /verify 发现死字段 → 回退 commit |

## 踩坑记录

### 1. 轮询脚本 grep false alarm
**问题**：轮询脚本 `grep -c "采购入库"` 匹配到了历史 commit message（"采购入库明细..."），误报 `[git commit 已出现，兑底]`

**修复**：grep 应匹配 `git log` 最近 1 条 commit 的 hash，而不是 commit message 中含项目名：
```bash
# 错（匹配 commit message 中任何匹配）
git log --oneline -3 | grep -c "采购入库"

# 对（只看最新 commit hash 是否变化）
LATEST=$(git log --oneline -1)
[ "${LATEST:0:7}" != "EXPECTED_PREVIOUS_HASH" ] && echo "new commit"
```

### 2. 协调者必须 /verify 兜底
**问题**：worker 提交的 commit 不一定完整。Claude 评审标注"orderNo 可选"，worker 误解为"应该加"，加了但 service 没填 → 死字段。

**修复**：
- /verify 必须做（不能只信 worker_done）
- curl 实测字段是否生效
- 死字段立即回退（不囤 PR）
- 修正 commit 单独发（不 amend）

## 端到端 SOP（已验证 22 分钟）

```
1. /brainstorm（1 轮，5 分钟）
2. /plan（出文件清单 + 测试三件套，2 分钟）
3. orca-review（协调者 dispatch Claude，5-8 分钟）
4. 吸收评审意见 → 修正 plan（1 分钟）
5. /decompose 判定（< 5 文件 → 跳过切片，30 秒）
6. 派 pi worker（精简 preamble，30 秒）
7. 30s 轮询等 worker_done（5-10 分钟）
8. /verify：mvn compile + curl 实测（3 分钟）
9. 协调者补漏（如有，1-3 分钟）
10. /session-wrap（1 分钟）
```

## 关联
- skill: `.claude/skills/delegate/SKILL.md`（v5 优化定义）
- command: `.claude/commands/orca/delegate.md`（v5 优化同步）
- commit: 17c9de7（worker 修复）+ d71d03f（协调者补漏）
