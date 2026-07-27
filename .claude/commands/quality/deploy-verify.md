---
description: 自有命令 — 部署后编排式验证：并行冒烟 API + 视觉截图 + 链路冒烟，输出综合质量报告
---

# /deploy-verify

部署完成后，Orca 编排三路并行验证，输出综合质量报告。

## 用法

```
/deploy-verify                    # 部署后验证
/deploy-verify --skip-visual      # 部署后验证（跳过视觉检查）
```

## 流程

使用 `deploy-verify` 技能获取领域知识，按 5 步执行：

### 1. 上下文膨胀保护

参考 `human-gate` 技能。

### 2. 获取变更差集 + 分级

`git diff .last-deploy-commit..HEAD --name-only` → 按 `business-chains.json` 中的 changeClassification 分级。

### 3. 三路并行验证

Orca orchestration 并行验证：

### 4. 聚合 + 输出报告

三路结果汇总 → PASS / NEEDS WORK / BLOCKED

### 5. 人工门控（需要时）

BLOCKED 或 NEEDS WORK 时发 human-gate 等人决定：
- 回滚 → git revert
- 修复后重新部署 → 记录问题清单
- 已知问题，跳过 → 更新 .last-deploy-commit
