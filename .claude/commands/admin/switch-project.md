---
description: 自有命令 — 切换项目：切换到另一个已有项目
---

# /switch-project <项目名>

切换到另一个项目。后续操作自动绑定到该项目。

## 执行
1. 使用 `list-projects` 技能验证目标项目是否存在
2. 存在 → 更新 `memory/active-project.md`
3. 不存在 → 提示用 `/new-project` 创建
