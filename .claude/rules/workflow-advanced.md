---
name: workflow-advanced
description: 开发流程低频专题 — /delegate派工/evolve增量/菜单路由/业务文档/派工兜底
glob: "**/*.{vue,ts},**/.claude/commands/delegate/**,**/.claude/commands/dev/decompose.md,**/.claude/commands/learn/**,**/hermes/prd/**"
version: 1.0
---

# 开发流程 — 低频专题

> 以下专题由 `workflow.md` 拆分而来。核心流程（步骤清单 + 分级测试 + 大任务切片）见 `workflow.md`。

## /delegate 派工场景规范（2026-08-02 沉淀）

> 派工到 pi 工人终端的场景，包含 2 项原则。

### 原则 1：工人必须现状摸底（第 0 步）

记忆卡片基于派发时刻的信息（可能是几天/几周前），工人接收时实际代码可能已演进。

**工人端必做**（不要跳）：

1. **读记忆卡片 + 任务背景** — 理解任务需求
2. **现状摸底（强制）**：
   - `git log --oneline | grep -E "<关键词>"` — 看是否已修
   - `grep -rn "<修复模式>" <相关模块>` — 看代码当前状态
   - `git blame <file>:<line>` — 看 P0 行号的最近修改
3. **判定修复方向**（三态）：
   - **已修** → commit message 写清"已在 V<版本> 阶段修复，不重复造轮子"
   - **需决议** → 写 ADR 引用（如"ADR 0002 拍板前保留现状"）
   - **真要改** → 按 plan 改文件 + update-begin/end + commit

**🚫 禁止**：盲目按记忆卡片写代码——卡片是输入不是答案。

### 原则 2：git 兜底判完成（不依赖 worker_done）

worker_done 未发 ≠ 未完成。派工完成判定三件套：

1. **git commit + push 已执行** — 任务范围产物落入 git
2. **产物文件存在** — 不要求 commit 的任务（如跑命令生成报告），看产物路径
3. **协调者代发可能** — Claude 协调者会检测产物到位后手动代发 worker_done

**判定优先级**：commit hash > 产物路径 > inbox worker_done（最后者不严谨，仅作为补充信号）。

**反例**（连续 2 次观察到）：pi 工人完成所有工作但忘了发 worker_done → 按 git 兜底判完成。

**详细落实**：见 `.claude/skills/delegate/SKILL.md`（polling 检测修复 + 协调者代发章节）。

## /evolve 增量规则（2026-08-02）

### 派工 polling 硬上限：7 分钟（orca-pi-terminal-tui-freeze）

pi 终端在派工后 ~7 分钟可能 TUI 假死（buffer 被 trim、busy 字符循环 `⠙⠧⠇⠋⠸`）。判僵死信号：
- [ ] `preview` 只显示 TUI busy 字符 > 5 分钟
- [ ] `terminal read` 返回 `output=""` 几乎为空
- [ ] 连续 2 次 ping (60s 间隔) 无回应

**触发兑底**：立即 `git reset --hard <last-known-good>`，不再尝试"再修"。详见 `learnings/2026-08-02-orca-pi-terminal-tui-freeze-after-7min.md`。

### worker_done 硬约束 + 协调者代发（delegate-worker-done）

工人完成工作后**第一步**必须发 `worker_done`，禁止"在我自己终端打印完成就 idle"。

**反模式**：
- ❌ 打印"完成"总结就 idle（以为这就够了）
- ❌ 觉得"任务轻量不需要回报"直接退出
- ❌ 忘记最后一步

**协调者兑底**：工人 5 分钟无 worker_done + 产物到位 → 协调者手动代发（不是脚本，是人工补发）。详见 `learnings/2026-08-02-delegate-worker-done-must-emit-hard-rule.md`。

### 派工第 0 步：工人现状摸底（delegate-worker-rebaseline）

工人接收记忆卡片时**实际代码可能已演进**（几天/几周差异）。强制摸底：

```bash
git log --oneline | grep -E "<关键词>"  # 看是否已修
grep -rn "<修复模式>" <相关模块>      # 看代码当前状态
git blame <file>:<line>               # 看 P0 行号最近修改
```

**三态判定**：
- **已修** → commit message 写"已在 V<版本> 阶段修复"
- **需决议** → 写 ADR 引用
- **真要改** → 按 plan 改文件 + update-begin/end + commit

🚫 禁止：盲目按记忆卡片写代码。详见 `learnings/2026-08-02-delegate-worker-rebaseline-and-git-fallback.md`。

> **元规则**：同 `debugging-cheatsheet.md` §code-fact-verification-before-plan。派工场景侧重三态判定（已修/需决议/真要改），日常编码场景侧重事实验证。两处命令形态略有不同，应保持同步。

### 部署控制台重置 + 强制全量（deploy-console-reset）

部署控制台缓存旧 class，可能导致代码改了但运行时仍跑老逻辑。**部署前重置控制台 + 强制全量**（清 classpath + 不增量）：

- 部署控制台 → 应用管理 → **强制重启**（不要软重启）
- 部署选项 → 选**全量替换**（不勾"增量部署"）
- 部署后 → `tail -f` 启动日志确认新 class 加载

🚫 禁止：控制台"软重启"或"增量替换"——可能复用旧 class。详见 `learnings/2026-08-02-deploy-console-reset-and-force-full.md`。

### 菜单/路由/权限规则（/evolve 增量 2026-07）

> 📦 **已迁入 `frontend.md`**。frontend.md 已有 Vue/TS glob 覆盖（`**/*.{vue,ts}`），改路由时自动加载。
> 详见 `.claude/rules/frontend.md` §菜单/路由/权限规则。

---

## 业务人员文档写作规范（2026-08-07 evolve 固化）

> 来源：`memory/learnings/2026-08-07-business-language-docs.md`
> 触发：写给业务人员（不懂技术）的文档 — 使用指南 / SOP / FAQ / 培训文档等

### 核心原则：业务动作 > 技术术语

业务人员**不懂技术**，他们关心"**我做什么**"和"**AI 做什么**"。把技术术语翻译成业务动作。

#### 翻译对照表

| ❌ 技术术语 | ✅ 业务语言 |
|---|---|
| `regression-test slice 4.1` | 测试 4.1 失败 |
| `regression-report.js` | 回归报告 |
| `expect(received).toBe(20)` | 账面数量对不上账 |
| `5s timeout` | 操作超时（页面没响应）|
| `Connection Refused` | 页面打不开 |
| `worker_done 被拒` | AI 任务交付失败 |
| `task-create + dispatch` | （业务人员无需知道）|
| `harness/.regression-runs/XXX/` | 报告位置（AI 自己记）|
| `endpoint / API / 端点` | 功能（必要时叫"操作"）|
| `git commit / push` | （业务人员无需知道）|
| `覆盖率 80%` | 测了 80% 的功能 |
| `P0 阻塞 / P1 主流程` | 24h / 1 周 / 2 周（**直接用时间**）|

### 4 个必备元素

#### 元素 1：自然语言命令清单

不要让业务人员记 `/test-regression` 这种命令，让他们说自然语言：

```markdown
| 场景 | 你对 AI 说的话 |
|---|---|
| 跑回归测试 | "跑回归测试" |
| 你复核 | "开始复核" |
| AI 复盘 | "复盘误判" |
| 派发修复 | "派发 bug 修复" |
```

AI 自己会翻译成 `/xxx` 命令。

#### 元素 2：复制粘贴模板

业务人员不想"造句"，给模板直接套：

```markdown
## 反馈模板

### 模板 A：误判（不是 bug）
"4.X <哪个测试> 是误判，因为 <你在系统里看到的情况>"

### 模板 B：真 bug
"4.X <哪个测试> 是真 bug，因为 <问题>，严重度 P0/P1/P2，负责人 <谁>"
```

#### 元素 3：业务判断标准

业务人员不知道怎么定 P0/P1/P2，给具体业务例子：

```markdown
| 等级 | 业务例子 |
|---|---|
| P0 | 客户付款后钱扣了但订单没生成；盘点后账面全乱了 |
| P1 | 某个常见场景走不通；数字对不上 |
| P2 | 页面某个按钮没的；颜色不好看 |
| P3 | 建议性反馈 |
```

#### 元素 4："我不需要知道"声明

明确告诉业务人员"哪些是 AI 做的 / 你不需要懂"：

```markdown
你不需要：
- ❌ 懂技术
- ❌ 用命令行
- ❌ 改代码
- ❌ 记命令（AI 自己会）

你只需要：
- ✅ 打开浏览器看系统
- ✅ 在对话窗口跟 AI 说话
- ✅ 30-60 分钟做业务复核
```

### 8 条写作铁律

1. **句子短，主语明确** — "回归测试 4 步走" 比 "本指南将阐述..." 好
2. **用"你"不用"用户"** — 直接对业务人员说话
3. **业务例子 > 抽象描述** — "客户付款后钱扣了但订单没生成 → P0"
4. **避免双重否定 + 条件句** — "看不到？让 AI 重新给具体步骤"
5. **可视化优于文字** — 流程图 + 表格 > 长段落
6. **速查表放在文档头部** — 业务人员 30 秒能上手
7. **章节字数控制** — 总文档 < 5000 字（10 页 A4）
8. **可视化检查** — 章节有"你做什么" + "AI 做什么"对照

### 文档结构（按业务人员"做事流程"组织）

```markdown
❌ 技术架构组织：
  第一章：系统概述
  第二章：架构设计
  第三章：API 规范
  第四章：测试框架
  第五章：报告生成

✅ 业务人员做事流程：
  第一章：什么时候需要做这件事
  第二章：整个流程 N 步走
  第三章：详细步骤（业务人员视角）
  第四章：反馈模板（直接复制）
  第五章：你需要知道的事
  第六章：常见问题
```

### 文档自检清单

写完业务人员文档后，对照这个清单自检：

- [ ] 业务人员看完能在 5 分钟内上手
- [ ] 没有命令 / API / 代码 / 端点等术语（或者已翻译）
- [ ] 每个步骤都有"你做什么"和"AI 做什么"
- [ ] 反馈模板可直接复制粘贴
- [ ] 有"严重度"业务例子（不只是 P0/P1/P2 抽象）
- [ ] 速查表在文档头部
- [ ] 总字数 < 5000 字

详见 `memory/learnings/2026-08-07-business-language-docs.md`。

---

## 派工兜底：git status 检查（2026-08-07 evolve 固化）

> 来源：`memory/learnings/2026-08-07-coordinator-git-status-fallback.md`
> 触发：派工协议失败时（worker_done 被 taskId 拒绝、工人超时、工人发不出回报）

### 核心原则

> **git 工作区 = 真实工作进度**
>
> worker_done 是"信号"，git 是"事实"。永远以事实为准。

### 兜底检查清单（每 5 分钟至少一次）

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

### 完整兜底工具集

#### 监听 worker 时的兜底（每 30s 轮询）

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

#### 发现未提交改动时的补救流程

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

### 实战案例：2026-08-07 B4 inventoryAlert 修复

**事件流**：
1. 派工给后端 + 前端 pi 工人（用 `terminal send`，错误协议）
2. 15 分钟轮询，worker_done 一直 0
3. 监听 17 分钟，工人都在 "Working..." 状态
4. **关键发现**：`git status` 列出 `inventoryAlert/index.vue | 384 ++++++`（B4 任务实际完成！）
5. 切到 `feat/inventory-alert-enhancement` 分支
6. `git add` + `git commit` + `git push` → B4 成功完成

**没有 git status 兜底**的话，B4 会被误判为 FAILED，B4 代码改动会丢失。

### 协调者必备 4 步兜底流程

派工后**每 5 分钟**至少做一次：

```bash
# Step 1: 看分支新 commit
git fetch origin
for BRANCH in <worker-branches>; do
  echo "=== $BRANCH ==="
  git log --oneline $BRANCH -3
  echo "本地 vs 远端："
  LOCAL=$(git rev-parse $BRANCH)
  REMOTE=$(git ls-remote --heads origin $BRANCH | awk '{print $1}')
  if [ "$LOCAL" = "$REMOTE" ]; then echo "  ✅ 已同步"; else echo "  ⚠️ 不同步"; fi
done

# Step 2: 看 main 工作区有没有未提交改动（关键！）
git status --short

# Step 3: 看 untracked / modified 文件是不是 worker 的任务范围
git diff --stat

# Step 4: 协调者代发 worker_done（如协议允许）
# 注意：必须先 task-create + dispatch 才能让 worker_done 关联 taskId
# 否则 worker_done 也会被拒（"worker_done requires taskId"）
```

详见 `memory/learnings/2026-08-07-coordinator-git-status-fallback.md` + `2026-08-07-orchestration-taskid-required.md`。
