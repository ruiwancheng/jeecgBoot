# Matt Pocock Skills 对 JeecgBoot Harness 工程的评估

> 评估日期：2026-07-27
> 插件版本：1.2.0
> 已链接：37 个 skill（17 engineering + 6 in-progress + 4 misc + 2 personal + 5 productivity）
> 安装路径：`~/.claude/plugins/cache/mattpocock/mattpocock-skills/1.2.0/`

---

## 哪些直接能提升 Harness

### ⭐⭐⭐⭐⭐ 立即可用、增益显著

| Skill | 对应 Harness 场景 | 增益 |
|------|------|------|
| **code-review** | `/review:review` 的升级版 | 双轴并行（Standards + Spec），比当前的串行审查更严谨；固定点 diff 模式可直接替代 `git diff` 审查 |
| **diagnosing-bugs** | `/debug` 的升级版 | 10 种反馈回路构造方法（从 failing test 到 HITL bash script），当前 debug 只排查→修复，缺少"先建反馈回路"的第一步 |
| **domain-modeling** | `CONTEXT.md` + `hermes/business-chains.json` 的维护者 | 业务链路术语表、ADRs、上下文文件——JeecgBoot 的 `business-chains.json` 缺乏正式的术语定义 |

### ⭐⭐⭐⭐ 有选择地采纳

| Skill | 对应 Harness 场景 | 增益 |
|------|------|------|
| **codebase-design** | `code-style.md` + `karpathy-guidelines.md` 的补充 | "Deep module" 词汇（interface/implementation/seam/depth）比当前的"函数不超过 50 行"更精准 |
| **prototype** | `/brainstorm` 的实物化 | 用可运行的代码验证设计直觉，替代纯文字讨论 |
| **research** | `hermes/research/` 的自动化 | 后台 agent 查文档→产出 Markdown，当前全靠手动 WebSearch |
| **tdd** | `gen-tests-rules.json` 的模式升级 | 从"先写代码后补测试"到"test-first"，但 JeecgBoot 的已有代码量大，改造成本高 |

### ⭐⭐⭐ 与现有能力重叠

| Skill | 与已有 Harness 的重叠 |
|------|------|
| **handoff** | ≈ `/cleanup-context` + `/new-terminal`（记忆卡片模式） |
| **grilling** | ≈ `/brainstorm` + `orca-review` 的第二意见 |
| **triage** | ≈ `audit-classification.md` 的自动分类 |
| **to-tickets** | ≈ `/plan` 的步骤分解 |
| **to-spec** | ≈ `/brainstorm` 的需求澄清 |
| **wayfinder** | ≈ `/plan` + `orca-review` 的组合（大任务先探路再执行） |
| **implement** | ≈ `/plan` + `/verify` 循环 |
| **setup-pre-commit** | ≈ 已有的 `pre-commit-check.sh`（但 Husky 方式更标准） |
| **git-guardrails-claude-code** | ≈ 已有的 `block-dangerous.sh`（已覆盖 git push --force 等） |
| **resolving-merge-conflicts** | ≈ 已有的 `/debug` 可覆盖 |

---

## 什么不应该引入

| Skill | 原因 |
|------|------|
| **teach** | Harness 的目标用户是业务人员，不需要教学 workspace |
| **edit-article** | 个人工具，与 JeecgBoot 无关 |
| **obsidian-vault** | 个人工具 |
| **migrate-to-shoehorn** | TypeScript-only 的工具，JeecgBoot 混合 Java/Vue 不适用 |
| **scaffold-exercises** | 培训用途，不在 Harness 范围内 |
| **batch-grill-me** (in-progress) | 仍在草案阶段 |
| **wizard** (in-progress) | 仍在草案阶段 |

---

## 3 个最高优先级采纳建议

### 1. `diagnosing-bugs` → 升级 `/debug`

当前 `/debug` 流程：读报错 → 定位 → 提方案 → 等确认 → 修复。缺少关键第一步：**建立可复现的反馈回路**。diagnosing-bugs 的 10 种回路构造方法（failing test / curl / headless browser / replay trace / bisection）可以直接嵌进 `/debug` 技能的第一步。

```
/debug 当前流程:
  读报错 → 定位 → 方案 → 确认 → 修复

/debug 升级后:
  建反馈回路 → 确认可复现 → 定位 → 方案 → 确认 → 修复 → 验证回路绿了
```

### 2. `code-review` → 升级 `/review:review`

当前 `/review:review` 是 7 类分析 + 4 级严重度，有效但缺少**对比原点**（spec vs actual）。code-review 的双轴模式（Standards 检查代码规范 + Spec 检查是否匹配需求）可以嵌入现有的 `/review:review`。

### 3. `codebase-design` 词汇 → 补充 code-style.md

"deep module" 的词汇（interface/implementation/seam/depth/leverage）比"函数不超过 50 行"更精准地衡量代码质量。可以在 `code-style.md` 中增加一个"模块深度"小节。

---

## 与 Harness 不冲突的保证

- 所有 mattpocock skills 通过 symlink 加载（`link-skills.sh`），不修改 `.claude/` 目录内的任何文件
- 它们的触发关键词不在现有 JeecgBoot 命令的命名空间内（没有 `/start`、`/verify`、`/client-start` 等冲突）
- `ask-matt` router 只在用户主动问"怎么用 X"时激活，不会抢占现有命令

---

## 总结

| 评级 | 数量 | 代表 |
|:--:|:--:|------|
| 直接可用、增益大 | 3 | code-review, diagnosing-bugs, domain-modeling |
| 有选择采纳 | 4 | codebase-design, prototype, research, tdd |
| 与现有重叠 | 10 | handoff, grilling, triage, to-tickets... |
| 不适用 | 7 | teach, edit-article, obsidian-vault... |

**结论：值得用，但不需要全量引入。** 优先将 diagnosing-bugs 和 code-review 的精华模式吸收到现有 `/debug` 和 `/review:review` 中，其他按需取用。

同事推荐得有道理——这组 skills 的品质很高，尤其是 `diagnosing-bugs` 的反馈回路思想和 `code-review` 的双轴并行模式，正好补上了当前 Harness 的两个关键短板。
