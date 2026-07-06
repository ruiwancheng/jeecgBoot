---
name: testing
description: 测试标准——从 Controller/Service 推导测试用例
glob: "**/*.test.*,**/*.spec.*"
version: 1.0
---

# 测试标准

## 后端
- `@GetMapping` → 正常查询 + 空数据 + 参数校验
- `@PostMapping` → 新增成功 + 必填缺失 + 重复数据
- `@PutMapping` → 更新成功 + 不存在 + 权限不足

## 实战要点
- API 测试需 `enableLoginCaptcha: false` 关闭验证码
- E2E 测试用浏览器登录（fill+click），不直接设 Token
- 测试文件放 `harness/tests/<项目名>/` 和 `harness/e2e/<项目名>/`

## 目标
- Service 层 80%+、Controller 层 60%+

## Bug 反哺 gen-tests 推导规则

开发过程中修复的 Bug 可反哺测试用例生成逻辑，让 gen-tests 持续进化：

```
Bug修复 → /debug 分析根因 → 判断gen-tests是否漏了此类场景
  → 是：询问用户确认 → 追加规则到 .claude/rules/gen-tests-rules.json
  → 否（架构/环境问题）：记录到 learnings/
```

下一次 `/gen-tests` 运行时自动加载自定义规则，同一类 Bug 场景被覆盖。

规则存储：`.claude/rules/gen-tests-rules.json`，内置规则 + 自定义规则合并，自定义优先。
