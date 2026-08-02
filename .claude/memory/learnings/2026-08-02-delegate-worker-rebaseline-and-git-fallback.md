# /delegate 派工时工人必须现状摸底 + 协调者 git 兜底判完成

**触发条件：** 任何 `/delegate <任务>` 派发场景 — 协调者写的记忆卡片基于历史审计/旧快照（可能是几天/几周前的状态），而工人接收时实际代码可能已演进。

## 处理方式

### 工人端：先摸底，再写代码（强制第 0 步）

记忆卡片里的"修复方向"是**基于派发时刻的信息**，不是实时状态。工人收到任务后必须：

1. **读记忆卡片 + 审计报告** — 理解任务背景和 P0/P1 清单
2. **现状摸底（必做，不要跳）**：
   - `git log --all --oneline | grep -E "<关键词>"` — 看历史 commit 是否已修
   - `grep -rn "<修复模式>" <相关模块>` — 看代码当前实现
   - `git blame <file>:<line>` — 看 P0 行号的最近修改
3. **判定修复必要性**：
   - 已修 → 在 commit message 里说明"已在 V<版本> 阶段修复，不重复造轮子"
   - 未修但需要决议 → 写 ADR 引用（如"ADR 0002 拍板前保留现状"）
   - 真要修 → 按 plan 改文件 + update-begin/end + commit
4. **不要盲目按记忆卡片改代码** — 记忆卡片是"任务输入"，不是"任务答案"

### 协调者端：worker_done 没发 ≠ 没完成

按 `delegate/SKILL.md` 强制校验清单：
- [ ] worker_done 已发 ← 这条**不是硬阻塞**

**真实判定**：git commit + push 已执行 + 改动落在任务范围内 → 视为完成。

**git 兜底流程**：
```bash
# 工人 worker_done 未到时
git log --oneline -5 | grep <slice-id-or-keyword>  # 看是否有新 commit
git log origin/main --oneline -3                    # 看是否已 push
git show <commit-hash> --stat                       # 看改动范围是否合理
```

如果 commit hash + 改动范围 + mvn compile 三者都对，**不要死等 worker_done**。

## 实证

**2026-08-02 P0-1~P0-5 批次管理修复任务**（5-8h 估时，阻塞发布）：

| 阶段 | 事件 |
|---|---|
| 19:21:52 | 主会话派发 v1 工人（v4.0 完整 preamble 7786 字节） |
| 19:30+ | v1 僵死（buffer 仅 TUI busy 字符，6+ 分钟无实质输出） |
| 19:35:?? | 关闭 v1 + 创建 v2 工人 + 注入精简 preamble（1514 字节，跳过 orca-review） |
| 19:36+ | v2 工人**先做现状摸底**（读 V8.0.0 git log + grep 代码） |
| 19:38+ | 摸底结论：P0-1~P0-4 已在 V8.0.0 阶段修复；P0-5 需决议 |
| 03:41:14 | v2 commit `c4bc65e fix(mes-batch): P0 必修 5 项` — 仅改 2 处注释 + ADR 决议说明 |
| push 后 | origin/main 确认，远程 HEAD = c4bc65e |

**关键事实**：
- 工人 v2 主动发现"任务基于过时信息"，避免 4 个 P0 重复造轮子
- 实际改动从"5 处业务逻辑修复"降为"2 处注释决议说明"（风险降最低）
- **worker_done 始终未发**（inbox 0 条），但 commit c4bc65e 已 push + mvn compile pass + 改动范围合理 → 按 git 兜底判完成
- 协调者无 worker_done 但不卡死，节省 30+ 分钟等待

**耗时对比**：
- 主会话直接做：5-8h（要 orca-review + 改 5 处 + 全量测试）
- 工人摸底后做：~30 分钟（决议 + 注释 + commit）
- 节省：~95% 时间 + 避免 4 处重复 commit

## 配套建议

### 主会话侧（协调者）

1. **记忆卡片标注"信息时效"**：在"下一步"小节加 `> 注：本卡片基于 2026-07-31 tiequan 报告，工人接收时请现状摸底复核`
2. **任务摘要加 git 兜底声明**：preamble 末尾加 "无论 worker_done 是否到达，按 git commit + push 即可判完成"
3. **不死等 worker_done**：每 60s 看 git log + inbox，超过 5 分钟无 worker_done 但有新 commit → 判完成

### 工人端（pi）

1. **第 0 步强制摸底**：任何 /delegate 任务的 preamble 必须含 "0. 现状摸底（必做）" 步骤
2. **改动前判定**：先判定"真要改 / 已修 / 需决议"三态，再决定下一步
3. **决议优先于改代码**：发现不需要改时，写 commit message 写清楚"决议保留现状 + 引用 ADR"比直接改代码更负责

### 模板更新

`/delegate` 的 preamble 模板应增加：
```markdown
### 0. 大任务前置摸底（强制）
- 读记忆卡片 + 审计/任务来源（理解背景）
- git log / grep / git blame 摸底当前状态
- 判定：已修 / 需决议 / 真要改
- **不要盲目按记忆卡片写代码** — 卡片是输入不是答案
```

### Git 兜底检查脚本（建议沉淀）

```bash
# 协调者侧：判完成函数
delegate_is_complete() {
    local slice_keyword="$1"
    local start_ts="$2"
    # 1. 看新 commit
    local new_commit=$(git log --since="$start_ts" --oneline | grep "$slice_keyword" | head -1)
    # 2. 看是否已 push
    local pushed=$(git log origin/main --oneline | grep "$new_commit" | head -1)
    # 3. 判定
    if [ -n "$new_commit" ] && [ -n "$pushed" ]; then
        echo "COMPLETE: $new_commit"
        return 0
    fi
    echo "INCOMPLETE"
    return 1
}
```