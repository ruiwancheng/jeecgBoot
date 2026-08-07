# Harness 文档（业务人员版）

本目录存放给业务人员看的使用指南，与笔记空间双备份。

## 当前文档

| 文档 | 用途 | 同步源 |
|---|---|---|
| `regression-guide.md` | 回归测试使用指南（业务人员版）| `/Users/ruisuyun/Documents/笔记空间/低代码平台方案/00环境配置/回归测试使用指南.md` |

## 同步策略

**双备份机制**：
1. **笔记空间**（权威源）— 业务人员本地笔记本
2. **仓库**（开发源）— 与代码一起版本控制

**什么时候同步**：
- 文档重大更新时（重大流程变更）
- 每个 sprint 结束（同步一次）

**同步命令**（业务人员）：

```bash
# 笔记空间 → 仓库
cp "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/00环境配置/回归测试使用指南.md" \
   .claude/docs/regression-guide.md
git add .claude/docs/regression-guide.md
git commit -m "docs: 同步回归测试使用指南"
git push
```

**反向同步**（仓库 → 笔记空间）：

```bash
# 仓库 → 笔记空间
cp .claude/docs/regression-guide.md \
   "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/00环境配置/回归测试使用指南.md"
```

## 双备份的好处

1. **离线可读**（笔记空间）— 不需要 git clone 就能用
2. **版本可追溯**（仓库）— 任何改动都有 commit + PR 记录
3. **AI 可读**（仓库）— AI 直接 grep 仓库内的 .claude/docs/ 给业务人员推荐
4. **跨设备同步**（仓库）— 笔记本 / 公司电脑 / 同事都能拿到最新版

## 文档自检

每次同步前跑一次（业务人员用）：

```bash
# 同步前检查
diff "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/00环境配置/回归测试使用指南.md" \
     .claude/docs/regression-guide.md

# 没输出 = 已同步
# 有输出 = 有差异，需要同步
```
