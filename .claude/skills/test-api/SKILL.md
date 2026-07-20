---
name: test-api
description: 后端 API 接口测试，支持模块级和全量测试，自动诊断报错、查询日志并修复。Backend API testing with auto-diagnosis, log inspection, and fix.
---

# 后端 API 接口测试

## 测试文件命名

`harness/tests/<项目名>/<功能名>.test.js`

## 错误诊断与修复映射表

| 报错类型 | 诊断方法 | 自动修复方案 |
|---------|---------|------------|
| 接口返回 500 | 查后端日志 `/tmp/jeecg-backend.log` 定位异常栈 | 根据异常信息修复代码后重跑 |
| 数据校验失败 | 检查请求参数是否缺少必填字段或格式不对 | 补全请求参数或调整校验规则 |
| 重复数据冲突 | 检查是否使用了固定值导致唯一约束冲突 | 测试数据加时间戳后缀避免冲突 |
| 返回格式异常 | 检查 Controller 是否用 `Result<T>` 包装返回 | 确认返回格式为 `{ code: 200, success: true, result: ..., message: "..." }` |
| 认证失败（401/403） | 检查登录配置 | 确认 `application-dev.yml` 中 `jeecg.login.enableLoginCaptcha: false` |

## JeecgBoot 特定知识

- API 响应格式：`Result<T>` 包含 `code`(int), `success`(boolean), `result`(T), `message`(String)
- 开发环境验证码配置键：`jeecg.login.enableLoginCaptcha`（需设为 false）
- 认证 Token 通过 `/jeecg-boot/sys/login` 获取

## 最大重试次数

3 次

## 智能测试范围（Graph Smart Scoping）

使用 code-review-graph MCP 工具精准确定测试范围，避免全量跑。

### 调用参数

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 1. 变更检测 | `detect_changes_tool` | `base="HEAD~1"`, `detail_level="minimal"` | 识别变更影响哪些 API |
| 2. 测试覆盖 | `query_graph_tool` | `pattern="tests_for"`, `target="<变更的Controller>"` | 确认是否有现成测试 |

### 判定规则

| 条件 | 动作 |
|------|------|
| 变更影响了 Controller | 只跑该 Controller 相关的 API 测试 |
| 变更未影响 Controller（仅 Service/Mapper） | 找到调用该 Service 的 Controller，跑对应测试 |
| 无变更（手动触发） | 全量跑 |
| 已有测试覆盖 | 直接跑已有测试，不重新生成 |

### 降级策略

图谱不可用 → 全量跑（标准行为）
