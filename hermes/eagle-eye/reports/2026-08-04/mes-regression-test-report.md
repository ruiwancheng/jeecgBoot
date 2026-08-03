# MES 全量回归测试报告 — 2026-08-04

**总测试数**：453 API + 26 E2E（+3 跳过） + 742 前端 TS 错误
**总失败数**：17 API + 7 E2E + 742 TS（按 P0/P1/P2/P3 分级）
**总通过率**：API 95.96% / E2E 73.1% / 前端 vue-tsc 错误率约 5.7%
**总耗时**：约 35 分钟（API 25 分钟 + E2E 2.2 分钟 + 前端 5 分钟）

---

## 一、模块汇总

| 模块 | API 测试 | 状态 | E2E 测试 | 状态 | 前端 TS | 报告 |
|---|:-:|:-:|:-:|:-:|:-:|---|
| basic | 14/14 | ✅ 100% | (basic.spec.ts) | ✅ | 0 | [basic](./mes-basic-test-report.md) |
| batch | 9/9 + 0/1 + 42/42 | ⚠️ 95.8% | 4/6 | ⚠️ 66.7% | 2 | [batch](./mes-batch-test-report.md) |
| manufacturing | 24/24 | ✅ 100% | ❌ 无 | — | 0 | [manufacturing](./mes-manufacturing-test-report.md) |
| purchase | 26/26 + 10/18 + 16/16 | ⚠️ 92.9% | 3/6 | ⚠️ 50% | 0 | [purchase](./mes-purchase-test-report.md) |
| sales | 30/30 + 24/24 | ✅ 100% | 1/2 | ⚠️ 50% | 0 | [sales](./mes-sales-test-report.md) |
| stock | 9/9 + 28/28 | ✅ 100% | 1/2 | ⚠️ 50% | 0 | [stock](./mes-stock-test-report.md) |
| **finance** | **113/119 (新增)** | ⚠️ 95% | ❌ 无 E2E | — | **18** | [finance](./mes-finance-test-report.md) |
| system | 13/15 + 20/20 | ⚠️ 87.5% | 1/1 | ✅ | 0 | [system](./mes-system-test-report.md) |
| commonSetting | — | — | 0/1 | ❌ | 0 | [commonSetting](./mes-commonSetting-test-report.md) |
| codeRule | 20/20 | ✅ 100% | — | — | 0 | (含 system 报告) |
| **前端 vue-tsc + build** | — | — | — | — | **742 / ✅ build** | [frontend](./mes-frontend-test-report.md) |

---

## 二、Top 失败（按级别排序）

### 🔴 P0 — 核心流程跑不通
- **无 P0 失败**（核心登录、菜单、路由全部正常）

### 🟠 P1 — 数据/接口错误（明早优先）

| # | 模块 | 失败点 | 错误 |
|---|---|---|---|
| **1** | **purchase** | **采购入库审核** | **SQL 异常：c_mes_payable 需要 supplier_id 但 c_mes_purchase_receipt 没这个字段** |
| **2** | **basic** | **Customer 列表查询** | **SQL 异常：MesCustomer 实体有 grade 等 6 列，c_mes_customer 表都不存在** |
| **3** | **前端 vite proxy** | **`.env.development` 路径错** | **`/jeecgboot` 应为 `/jeecg-boot`**（影响所有 E2E 测试） |
| **4** | **前端路由** | **finance 路由完全未注册** | **`router/routes/modules/mes.ts` 缺 finance 节点** |
| 5 | system | GlobalSwitch.save 空 body | 返回 `500 + java.sql.SQLException`（应业务校验拦截）|
| 6 | finance | 8 个 controller 的 `.data.ts` | 用 `dictCode` / `dictTable` 字段（BasicColumn 类型不支持）|
| 7 | batch | BatchMasterDrawer | `onValuesChange` 类型错 + 参数个数错 |
| 8 | 前端 | 742 个 TS 错误（MES 占 30） | 涉及 super/demo/system/project 多个模块 |

### 🟡 P2 — UI/E2E 异常

| # | 模块 | 失败点 | 备注 |
|---|---|---|---|
| 1 | commonSetting | 通用设置页面 | 整页不可达 |
| 2 | materialBatch | 总开关开启时物料表单 | batchEnabled 可编辑测试失败 |
| 3 | other-stock-in | 新增入库单物料预填成本 | 移动平均成本未自动预填 |
| 4 | purchase | E2E-04 采购订单页面加载 | 列表/搜索无响应 |
| 5 | purchase | E2E-05 采购入库页面加载 | 同上 |
| 6 | sales-order | E2E-01 销售订单页面加载 | 列表/搜索无响应 |
| 7 | traceability | #4 抽屉"批次流水" | drawer 显示"暂无流水"（V10.0.3 已知问题） |
| 8 | purchase-apply-order.chain | 审核申请 | 交货日期不能早于订单日期 |

### 🟢 P3 — 测试代码 / 数据 bug

| # | 模块 | 失败点 | 备注 |
|---|---|---|---|
| 1 | batch-global-switch | 找不到 status=4 采购订单 | 测试前置数据缺失 |
| 2 | finance | add 空 body 断言 | 后端 500 + 业务校验，断言写错 |
| 3 | system | 字段名猜错 | enabled/switchValue，hasError/canClose |

---

## 三、跨模块问题

1. **TS 错误集中在 finance .data.ts**（8 个文件 × 2 个错误 = 18 个） — 同样的反模式 8 次复制
2. **多个 E2E 页面加载失败**（purchase/sales-order/commonSetting） — 可能是登录后 token 注入失败或菜单权限问题
3. **V10.0.3 批次追溯抽屉问题**仍是 P2

---

## 四、🔴 DB 状态 — 重要 ⚠️

**测试期间 DB 大小从 7.3MB → 645K（缩水 91%）！**

| 时间点 | 文件 | 大小 | 用途 |
|---|---|---:|---|
| 测试前 | `/tmp/mes-snap-20260804-001501.sql` | 7.3M | 完整 baseline |
| 测试后 | `/tmp/mes-post-test-20260804.sql` | 645K | 当前状态 |

**根因分析**（待排查）：
- 部分测试用 helpers/fixtures.js 的 safeDeleteDoc 自动清理（成功）
- 部分测试可能直接 DELETE 而未清理（漏掉了）
- 或 batch-manual-e2e 创建的批次被级联删除（外键约束）

**回滚选项**：
```bash
# 选项 A：完整回滚到测试前（明早再操作）
"/c/Program Files/MySQL/MySQL Server 8.4/bin/mysql.exe" -uroot -proot --host=127.0.0.1 --protocol=TCP jeecg-boot < /tmp/mes-snap-20260804-001501.sql

# 选项 B：保留当前数据用于排查
#（已备份 mes-post-test-20260804.sql）
```

**建议**：明早第一件事先确认是否要回滚。

---

## 五、明早行动建议

### 优先级 1（先做，影响核心）
1. **DB 回滚决策**（先执行，避免进一步数据丢失）
2. **P1-1**: System GlobalSwitch.save 加 `@RequestBody` 校验或 `@Valid` 注解
3. **P1-2/3**: finance 8 个 `.data.ts` 的 `dictCode/dictTable` 改为支持的字段（如 `customRender`），或扩展 BasicColumn 类型
4. **P1-4**: BatchMasterDrawer 的 `onValuesChange` 类型 + 参数修复

### 优先级 2（批量修）
- P2-1/2/3/4/5/6: 多个 E2E 页面加载失败 — 先看截图 + trace token 注入
- P2-7: traceability 抽屉 — 已知 V10.0.3 问题（详见 traceability 报告）
- P2-8: purchase-apply-order 日期校验

### 优先级 3（清理）
- P3-1: 给 batch-global-switch 准备测试前置数据
- P3-2/3: finance/system 测试断言改写

---

## 六、产物清单

```
hermes/eagle-eye/reports/2026-08-04/
├── mes-regression-test-report.md       # 本文件
├── mes-basic-test-report.md
├── mes-batch-test-report.md
├── mes-manufacturing-test-report.md
├── mes-purchase-test-report.md
├── mes-sales-test-report.md
├── mes-stock-test-report.md
├── mes-finance-test-report.md
├── mes-system-test-report.md
├── mes-commonSetting-test-report.md
└── mes-frontend-test-report.md         # vue-tsc + build

hermes/eagle-eye/state/
├── mes-regression.json                  # 状态快照
├── api-logs/                            # API 测试原始日志
├── e2e-20260804.log                     # E2E 原始日志
├── typecheck-20260804.log               # vue-tsc 原始日志
└── build-20260804.log                   # pnpm build 原始日志
```

---

## 七、跑测期间的环境变更

| 项 | 状态 |
|---|---|
| 后端 fat JAR | PID 91207（V10.0.3 已部署，未变）|
| 前端 vite dev | PID 91677（启动于 /test-all 阶段，本次继续使用）|
| Orca 工作树 | `eagleeye/mes-regression` 已建（未使用，代码 baseline）|
| git longpaths | ✅ 启用 |
| 新增测试代码 | `harness/tests/mes/finance.test.js`、`harness/tests/mes/system.test.js`（未 commit）|