# crg CLI 桥接 MCP 冷启动 (2026-08-07)

## 背景

pi-coding-agent 会话被重置/冷启动后，`code-review-graph` MCP server
未随会话状态自动重新连接，导致以下 MCP 工具全部不可用：

- `semantic_search_nodes_tool`
- `query_graph_tool`
- `detect_changes_tool`
- `get_review_context_tool`
- `get_impact_radius_tool`
- `get_affected_flows_tool`
- `get_architecture_overview_tool`
- `list_communities_tool`
- `refactor_tool`
- （以及另外 2 个）

## 降级方案：crg CLI 桥接

项目根目录提供 `crg` 命令行包装，覆盖 11/13 的 MCP 能力。
用法对照：

| MCP 工具                          | crg 子命令                |
| --------------------------------- | ------------------------- |
| `semantic_search_nodes_tool`      | `crg search "关键词"`     |
| `query_graph_tool`                | `crg query --pattern X`   |
| `detect_changes_tool`             | `crg changes`             |
| `get_impact_radius_tool`          | `crg impact <node>`       |
| `get_affected_flows_tool`         | `crg flows <node>`        |
| `get_architecture_overview_tool`  | `crg arch`                |
| `list_communities_tool`           | `crg communities`         |
| `refactor_tool`                   | `crg refactor`            |
| （死代码扫描）                    | `crg dead-code`           |
| （图重建）                        | `crg build`               |
| （图统计/健康度）                 | `crg stats`               |
| （图增量更新）                    | `crg update`              |

## 注意事项

1. **静默降级是禁止的**：如果 MCP + crg 都不可用，必须向用户输出
   "⚠️ 降级：code-review-graph MCP 不可用 → 改用 Grep/Read" 提示。
2. crg 输出为纯文本，不带 MCP 的 token 节省统计，但保留了节点的
   callers/callees/imports/tests_for 关系链，足够支撑常规 code review。
3. 不要因为 crg 能用就重启 pi 重连 MCP —— 成本太高，按需用即可。
4. crg 内部走 `~/.crg/index.duckdb` 本地 DuckDB 索引，不依赖网络。

## 触发场景（何时记起本卡片）

- 会话开头收到 "本会话未注入 MCP 工具" 字样
- 调用 MCP 工具返回 "Tool not found" / "MCP server not connected"
- 需要调用 `semantic_search` 等工具但工具列表为空
