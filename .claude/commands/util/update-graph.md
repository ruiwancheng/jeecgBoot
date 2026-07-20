# /update-graph

更新代码知识图谱：手工触发增量或全量重建，用于代码审查、新模块索引、图谱数据修复。

## 用法

```
/update-graph           # 增量更新（默认，只解析变更文件）
/update-graph --full    # 全量重建（重新解析所有文件）
```

## 场景

| 场景 | 用什么 |
|------|------|
| 日常提交后 | `/update-graph` |
| 新建模块/大规模重构后 | `/update-graph --full` |
| 图谱数据不准 | `/update-graph --full` |
| 代码审查前 | `/update-graph` |

## 执行

1. 增量：调用 `build_or_update_graph_tool` 不传参数
2. 全量：调用 `build_or_update_graph_tool` 传 `full_rebuild=true`
3. 输出节点/边/文件统计
