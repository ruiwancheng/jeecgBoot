# harness/ — 测试产物

## 说明
自动化测试代码、测试结果、E2E 测试工程等可丢弃产物。永久文档请放 `hermes/`。

## 子目录

| 目录 | 说明 | 跟踪 |
|------|------|:--:|
| [tests/](tests/) | AI 自动生成的测试代码 | 本地 |
| [e2e/](e2e/) | 独立 E2E 测试工程 | 本地 |
| [test-results/](test-results/) | 测试运行产物（临时） | 本地 |

## 文件列表

| 日期 | 文件 | 说明 |
|------|------|------|
| 2026-07-18 | [tests/mes/sales-api.test.mjs](tests/mes/sales-api.test.mjs) | 销售模块 API 测试 |
| 2026-07-16 | [tests/mes/purchase.test.js](tests/mes/purchase.test.js) | 采购模块 API 测试 |
| 2026-07-16 | [tests/mes/manufacturing.test.js](tests/mes/manufacturing.test.js) | 生产制造模块 API 测试 |
| - | [tests/mes/basic.test.js](tests/mes/basic.test.js) | 基础数据 API 测试 |
| - | [e2e/mes/basic.spec.ts](e2e/mes/basic.spec.ts) | 基础数据 E2E 测试 |
| 2026-07-16 | [e2e/mes/purchase.spec.ts](e2e/mes/purchase.spec.ts) | 采购模块 E2E 测试 |

*最后更新: 2026-07-18*
