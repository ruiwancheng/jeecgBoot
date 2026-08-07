# Codex 作为 /delegate worker 的端到端能力验证

**日期**：2026-08-07
**上下文**：v3 孤儿行清理方案 6 阶段实施
**验证场景**：8 个 slice 全部由 codex（独立 codex 终端 `term_893f7603`）通过 Orca orchestration 完成

## TL;DR

Codex 可以作为 `/delegate` worker 的**完整替代**，不限于只做评审。代码编辑 + commit + push + 验证全流程都稳定。/delegate 命令当前只支持 pi，但实际工作流（orca dispatch → worker 干活 → 收产物）codex 完全胜任。

## 验证过程

### 派工链路（已稳定运行）

```bash
# 1) 创建 run
RUN_ID=$(orca orchestration run-create --objective "..." --json | jq -r .result.run.id)

# 2) 创建 task
TASK_ID=$(orca orchestration task-create --run "$RUN_ID" \
  --spec "$(cat preamble.md)" \
  --task-title "slice-N-..." --json | jq -r .result.task.id)

# 3) 注入到 codex 终端（已存在的 term_xxx）
orca terminal send --terminal term_xxx --text "$(cat preamble.md)" --enter

# 4) 监听产物
while sleep 30; do
  git log --oneline -1 | grep "slice-N" && break
done
```

### 8 个 slice 全部 commit 落地

| Slice | commit | 用时 |
|---|---|---|
| 1 UI | `a6d549f` | ~3min |
| 2 后端 | `e4e8aae` | ~10min |
| 2-fix | `372500f` | ~3min |
| 3 守卫 19 checker | `8422eb8` | ~10min |
| 3-fix | `3daaa57` | ~3min |
| 4 性能优化 | `c31eb60` | ~10min |
| 5 测试 | `8a7e071` | ~10min |
| 6 Runbook | `6147fde` | ~5min |

**总用时**：~55 分钟（含 codex 自查错误修复）
**总产出**：8 commits / 1300+ 行 / 5 个新模块

## Codex vs Pi：能力对比

| 维度 | codex | pi |
|---|---|---|
| 阅读代码 | ✅ 全 | ✅ 全 |
| 编辑代码 | ✅ 稳定 | ✅ 稳定 |
| Commit + Push | ✅ 稳定（需审批） | ✅ 稳定 |
| 多文件改动 | ✅ 强（context 大） | �️ 中（容易 context 爆炸） |
| 长时间任务 | ✅ 稳定（55 分钟不卡） | ⚠️ 易卡（>20 分钟需谨慎） |
| 自查 bug | ✅ 强（v2 评审遗漏的 LEFT JOIN bug 被 codex 自查发现） | 弱 |
| 业务理解 | ⚠️ 弱（需详细 prompt） | ✅ 强（懂 jeecg 业务） |
| 工作流遵循 | ⚠️ 易偏离（需 preamble 强约束） | ✅ 强 |

## 关键约束（派 codex 时必须）

1. **prompt 必须详细**：preamble 含文件路径、commit message、验收标准、硬规则清单
2. **审批敏感操作**：git push / git add 等需要审批（codex 会问 yes/no）
3. **必须发 worker_done**：但 Orca runtime 经常 stale_bootstrap 报错，需要协调者兜底
4. **不要中途打断**：codex 在 commit 时如果被打断会卡死，需发"y"+Enter 批准

## 推荐工作流

```
Plan + /decompose 切片
  ↓
每个 slice 派 codex worker（独立 review terminal 不影响实现）
  ↓
协调者轮询 git log 看产物
  ↓
派独立 codex review terminal 做评审
  ↓
修复 commit 也派 codex
  ↓
派第二轮复评审
  ↓
全部 slice 完成 → release notes + 发版
```

## 不推荐做法

- ❌ 让 codex 做大型跨模块重构（>50 文件）
- ❌ 让 codex 写业务文档（不如 pi）
- � 单次派工 >30 分钟任务（context 可能爆）
- ❌ 不带 preamble 的"自由发挥"派工（codex 容易跑偏）
