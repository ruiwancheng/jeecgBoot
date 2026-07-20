---
name: architecture-report
description: 架构健康报告 — 基于知识图谱生成数据驱动的架构健康报告，含社区地图、热点风险、耦合违规、结构债务。Data-driven architecture health report powered by code knowledge graph.
version: 1.0.0
---

# architecture-report — 架构健康报告

## Overview

综合 code-review-graph MCP 的多个工具，生成一份数据驱动的架构健康报告。适合迭代评审、架构决策记录（ADR）、重构规划。

**输出位置：** `hermes/architecture/YYYY-MM-DD-architecture-report.md`

## 调用参数

### 第 1 层：架构总览

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 1. 入口 | `get_minimal_context_tool` | `task="architecture report"` | 快速了解当前图状态 |
| 2. 架构 | `get_architecture_overview_tool` | `detail_level="standard"` | 社区地图 + 跨社区耦合数据 |

### 第 2 层：热点与风险

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 3. Hub 节点 | `get_hub_nodes_tool` | `top_n=20` | 引用最多的函数（高风险变更区） |
| 4. Bridge 节点 | `get_bridge_nodes_tool` | `top_n=20` | 架构瓶颈（断裂影响最大） |
| 5. 意外耦合 | `get_surprising_connections_tool` | `top_n=20` | 违反预期分层的依赖 |

### 第 3 层：结构债务

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 6. 知识缺口 | `get_knowledge_gaps_tool` | 默认参数 | 孤立节点 + 未测试热点 + 薄社区 |
| 7. 大函数 | `find_large_functions_tool` | `min_lines=50`, `limit=30` | 拆分候选列表 |
| 8. 统计 | `list_graph_stats_tool` | 默认参数 | 节点/边/语言/新鲜度 |

## 报告模板

```markdown
# 架构健康报告 — {YYYY-MM-DD}

## 1. 社区地图
- 社区总数：{N}
- 社区列表（按规模排序）
- 跨社区耦合 Top 5

## 2. 热点风险（Top 20 Hub + Bridge）
- Hub 节点：高引用函数（变更波及面大）
- Bridge 节点：架构瓶颈（断裂影响最大）
- 建议：这些节点应优先保证测试覆盖

## 3. 耦合违规（Top 20 意外连接）
- 跨社区 + 跨语言 + 周边到中枢的异常依赖
- 每条标注惊喜评分和原因

## 4. 结构债务
- 未测试热点：{N} 个
- 孤立节点：{N} 个
- 大函数（>50 行）：{N} 个
- 建议优先拆分的前 10 个

## 5. 趋势（如有历史报告）
- 与上次报告的对比
- 新增/消失的社区
- 耦合度变化

## 6. 改进建议
- 基于以上数据的 3-5 条优先级排序建议
```

## 降级策略

- 图谱不可用 → 输出 `"架构报告需要 code-review-graph，请先运行 build_or_update_graph_tool"`
- 部分工具失败 → 报告中标注 `"数据不可用"`，可用工具仍参与
- 无历史报告 → 趋势章节标注 `"首次报告，无历史对比"`
