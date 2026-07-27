---
description: 自有命令 — 浏览器可视化验证：Orca browser 截图 + 基线对比，发现 UI 差异后人工门控判定
---

# /visual-check [模块名]

用 Orca browser 打开目标页面截图，与历史基线对比，发现 UI 异常。

## 用法

```
/visual-check                    # 基于 git diff 自动推断变更模块
/visual-check purchase           # 指定模块
/visual-check --page http://localhost:3100/project/mes/purchase/order  # 指定页面 URL
```

## 流程

使用 `visual-check` 技能获取领域知识，按 5 步执行：

### 1. 上下文膨胀保护

参考 `human-gate` 技能，检查 token 用量。

### 2. 加载技能 + 确认范围

使用 `visual-check` 技能加载领域知识。确定要检查的页面 URL。

### 3. Orca browser 截图

按技能中的浏览器操作步骤执行。

### 4. 基线对比

- 首次检查 → 设置为本模块的基线
- 已有基线 → 对比本次截图与基线

### 5. 人工门控

发现差异时，按 `human-gate` 技能发 decision_gate 等人判定：
- 预期变化 → 更新基线
- 真问题 → 标记需修复
- 忽略 → 保留旧基线
