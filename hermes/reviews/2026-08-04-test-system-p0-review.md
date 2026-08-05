# 测试体系 P0 改造 — 架构评审报告

> **日期**: 2026-08-04
> **评审范围**: CI 集成 + gen-tests 断言密度 + 补 0 断言文件（3 块 × 10 文件）
> **评审方法**: 逐项对账计划声明 vs 实际代码状态

---

## 一、通过项 ✅

| # | 项目 | 判定 |
|---|------|:--:|
| 1 | `security-regression.yml` 作 CI 模板参考——结构成熟（215 行、3 job 分层、MySQL/Redis service container、Java 17 + Maven build + curl 等后端就绪） | ✅ |
| 2 | `gen-tests-rules.json` 8 条规则格式统一，加 R009 在技术上是安全的 | ✅ |
| 3 | `harness/tests/helpers/api.js` 的 `createClient` + `check()` + `summary()` 模式适合 CI（`process.exit(failed > 0 ? 1 : 0)` 直接映射 CI 退出码） | ✅ |
| 4 | API 测试用原生 `node` 跑（非 vitest/jest），CI 无需额外 test runner | ✅ |
| 5 | 串行策略（api → e2e → typecheck）资源效率合理，避免并行争抢 MySQL/Redis | ✅ |
| 6 | R009 规则格式与现有 R001-R008 风格一致 | ✅ |

---

## 二、必须修改项 🔴（高风险遗漏，不解则阻塞实施）

### P0-1: "6 个文件 0 断言"诊断事实错误

**计划声称**: `basic` / `finance` / `system` / `batch-global-switch` / `batch-manual-e2e` / `traceability-batch-level` 共 6 个文件 0 断言。

**实际代码核实**:

| 文件 | 行数 | 断言数（`c.check()`/`check()`） | 真实问题 |
|------|:--:|:--:|------|
| `basic.test.js` | 117 | **14** | 断言充分（CRUD + 删除保护 + 重复编码） |
| `finance.test.js` | 192 | **100+** | 断言多是"不崩溃"而非"返回正确数据"——**深度问题，非数量问题** |
| `system.test.js` | 98 | **20+** | 字段存在性 + 鉴权 + 特殊字符——断言充分 |
| `batch-global-switch.test.js` | 195 | **20+** | 总开关关闭/开启 + 批次计数——**这是最复杂的集成测试** |
| `batch-manual-e2e.test.js` | 76 | **9** | 6 场景 × 1-2 断言，覆盖手工录入/重复/兜底/超长 |
| `traceability-batch-level.test.js` | 217 | **40+** | 10 组场景（列表/搜索/抽屉/导出/越权/边界/SQL注入/对账/空数据） |

**根因**: 评估报告用了只匹配 `expect()` / `assert.*` 的正则，漏掉了项目自定义的 `c.check(name, condition, detail)` 模式。**这 6 个文件全部有断言，且部分文件（finance/traceability）断言密度不低。**

**影响**:
- 计划中"步骤 3：补 6 个 0 断言文件"的 5 锚点断言——对 finance/traceability/system 是**重复劳动**（已有鉴权/边界/SQL注入断言）
- `basic.test.js` 已有 14 条断言覆盖仓库+库位全生命周期，补"5 锚点"无意义
- `batch-global-switch.test.js` 是**最复杂的端到端集成测试**（总开关 × 采购入库 × 完工入库），断言远不止 5 条

**修正方案**:
1. 重新扫描断言密度用 `grep -c "c\.check\|\.check(" harness/tests/mes/*.test.js`（而非 `expect(`）
2. 将"补 0 断言"改为"断言深度审计"——重点看 finance（"不崩溃"→"正确数据"）和 batch-global-switch（"不崩溃"→"状态流转验证"）
3. 删除 basic / system / traceability-batch-level / batch-manual-e2e 从"待补"清单——它们已有充分断言

### P0-2: E2E CI 服务器可达性——计划完全未覆盖

**代码事实**:
```
playwright.config.ts: baseURL: 'http://100.122.125.106'       ← 硬编码服务端 IP
auth.ts:            API_BASE = 'http://100.122.125.106:8080'  ← 同样硬编码
```

**问题**: GitHub Actions `ubuntu-latest` runner 在云端，**无法访问** `100.122.125.106`（这是内网/专线地址）。计划只问了"用 self-hosted runner 还是只跑不需要后端的检查"，但**没有给出方案**。

**对比**: `security-regression.yml` 的 `authorization-poc` job **在 CI 内自建后端**：`services: mysql + redis` → `mvn clean install` → `java -jar` → `curl` 等就绪 → 测试跑在 `http://127.0.0.1:8080`。这个模式对 API 测试适用但对 E2E **不适用**——E2E 需要前端（Vue 3 + Vite），CI 中没有前端构建和启动步骤。

**修正方案**（三选一，建议 A+C 组合）:

| 方案 | 内容 | 成本 |
|------|------|:--:|
| **A（推荐）** | E2E job 在 CI 中 `pnpm build` + `pnpm preview` 启动前端（端口 4173），`playwright.config.ts` baseURL 改为 `http://localhost:4173`，API_BASE 指向本地后端 `http://localhost:8080/jeecg-boot` | ~30 行 YAML |
| **B** | Self-hosted runner 标签 `mes-e2e`，部署在能访问 100.122.125.106 的机器上，workflow 加 `runs-on: [self-hosted, mes-e2e]` | 运维成本 |
| **C（兜底）** | E2E job 加 `continue-on-error: true`，CI 不阻塞但报警——先上线再逐步修通 | 1 行 YAML |

**推荐组合**: A（主路径）+ C（兜底）。先让 E2E 在 CI 中能跑，失败不阻塞 PR，逐步修到 90% 通过率后再改为阻塞。

### P0-3: API test CI job 缺少后端启动步骤

**计划描述**: "api-test → e2e-test → typecheck，PR + push 触发"——但**没有描述 api-test job 如何启动后端**。

**代码事实**:
```
harness/tests/mes/*.test.js: BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot'
```

API 测试是真实 HTTP 调用（不是 mock），**必须有运行中的后端**。

**修正方案**: api-test job 必须包含（参考 security-regression.yml 的 authorization-poc job）:
```yaml
services:
  mysql: { image: mysql:8.0, env: { MYSQL_ROOT_PASSWORD: root }, ports: ['3306:3306'] }
  redis: { image: redis:7, ports: ['6379:6379'] }
steps:
  - Setup Java 17
  - mvn clean install -DskipTests (jeecg-system-start)
  - nohup java -jar target/jeecg-system-start-*.jar &
  - curl 等后端就绪（最多 120s）
  - HARNESS_BASE=http://localhost:8080/jeecg-boot node harness/tests/mes/*.test.js
```

### P0-4: CI 缺少 harness/ 的前端依赖安装

`harness/package.json` 只有 `@playwright/test` 一个依赖，没有 lockfile。typecheck job 需要 `vue-tsc` 但在 `jeecgboot-vue3/` 目录。

**修正方案**:
- api-test job: 不需要 `pnpm install`（API 测试是纯 Node，只用 `fetch`）
- e2e-test job: 需要 `cd harness && npm install`（安装 @playwright/test + 浏览器）
- typecheck job: 需要 `cd jeecgboot-vue3 && pnpm install && npx vue-tsc --noEmit`

---

## 三、建议修改项 🟠（可优化，不阻塞）

### P1-1: R009 阈值应改为"断言深度"而非"断言数量"

**当前提案**: ≥ 1 断言/`it()` + 总断言数 ≥ 场景数 × 0.5

**问题**: 这个阈值对 finance.test.js（100+ 断言但多是"不崩溃"）给 PASS，对 batch-manual-e2e.test.js（9 断言但每条验证具体行为）可能给 WARN。**数量阈值不解决真正的质量问题。**

**建议**: R009 改为"断言语义检查"而非"断言计数":
```json
{
  "id": "R009",
  "bugType": "浅断言（只测不崩溃，不测正确性）",
  "trigger": "测试文件中 check() 只验证 code===200 或 code===500",
  "missingScenario": "没验证返回数据的语义正确性",
  "addCase": {
    "api": "至少 1 条断言验证业务字段值（非仅 code），至少 1 条断言验证状态流转（status 变化）",
    "e2e": "至少 1 条断言验证 UI 显示值非 ID（锚点 #4）"
  },
  "source": "测试体系改造",
  "created": "2026-08-04"
}
```

配合 gen-tests SKILL.md 加检查步骤："生成后自检：每个 describe 块是否有至少 1 条语义断言（验证具体字段值，非仅 code===200）"

### P1-2: 优先级应按业务关键性 + E2E 空白排序

**计划排序**: basic(117行) → batch-global-switch → batch-manual-e2e → finance → system → traceability

**建议排序**（按业务影响）:

| 优先级 | 文件 | 理由 |
|:--:|------|------|
| 1 | **finance** | 8 个 Controller、0 个 E2E、119 用例但多是"不崩溃"——**业务链路关键节点无 UI 守卫** |
| 2 | **batch-global-switch** | 总开关集成 4 个 Service——错一个影响全局批次创建 |
| 3 | traceability-batch-level | V10.0.3 新功能，断言密度已高，仅需对账断言强化 |
| 4 | system | 全局开关鉴权已覆盖，优先级低 |
| 5 | basic | **已充分测试**，无需额外工作 |
| 6 | batch-manual-e2e | 6 场景已覆盖，断言密度合理 |

### P1-3: CI 应加缓存策略

**遗漏**: `actions/cache@v4` for `~/.m2/repository`（Maven）和 `pnpm store`。没有缓存时 `mvn clean install` 需 3-5 分钟下载依赖。

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: maven-${{ hashFiles('**/pom.xml') }}
```

### P1-4: typecheck job 的 742 错误处理策略缺失

计划说 typecheck 串行在 e2e 之后，但当前 `vue-tsc` 有 **742 个错误**。CI 上线第一天就会全红。

**建议**: typecheck job 初期设 `continue-on-error: true`，只报告不阻塞。同时启动逐步修复（按目录/模块分批）。

---

## 四、拒绝采纳项 ❌

无。计划整体方向正确，主要是执行细节需要基于代码事实修正。

---

## 五、修订后实施建议

| 步骤 | 原计划 | 修订后 |
|:--:|------|------|
| 1 | functional-regression.yml 三 job 串行 | **api-test（含后端启动）→ e2e-test（含前端 build+preview 或 continue-on-error）→ typecheck（continue-on-error）**，加 Maven/pnpm 缓存 |
| 2 | R009 断言密度下限 | **R009 断言语义检查**（≥1 语义断言/场景，非计数下限），SKILL.md 加自检步骤 |
| 3 | 补 6 个 0 断言文件 | **只补 finance（浅断言→语义断言）+ batch-global-switch（状态流转验证）**，其余 4 个文件断言已充分 |
| 4 | E2E 服务器可达性 | **方案 A（CI 内启动前端）+ C（兜底不阻塞）** |
| 5 | CI 环境变量 | `HARNESS_BASE=http://localhost:8080/jeecg-boot` + `E2E_UI_BASE=http://localhost:4173` + `E2E_API_BASE=http://localhost:8080/jeecg-boot` |

**修订后文件清单**: 从 10 个缩减到 **6 个**（删 basic/system/traceability-batch-level/batch-manual-e2e 的"补断言"，因为已有充分断言）。

---

## 六、风险提示

| 风险 | 原计划认知 | 实际情况 |
|------|-----------|---------|
| "0 断言"文件 | 6 个 | **0 个**——全部有断言，诊断方法错误 |
| E2E CI 可达性 | "用 self-hosted runner 还是静态检查" | 未决策——**这是实施第一天就会撞的墙** |
| CI 首次全红 | 未提及 | typecheck 742 错误 + E2E 可能大面积失败 |
| harness/ 依赖 | 未提及 | 缺 lockfile、`@playwright/test` 在 dependencies 非 devDependencies |

---

**评审结论**: 计划方向正确，但 **P0-1（诊断事实错误）和 P0-2（E2E 可达性未决策）必须在写第一行代码前修正**。其余 P1 项可在实施中逐步调整。
