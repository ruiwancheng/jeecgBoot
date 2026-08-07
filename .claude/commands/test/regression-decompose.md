<!-- update-begin---author:pi---date:2026-08-07---for:【REGRESSION-DECOMPOSE】新增真实 BUG 切片处理命令，参考 /decompose 把真实 BUG 切成可执行的开发任务 -->
---
description: 自有命令 — 真实 BUG 切片处理：把回归双重复核确认的真实 BUG 按 /decompose 模式切成可验收的开发任务
---

# /regression-decompose --run-dir <run-id>

回归双重复核**完成后**（`/regression-review` 已确认所有真实 BUG），参考 `/decompose` 把真实 BUG 切成可验收的开发任务：
1. 真实 BUG 按 P0/P1/P2 分级
2. 每个 BUG 转成 1 个 cleanup 任务（带验收标准）
3. 派发给对应负责人（前端/后端/cleanup 脚本）

> **为什么必要**：2026-08-07 回归发现 3 个真实 BUG（other-stock-in 精度丢失 P1 / traceabilityBatch #4 抽屉渲染 P1 / purchase-mesCostLog 权限码 P0），如果不切片处理，容易遗漏 / 重复 / 责任不清。

## 使用方法

```bash
/regression-decompose                              # 自动用最近一次 run-dir，处理所有真实 BUG
/regression-decompose --severity P0                # 只处理 P0（最高优先级）
/regression-decompose --owner backend              # 只处理后端 BUG
/regression-decompose --run-dir 20260807-032053    # 显式指定
```

## run-dir 自动检测（与 regression-review / regression-retro 共享）

```bash
RESOLVE_RUN_DIR() {
  local EXPLICIT="$1"
  if [ -n "$EXPLICIT" ]; then echo "$EXPLICIT"; return; fi
  if [ -f ".claude/.regression-state.json" ]; then
    local STORED=$(python -c "import json; d=json.load(open('.claude/.regression-state.json')); print(d.get('last_run_dir',''))" 2>/dev/null)
    if [ -n "$STORED" ] && [ -d "harness/.regression-runs/$STORED" ]; then echo "$STORED"; return; fi
  fi
  if [ -d "harness/.regression-runs" ]; then
    local LATEST=$(ls -t harness/.regression-runs/ 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then echo "$LATEST"; return; fi
  fi
  echo "ERROR: 无法确定 run-dir" >&2; exit 1
}

RUN_ID=$(RESOLVE_RUN_DIR "$1")
```

## 必须加载

1. `/decompose`（复用切片模板 + 反模式清单）
2. 当前回归报告：`harness/.regression-runs/<run-id>/regression-report.md`（自动检测 run-dir）
3. 真实 BUG 的原始日志 / 复核证据

## 工作流（6 步）

### 0. 解析 run-dir（自动）

```bash
RUN_ID=$(RESOLVE_RUN_DIR "$1")
```

### 1. 抽取所有真实 BUG

从报告第四节「复核结果」section 抽取所有判定为「真实 BUG」的切片：

```bash
# 抽取真实 BUG
grep -B 1 -A 4 "真实 BUG" harness/.regression-runs/$RUN_ID/regression-report.md | head -200
```

输出真实 BUG 清单：

| 切片 | 严重度 | 业务原因 | 跟进负责人 |
|---|---|---|---|
| 4.2 other-stock-in 精度 | P1 | 后端落库 4 位小数被截断为 2 位（`18.6765 → 18.68`）| 后端工程师 |
| 4.2 traceabilityBatch #4 | P1 | 抽屉未显示"批次流水"标题/流水表 | 前端工程师 |
| 4.4 purchase-mesCostLog | P0 | 权限码 `mes:purchase:costLog:list` 未注册到 sys_permission | 后端工程师 |
| 4.6 inventoryAlert × 5 | P2 | 库存预警页面功能单调（无搜索/导出/新增/筛选）| 前端工程师（优化排期）|
| ... | ... | ... | ... |

### 2. 按 P0/P1/P2/P3 分级 + 排序

| 严重度 | 处理时效 | 跟进方式 |
|---|---|---|
| **P0 (阻塞)** | 24h 内 hotfix | 立即派发到对应 owner |
| **P1 (主流程)** | 1 周内修复 | 进 issue tracker 排期 |
| **P2 (次要)** | 2 周内优化 | 进优化 backlog |
| **P3 (无需跟进)** | 文档记录 | 归档即可 |

### 3. 每个真实 BUG 切成 1 个 cleanup 任务（6 要素）

参考 `/decompose` 的 6 要素（业务名+用户路径、验收标准、依赖、风险、工作量、Rollback），为每个真实 BUG 写一份任务卡：

```markdown
# Cleanup Task: <bug-name-kebab>

## 业务名
<real_bug_title>

## 用户路径
- 复现路径：<from regression-report.md>
- 操作步骤：<from scenario-metadata.steps>
- 预期：<from scenario-metadata.expected>
- 实际：<from regression-report 实际结果>

## 验收标准
- [ ] <具体可验证点 1>
- [ ] <具体可验证点 2>
- [ ] 回归测试 <slice-id> 通过

## 依赖
- <依赖的服务/前端组件/数据库表>

## 风险
- <low/medium/high> + 原因

## 工作量
- <small/medium/large> + 估算

## Rollback
- <如何回滚>

## Owner
- <前端工程师/后端工程师/cleanup 脚本任务>

## 关联
- 回归报告：harness/.regression-runs/<run-id>/regression-report.md#4.X
- 原始日志：harness/.regression-runs/<run-id>/logs/<slice-id>.attempt-1.log
- issue 复核：hermes/eagle-eye/reports/<date>/issues/<spec>.md
```

### 4. 派发任务（按 owner 分类）

按 owner 分类批量派发：

```bash
# 后端 P0（mesCostLog 权限码）
/delegate 修复 purchase-mesCostLog 权限码 — 详见 .claude/cleanup-tasks/2026-08-07-fix-mes-costlog-permission.md

# 后端 P1（other-stock-in 精度）
/delegate 修复 other-stock-in 精度丢失 — MesOtherStockInServiceImpl:190 等多处 setScale(2) 改 setScale(4)

# 前端 P1（traceabilityBatch #4 抽屉渲染）
/delegate 修复 traceabilityBatch 抽屉未显示"批次流水" — TraceabilityDrawer.vue 排查 v-if/mounted/data 未就绪

# 前端 P2（inventoryAlert 优化）
/delegate 优化 inventoryAlert 页面（5 个新功能）— 加搜索/查询/导出/新增/抽屉/筛选
```

每个 `/delegate` 调用：
1. 用 `/cleanup-context` 生成记忆卡片
2. 用 `orca terminal create --command "codex" --json` 创建独立 AI
3. 派发任务，**等 worker_done 回报**
4. 收到回报后跑 `/verify` 验证
5. `/done` 关闭

### 5. 状态跟踪

每个 cleanup 任务写入 `.claude/cleanup-tasks/<date>-<bug-name>.md`，并在 issue tracker 中创建对应工单（如果团队用 Jira/GitHub Issues）。

### 6. 更新状态文件（decompose 完成后）

```bash
# decompose 完成后 → next_step = completed
UPDATE_STATE() {
  python -c "
import json, datetime
state_file = '.claude/.regression-state.json'
state = json.load(open(state_file, encoding='utf-8')) if __import__('os').path.exists(state_file) else {}
state['next_step'] = 'completed'
state['updated_at'] = datetime.datetime.now().isoformat()
json.dump(state, open(state_file, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
"
}
UPDATE_STATE
```

## 反模式清单

| ❌ 反模式 | 危害 |
|---|---|
| 多个真实 BUG 混在 1 个任务 | 责任不清 / 一个失败阻塞其他 |
| 真实 BUG 切片不带验收标准 | 完成后无法验证 |
| 真实 BUG 切片不写 Rollback | 出问题无法回滚 |
| 真实 BUG 切片不关联回归报告 | 后续无法追溯 |
| 跳过 P0 直接做 P1 | 阻塞问题积压 |

## 验证清单（必走）

- [ ] 所有真实 BUG 已抽取（按 P0/P1/P2/P3 分级）
- [ ] 每个真实 BUG 有 1 份 cleanup 任务（6 要素）
- [ ] cleanup 任务已派发到对应 owner
- [ ] worker_done 回报已收到 + 验证通过
- [ ] 真实 BUG 已进 issue tracker
- [ ] 下次回归跑前所有 cleanup 任务已 close

## 关联命令

- `/test-regression` — 跑回归测试
- `/regression-review` — 双重复核（前序，共享 run-dir 自动检测）
- `/regression-retro` — 误判复盘（平行，共享 run-dir 自动检测）
- `/decompose` — 大任务切片（模板复用）
- `/delegate` — 派发 cleanup 任务
- `/verify` — 验证 cleanup 任务完成
- `/done` — 关闭 cleanup 任务

## 参考

- 起源：2026-08-07 回归复盘，3 个真实 BUG
- 详细真实 BUG 清单：`harness/.regression-runs/20260807-032053/regression-report.md` 第四节
- 双重复核流程：`/regression-review`
- 误判复盘流程：`/regression-retro`
<!-- update-end---author:pi---date:2026-08-07---for:【REGRESSION-DECOMPOSE】 -->
