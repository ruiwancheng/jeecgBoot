---
name: orca-worktree-conventions
description: Orca工作树命名规范 — feature/tiequan/eagleeye/hotfix/review 五大前缀及使用场景
metadata:
  type: reference
---

# Orca 工作树命名规范

JeecgBoot 项目使用 Orca Worktrees 进行多任务隔离开发，按以下前缀分类：

## 五大前缀

| 前缀 | 命名格式 | 用途 | 分支存活周期 | 示例 |
|------|------|------|:--:|------|
| `feature/` | `feature/{模块名}` | 新功能开发 | 合并后删除 | `feature/mes-procurement` |
| `tiequan/` | `tiequan/{模块名}` | 铁拳团审计（只读分析） | 报告生成后删除 | `tiequan/mes-sales` |
| `eagleeye/` | `eagleeye/{模块名}` | 鹰眼团测试（隔离环境） | 测试完成后删除 | `eagleeye/mes-warehouse` |
| `hotfix/` | `hotfix/{问题编号}` | 紧急 Bug 修复 | 修复合并后删除 | `hotfix/p0-concurrent-lock` |
| `review/` | `review/{PR编号}` | PR 代码审查 | 审查完成后删除 | `review/pr-42` |

## 使用规则

1. **主工作树 (main)** — 日常开发、提交、推送。不在此工作树做大规模审计或测试。
2. **创建命令** — `orca worktree create --name {前缀}/{名称}`
3. **进度追踪** — `orca worktree set --worktree branch:{分支名} --comment "当前进展描述"`
4. **完成清理** — `orca worktree rm --worktree branch:{分支名}`

## 工作树元数据管理

```bash
# 查看所有工作树概况
orca worktree ps --limit 10

# 标记工作树状态
orca worktree set --worktree branch:feature/mes-procurement --comment "Entity+Mapper完成，正在写Service"

# 完成后清理
orca worktree rm --worktree branch:feature/mes-procurement
```

## 禁止事项

- 禁止在主工作树同时进行多项不相关的开发任务
- 禁止铁拳团审计 Agent 在非隔离环境读取未提交代码
- 禁止长期保留已合并的工作树（保持 `orca worktree list` 干净）

**Why:** 确保不同性质的任务（开发、审计、测试、修复）互不干扰，避免未提交代码被审计 Agent 读取造成误判。
**How to apply:** 新任务开始前先判断类型 → 创建对应前缀的工作树 → 任务完成提交合并后删除工作树。
