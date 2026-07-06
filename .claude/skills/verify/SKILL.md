---
name: verify
description: 变更自验证，按变更类型匹配验证方法并逐项输出证据 — Change self-verification: match verification method by change type, output evidence item by item
---

# 变更自验证 (Verify)

## 变更类型到验证方法的映射

### Controller 新增/修改

**验证方法：** curl 调用接口

```bash
curl -s -X GET "http://localhost:8080/jeecg-boot/xxx/yyy" -H "X-Access-Token: <token>"
```

**验证点：**
- HTTP 状态码为 200
- 响应体 `code` 字段为 200，`success` 为 true
- `result` 字段存在且结构与预期一致
- 数据内容符合业务逻辑

### .vue 组件变更

**验证方法：** Playwright 打开页面，检查元素。

**验证点：**
- 目标元素存在（`page.locator(...).isVisible()`）
- 文本内容与预期一致
- 交互行为（点击/输入/提交）正常

### .data.ts 变更（表格列/表单字段/SearchSchema）

**验证方法：** 根据字段类型选择。

| 变更类型 | 验证方法 |
|----------|----------|
| 表格列定义 | Playwright 打开列表页 → 验证列头存在 |
| 表单字段 | Playwright 打开新增/编辑页 → 验证输入框/选择器存在 |
| SearchSchema | Playwright 打开列表页 → 验证搜索区域字段存在 |

**验证点：**
- 列头/表单标签/搜索字段名与 `.data.ts` 中配置一致
- 必填字段有 `*` 标记
- 字典类型的字段渲染为下拉选择器

### Service 方法变更

**验证方法：** curl 调用上层 Controller（Service 不直接暴露 HTTP 端点）。

**验证点：**
- 间接验证：Controller → Service 调用链正确
- 业务逻辑正确：输入 → 预期输出吻合
- 异常场景：传入非法参数，验证错误信息

### 配置文件变更（application-*.yml / pom.xml）

**验证方法：** 检查对应功能。

| 配置变更 | 验证方法 |
|----------|----------|
| 数据库连接 | curl 查询接口，验证数据返回 |
| 端口 | curl 指定端口，验证连通 |
| 日志级别 | 触发对应日志，检查输出 |
| Maven 依赖 | 编译通过 + 引用新依赖的代码运行正常 |

## 铁律

> **没有具体证据不能声称通过。**

逐项输出格式：

```
✓ 接口 GET /xxx/yyy — HTTP 200, code=200, result 含 3 条记录
✗ 接口 POST /xxx/yyy — HTTP 500, {"message": "NullPointerException at XxxService:42"}
```

每项的 `✓` 必须附具体证据（状态码 + 响应关键片段），`✗` 必须附完整报错信息。

## 验证流程

1. 读取 git diff，识别变更文件和变更类型
2. 按映射表确定每个变更的验证方法
3. 逐项执行验证
4. 汇总输出，标注通过/失败及证据
5. 如有 ✗ 项，分析根因并尝试修复（最多 2 次），修复后重验证
