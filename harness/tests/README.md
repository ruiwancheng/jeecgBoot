# Harness 测试体系使用指南

> **业务人员 + 开发者共用**：本文档说明如何运行、扩展、维护回归测试。
> **建立日期**：2026-08-04（W2 收尾落地）

## 一、体系总览

| 测试类型 | 目录 | 数量 | 用途 |
|---|---|---|---|
| **API 模块测试** | `harness/tests/modules/basic-*.test.js` | 9 个 | 测后端 controller 端点（CRUD + 校验 + 边界）|
| **链路测试** | `harness/tests/chains/*.test.js` | 9 个 | 测多步业务链路（跨 controller 流程）|
| **E2E UI 测试** | `harness/e2e/mes/basic-*.spec.ts` | 9 个 | 测前端页面渲染 + Drawer + 工具栏 |
| **冒烟测试** | `harness/e2e/smoke/*.spec.ts` | 2 个 | 快速验证关键页面可达 |

**总计**：~260 个测试用例，**100% 通过率**（W2 完成后）。

## 二、快速运行

### 2.1 一键运行（推荐）

**Linux / macOS / Windows**（统一入口）：
```bash
cd harness
python3 ../harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json
```

> 自 2026-08-06 起，原一键 shell/bat 脚本已废弃（死代码，仅 1 个 git commit，runner 端无引用）。统一改用 `resilient_regression.py` 走 manifest 调度（自带 crash guard + checkpoint + 报告生成）。

### 2.2 单文件运行

**API 模块测试**：
```bash
cd harness
node tests/modules/basic-customerAddress.test.js
node tests/modules/basic-batchInventory.test.js
node tests/modules/basic-otherStockOut.test.js
# ... 等等（9 个 basic-* 文件）
```

**E2E UI 测试**：
```bash
cd harness
PLAYWRIGHT_BASE_URL=http://localhost:3100 \
E2E_UI_BASE=http://localhost:3100 \
E2E_API_BASE=http://localhost:8080/jeecg-boot \
npx playwright test e2e/mes/basic-customerAddress.spec.ts

# 全部 E2E
npx playwright test e2e/mes/basic-*.spec.ts
```

**链路测试**：
```bash
cd harness
node tests/chains/sales-receipt-flow.test.js
node tests/chains/purchase-chain.test.js
# ... 等等
```

## 三、前置依赖

### 3.1 服务要求

| 服务 | 端口 | 启动方式 |
|---|---|---|
| **MySQL** | 3306 | `docker compose up -d mysql`（密码 root/root）|
| **后端 fat-jar** | 8080 | 详见 `mes-2026-08-04` 业务记录 |
| **前端 Vite dev** | 3100 | `cd jeecgboot-vue3 && pnpm dev` |

### 3.2 工具要求

- **Node.js** 18+
- **Maven** 3.9+（后端编译）
- **Java 17**（后端运行）
- **pnpm** 10+（前端包管理）

### 3.3 Playwright 浏览器

第一次跑 E2E 前需要安装 Chromium：
```bash
cd harness
npx playwright install --with-deps chromium
```

## 四、新增测试（业务人员命令）

### 4.1 业务人员触发

**告诉 AI 命令**，例如：

```bash
/add-tests basic customerContact   # 添加 basic 项目的 customerContact 子模块
/add-tests stock otherOut         # 添加 stock 项目的 otherOut 子模块
/add-tests sales 链路 sales-receipt-flow  # 添加完整业务链路
```

**AI 自动完成**：
1. 读后端 controller + 前端 index.vue + api.ts
2. 设计测试矩阵（CRUD + 校验 + 边界 + 错误路径）
3. 写 `harness/tests/modules/basic-<scope>.test.js`
4. 写 `harness/e2e/mes/basic-<scope>.spec.ts`
5. 跑测验证
6. commit + push（commit 信息带 `[/add-tests]` 前缀）

### 4.2 覆盖度查询

```bash
/coverage                 # 总览：覆盖率统计
/coverage gap             # 缺口清单：所有无覆盖端点
/coverage basic           # basic 项目详情
/coverage basic customer  # customer 模块详情
```

## 五、测试命名规范

### 5.1 API 模块测试

- **位置**：`harness/tests/modules/basic-<scope>.test.js`
- **示例**：`basic-customerAddress.test.js`、`basic-otherStockOut.test.js`
- **结构**：
  - 1.x CRUD 主流程
  - 2.x 树形/特殊查询
  - 3.x 校验规则
  - 4.x 错误路径
  - 5.x 边界条件
  - 6.x 导出
  - 7.x 删除

### 5.2 E2E UI 测试

- **位置**：`harness/e2e/mes/basic-<scope>.spec.ts`
- **示例**：`basic-customerAddress.spec.ts`
- **结构**（5-7 个 test）：
  - 1. 路由可达
  - 2. 表格渲染
  - 3. 工具栏按钮
  - 4. 数据/空状态
  - 5. 点击新增 → Drawer 打开
  - 6. 搜索表单 + 查询
  - 7. 行操作（如有：编辑/删除/查看追溯）

### 5.3 链路测试

- **位置**：`harness/tests/chains/<flow>.test.js` 或 `<flow>.chain.test.js`
- **示例**：`sales-receipt-flow.test.js`、`purchase-chain.test.js`
- **结构**（按 step）：
  - 0. Setup（仓库/物料/客户等）
  - 1.x 主业务步骤
  - 2.x 审核
  - 3.x 数据校验
  - 4.x 跨表对账
  - 5.x 财务生成
  - 6.x 收款/付款
  - 7.x Cleanup

## 六、CI 集成

GitHub Actions workflow：`.github/workflows/functional-regression.yml`

**3 个 job**：
- `api-test`：跑 `tests/modules/basic-*.test.js`
- `e2e-test`：跑 `e2e/mes/basic-*.spec.ts`
- `typecheck`：跑 `vue-tsc --noEmit`（软门控 ≤200 错误）

**触发**：
- push to main / fix/**
- pull_request to main
- workflow_dispatch（手动触发）

## 七、维护说明

### 7.1 测试失败定位

| 失败类型 | 排查路径 |
|---|---|
| API 测试失败 | 看 `harness/tests/modules/basic-*.test.js` 的 console.log 输出 |
| E2E 失败 | 看 `harness/test-results/<spec>/test-failed-1.png` 截图 |
| 服务不可用 | 确认 8080 / 3100 / 3306 三个端口服务正常 |

### 7.2 数据清理

API 测试用 `dbCleanup` 函数清理历史数据（依赖 MySQL root 权限）。CI 上 GitHub Actions service 提供了 `mysql:8.0` + `MYSQL_ROOT_PASSWORD: root`，可直接跑 dbCleanup。

### 7.3 新增 controller 的测试

未来新加 controller 时：
1. 主动跑 `/add-tests <项目> <模块> <页面>` 命令
2. AI 自动补齐测试
3. 业务人员无需懂代码细节

## 八、相关命令

| 命令 | 用途 |
|---|---|
| `/add-tests` | 主动添加测试（业务人员用）|
| `/coverage` | 查看覆盖率统计（业务人员用）|
| `/test-all` | 跑全量测试 |
| `/test-e2e` | 跑 E2E 测试 |
| `/test-api` | 跑 API 测试 |
| `/test-regression` | 跑回归测试 |

（命令定义在 `.claude/commands/test/` 目录）

## 九、变更记录

- **2026-08-04**：W2 完成，建立回归测试体系
  - 9 个子模块测试（0 → 100% 覆盖）
  - 18 个测试文件 / ~260 个测试用例
  - 一键运行脚本（Linux/Windows）
  - CI workflow 修复（路径从 `tests/mes/` → `tests/{modules,chains}/`）