# /auto-learn

手工触发三层学习机制，展示完整成果。

## 执行流程

### 第一层：learnings 清单
列出 `.claude/memory/learnings/` 中所有经验，按日期倒序。

### 第二层：规则覆盖率
对照 learnings 检查 code-style.md / audit-classification.md / frontend.md 已覆盖哪些、未覆盖哪些。

### 第三层：速查表健康度
统计 audit-classification.md 常见模式速查表的条目数、最新更新时间、模块覆盖度。

## 输出格式

```
=== /auto-learn 报告 ===

📚 learnings 清单 (N 条)
  2026-07-14 self-invoke-proxy-failure ✅→code-style.md
  2026-07-14 mask-sensitive-copy       ✅→code-style.md
  2026-07-14 sql-default-dict-code     ✅→code-style.md + audit

🛡️ 规则覆盖率: X/Y (Z%)
  已覆盖: self-invoke, mask, dict-code, del_flag, menu-encoding...
  未覆盖: (none)

📊 速查表: M 条模式, 覆盖 N 个模块
  新增建议: (if any)

🔄 待进化: (if any learnings not in rules)
```

## 校验

不修改任何文件。只读报告。
