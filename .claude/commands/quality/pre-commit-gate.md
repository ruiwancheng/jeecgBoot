---
description: 自有命令 — 提交前可视化门控：安全扫描 + Orca 页面截图 + 基线对比，阻断时人工门控判定
---

# /pre-commit-gate

git commit 前深度检查。在 `pre-commit-check.sh` 钩子的秒级阻断基础上，加视觉+编排式覆盖。

## 用法

```
/pre-commit-gate                  # 检查 git diff --cached
/pre-commit-gate --skip-visual    # 跳过视觉检查（仅安全检查）
```

## 流程

使用 `pre-commit-gate` 技能获取领域知识，按 5 步执行：

### 1. 上下文膨胀保护

参考 `human-gate` 技能。

### 2. 变更分级

`git diff --cached` → 按 business-chains.json 的 changeClassification 分级。

skip 级 → 直接 PASS，不继续。

### 3. 安全检查

复用 pre-commit-check.sh 的逻辑，Orca agent 执行。
- 检测项详见 `@rules/code-style.md` 安全规范章节：@RequiresPermissions 缺失、硬编码密码/密钥、SQL 字符串拼接、Mapper XML ${} 非参数化等。

### 4. 视觉门控（非 skip 级）

变更的 Vue 页面 → Orca browser 截图 → 与基线对比。

### 5. 输出判定 + 人工门控

PASS → 可以提交
WARN → 有隐患但可提交，备注
BLOCKED → 发 human-gate 等人判定
