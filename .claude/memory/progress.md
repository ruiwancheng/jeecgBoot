# Harness 工程进度

## 工作流阶段追踪

> ⚠️ 防失忆：每次完成一个阶段后更新 `phase` 字段。session-start hook 会检查此文件。

| 字段 | 值 | 说明 |
|------|-----|------|
| phase | done | brainstorm / plan / coding / verify / testing / done |
| last_verify | 2026-07-06 | 最后一次 /verify 通过的时间 |
| last_test | 2026-07-06 | 最后一次测试通过的时间 |
| pending_step | — | 下一步该做什么（空=已完成） |

## 当前状态
- 最后更新：2026-07-06
- Harness 健康度：35/35
- 当前任务：MES 基础设置模块开发完成 + 防失忆机制落地

## 本次完成

### 工程架构优化
- 命令与技能分离：创建 16 个 SKILL.md，16 个命令文件瘦身
- 创建 `skill-command-boundary.md` 边界规则
- 创建 `override-mechanism.md` 覆盖机制规则
- CLAUDE.md 改为索引式（指向 Rules 而非重述内容）
- CLAUDE.md 新增"本文档的角色"元规则段落

### 测试体系改进
- 创建 `gen-tests-rules.json` — Bug 反哺推导规则
- gen-tests 新增环境自引导能力
- debug 新增修复后反哺步骤

### 目录治理
- harness/ hermes/ 加入 .gitignore
- .remember/ 加入 .gitignore
- 清理 learned/ 空目录，创建 hermes/README.md

### 缺陷修复（13 项）
- 悬空引用：`/new-customer`→`/new-project`、`jeecg-lowcode-miniflow`→`jeecg-bpmn`、`jeecg-graphreport`→`jeecg-onlchart`
- 占位符：jimureport、jeecg-bpmn 的 `<SKILL_NAME>` 已替换
- Hook 全部注册，pre-commit-check.sh 变量顺序修复
- harness-check 命令/规则计数修正，重试次数统一

### harness-check 升级
- 6 轴 → 7 轴（新增交叉验证）
- 悬空引用、Frontmatter、配置一致性、内容质量、自检

## 关键决策
- 2026-07-05: 命令只做编排，技能管领域知识
- 2026-07-05: CLAUDE.md 只索引，Rules 管约束
- 2026-07-05: harness/ 全量 gitignore，环境配置在技能中
- 2026-07-05: 暂不需要 SubAgent
- 2026-07-05: Bash 描述必须中文业务语言

## 待推进
- ECC GateGuard 拦截频繁（约 20 次/会话）
- features.json 模块补全
- code-style / frontend 重叠清理
- debug Skill / debugging Rule 冗余合并
- settings.local.json 权限清理

## 经验记录
- 2026-07-05: 引用腐烂是最大风险——Rule/Command/Skill 互相引用无自动校验
- 2026-07-05: harness-check 自身会过时，需要交叉验证自检
