---
name: workflow
description: 开发流程——需求→计划→实现→自验证→提交
glob: "**/*"
version: 4.0
---

# 开发流程

```
/brainstorm → /plan → [orca-review] → 写代码 → /verify → git commit + push → /done
```

步骤清单：

| 步骤 | 命令 | 轻量 | 标准 | 全量 |
|------|------|:---:|:---:|:---:|
| 需求澄清 | /brainstorm | ✓ | ✓ | ✓ |
| 实施计划 | /plan | ✓ | ✓ | ✓ |
| 编码实现 | - | ✓ | ✓ | ✓ |
| 自验证 | /verify | ✓ | ✓ | ✓ |
| /quality-gate | — | ✓ | ✓ |
| 提交推送 | git commit + push | ✓ | ✓ | ✓ |
| 前端静态 | /test-frontend | ✓ | ✓ | ✓ |
| 模块测试 | /test-api | - | ✓ | ✓ |
| E2E 测试 | /test-e2e | - | - | ✓ |
| 全量测试 | /test-all | - | - | ✓ |
| 完成检查 | /done | ✓ | ✓ | ✓ |

遇报错用 /debug，部署质量门控详见 `deploy-quality-gate.md`。

## 分级测试规则

写代码后按变更影响面选择测试级别：

| 级别 | 触发条件 | 执行内容 |
|:--:|------|------|
| 轻量 | 文案/样式/注释 | /verify |
| 标准 | Controller/Service/Vue（≤3文件） | /verify + /test-api |
| 全量 | Entity/Mapper/SQL/≥5文件 | /verify + /test-api + /test-e2e + /test-all |

不变更不测试。

## PRD 阅读规则

**PRD 核心逻辑和操作演示必须同时阅读，不可只看其一。** 操作演示里的交互动词决定数据结构：

| 操作演示动词 | 数据结构含义 |
|-------------|-------------|
| "选择/关联 XX" | 外键引用（如 deliveryNoteId） |
| "系统自动带出产品、数量" | 明细行 + 关联查询（主子表） |
| "输入/填写实际数量" | 明细行独立字段（如 actualQty） |
| "多行/明细/逐行" | 主子表而非单表 |

> **来源模块：** 销售出库。单看核心逻辑判断为单表，补读操作演示后发现应是主子表，多花一倍工作量。

## 开发前依赖查证

新模块开发前确认以下依赖链可用：

| # | 检查项 | 验证方法 |
|---|--------|---------|
| 1 | Shiro 权限链 | 确认菜单+权限码在 `MesMenuRegistry` 注册 |
| 2 | SQL 兼容性 | 新 SQL 文件不含 `IF EXISTS`、`sys_dict_item` 不含 `del_flag` |
| 3 | 前端组件 | 表字典用 `JSearchSelect`（合写 `dict: 'table,text,code'`） |
| 4 | 字典存在 | 需要的 `sys_dict` + `sys_dict_item` 已在 SQL 中注册 |
| 5 | 父菜单存在 | 新模块的 `parentId` 指向的菜单已注册 |

## 推送前检查

| 检查项 | 阻塞？ | 说明 |
|--------|:--:|------|
| boot-module 声明的模块目录存在 | 是 | 缺目录 → 编译失败 |
| system-start 有对应依赖声明 | 是 | 缺依赖 → 运行时找不到类 |
| 模块代码已 git 跟踪 | 是 | 漏提交 → CI 编译失败 |

## 大任务切片（大型任务强制）

**触发条件**（满足任一即触发）：

- 任务涉及 ≥3 个页面（Vue 路由）
- 改动文件 ≥10 个
- 用户主动说"任务太大"、"token 爆了"、"环境崩了"

**标准流程**：

```
/brainstorm 大任务 → /plan 大任务 → /decompose 大任务
  → [对每个切片：/brainstorm 切片 → /plan → orca-review → 写代码 → /verify → /done]
  → git commit slice-<顶层ID>.<子ID>-<业务名-kebab>
```

**核心原则**：每个切片 = 一个**端到端可手工验证**的最小业务场景（用户能在浏览器里点一遍看到结果）。

**切片两级结构**：

- **顶层**：按页面（Vue 路由）切
  - simple 页面（每页 1 个功能，如字典）→ 顶层 1:1 对应子切片
  - complex 页面（每页多个操作，如订单列表页含新建+编辑+作废+审核）→ 再分子功能
- **子功能**：按"用户操作流"切
  - ≤5 行代码变化 → 必须合并到相邻子功能
  - 6-50 行 → 独立子功能
  - \>50 行 → 警示，可能需要再拆

**6 要素**（每个子切片必填）：

1. 业务名 + 用户操作路径（浏览器打开 → 操作 → 看到结果）
2. 验收标准（**UI 上能看到什么**；禁止 "Service 返回 X" 这种用户看不到的描述）
3. 依赖关系（其他切片 ID，禁止循环依赖）
4. 风险等级（**高**=Entity/SQL/状态机；**中**=Service/Controller/加字段；**低**=Vue/文案）
5. 工作量估算（小 ≤20 行；中 21-100 行；大 >100 行）
6. Rollback 策略（commit 锚点 + `git revert <commit>` 命令）

**绝对禁止的反模式**（任一违反立即修正）：

- ❌ 按层切（Entity→Service→Controller→Vue）→ 中途不可验收，违反"逐步把控质量"
- ❌ 按代码文件类型分片 → 任何一片都跑不通
- ❌ 先做完所有 Entity / Service / Vue 列表 / 后端接口 → 用户看不到结果
- ❌ 按菜单结构切（菜单层级 ≠ 业务场景）
- ❌ 先做权限（权限依赖功能完成）

**Token 成本控制**（每个切片输出时附带）：

| 切片规模 | orca-review 模式 | Token |
|---------|-----------------|-------|
| ≤3 文件 | 免评审 | 0 |
| 4-10 文件 | 轻量评审 | ~30K |
| \>10 文件 | 完整评审 | ~150K |

**自动衔接**：`/decompose` 自动读取 `/plan` 输出（30 分钟内），无需重新描述任务。缓存文件 `.claude/.last-plan.json`（已 gitignore）。显式覆盖用 `--no-cache` 或 `--restart`。

**详细方法论 + 完整 8 反模式 + 切片模板**：见 `.claude/skills/decompose/SKILL.md`

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
3. **协调者代发可能** — Claude 协调者（`term_924cd402`）会检测产物到位后手动代发 worker_done

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

### 部署控制台重置 + 强制全量（deploy-console-reset）

部署控制台缓存旧 class，可能导致代码改了但运行时仍跑老逻辑。**部署前重置控制台 + 强制全量**（清 classpath + 不增量）：

- 部署控制台 → 应用管理 → **强制重启**（不要软重启）
- 部署选项 → 选**全量替换**（不勾"增量部署"）
- 部署后 → `tail -f` 启动日志确认新 class 加载

🚫 禁止：控制台"软重启"或"增量替换"——可能复用旧 class。详见 `learnings/2026-08-02-deploy-console-reset-and-force-full.md`。
