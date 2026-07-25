---
description: 多客户端兼容性检测 — 扫描 hooks/skills 中的 OS 专有命令、硬编码路径、平台假设，输出 P0/P1/P2 分级报告
---

# /compat-check

扫描 harness 工程文件，检测多客户端（macOS/Windows/Linux）兼容性问题。

## 流程

### 1. 加载领域知识
使用 `compat-check` 技能获取：P0/P1/P2 检测矩阵、grep 检测模式、排除规则、报告模板。

### 2. 执行扫描
按技能中的检测矩阵，对 `.claude/hooks/` 和 `.claude/skills/` 逐项 grep 扫描。

### 3. 去噪 + 分级
按排除规则过滤误报，按 P0/P1/P2 分级归类。

### 4. 输出报告
按技能模板输出。P0 出现 → 建议阻断合入。全部通过 → PASS。
