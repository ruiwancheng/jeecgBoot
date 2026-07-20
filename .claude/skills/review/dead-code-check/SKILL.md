---
name: dead-code-check
description: 死代码检测 — 扫描前后端未引用代码，按置信度分级输出清理建议。Dead code detection with confidence scoring.
version: 1.0.0
---

# dead-code-check — 死代码检测

## Overview

使用 code-review-graph MCP 工具的 `refactor_tool(mode="dead_code")` 扫描全项目未引用代码，按置信度分级，输出清理建议。

**只查不改。** 删除操作需用户手动确认。

## 检测参数

### 后端扫描

| 参数 | 值 |
|------|-----|
| 工具 | `refactor_tool` |
| mode | `dead_code` |
| kind | `Function` |
| file_pattern | `jeecg-boot/` |

### 前端扫描

| 参数 | 值 |
|------|-----|
| 工具 | `refactor_tool` |
| mode | `dead_code` |
| kind | `Function` |
| file_pattern | `jeecgboot-vue3/` |

## 过滤规则（排除框架调用的假阳性）

以下类型的函数即使无直接调用者也不应标记为死代码：

- `public static void main()` — 程序入口
- `@Override` 方法 — 框架通过接口调用
- `@EventListener` 方法 — 框架通过事件机制调用
- `@Scheduled` 方法 — 框架通过定时器调用
- `@PostConstruct` / `@PreDestroy` — 生命周期回调
- Controller `@Mapping` 方法 — 框架通过反射调用（通常已被 Endpoint 边覆盖）

## 置信度分级

| 级别 | 条件 | 建议动作 |
|------|------|---------|
| **HIGH** | 0 callers + 0 tests + 0 importers | 可安全删除 |
| **MEDIUM** | 0 callers + 有 tests 但 tests 也未使用 | 建议标记 `@Deprecated`，下一版删除 |
| **LOW** | 0 callers + 有 tests 且 tests 在使用 | 保留（测试辅助函数） |
| **FALSE** | 匹配过滤规则 | 忽略 |

## 输出格式

```
## 死代码检测报告

### 后端 (jeecg-boot/)

| # | 文件 | 函数 | 行数 | 置信度 | 建议 |
|---|------|------|:--:|:--:|------|
| 1 | XxxService.java | oldMethod | 12 | HIGH | 可安全删除 |
| 2 | YyyUtil.java | helperFunc | 8 | MEDIUM | 先标记 @Deprecated |

### 前端 (jeecgboot-vue3/)

| # | 文件 | 函数 | 行数 | 置信度 | 建议 |
|---|------|------|:--:|:--:|------|
| 1 | old.api.ts | legacyFetch | 5 | HIGH | 可安全删除 |

### 统计
- HIGH 置信度: N 个（可安全删除）
- MEDIUM 置信度: N 个（建议标记废弃）
- LOW 置信度: N 个（保留）
```

## 降级策略

- 图谱不可用 → 输出 `"死代码检测需要 code-review-graph，请先运行 build_or_update_graph_tool"`
- 结果量过大（>1000 条）→ 分批输出，按文件路径排序，前 100 条 + 提示剩余数量
