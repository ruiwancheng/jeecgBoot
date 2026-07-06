---
description: 自有命令 — 自动生成测试：根据接口代码+前端页面自动生成API和E2E测试用例
---

# /gen-tests <项目名> <功能名>

**每次运行都重新生成**，覆盖已有测试文件。根据最新代码 + 自定义推导规则重新生成 API 和 E2E 测试用例。

## 用法
- `/gen-tests demo 仓库管理` — 为仓库管理生成 API + E2E
- `/gen-tests demo` — 为 demo 项目所有功能生成

## 流程

### 1. 加载领域知识
使用 `gen-tests` 技能获取：环境初始化命令、Playwright 配置模板、API/E2E 推导规则、测试目录结构、自定义规则合并逻辑。

### 2. 生成 API 测试
按技能中的推导规则，从 Controller 方法生成测试用例。输出到 `harness/tests/<项目名>/<功能名>.test.js`。

### 3. 生成 E2E 测试
按技能中的推导规则，从前端 `.data.ts` 配置生成测试用例。E2E 测试用 `npx playwright test` 运行。输出到 `harness/e2e/<项目名>/<功能名>.spec.ts`。

### 4. 告知
生成了哪些测试文件、API 覆盖了几个接口（标注自定义规则命中数）、E2E 覆盖了几个场景。
