---
name: capability-check
description: MCP 能力检测 — 诊断 code-review-graph MCP 工具可用性，三阶段探测输出 P0/P1/P2 分级报告 + 配置指引。MCP capability diagnostic with tiered reporting.
version: 1.0.0
---

# MCP 能力检测

## 探测流程

### Stage 1: MCP 服务可用性
检查 code-review-graph MCP 工具是否在当前会话的工具列表中。
- 工具列表中有 `mcp__code-review-graph__*` 开头的工具 → ✅ MCP 服务已连接
- 工具列表中无相关工具 → ❌ MCP 服务未安装或未配置

> 不需要实际调用工具，直接检查系统提示中的 MCP 工具列表即可。

### Stage 2: 知识图谱状态
如果 Stage 1 通过，调用 `list_graph_stats_tool` 检查图谱是否已构建。
- 返回节点数 > 0 → ✅ 图谱已构建（标注构建日期和节点数）
- 返回节点数 = 0 或报错 → ⚠️ 图谱未构建（MCP 在线但需初始化）
- 调用失败/超时 → ❌ 图谱不可用

### Stage 3: 代表性工具探测
如果 Stage 2 通过，调用 `get_minimal_context_tool(task="capability check")` 验证工具链完整。
- 返回正常 → ✅ 工具链正常
- 返回错误 → ⚠️ 部分工具不可用（标注具体工具）

## P0/P1/P2 分类矩阵

### P0 级依赖（阻断 — 缺失则命令不可用）
| 命令 | 依赖工具 | 不可用时 |
|------|---------|---------|
| /architecture-report | get_architecture_overview_tool, get_hub_nodes_tool, get_bridge_nodes_tool 等 | ❌ 完全不可用 |
| /dead-code-check | refactor_tool(mode="dead_code") | ❌ 完全不可用 |

### P1 级依赖（降级 — 缺失则失去增强能力）
| 命令 | 依赖工具 | 降级影响 |
|------|---------|---------|
| /review | detect_changes_tool, get_hub_nodes_tool, get_bridge_nodes_tool | 失去架构感知严重度调整 |
| /verify | detect_changes_tool, get_impact_radius_tool | 失去风险评分和波及分析 |
| /debug | query_graph_tool, get_affected_flows_tool | 失去调用链自动追踪 |
| 自由对话（代码探索）| semantic_search_nodes_tool, query_graph_tool | 失去结构化代码导航 |

### P2 级依赖（增强 — 缺失不影响核心功能）
| 命令 | 依赖工具 | 失去的功能 |
|------|---------|-----------|
| /gen-tests | query_graph_tool, get_knowledge_gaps_tool | 调用链覆盖扩展 |
| /test-api | detect_changes_tool | 智能测试范围 |
| /test-e2e | get_affected_flows_tool | 流程覆盖增强 |
| /test-frontend | query_graph_tool | 组件引用验证 |
| /test-all | get_minimal_context_tool | 智能范围判定 |
| /harness-check | 多个 MCP 工具 | 第8轴（代码结构健康） |

## 报告模板

```
## MCP 能力检测报告

### 基础设施
| 组件 | 状态 | 详情 |
|------|:----:|------|
| MCP 服务 (code-review-graph) | ✅/❌ | 已连接 / 未安装 |
| 知识图谱 | ✅/⚠️/❌ | N 节点, N 边 (N天前构建) / 需初始化 / 不可用 |
| 工具链完整性 | ✅/⚠️ | 正常 / 部分不可用 |

### P0 级依赖（阻断）
| 命令 | 状态 | 说明 |
|------|:----:|------|
| /architecture-report | ✅/❌ | 可用 / 完全不可用 |
| /dead-code-check | ✅/❌ | 可用 / 完全不可用 |

### P1 级依赖（降级）
| 命令 | 状态 | 降级影响 |
|------|:----:|---------|
| /review | ✅/⚠️ | 失去架构感知严重度调整 |
| /verify | ✅/⚠️ | 失去风险评分和波及分析 |
| /debug | ✅/⚠️ | 失去调用链自动追踪 |
| 自由对话(代码探索) | ✅/⚠️ | 失去结构化代码导航 |

### P2 级依赖（增强）
| 命令 | 状态 | 失去的功能 |
|------|:----:|-----------|
| /gen-tests | ✅/⚠️ | 调用链覆盖扩展 |
| /test-* (4个) | ✅/⚠️ | 智能范围/流程覆盖 |
| /harness-check | ✅/⚠️ | 第8轴(代码结构健康) |

### 总结
- P0 阻断: N 项 (N/2 可用)
- P1 降级: N 项
- P2 缺失: N 项

### 配置指引
如需配置 MCP，请参考：
- settings.local.json: "enableAllProjectMcpServers": true, "enabledMcpjsonServers": ["code-review-graph"]
- 首次使用需构建图谱: /update-graph
```

## 配置指引

### 前提条件
1. 项目 `.claude/settings.local.json` 中包含：
   ```json
   "enableAllProjectMcpServers": true,
   "enabledMcpjsonServers": ["code-review-graph"]
   ```
2. MCP 服务已安装（`code-review-graph` Python 包）
3. 首次使用需运行 `/update-graph` 构建知识图谱
