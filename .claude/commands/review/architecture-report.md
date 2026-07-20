---
description: 架构健康报告 — 基于知识图谱生成数据驱动的架构健康报告，用于迭代评审和重构规划
---

# /architecture-report

基于 code-review-graph 知识图谱，生成一份数据驱动的架构健康报告。

输出到 `hermes/architecture/YYYY-MM-DD-architecture-report.md`。

## 流程

### 1. 加载领域知识
使用 `architecture-report` 技能获取：三层调用参数（总览/热点/债务）、报告模板、降级策略。

### 2. 确认图谱可用
调用 `list_graph_stats_tool` 检查图谱状态。
- 图谱不存在或过期（>7 天）→ 先运行 `build_or_update_graph_tool`
- 图谱正常 → 继续

### 3. 采集架构数据（三层）
按技能参数，依次调用：
- **第 1 层：** `get_minimal_context_tool` → `get_architecture_overview_tool`（社区地图）
- **第 2 层：** `get_hub_nodes_tool` + `get_bridge_nodes_tool` + `get_surprising_connections_tool`（热点风险 + 耦合违规）
- **第 3 层：** `get_knowledge_gaps_tool` + `find_large_functions_tool` + `list_graph_stats_tool`（结构债务）

### 4. 生成报告
按技能模板填充数据，写入 `hermes/architecture/YYYY-MM-DD-architecture-report.md`。

如有历史报告，自动对比趋势。

### 5. 输出摘要
打印报告路径 + 关键发现摘要（不输出完整报告到对话中）。
