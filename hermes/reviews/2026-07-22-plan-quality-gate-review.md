# quality-gate 体系漏洞分析与优化建议 — 外部评审

**评审人：** Claude Code (orca-review)
**日期：** 2026-07-22
**范围：** quality-gate 体系（3命令+5技能+4规则+2钩子增强）

---

## 一、4条优化合理性判定

### ① /verify vs /quality-gate 边界模糊 — ✅ 合理，且更严重

**发现：** 两条命令的"证据要求矩阵"几乎完全相同。`quality-gate-criteria.md` 逐项复制了 `verify/SKILL.md` 的变更类型→证据映射表。

这导致 AI 面对 Controller 变更时不知道该跑哪个——都要求 curl。更糟的是 quality-gate 的 Step 1（现实核查）**等价于重跑 /verify**，但 skill 中没有声明这个关系。

**建议升级为：** quality-gate 不重复收集证据，而是检查 /verify 是否已通过。分工变为：

```
/verify           → 逐项收集证据（curl/Playwright/DESCRIBE）
/quality-gate     → 检查 verify 是否通过 + 安全扫描 + API 验证 → 判定
```

具体做法：`quality-gate-criteria.md` 删除证据要求矩阵（已在 verify 中），改为：

| verify 结果 | quality-gate 现实核查判定 |
|:--|:--|
| 全部 ✓ | PASS |
| 部分 ✗（非核心端点） | NEEDS WORK |
| 核心端点 ✗ | BLOCKED |
| 未跑 verify | NEEDS WORK（强制要求先跑 verify） |

### ② deep-inspect 基线未初始化 — ✅ 合理，需要标注

当前 `deep-inspect/SKILL.md` 铁律中有"先建基线再做对比"，但：
- 没有明确说"首次运行不会输出判定，只建基线"
- 没有初始化基线的前置条件检查清单（需要什么工具？需要什么权限？）
- Playwright 依赖 k6/Playwright 两个外部工具但降级策略不一致（k6→curl，Playwright→手动截图指引）

**建议增加：**
```markdown
## 前置条件
- [ ] k6 已安装 (`which k6`) 或接受 curl 降级
- [ ] Playwright 已安装 (`npx playwright --version`) 或接受手动截图降级
- [ ] 后端在 8080 端口运行（性能测试需要）
- [ ] 前端在 3100 端口运行（视觉采集需要）
- [ ] 基线目录存在: `mkdir -p hermes/eagle-eye/benchmarks`
```

### ③ quality-orchestrator 878B 骨架 — ✅ 合理，但方向对

当前 35 行骨架定义了升级规则和自进化闭环，但缺少：
- **触发条件的具体阈值**（连续几次失败触发升级？）
- **与 Orca 铁拳团的交互协议**（触发审计后如何获取结果？）
- **状态持久化**（升级状态写到哪里？）

**关于冲突问题：** 不冲突，是互补的。
- 铁拳团 = 一次性的 10 人并行深度审计 → 产物是静态报告
- Orchestrator = 持续的串行协调层 → 读取报告、升级、调度下一个动作

Orchestrator 应该是铁拳团的"调度者"而非"替代者"。骨架中已有"触发铁拳团审计"的升级规则，方向正确。

### ④ SKIP_SECURITY_SCAN 环境变量 — ⚠️ 部分合理，但方案偏差

**已有逃生舱：** `git commit --no-verify`（hook 代码第 139 行已注明）。

增加 `SKIP_SECURITY_SCAN` 环境变量会制造两个逃生舱，用户不知道该用哪个。

**真正的问题是误判风险本身，不是缺少逃生舱。** 当前最可能误判的规则：

| 规则 | 误判风险 | 说明 |
|------|:--:|------|
| `password\s*=\s*"[^"]{3,}"` | 中 | 测试固件中 `password = "test"` 合法；注释中 `// password = "xxx"` 合法 |
| `^\+.*\+.*"SELECT` | 高 | 日志消息 `log.info("SELECT completed")` 会命中；字符串常量定义会命中 |
| `${` in XML | 低 | MyBatis 中 `${}` 确实危险，但表名/列名动态场景（如 `ORDER BY ${sortColumn}`）是合法用途 |

**建议方案替代 SKIP_SECRET_SCAN：**
1. 收紧正则：排除注释行（`//` 和 `*` 开头）、排除 `log.` 调用行
2. 加白名单文件 `.quality-gate-ignore`，模块级声明已知安全模式
3. 保持 `git commit --no-verify` 作为唯一逃生舱

---

## 二、与现有 workflow 集成冲突检查

### 已有体系链条

```
brainstorm → /plan → orca-review → 写代码 → /verify → commit → push → deploy → 差集回归 → 分级测试 → /done → 铁拳团审计
```

### quality-gate 体系插入点分析

| quality-gate 组件 | 最佳插入位置 | 冲突？ |
|------|------|:--:|
| `/quality-gate` | /verify 之后、commit 之前 | ⚠️ 见下方 |
| pre-commit hook 增强 | 已插入 commit 步骤 | ✅ 无冲突 |
| `/deep-inspect` | deploy 之后、差集回归之前 | ✅ 无冲突 |
| `/quality-dashboard` | /done 之后 | ✅ 无冲突 |
| session-start 提醒 | 会话启动 | ✅ 无冲突 |

### ⚠️ 发现的冲突和遗漏

**冲突 1：防失忆触发条件表缺少 /quality-gate**

`workflow.md` 的"防失忆触发条件"表没有 quality-gate。写完代码后 AI 会自动进 /verify，但 verify 通过后不会提示 quality-gate。结果是：**安全扫描只在 git commit hook 中跑了轻量版，完整的 STRIDE 分析从未触发。**

**冲突 2：分级测试规则未考虑 quality-gate 判定**

`workflow.md` 的分级测试规则按 `git diff` 复杂度选择测试级别。但 quality-gate 的安全扫描可能发现 P0 问题，此时即使 git diff 判定为"轻量级"，也应强制走标准级测试。

**冲突 3：`@Transactional` 移除检测重复**

pre-commit-check.sh 原有代码（第 40-44 行）已检测 `@Transactional` 移除 → WARN。security-gate-checklist.md 也列为 P1。两者一致，无冲突，但**规则中说 `@RequiresPermissions` 移除是 P0，hook 代码中只打了 WARN（第 46-48 行），没有 exit 1**——这是 bug：P0 的移除检查实际上不会被阻断。

---

## 三、quality-orchestrator 应填什么

878B 骨架方向正确，需要填入三方面内容：

### 1. 状态机定义

```markdown
## 质量状态机

IDLE → VERIFY_PASSED → GATE_PASSED → COMMITTED → DEPLOYED
                                          ↓ (BLOCKED)
                                       FIXING → VERIFY_PASSED

COMMITTED → INSPECT_SCHEDULED → INSPECTED_CLEAN
                               → ISSUES_FOUND → FIXING

DEPLOYED → REGRESSION_PASSED → READY_FOR_DONE
```

### 2. 与 Orca 铁拳团的调度协议

```markdown
## 铁拳团触发条件
| 触发条件 | 审计范围 | 优先级 |
|---------|---------|:--:|
| 同一模块连续 3 次 GATE_BLOCKED | 该模块全量 | P0 |
| 仪表盘趋势连续 2 周下降 | 所有活跃模块 | P1 |
| 部署后发现 P0 缺陷 | 该模块 + 关联模块（MCP 图形追溯） | P0 |
| 实验到期且效果不显著 | 该模块 | P2 |
```

### 3. 状态持久化

```json
// .claude/memory/quality-state.json
{
  "currentState": "READY_FOR_DONE",
  "moduleStates": {
    "mes": { "gateConsecutiveWarns": 0, "lastAuditDate": "2026-07-16", "openP0": 0 }
  }
}
```

**关于 Orca 铁拳团冲突：不冲突。** Orchestrator 是调度层，铁拳团是执行层。Orchestrator 决定"何时触发审计"，铁拳团负责"执行审计并产出报告"。

---

## 四、pre-commit 原有逻辑与 quality-gate 重叠检查

### 逐段对照

| 原 hook 检查项 | 位置（行号） | quality-gate 对应 | 关系 |
|------|:--:|------|:--:|
| SQL DROP/TRUNCATE | 17-23 | 无 | 互补（质量门控不检测 DDL 危险操作） |
| 前端 TS 语法 | 26-37 | 无 | 互补（质量门控不检测前端语法） |
| @Transactional 移除 | 40-44 | P1 警告（规则 6） | ✅ 一致 — 都是 WARN |
| @RequiresPermissions 移除 | 46-48 | P0 阻断（规则 2） | ❌ 不一致！hook 只打 WARN，规则说是 P0 |
| 测试门控 | 51-74 | 无 | 互补（质量门控不运行测试） |
| **新增** @RequiresPermissions 缺失 | 86-103 | P0 阻断（规则 1） | ✅ 但 hook 也只打 WARN |
| **新增** 硬编码密钥 | 106-112 | P0 阻断（规则 4） | ✅ BLOCK |
| **新增** SQL 拼接 | 114-120 | P0 阻断（规则 3） | ✅ BLOCK |
| **新增** XML ${} | 124-131 | P0 阻断（规则 5） | ✅ BLOCK |
| 受保护目录 | 152-166 | 无 | 互补（质量门控不检查文件路径） |

### 发现的 Bug

**`@RequiresPermissions` 移除检测不一致：**
- `security-gate-checklist.md` 规则 #2：P0 级，检测到即阻断
- `pre-commit-check.sh` 第 46-48 行：只 echo WARN，不 exit
- 实际效果：有人删了权限注解，hook 只会在终端悄悄打印一个 WARN，提交照常进行

**建议修复：** 第 46-49 行的 WARN 后面加 `exit 1`（与硬编码密钥同级），或者在规则中降级为 P1（因为移除可能是重构的一部分——移到基类或接口）。目前中间地带（规则说 P0，代码不阻断）是最差的选择。

---

## 五、遗漏项：方案中完全没提的事

### 1. workflow.md 缺失 quality-gate 触发步骤（P0）

workflow.md 的防失忆表需要新增一行：

| 当 AI 刚刚完成了 | 必须做 | 触发词 |
|------|------|------|
| /verify 通过 | **提示运行 /quality-gate 做安全扫描 + 综合判定** | git diff 有变更 |

没有这条，quality-gate 只会在 git commit 时被 hook 轻量触发，完整的 STRIDE 分析永远不会跑。

### 2. `/verify → /quality-gate` 数据管道缺失（P0）

如第一部分所述，quality-gate 不应重新收集证据。它应该读取 /verify 的输出（或让 AI 复用 verify 会话中的 curl 结果），只追加安全扫描和综合判定。

### 3. dashboard 的数据源是空的（P1）

`quality-dashboard/SKILL.md` 列出了 6 个数据源，但实际运行时这些路径大概率不存在：
- `hermes/eagle-eye/reports/` — 首次使用前为空
- `hermes/tiequan/` — 可能有历史审计数据
- `experiments.json` — 不存在

方案建议"对接已有数据源"是对的，但还缺一个 **首次初始化引导**：dashboard 第一次运行时应该输出"数据源为空，建议先运行 /quality-gate 和 /deep-inspect 建立初始数据"。

### 4. 没有 quality-gate 的 `--dry-run` 模式（P2）

开发者想在提交前检查"会不会被 block？"时，需要跑 /quality-gate 但不希望它真的阻断什么。目前没有 dry-run 模式。

### 5. deep-inspect 和 test-all 的职责边界未定义（P2）

`test-all` 已经跑 API + E2E 测试。`deep-inspect` 中的"视觉证据采集"和 E2E 测试有什么区别？如果 Playwright 既在 E2E 中做功能验证，又在 deep-inspect 中做视觉回归，截图会跑两次。

---

## 六、总结与优先级

### 必须修复（P0）

| # | 问题 | 修复方式 |
|:--:|------|---------|
| 1 | /verify 和 /quality-gate 证据收集重复 | quality-gate 改为检查 verify 结果，不重复执行 |
| 2 | workflow.md 缺少 /quality-gate 触发步骤 | 防失忆表新增一行 |
| 3 | @RequiresPermissions 移除检测不一致 | hook 升级为 BLOCK 或规则降级为 P1 |

### 建议修复（P1）

| # | 问题 | 修复方式 |
|:--:|------|---------|
| 4 | SQL 拼接正则可能误判 | 排除注释行和 log 行 |
| 5 | dashboard 首次数据源为空 | 增加初始化引导输出 |
| 6 | deep-inspect 基线前置条件缺失 | 增加前置条件检查清单 |

### 可选优化（P2）

| # | 问题 | 修复方式 |
|:--:|------|---------|
| 7 | 缺少 --dry-run | quality-gate 增加参数 |
| 8 | deep-inspect 和 test-all E2E 职责 | 明确边界：test-all = 功能验证，deep-inspect = 视觉回归+性能 |
| 9 | quality-orchestrator 骨架补全 | 填入状态机、铁拳团触发协议、持久化格式 |

---

## 评审结论

**4条优化全部合理，其中①的严重度被低估（不是"边界模糊"，是"功能重复"）。** 质量体系与现有 workflow 有两处真实冲突（verify/gate 重复 + 防失忆表缺失），均需在 Phase 1 修复后才能投入使用。Orchestrator 与铁拳团不冲突，是互补关系。pre-commit 中有一处安全隐患（权限移除不阻断）需要立即修复。
