# W2 Sprint 回归测试体系 — Claude 评审报告

> **评审人**：Claude Opus 4.8（第二意见评审）
> **评审日期**：2026-08-04
> **评审对象**：`hermes/eagle-eye/reports/2026-08-04/regression-system-design.md`
> **证据基础**：实际代码走读（9 模块测试 + 9 E2E spec + 9 链路测试 + CI workflow + 脚本 + helpers）

---

## 总评：B+（良好，有 6 个必须修复项）

设计合理、覆盖面广、文档清晰。但**段文件 `process.exit` 会杀死父编排器**（P0 bug）、**双 Playwright config 不一致导致误解**、**auth helper 默认值违反 `testing.md` 禁止硬编码规则**、**CI API 测试没有后端服务**（job 间独立隔离）——这些问题让 100% 通过率存在脆弱性。

---

## 1. 完整性评审

### 1.1 覆盖了什么（✅ 做得好）

| 维度 | 实际覆盖 | 评价 |
|------|---------|:--:|
| 9 子模块 API（CRUD + 校验 + 边界） | 9 文件，178 check() 断言 | ✅ |
| 9 子模块 E2E（路由 + 渲染 + 工具栏 + Drawer） | 9 spec（另有 6 个存量 basic-* spec 不在本次范围） | ✅ |
| 9 条链路（跨模块数据流） | 9 文件（含 3 段链 + 1 编排器） | ✅ |
| 前端类型检查 | CI job typecheck（软门控 ≤200 错误） | ✅ |
| 断言密度自检 | CI api-test step：每个 .test.js ≥2 断言 | ✅ |
| 运行时诊断采集 | diagnostic-test.ts 收集 console/pageerror/failed requests | ✅ |

### 1.2 没覆盖什么（⚠️ 需关注）

| 缺口 | 严重度 | 说明 |
|------|:--:|------|
| **并发安全** | P1 | 0 个并发测试。`synchronized+@Transactional` 取号重复、金额并发超收等历史 P0 都没有回归防护。建议加 `Promise.all` 并发调用同一端点验证幂等/行锁。 |
| **性能回归** | P2 | 0 个性能断言。无响应时间阈值、无大数据量查询限制验证。现有 deep-inspect 基础设施可用但未联动——建议 `/coverage` 命令补 `--perf` 选项。 |
| **跨浏览器** | P3 | Playwright 仅用 chromium。对于 B2B 内网系统可接受，但 README 应注明"当前仅 chromium"。 |
| **错误恢复路径** | P1 | 只测了"编辑不存在 ID"等基础错误路径（mybatis-plus 静默成功 0 行），没有测：<br>- 事务回滚后状态一致性<br>- 审核失败后单据是否留在草稿<br>- API 超时/网络断开后重试 |
| **数据隔离（权限）** | P1 | 所有测试用 `mes_admin`/`admin` 登录。没有验证普通用户的数据范围过滤（`@PermissionData`）。历史审计 P0 曾发现数据隔离用硬编码用户名——这条规则加了但没回归验证覆盖。 |
| **导入/导出实质性验证** | P2 | 只验证端点可达（HTTP 200），不验证：导出内容正确、导入校验拒绝非法数据。 |
| **测试间隔离** | P2 | 9 个 module 测试共享同一个数据库。没有并发跑的安全保证——如果并行化（如 CI 加 `matrix`），`LIKE 'ADDR_T_%'` 清理会互相踩。 |

### 1.3 边界覆盖矩阵

```
                     covered?    depth
CRUD happy path      ✅ ✅ ✅    good (创建→查询→编辑→删除)
空状态               ✅          basic (list with pageSize=0)
超大分页             ✅          basic (pageNo=999, pageSize=999999)
负数参数             ✅          basic (pageNo=-1)
必填字段缺失          ⚠️         skipped ("controller 不校验")
并发冲突              ❌          none
事务回滚              ❌          none
权限越权              ❌          none
大数据量              ❌          none
网络异常              ❌          none
```

---

## 2. 可行性评审

### 2.1 CI workflow 结构问题（🔴 P0）

**核心问题：api-test 和 e2e-test 是两个独立 job，不共享 services。**

```yaml
# api-test job: 有 mysql + redis services，自启动 java -jar 后端
# e2e-test job: 无 mysql/redis services，只 build 前端 + pnpm preview
```

**结果**：
- ✅ **api-test** 可以独立运行（自包含后端 + DB）
- ❌ **e2e-test** 跑不了——前端 `pnpm preview` 启动后，页面内的 API 调用 `fetch('http://localhost:8080/jeecg-boot/...')` 没有后端响应。前端只是静态文件服务，所有 XHR 都 404/ECONNREFUSED。
- ❌ **e2e-test 配置了 `continue-on-error: true`（软门控）**，所以**即使全部 E2E 失败，job 也会绿**。

**实际后果**：CI 上 e2e-test 从未真正通过过（在 fork 环境更不可能——连数据库都没有）。soft gate 掩盖了这个事实。

**修复方案**：二选一
- **A（推荐，简单）**：e2e-test job 也加 `services: mysql + redis`，在 job 内启动后端
- **B（更快但 hacky）**：合三为一——一个 job 同时启动后端+前端+跑测试

**可临时不修**：如果 CI workflow 尚未在任何 fork 跑过且当前只用于"文档演示"，可在 README 明确标注"CI workflow 为模板，实际运行需服务端数据库"。

### 2.2 服务配置足够吗？

| 服务 | 配置 | 评价 |
|------|------|:--:|
| MySQL 8.0 | `MYSQL_ROOT_PASSWORD: root` | ✅ CI services OK。但 `Init MySQL schema` 步骤 `find ... -exec mysql < "$f"` **每次运行都导入所有 SQL**——幂等的建表 OK，但 `DELETE+INSERT` 字典项会擦写。不影响结果但非最优（慢）。 |
| Redis 7 | 仅 api-test 有 | ⚠️ JeecgBoot 用 Redis 做 Shiro session 缓存。prod 配置通常要 Redis，但 dev 可用内存 session。当前 CI 没验证 Redis 是否真被用到。 |
| 后端启动 | `java -jar ... --spring.flyway.enabled=false` | ⚠️ 手动 init schema 后关 Flyway 是正确做法，但 `for i in $(seq 1 40); sleep 3` 等 120s——fat-jar 冷启动在 GitHub Actions 2-core runner 上可能需要 60-90s，120s 是安全边界，OK。 |

### 2.3 时间估算

| 场景 | 估算 | CI timeout | 充裕？ |
|------|------|:--:|:--:|
| api-test（9 模块 + 9 链路，串行） | ~3-5 min（本地 localhost）<br>~8-12 min（CI cold start + DB init + mvn install） | 25 min | ✅ |
| e2e-test（9 spec × ~8s each） | ~2-3 min（本地 localhost）<br>N/A（CI 不可跑，见 2.1） | 20 min | ✅ 但实际空转 |
| typecheck | ~2-5 min | 15 min | ✅ |

### 2.4 Fork 环境

**当前状态：未验证。** CI workflow 依赖：
- `harness/tests/helpers/fixtures.js` → `mysql -uroot -proot`（假设 root 密码 = root）
- `Init MySQL schema` → 假设 `jeecg-boot/db/jeecgboot-mysql-5.7.sql` 存在
- Maven cache → actions/cache@v4（首次冷启动 ~5-8 min）

Fork 环境大概率**第一次跑会失败**（需要人工确认 base SQL 路径 + Maven 模块结构），但修复后应该可重复。建议在 README 加一栏"Fork 环境首次运行"。

---

## 3. 安全性评审

### 3.1 dbCleanup SQL 注入风险（🟡 P1，可控）

**现有模式**：
```js
dbCleanup(`DELETE FROM c_mes_customer WHERE code LIKE 'ADDR_T_%';`);
dbCleanup(`DELETE FROM c_mes_customer WHERE id = '${customer.id}';`);
```

**分析**：
- `LIKE 'ADDR_T_%'` — ✅ 安全。模式字符串硬编码在测试文件中，不接受外部输入。
- `'${customer.id}'` — ✅ 安全。`customer.id` 来自本地 API 调用（`findDoc` 查自己的测试数据），不是外部输入。
- `'${whId}'` — ✅ 同理。

**但是有例外**：
```js
// fixtures.js L81-87
function cleanupWarehouseScope(whId, matId) {
  return dbCleanup(`
    DELETE FROM c_mes_inventory WHERE warehouse_id='${whId}';
    ...
${whId}` 和 `${matId}` 是参数化的（调用者传入）。调用者都是测试代码（不是用户输入），所以**风险可控但不是最佳实践**。

**结论**：没有 SQL 注入漏洞（所有拼接值来自测试代码内部，不是外部输入）。但**强烈建议**改为参数化，因为：
1. 未来如果有人复制此模式到接收用户输入的场景，就是漏洞
2. `cleanupWarehouseScope` 是共享 helper，**没有文档说明其参数必须是"来自 API 响应的安全 ID"**

### 3.2 Token/密码 暴露（🟢 安全）

| 位置 | 内容 | 安全？ |
|------|------|:--:|
| `fixtures.js:69` | `mysql -uroot -proot` | ✅ 本地测试库（CI services 同样设 `MYSQL_ROOT_PASSWORD: root`） |
| `api.js:9` | `password: '123456'` | ✅ 测试账号（mes_admin） |
| `auth.ts:21` | `password: '123456'` | ✅ 测试账号（admin） |
| `auth.ts:10-11` | `http://100.122.125.106` | ⚠️ 内网 IP，非敏感但应该用环境变量 |
| `.env` | 未修改 | ✅ |
| `package.json` | 无敏感信息 | ✅ |

**没有泄露生产 token。** 但 `auth.ts` 的默认值硬编码了内网 IP（违反 `testing.md` 禁止硬编码规则）。

### 3.3 CI 权限

```yaml
permissions:
  contents: read
```

✅ 最小权限。job 不需要 write。

### 3.4 SQL 文件导入安全

CI 的 `Init MySQL schema` 步骤：
```bash
find ... -exec mysql ... < "$f" || true
```

`|| true` 意味着**导入失败的 SQL 文件静默跳过**。如果某次提交改了 DDL 引入语法错误，CI 不会报。建议改为：
```bash
find ... -print0 | while IFS= read -r -d '' f; do
  mysql ... < "$f" || { echo "FAILED: $f"; exit 1; }
done
```

---

## 4. 可优化评审

### 4.1 测试并行化（⚠️ P2）

**当前**：所有测试串行（`for f in tests/modules/basic-*.test.js; do node "$f"; done`）。

**可并行化空间**：
- **模块测试**：9 个 `basic-*.test.js` 可以用不同 suffix 前缀隔离（`ADDR_T_`, `CONT_T_`, `FU_T_` 等），理论上可并行。但共享 MySQL 连接池 + DB 状态——并行后 `dbCleanup` 可能互相踩。
- **E2E 测试**：Playwright 自带 `--workers` 参数，当前未用。给每个 worker 分配不同 spec 文件（`fullyParallel: true`），但同样需要 DB 隔离。

**建议**：
1. 短期：不改。串行 3-5 分钟够用。
2. 中期：如果要并行，每个测试文件用 `UNIQUE SUFFIX = <module>_<timestamp>`，确保清理不互相踩。
3. CI 可用 `matrix` 把 9 个模块分成 3 组并行跑。

### 4.2 报告聚合（⚠️ P2）

**当前**：每个测试文件独立输出 `✅/❌` 到 stdout。CI 通过 `exit 1` 判定失败。

**缺失**：
- 没有 JUnit XML / JSON 聚合报告（GitHub Actions 不能按测试用例展示）
- 没有历史趋势（过去 7 天通过率变化）
- 没有 flaky 检测（同一测试连续失败 2 次 vs 偶发失败）

**建议**：
1. 最小改动：修改 api.js 的 `check()` 函数，同时写 `harness/test-results/results.jsonl`（每行一个断言结果 JSON）
2. CI step 后用 `dorny/test-reporter@v1` 消费 JSON 报告
3. 看板（`regression_dashboard.py`）已有状态文件格式——可复用

### 4.3 覆盖率统计自动化（⚠️ P2）

**当前**：`/coverage` 命令手动统计端点覆盖。

**缺失**：
- 没有代码行覆盖率（`nyc` / `c8` for JS, `jacoco` for Java）
- 没有分支覆盖率
- 没有"哪些端点未测试"的自动对比（需 parse Controller.java 提取所有 `@GetMapping/@PostMapping`，对比测试文件中调用的 URL）

**建议**：`/coverage gap` 命令自动 parse Controller → 输出未覆盖端点列表（不是手工维护）。

---

## 5. 更好方案评审

### 5.1 裸 Node vs Jest/Mocha（🟢 当前方案 OK）

**设计文档选择**：Node.js 原生（零依赖、CI 轻量）。

**分析**：
| 维度 | 裸 Node（当前） | Jest/Mocha |
|------|:--:|:--:|
| 依赖 | 0 | +200 packages |
| CI 冷启动 | 0s（无 install） | 30-60s（npm install） |
| 断言可读性 | `check('name', ok, detail)` 手写 | `expect(x).toBe(y)` 标准 |
| before/after hooks | 手动（try/finally） | `beforeAll`/`afterAll` 自动 |
| 并行 | 自己实现 | `--maxWorkers` 内置 |
| 报告 | stdout 文本 | JUnit XML / JSON 内置 |
| 重试 | 自己实现 | `jest.retryTimes` 内置 |
| IDE 集成 | 无 | VSCode Jest 插件 |

**结论**：裸 Node 对这个规模（9 模块 × ~20 断言）是合理的。**短期不需要换**。但当测试文件超过 30 个时，before/after hooks 的缺失（现在每个文件手写 `login()` + `dbCleanup()`）会变成维护负担。那时再迁移。

当前可以做一个低成本改进：把 `api() + login() + check()` 三个函数从每个测试文件复制粘贴改为统一 `require('../helpers/api').createClient()`（链路测试已经这样做了，但 9 个 module 测试还在复制粘贴）。**这 9 个文件有 ~150 行重复代码**。

### 5.2 Mutation Testing（🟢 不需要现在加）

Mutation testing（如 Stryker）在这个阶段是**过度设计**：
- 需要 Java + JS 双语言支持（Stryker 都支持但配置复杂度高）
- 运行时间 10-30× 原始测试时间（9 模块 3min → 30-90min）
- 对业务人员不可解释

**建议**：等测试数量 > 500 且团队有专人维护测试基础设施时再考虑。

### 5.3 Visual Regression（🟡 值得加，低成本）

Playwright 已内置 `toHaveScreenshot()`：
```ts
await expect(page).toHaveScreenshot('customer-list.png');
```

当前 E2E 验证"表格可见"、"按钮可见"，但没有验证**视觉正确性**（布局错乱、CSS 溢出、z-index 遮挡）。这些恰是 JeecgBoot antd 组件常见的 bug。

**建议**：选 2-3 个关键页面（客户列表、仓库列表、盘点）加 screenshot 基线。成本 ≤ 20 行/spec。

### 5.4 Playwright Config 双份问题（🔴 必须统一）

**现在有 2 个 playwright.config.ts**：

| 文件 | baseURL | 用途 |
|------|---------|------|
| `harness/playwright.config.ts` | `http://localhost:4173` | ✅ CI pnpm preview（`--config` 不传时用这个） |
| `harness/e2e/playwright.config.ts` | `http://100.122.125.106` | ❌ 硬编码服务器 IP |

**问题**：
- `run-regression.sh` 用 `--config e2e/playwright.config.ts`（硬编码 IP）
- CI workflow 没传 `--config`（会捡 `harness/playwright.config.ts`，用 localhost:4173）
- `e2e/playwright.config.ts` 的 `baseURL: 'http://100.122.125.106'` 没有环境变量 fallback

**建议**：删除 `e2e/playwright.config.ts`，把 evidence-reporter 配置移到 `harness/playwright.config.ts`。所有 E2E 统一用一个 config。

---

## 6. 发现的具体 Bug

### 🔴 BUG-1：purchase-chain.test.js 段文件 process.exit 杀死父编排器

**位置**：`harness/tests/chains/purchase-chain.test.js:17-23`

```js
// purchase-chain.test.js（编排器）
require('./purchase-apply-order.chain.test.js');    // L117: process.exit(ok ? 0 : 1)
require('./purchase-order-receipt.chain.test.js');  // L139: process.exit(ok ? 0 : 1)
require('./purchase-payment-flow.test.js');         // L316: process.exit(...)
```

**问题**：`require()` 会执行被 require 文件的全部代码。如果 `purchase-apply-order.chain.test.js` 的 `run()` 完成后调 `process.exit(0)`，**整个 Node 进程立即退出**，段 2 和段 3 永远不会执行。

**当前状态**：`purchase-chain.test.js` 声称 3 段全跑，但段 1 `process.exit(0)` 后进程终止。段 2、段 3 从未被 CI 跑到过。

**验证**：
```bash
# CI 输出会是：
# 段 1/3: 采购申请 → 采购订单
# [purchase-apply-order 的输出]
# [进程退出，exit code 0]
# 段 2/3 和段 3/3 的日志永远不会出现
```

**修复**（二选一）：
- **A**：段文件不调 `process.exit`，改为 `module.exports = run`，编排器 `await require('./...').run()`
- **B**：段文件检测 `require.main === module` 再 `process.exit`（独立运行时退出，被 require 时不退出）

### 🟡 BUG-2：E2E spec 内嵌 `http://localhost:8080` 硬编码

```ts
// harness/e2e/mes/basic-customerAddress.spec.ts:27
const r = await fetch(`http://localhost:8080/jeecg-boot${p}`, {
```

**问题**：`apiViaPage` helper 在 `page.evaluate` 里硬编码 `localhost:8080`。如果 E2E 在远程服务器跑（如 CI），这个 URL 不可达。

**根因**：`page.evaluate` 在浏览器 context 执行，不能读 Node 环境变量。这是 Playwright 已知限制。

**修复**：把 `API_BASE` 通过参数传入 `page.evaluate`：
```ts
const API_BASE = process.env.E2E_API_BASE || 'http://localhost:8080/jeecg-boot';
// ...
return page.evaluate(async ({ m, p, b, base }) => {
  const r = await fetch(`${base}${p}`, ...);
}, { m: method, p: path, b: body, base: API_BASE });
```

### 🟡 BUG-3：auth.ts 和 playwright.config.ts 硬编码内网 IP（违反 testing.md）

`testing.md` 明确禁止：
> 测试代码 / .claude/commands / .claude/rules 中禁止出现 `http://100.122.125.106`

但以下文件仍有硬编码：
- `harness/e2e/mes/helpers/auth.ts:10-11`（默认值）
- `harness/e2e/playwright.config.ts:7`（baseURL）
- `harness/e2e/smoke/smoke-*.spec.ts`（4 个文件）
- `harness/tests/modules/manufacturing.test.js:5`
- `harness/tests/modules/purchase.test.js:3`

这些默认值在环境变量存在时会被覆盖，但默认值本身应改为 `localhost`。

### 🟡 BUG-4：9 个 module 测试文件复制粘贴 api/login/check 函数

每个 `basic-*.test.js` 都有自己的 `async function api()`、`async function login()`、手动 `let passed=0,failed=0`。这 9 个文件共 ~150 行重复代码。

链路测试已经用了 `createClient(BASE)` helper（`require('../helpers/api')`），但 module 测试没有。不一致且容易引入 bug（比如某个文件改了 `api()` 签名但其他的没改）。

### 🟢 BUG-5：dbCleanup 失败静默吞掉

```js
function dbCleanup(sqlStatements) {
  try {
    // ...
    return true;
  } catch (e) {
    return false;  // ← 不 log 错误
  }
}
```

测试文件调用 `dbCleanup(...)` 后从不检查返回值。如果 MySQL 不可达，清理失败但测试继续——可能用残留数据"假通过"。

---

## 7. 修复优先级汇总

| # | 问题 | 严重度 | 修复工作量 |
|---|------|:--:|:--:|
| BUG-1 | purchase-chain 段文件 process.exit 杀死父编排器 | 🔴 P0 | 5 min |
| BUG-2 | E2E apiViaPage 硬编码 localhost:8080 | 🟡 P1 | 2 min |
| BUG-3 | 多处硬编码 `100.122.125.106`（违反 testing.md） | 🟡 P1 | 10 min |
| BUG-4 | 9 module 测试复制粘贴 api/login（改用 createClient） | 🟡 P1 | 30 min |
| BUG-5 | dbCleanup 失败静默 | 🟢 P2 | 5 min |
| BUG-6 | CI e2e-test job 无后端服务（永远跑不了） | 🔴 P0 | 20 min |
| GAP-1 | 0 并发测试 | 🟡 P1 | 2h |
| GAP-2 | 0 权限越权测试 | 🟡 P1 | 1h |
| GAP-3 | 双 playwright.config.ts 不一致 | 🟡 P1 | 10 min |
| GAP-4 | 无聚合报告 | 🟢 P2 | 1h |
| GAP-5 | SQL 导入 `|| true` 静默吞错 | 🟢 P2 | 5 min |

---

## 8. 对设计文档 5 个问题的直接回答

### Q1: 完整性 — 哪些没覆盖？

**并发安全、权限越权、事务回滚**三块完全空白。这些都是 MES 历史审计反复出现的 P0 类型（`synchronized+@Transactional` 取号、金额并发超收、数据隔离硬编码用户名）。建议在 `/add-tests` 命令中加 `--depth deep` 选项触发这三类测试。

另外，错误恢复路径只测了"不存在的 ID"——没有测审核失败后数据一致性（历史盘点 bug：审核失败但库存已扣）。

### Q2: 可行性 — CI 能跑吗？

**api-test 可以，e2e-test 不能**（缺后端服务，见 BUG-6）。fork 环境未验证。mysql 8.0 + redis 7 配置够用，但 e2e-test job 根本没配这些 services。

### Q3: 安全性 — dbCleanup 安全吗？

**没有 SQL 注入漏洞**（所有拼接值来自测试代码内部）。但 `cleanupWarehouseScope` 作为共享 helper 无文档说明参数安全约束——属于"设计债"。token/密码没有泄露。

### Q4: 可优化 — 能并行吗？

可以，但需要先解决 DB 隔离问题（不同测试文件的 `LIKE 'PREFIX_%'` 清理依赖不同前缀）。CI 可以用 matrix 分 3 组。报告聚合可以通过 `results.jsonl` 实现（最小改动）。

### Q5: 更好方案 — Jest/Mutation/Visual？

- **Jest**：短期不需要。先统一用 `createClient` helper（修 BUG-4）效果一样，零成本。
- **Mutation Testing**：过度设计。等测试 > 500 用例时再考虑。
- **Visual Regression**：**低成本高价值**。选 2-3 关键页面加 `toHaveScreenshot()`，≤ 20 行/spec。值得现在做。

---

## 9. 总体评价

| 维度 | 评分 | 说明 |
|------|:--:|------|
| 覆盖面 | B+ | 9 模块 100% 端点覆盖 + 9 链路 + E2E。缺并发/权限/事务回滚。 |
| 代码质量 | B | 有 150 行复制粘贴。helpers 好但 module 测试没用。 |
| CI 就绪度 | C | api-test 可跑，e2e-test 永远绿（空转）。双 config 混乱。 |
| 安全性 | A- | 无 SQL 注入、无 token 泄露。cleanupWarehouseScope 缺文档。 |
| 可维护性 | B | README 详尽。但双 config + 段 process.exit + 硬编码 IP 是陷阱。 |
| 文档 | A | README 4739 字，结构清晰，业务人员可读。 |

**综合**：B+。修完 6 个 P0/P1 后可以到 A-。

---

*📎 此报告路径：`hermes/eagle-eye/reports/2026-08-04/issues/regression-system-review-claude.md`*
*🔄 建议在 W3 Sprint 排期：BUG-1/BUG-6 先修（20 min），其余 P1 边跑边修。*
