# Harness 工程巡检报告

| 项目 | 信息 |
|------|------|
| 巡检日期 | 2026-07-18 |
| 检查范围 | 29 Commands / 16 Rules / 6 Hooks / 31 Skills |
| 检查方式 | 七轴评分 + 交叉验证 |

---

## 一、七轴评分

| 轴 | 评分 | 说明 |
|------|:--:|------|
| 1. 结构（Structure） | **5.0** | 目录层级清晰，命令/技能边界无违规 |
| 2. 上下文（Context） | **4.0** | 2个Rule缺少frontmatter |
| 3. 规划（Planning） | **5.0** | brainstorm→plan 流程完整，决策树清晰 |
| 4. 执行（Execution） | **5.0** | 6个Hook全部注册生效，命令覆盖全流程 |
| 5. 验证（Verification） | **5.0** | /done /review /debug 流程完善 |
| 6. 改进（Improvement） | **5.0** | /session-wrap /learn progress.md 均在更新 |
| 7. 交叉验证（Cross-Validation） | **2.5** | 自检计数不准(-2) + frontmatter缺失(-0.5) |

| **综合** | **4.5/5** | 工程基础扎实，自检数据需同步 |
|------|:--:|------|

---

## 二、详细发现

### 🔴 阻塞项（自检计数不准确，-1分/项）

| # | 问题 | 位置 | 实际值 | 声明值 | 修复建议 |
|:--:|------|------|:--:|:--:|------|
| 1 | **命令数量不对** | `harness-check/SKILL.md:13` | **29** 个 | 声称 27 个 | 更新 SKILL.md 中的命令列表为实际29个 |
| 2 | **规则数量不对** | `harness-check/SKILL.md:16` | **16** 个 .md | 声称 12 个 | 更新为16（另加 `gen-tests-rules.json` 1个） |

> 计数错误导致巡检报告失信。29个命令中多了 `generate/new-module` 和 `learn/auto-learn` 未在清单中。

### 🟠 警告项

| # | 问题 | 位置 | 修复建议 |
|:--:|------|------|------|
| 3 | **tiequan-report-retention.md 缺 frontmatter** | `.claude/rules/` | 添加 `name/description/globs/version` |
| 4 | **tiequan-report-scope.md 缺 frontmatter** | `.claude/rules/` | 添加 `name/description/globs/version` |
| 5 | **harness-check SKILL.md 规则清单过时** | 缺少 `audit-classification`、`engineering-artifacts`、`tiequan-report-retention`、`tiequan-report-scope` 四个规则 | 补全清单 |

### ✅ 通过项

| 检查项 | 结果 |
|------|:--:|
| 命令/技能边界（29个命令全部无违规） | ✅ |
| 悬空引用（CLAUDE.md → 15个规则全部存在） | ✅ |
| Hook注册（6个脚本全部在settings.json注册且文件存在） | ✅ |
| 空技能目录（31个Skill均有SKILL.md且非空） | ✅ |
| 未替换占位符（全部技能无 `<SKILL_NAME>` 或 `<XXX>`） | ✅ |
| CLAUDE.md 不重述Rule（使用"详见"引用模式） | ✅ |
| 构建一致性（4个boot-module模块目录存在且已git跟踪） | ✅ |
| system-start依赖声明（project-mes, customer-demo都已注册） | ✅ |
| features.json 存在 | ✅ |
| progress.md 持续更新 | ✅ |
| 工程产物规范（hermes/harness 目录、INDEX.md覆盖） | ✅ |

---

## 三、资产总览

| 类别 | 数量 | 状态 |
|------|:--:|------|
| Commands（命令） | 29 | ⚠️ 清单需更新为29 |
| Rules（规则.md） | 16 | ⚠️ 2个缺frontmatter |
| Rules（规则.json） | 1 | gen-tests-rules.json ✅ |
| Hooks（钩子） | 6 | ✅ 全部注册 |
| Skills（技能） | 31 | ✅ 全部有效 |

---

## 四、改进建议

### 立即修复（5分钟）

1. **更新 harness-check SKILL.md 命令清单** — 29个命令补全（新增 `generate/new-module`、`learn/auto-learn`）
2. **更新规则清单** — 16个规则补全（新增4个）
3. **为两个 tiequan 规则添加 frontmatter**

### 建议优化

4. `gen-tests-rules.json` 虽然不属于 `.md` 规则，但在规则目录中容易混淆，可考虑加个 `README.md` 说明其用途
5. `project-template` 在 boot-module 的 pom.xml 中声明了但无 system-start 依赖——这是合理的（模板不参与编译），无需改动

---

*巡检执行: 赤兔 | 2026-07-18 | 工具: harness-check v7*
