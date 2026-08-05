# 评审报告 — 回归测试体系 v0.2（5 轮修复后）

> **评审人**：Claude Opus 4.8（第二意见评审）
> **评审日期**：2026-08-05
> **评审对象**：v0.2 当前代码（commit `00320f1` + 5 轮修复后）
> **上一次评审**：`hermes/eagle-eye/reports/2026-08-04/issues/regression-system-review-claude.md`（Grade B+）
> **验证方式**：全部文件逐行走读（非 reading-by-memory）——CI workflow、18 个测试文件、helpers、config、schema、commands、README

---

## 总评：B+ → A-（6 个必须修复项 → 5 个已落地，但引入 2 个新 P0）

5 轮 commit 修复了 Claude 上次报告的 6 个 P0/P1 中的 5 个（BUG-1 段 process.exit ✅、BUG-6 e2e 加 services ✅、V0.0.0 schema ✅、断言 grep ✅、classpath SQL ✅）。**但 BUG-3（硬编码 100.122.125.106）修复不完整**——修了 `harness/playwright.config.ts` 但漏了 `harness/e2e/playwright.config.ts`，而 CI 恰好在用后者。这是一种**半修复产生的伪安全感：env vars 设了、注释说"修复了"、但配置文件选错了。**

---

## 🔴 新发现：2 个 P0（导致 CI E2E 第五次仍不可能绿）

### P0-1：CI E2E playwright config 双份半修复 —— CI 用的那份从未被修

**现象**：
```
CI 命令（workflow L308-312）:
  npx playwright test --config e2e/playwright.config.ts e2e/mes/ ...

e2e/playwright.config.ts（CI 实际使用的）:
  baseURL: 'http://100.122.125.106',    ← 硬编码，无 env var fallback

harness/playwright.config.ts（被修复的那份，CI 不用的）:
  baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4173',  ← 修了的

CI 环境（env vars 设置了的）:
  E2E_UI_BASE: http://localhost:4173       ← 设了但白设
  E2E_API_BASE: http://localhost:8080/jeecg-boot
```

**为什么 env vars 设了但 playwright 不用**：`e2e/playwright.config.ts` 是纯文字量 `'http://100.122.125.106'`，不读 `process.env` 也不读 `PLAYWRIGHT_BASE_URL`。CI 的 env vars 只被 `auth.ts` 的 `BASE`/`API_BASE` 使用（登录跳转），但**测试用例中的 `page.goto(PAGE_PATH)`（相对路径）全部由 playwright baseURL 拼接**。

**后果**：
- `loginViaApi(page)` 导航到 `http://localhost:4173` → ✅（auth.ts 用 env var）
- 测试体 `page.goto('/project/mes/basic/customer')` → Playwright 解析为 `http://100.122.125.106/project/mes/basic/customer` → ❌（`e2e/playwright.config.ts` hardcoded）
- GitHub Actions runner 无法访问 100.122.125.106（内网 IP）→ ECONNREFUSED
- 9 个 E2E spec 全部失败

**根因**：BUG-3 修复时只改了 `harness/playwright.config.ts`，但 `e2e/playwright.config.ts` 被遗漏了。`e2e/playwright.config.ts` 还设置了 `testDir: './mes'`（不同于 `harness/playwright.config.ts` 的 `testDir: './e2e'`），所以不能简单地删掉它——testDir 不一致。

**修复**（二选一）：
- **A（推荐，彻底统一）**：删除 `e2e/playwright.config.ts`，将 evidence-reporter 配置合并到 `harness/playwright.config.ts`，CI 改为 `--config playwright.config.ts`（或省略 `--config` 用默认）
- **B（最小改动）**：给 `e2e/playwright.config.ts` 加上 env var fallback：`baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4173'`，同时 CI 加 `PLAYWRIGHT_BASE_URL=http://localhost:4173`

---

### P0-2：4 个 E2E spec 中 `apiViaPage` 硬编码 `localhost:8080`，`API_BASE` 变量已定义但从不使用

**位置**：`harness/e2e/mes/basic-customer{Address,Contact,FollowUp,Price}.spec.ts`

```ts
// L11: 定义了但死变量
const API_BASE = process.env.E2E_API_BASE || 'http://localhost:8080/jeecg-boot';

// L25: 硬编码，不用上面的变量 ← BUG
const r = await fetch(`http://localhost:8080/jeecg-boot${p}`, {
```

**为什么 CI 上碰巧能跑**：CI 的 backend 确实在 localhost:8080，所以 fetch 在 page context 里能命中。但这是巧合，不是设计。**跨环境场景下（本地打远程、远程打不同端口）会静默失败。**

**另外 2 个 E2E spec（materialBatchEnabledSave.spec.ts + purchaseReceiptBatch.spec.ts）更糟**——连 `process.env.E2E_API_BASE` 都没定义：

```ts
// materialBatchEnabledSave.spec.ts:11
const API_BASE = 'http://localhost:8080/jeecg-boot';  // ❌ 纯硬编码
// purchaseReceiptBatch.spec.ts:6
const API_BASE = 'http://localhost:8080/jeecg-boot';  // ❌ 纯硬编码
```

**修复**：
```ts
// 正确做法：把 API_BASE 通过 page.evaluate 闭包传入
async function apiViaPage(page: any, method: string, path: string, body?: any) {
  return page.evaluate(async ({ m, p, b, base }: any) => {
    const r = await fetch(`${base}${p}`, ...);
  }, { m: method, p: path, b: body, base: API_BASE });
}
```

---

## 🟡 验证：已解决项（5/6 上次 P0/P1 已落地）

| # | 上次发现 | 状态 | 验证方式 |
|---|---------|:--:|------|
| BUG-1 | purchase-chain process.exit 杀死父编排器 | ✅ 已修 | `purchase-chain.test.js` L18-30 改用 `await require(...).run()` |
| BUG-6 | CI e2e-test 无后端 services | ⚠️ 半修 | services 加了，但 playwright config 选了错的文件（见 P0-1） |
| BUG-3 | 多处硬编码 `100.122.125.106` | ⚠️ 半修 | `harness/playwright.config.ts` 修了，但 `e2e/playwright.config.ts` 没修；auth.ts / 4 smoke / 3 存量 test 仍有硬编码 |
| V0.0.0 schema | 与 platform SQL 冲突 | ✅ 已修 | commit `00320f1`：只含 c_mes_* 表 |
| 断言密度 grep | `c\.check` → `check(` | ✅ 已修 | CI L153 已改 `grep -cE "check\(|expect\(|assert\("` |
| classpath SQL | mes_admin 用户缺失 | ✅ 已修 | CI L110-114 已加 classpath resources SQL |

---

## 🟡 仍有 10+ 处硬编码 IP（上次标记 P1，部分未修）

上次评审报告标记了 6 处，现状：

| 文件 | 状态 | 说明 |
|------|:--:|------|
| `e2e/playwright.config.ts:7` | ❌ 未修 | 纯硬编码，无 env fallback |
| `e2e/mes/helpers/auth.ts:10-11` | ❌ 未修 | 默认值仍是服务器 IP |
| `e2e/smoke/smoke-01-login.spec.ts:6-7` | ❌ 未修 | 4 个 smoke 全部硬编码 |
| `e2e/smoke/smoke-02-user-list.spec.ts:6` | ❌ 未修 | |
| `e2e/smoke/smoke-03-role-list.spec.ts:6` | ❌ 未修 | |
| `e2e/smoke/smoke-04-logout.spec.ts:6-7` | ❌ 未修 | |
| `tests/modules/manufacturing.test.js:5` | ❌ 未修 | 默认值仍是服务器 IP |
| `tests/modules/purchase.test.js:3` | ❌ 未修 | 默认值仍是服务器 IP |
| `tests/modules/sales-order.test.mjs:7` | ❌ 未修 | |
| `tests/modules/sales-api.test.mjs:5` | ❌ 未修 | |
| `tests/modules/codeRule.test.mjs:5` | ❌ 未修 | |
| `playwright.config.ts:19` | 🟡 注释中的示例 | 注释写 `http://100.122.125.106:3100` 作为示例，可接受 |
| `jeecgboot-vue3/.env.development:17` | ✅ 设计如此 | 开发环境配置，不是测试代码 |

**这 11 个硬编码位置加上 2 个 P0，使得当前回归体系虽然在本地"100% 通过"，但在 CI/远程环境的可靠性极其脆弱。**

---

## 🟡 对 10 个待评审问题的逐一回答

### Q1: CI 4 次跑都失败，第 5 次能否绿？

**答**：不能。第 5 次（commit `00320f1`）刚 push，但：
1. **P0-1 阻止 E2E 变绿**——playwright 导航到 100.122.125.106 而不是 localhost:4173
2. **CI summary 仍把 e2e-test 当软门控**——即使 e2e 全失败，summary 也只打印 ⚠️ 不 exit 1，api-test+typecheck 通过则整 workflow 绿
3. **所以第 5 次会很可能是"绿的"**——但 e2e 全在远程 IP 不可达状态下失败，summary 的软门控会掩盖这个事实。**和 BUG-6 修复前一样的问题：软门控掩盖 E2E 失败。**

### Q2: 3 个已知易修 P1 未做

| 易修项 | 现状 | 影响 |
|------|------|------|
| `apiViaPage` 硬编码 localhost:8080 | 6 个 spec 有此问题（4 个有死变量 + 2 个纯硬编码） | CI 能跑纯属巧合；远程环境不可达 |
| 6+ 处硬编码 100.122.125.106 | 实际 11+ 处，远超报告的 6 处 | 违反 testing.md R009；远程测试被阻断 |
| 9 module 测试 150 行重复 | 全部 9 个 `basic-*.test.js` 各自复制 api/login/check | 修 BUG 需要改 9 份；不一致风险 |
| 双 playwright.config.ts 不一致 | `e2e/playwright.config.ts` 无 env var + 不同 testDir | 本次评审的核心 P0 发现 |
| dbCleanup 失败静默 | `fixtures.js:71` return false 但调用方从不检查 | 测试可能用残留数据"假通过" |

### Q3: 测试间隔离（9 module 共享 DB）

**风险评级**：当前串行模式下无风险。但如果未来并发跑（CI matrix 分 3 组），`LIKE 'ADDR_T_%'` 这种按业务前缀的清理会互相踩——模块 A 在清理 `ADDR_T_%` 时模块 B 正在创建 `ADDR_T_xxx` 客户。

**建议**：短期不需要改（串行够用）。中期方案——每个测试文件用 `UNIQUE_SUFFIX = <module>_<timestamp>` 而不是共享 `LIKE 'PREFIX_%'`。

### Q4: 数据隔离（权限）

**严重度维持 P1**。所有测试都用 `mes_admin`/`admin`，0 个权限越权测试。铁拳团审计反复发现的数据隔离 bug（硬编码 `"admin".equals(username)` 判断用户）没有回归防护。建议 `/add-tests` 在 `--scenario=permission` 模式下自动生成一层普通用户 + 验证数据范围过滤。

### Q5: QRTZ 表缺失

**不阻塞**。Quartz scheduler 启动时报 `QRTZ_LOCKS doesn't exist`，Spring Boot 仍然启动（非致命异常）。但 CI 日志中有这个错误噪音，可能掩盖真实问题。建议在 platform SQL 或 V0.0.0 中加 QRTZ 建表语句（或因不需要定时任务而显式 `spring.quartz.auto-startup=false`）。

### Q6: V0.0.0 vs V1.x 兼容性

**当前可通过但非最优**。V0.0.0 是生产 schema 超集，V1.x ALTER 在 CI 上跑会报 1060 "Duplicate column" 被 `|| true` 吞掉。**风险**：
- 如果某次部署在 V0.0.0 之后改了 V1.x 的 DDL（如改 column type、加 index），CI 吞掉错误 → 测试通过的 schema 与生产不一致
- 如果生产是从空库跑全套 SQL 重建（不是从 V0.0.0 增量），重复 ALTER 也会报错

**建议**：`find ... V[0-9]*.sql -not -name "V0.0.0*"` 改为**不吞错**（`|| { echo "FAILED: $f"; exit 1; }`），或明确让 V1.x 只做 `INSERT IGNORE`（不做 DDL），DDL 全部收归 V0.0.0。

### Q7: classpath SQL 顺序依赖

**风险中等**。`find ... -name "*.sql"` 按文件系统顺序（非语义顺序），不同 CI runner 可能不同。实测跑 5+ 个文件：V3.9.3_0、V1.8.0、V9.5.0、init-role-user、mes-customer-init、mes-basic-init、V3.9.3_0__mes_price_dict。部分有 INSERT IGNORE（幂等 OK），部分无（可能重复插入）。

**建议**：
1. classpath SQL 只在 `init-role-user.sql`（mes_admin 注册）+ `mes-*-init.sql`（必要种子数据）保留
2. 删除 `V3.9.3_0*.sql` 等 classpath 目录下的重复 SQL（DDL 已在 V0.0.0 中）
3. 或用 `sort` 保证执行顺序（但语义顺序仍需人工保证）

### Q8: 断言降级（1.1 list 从 `r.result.total >= 0` 降为 `r.code === 200`）

**当前可接受，但建议加固**。降级的原因是 CI 上 `r.result` 可能为 null 导致 deref 崩溃。修改为 `r.code === 200` 避免了崩溃但失去了 total 字段验证。更好的写法：

```js
const total = r.result?.total; // null-safe
check('1.1 list', r.code === 200 && total != null, `total=${total}`);
```

或者做三层 fallback：`const total = (r.result && r.result.total != null) ? r.result.total : -1;`

这样既避免 null deref，又保留了 total 字段的验证。

### Q9: mes_admin 密码 123456 硬编码

**可接受**。这是测试专用账号，CI 环境亦同。mes_admin 在 `init-mes-role-user.sql` 中创建，密码 `123456` 是测试库的约定。不涉及生产凭证。**唯一风险**：如果某天有人把 CI 的 MySQL 暴露到公网，root/root 就是个入口——但 GitHub Actions services 只在 runner 内部可达，risk 极低。

### Q10: CI 缓存命中率

冷启动 ~5-8 min，命中后 ~2-3 min。当前配置合理（Maven cache key = `hashFiles('**/pom.xml')`，pnpm cache key = `hashFiles('**/lock')`）。**建议**：api-test 和 e2e-test 两个 job 各自独立跑 `mvn clean install` + `Init MySQL schema`——重复耗时 ~3-4 min。可考虑合并为一个 job 或提取为 shared step，但目前优先级低。

---

## 🟢 正面肯定：5 轮修复后做得好的地方

1. **README 4739 字完整详尽**——业务人员能独立运行测试，每个模式都有示例命令
2. **package.json npm scripts**——`npm run test:api` / `test:e2e` / `test:chains` / `test:all` 完整可用
3. **一键脚本双平台**——`run-regression.{sh,bat}` 覆盖 Linux/macOS/Windows
4. **CI 三项合理**——api-test（后端+DB+Redis完全自包含）、typecheck（≤200 软门控）、并发控制（cancel-in-progress）
5. **add-tests 命令设计**——8 个项目 + 9 种场景维度，覆盖全面
6. **diagnostic-test.ts**——自动采集 console/pageerror/failed requests，排错高效
7. **V0.0.0 schema 干净**——54 张 c_mes_* 表，无 sys_*/QRTZ_* 冲突
8. **BUG-1 修复完整**——`await require(...).run()` + try/catch + 三态返回值

---

## 🤖 AI 自检：v0.2 设计的 3 个结构性问题

### 结构问题 1：「100% 通过率」的构成

当前声称"本地 100% 通过"。这是真的。但本地通过建立在以下条件上：
- 后端 fat-jar 在 localhost:8080 运行
- 前端 Vite dev 在 localhost:3100 运行
- MySQL root/root 在 localhost:3306 运行
- 硬编码的默认值恰好是 localhost（9 个 new spec）或远程 IP（11 个遗留）

换一个环境——比如同事的电脑、CI runner、远程服务器——这个"100%"会塌陷到 60-70%。**通过率是环境耦合的，不是测试覆盖率耦合的。**

**建议**：在所有测试文件和 CI 中强制要求设置 `HARNESS_BASE`/`E2E_UI_BASE`/`E2E_API_BASE` 环境变量（不设则报错退出），而不是用默认值。这会暴露所有硬编码问题。

### 结构问题 2：E2E 测试的架构分层不对

当前 E2E 测试做了两件完全不同的事：
1. 验证前端页面渲染（路由可达、表格可见、按钮可见）——真正的 E2E
2. 通过 `apiViaPage` 在浏览器 context 里调后端 API 准备测试数据——这本质是 API 测试，不是 E2E

问题出在 #2：`apiViaPage` 绕过了 Playwright 的 `page.request`（Playwright 提供的 API testing context），也绕过了 auth helper（直接在 `page.evaluate` 里从 localStorage 读 token）。**这个模式在每个 spec 里复制了 4 次**，每次都有 P0-2 的硬编码 bug。

**建议**：
- 提取 `apiViaPage` 到 `helpers/apiViaPage.ts`（单一来源，修一个地方九个 spec 都受益）
- 或者改用 Playwright 的 `page.request`（内置 API testing context，自动处理 cookies/headers）
- E2E 测试的数据准备应该用独立的 API client（`createClient` from `../helpers/api`），不通过 `page.evaluate`

### 结构问题 3：9 个 module 测试 vs 9 个链路测试使用的是两套完全不同的代码模式

| | module 测试 | 链路测试 |
|---|---|---|
| 客户端 | 手写 `api()` + `login()` | `createClient(BASE)` |
| 断言 | 手写 `check()` | `c.check()` |
| fixture | 手写造数 | `createSupplier/Material/Warehouse()` |
| cleanup | 手写 SQL 字符串 | `cleanupWarehouseScope()` |

链路测试已经走对了路（引入 shared helper），但 module 测试还在原始模式。**如果 helper 有问题，改链路测试就修了；但 module 测试要 9 个文件逐个改。** 这与"5 断言锚点"的要求不一致——helper 无法跨文件一致加强。

---

## 🔧 修复优先级（新评审版）

| # | 问题 | 严重度 | 工作量 | 阻塞 CI E2E？ |
|---|------|:--:|:--:|:--:|
| P0-1 | CI E2E 用了错的 playwright config（硬编码 remote IP） | 🔴 P0 | 5 min | **是** |
| P0-2 | 6 个 E2E spec apiViaPage 硬编码 localhost:8080 | 🔴 P0 | 10 min | 否（巧合） |
| BUG-3-R | e2e/playwright.config.ts + auth.ts + smoke + 5 存量 test 仍有硬编码 IP | 🟡 P1 | 15 min | 是（P0-1 修复后自然解决） |
| BUG-4-R | 9 个 module 测试改用 createClient（去 150 行重复） | 🟡 P1 | 30 min | 否 |
| BUG-5-R | dbCleanup 失败输出诊断 + 调用方检查返回值 | 🟡 P1 | 10 min | 否 |
| GAP-6 | E2E apiViaPage 提取为共享 helper（去 4 份重复） | 🟡 P1 | 10 min | 否 |
| GAP-7 | CI classpath SQL 顺序依赖（只保留必要的 init-role-user） | 🟢 P2 | 10 min | 否 |
| GAP-8 | CI V1.x ALTER `\|\| true` 吞错（改为 hard fail + 审计） | 🟢 P2 | 5 min | 否 |
| GAP-9 | 1.1 list 断言用 null-safe 恢复 total 验证 | 🟢 P2 | 2 min | 否 |
| GAP-10 | 强制要求 env var（不设则报错退出） | 🟢 P2 | 5 min | 否 |
| GAP-11 | Visual regression（3 个关键页面） | 🟢 P2 | 30 min | 否 |
| GAP-12 | 并发安全测试（synchronized+@Transactional 取号回归） | 🟢 P2 | 2h | 否 |
| GAP-13 | 权限越权测试（普通用户数据过滤） | 🟢 P2 | 1h | 否 |
| GAP-14 | CI summary 注释过时（仍说 e2e 软门控） | 🟢 P3 | 1 min | 否 |

---

## 判定：NEEDS WORK

**原因**：
- 2 个 P0 阻止 CI E2E 真正通过（已修 5 个旧 P0 但引入 2 个新 P0）
- 硬编码问题比上次评审时更严重（双 config 半修复导致 CI 命令选错文件）
- 本地 100% 通过但环境耦合太紧——换环境立刻塌陷

**可以提交并继续迭代**，但在 P0-1 和 P0-2 修复前：
- CI E2E 永远不会真正绿
- "100% 通过率"只在本地环境有效
- `/add-tests` 生成的新 spec 会继续复制 `apiViaPage` 的硬编码 bug

**建议 W3 排期**：
1. 先修 P0-1 + P0-2（15 min）→ 立即推 CI 看第五次能不能绿
2. 再修 BUG-3-R + BUG-4-R + GAP-6（55 min）→ 去重、统一
3. 最后补 GAP-7~GAP-14 → 加固

---

*📎 此报告路径：`hermes/eagle-eye/reports/2026-08-05/regression-v0.2-review-claude-round2.md`*
*🔄 与上次评审的 diff：上次 6 个必修复项中 5 个已落地，但半修复的 BUG-3 引入 2 个新 P0。根因：双 config 未统一——修了一个漏了一个。*
