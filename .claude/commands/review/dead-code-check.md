---
description: 死代码检测 — 扫描未引用代码，按置信度分级输出清理建议
---

# /dead-code-check

扫描项目前后端死代码（0 调用者 + 0 测试的函数），按置信度分级输出清理建议。

**只查不改。** 删除操作需手动确认。

## 流程

### 1. 加载领域知识
使用 `dead-code-check` 技能获取：检测参数、过滤规则、置信度分级标准、输出格式。

### 2. 确认图谱可用
调用 `list_graph_stats_tool` 检查图谱状态。
- 图谱不存在或过期 → 先运行 `build_or_update_graph_tool`
- 图谱正常 → 继续

### 3. 扫描后端
按技能参数调用 `refactor_tool(mode="dead_code")` 扫描 Java 代码。
按过滤规则排除假阳性，按置信度分级。

### 4. 扫描前端
同上，扫描 Vue/TypeScript 代码。

### 5. 输出报告
按技能格式输出清理报告。询问：
```
删除所有 HIGH 置信度死代码？(y/n)
```
仅删除 HIGH 置信度项（MEDIUM/LOW 保留）。
