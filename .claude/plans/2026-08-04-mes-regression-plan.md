# MES 全量回归测试 — 实施方案（Plan）

**日期**：2026-08-03 制定，2026-08-04 执行
**触发**：用户主动要求回归测试
**范围**：MES 全模块（9 后端 + 8 前端）
**约束**：业务代码不改 / 测试代码可造 / 测试数据可造 / 跑后回滚

---

## 1. 范围盘点

### 1.1 后端模块 + Controller 数

| 模块 | Controller 数 | 路径 |
|---|:-:|---|
| basic | 12 | basic/* |
| batch | 4 | batch/* |
| config | 0 | （纯配置无 Controller）|
| finance | 8 | collection/invoice/payable/payment/purchaseInvoice/receivable/subject/voucher |
| manufacturing | 4 | manufacturing/* |
| purchase | 5 | purchase/* |
| sales | 4 | sales/* |
| stock | 3 | stock/* |
| system | 1 | system/MesGlobalSwitchController |
| **合计** | **41** | |

### 1.2 前端页面（src/views/project/mes/）

| 目录 | 子目录/页面数 | 备注 |
|---|:-:|---|
| basic | 多 | — |
| batch | 5（inventory/ledger/master/shared/traceability） | V10.0.3 在此 |
| finance | 8（collection/invoice/payable/payment/purchaseInvoice/receivable/subject/voucher） | 与后端 1:1 对应 |
| manufacturing | 多 | — |
| purchase | 多 | 最近改动密集（a-date-picker 等） |
| sales | 多 | — |
| stock | 多 | — |
| dev / commonSetting | 多 | 配置类 |

### 1.3 已有测试覆盖矩阵

| 模块 | API 测试 | E2E 测试 |
|---|:-:|:-:|
| basic | ✅ basic.test.js | ✅ basic.spec.ts |
| batch | ✅ ×3（switch / manual / traceability） | ✅ ×2（materialBatch / traceability） |
| finance | ❌ 空白 | ❌ 空白 |
| manufacturing | ✅ manufacturing.test.js | ❌ |
| purchase | ✅ ×3（apply / chain / receipt） | ✅ ×2（purchase / purchaseReceipt） |
| sales | ✅ ×2（sales-api / sales-order） | ✅ sales-order |
| stock | ✅ ×1（other-stock-in） | ✅ ×2（other-stock-in / stocktake） |
| system | ❌ 空白 | ❌ 空白 |

**已有合计**：13 个 API 测试 + 11 个 E2E 测试

### 1.4 本次新增覆盖（决策 B2）

- **finance**：8 个 Controller，全部用 `gen-tests finance` 生成 API 测试
- **system**：1 个 Controller，用 `gen-tests system` 生成 API 测试
- finance + system 的 E2E 跳过（无前端页面，且时间预算紧张）

---

## 2. 决策结果

| # | 决策项 | 选择 | 说明 |
|:-:|---|---|---|
| A | Orca 工作树 | **A1** | 跑前 `git config --system core.longpaths true`，重试创建 eagleeye/mes-regression；失败则降级 |
| B | finance/system 处理 | **B2** | gen-tests 生成 API 测试（用户澄清：测试代码可造，业务代码不改） |
| C | DB 备份 | **C1** | mysqldump 全库 jeecg-boot，跑前备份 + 跑后回滚 |
| D | 失败分级 | **P0/P1/P2/P3**（按草案） | 见 §5 |

---

## 3. 执行序列

### 阶段 0：环境准备 + 备份（约 5 分钟）

```bash
# 0.1 确认本地后端（localhost:8080）
curl -s -o nul -w "%{http_code}" http://localhost:8080/jeecg-boot/sys/login
# 预期：200

# 0.2 确认本地前端（localhost:3100）
curl -s -o nul -w "%{http_code}" http://localhost:3100
# 预期：200（vite dev 已在跑，PID 91677）

# 0.3 DB 全量备份
mysqldump -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot > /tmp/mes-snap-$(date +%Y%m%d-%H%M%S).sql
ls -lh /tmp/mes-snap-*.sql  # 确认文件大小 ~50MB

# 0.4 试启用 longpaths + 创建 Orca 工作树（决策 A1）
git config --system core.longpaths true
orca worktree create --name eagleeye/mes-regression --repo path:D:/vibecoding/jeecgBoot --base-branch main
# 若失败：降级到主目录继续

# 0.5 记录基线状态
mkdir -p hermes/eagle-eye/reports/2026-08-04
mkdir -p hermes/eagle-eye/state
echo "{\"runId\":\"2026-08-04-mes-regression\",\"startedAt\":\"$(date -Iseconds)\",\"phase\":\"0\"}" > hermes/eagle-eye/state/mes-regression.json
```

### 阶段 1：缺测模块测试生成（约 10 分钟）

```bash
# 1.1 finance 模块（8 Controller）
gen-tests mes finance          # 用户发命令确认

# 1.2 system 模块（1 Controller）
gen-tests mes system           # 用户发命令确认
```

**注意**：`gen-tests` 会**新建**测试文件（`harness/tests/mes/finance.test.js` 等），不会改业务代码。

### 阶段 2：前端构建（约 10 分钟，独立通道）

```bash
cd jeecgboot-vue3
pnpm typecheck 2>/dev/null || npx vue-tsc --noEmit 2>&1 | tee hermes/eagle-eye/state/typecheck-$(date +%H%M%S).log
pnpm build 2>&1 | tee hermes/eagle-eye/state/build-$(date +%H%M%S).log
```

### 阶段 3：三路并行测试（max 60-90 分钟）

```
┌─────────────────┬─────────────────┬─────────────────┐
│  3a. API        │  3b. E2E        │  3c. 前端静态   │
│  13 + 新增脚本  │  11 spec        │  vue-tsc+build  │
│  ~20 分钟       │  ~60 分钟       │  ~10 分钟       │
└─────────────────┴─────────────────┴─────────────────┘
```

#### 3a. API 测试（按模块依次跑）

```bash
for m in basic batch purchase sales stock manufacturing finance system; do
  echo "===== API: mes-$m ====="
  cd D:/vibecoding/jeecgBoot
  if ls harness/tests/mes/$m*.test.* 2>/dev/null; then
    for f in harness/tests/mes/$m*.test.*; do
      node "$f" 2>&1 | tee hermes/eagle-eye/state/api-$m-$(basename $f).log
    done
  fi
done
```

#### 3b. E2E 测试（Playwright 批量跑）

```bash
cd harness
E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
  npx playwright test e2e/mes/ --reporter=list,html \
  2>&1 | tee hermes/eagle-eye/state/e2e-$(date +%H%M%S).log
```

#### 3c. 前端（已阶段 2 完成，此处只汇总）

### 阶段 4：DB 回滚（约 5 分钟）

```bash
# 4.1 确认测试产生了数据差异
mysql -uroot -proot --host=127.0.0.1 --protocol=TCP jeecg-boot -e "SHOW TABLE STATUS" > /tmp/mes-post-tables.txt

# 4.2 回滚（全量备份恢复）
mysql -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot < /tmp/mes-snap-*.sql

# 4.3 验证回滚成功
mysql -uroot -proot --host=127.0.0.1 --protocol=TCP jeecg-boot -e "SELECT COUNT(*) FROM c_mes_batch"
```

### 阶段 5：报告产出（约 5 分钟）

每模块 1 份报告 + 1 份总报告，写入 `hermes/eagle-eye/reports/2026-08-04/`。

每份报告模板见 §6。

### 阶段 6：会话记忆 + 通知

```bash
# 6.1 写会话记忆
echo "## $(date +%H:%M) | MES 全量回归测试报告已产出（hermes/eagle-eye/reports/2026-08-04/）" >> .remember/now.md

# 6.2 通知用户：报告路径 + 总览
```

---

## 4. 风险与兜底

| 风险 | 概率 | 影响 | 兜底 |
|:-:|:-:|---|---|
| 本地 DB 被改无法回滚 | 低 | 高 | C1 全量备份 |
| 前端构建失败阻塞 | 中 | 中 | 跳过 build，只跑 API + E2E |
| E2E 服务器未同步 | 已发生 | 中 | 本地 E2E（已验证） |
| Orca 工作树长路径 | 高 | 低 | A1 重试一次，失败降级 |
| 测试代码里有 fibonacci/随机种子 | 低 | 中 | 标记但不改 |
| 测试运行超过 3 小时 | 中 | 中 | 按模块分批报告，可中断 |
| finance 8 Controller gen-tests 失败 | 中 | 中 | 退化到 curl 探测（B1） |
| DB 备份太大失败 | 低 | 高 | 压缩 + 大磁盘兜底 |

---

## 5. 失败分级（P0/P1/P2/P3）

### P0 — 核心流程跑不通
- 登录失败、token 失效
- 菜单/路由 404
- 单据 新增/审核/反审 链路断
- 列表 5xx 持续错

### P1 — 数据/接口错误
- 响应字段缺失（与文档/前端期望不一致）
- 计算结果错（库存数量、金额、聚合统计）
- 状态机异常（状态流转不正确）
- 跨表对账不平（ledgerCount vs 实际流水数）
- 字典反查失败（dictText 为空）
- 导出文件损坏

### P2 — UI/E2E 异常
- 按钮找不到（操作列、抽屉触发）
- 抽屉/弹窗空白/错位
- 列头错位（fixed 列、固定列错乱）
- 列表加载超时（> 10s）
- 表单校验错误（必填项漏报）

### P3 — 性能/样式/告警
- warn 级别日志
- 慢查询（> 1s）
- 性能指标（首屏 > 3s）
- 浏览器 console warn
- 样式细节（间距、颜色）

### 分级映射到测试结果

| 测试失败类型 | 默认级别 | 升级条件 |
|---|:-:|---|
| API 5xx | P1 | 链路核心 → P0 |
| API 字段缺失 | P1 | 主键/必备字段 → P0 |
| API 鉴权失败 | P0 | — |
| E2E 选择器找不到 | P2 | 核心流程 → P1 |
| E2E 抽屉空白 | P1 | — |
| 前端 build 失败 | P1 | TS 类型错 → P0 |
| 前端 typecheck 失败 | P2 | 大量（>10 个文件）→ P1 |

---

## 6. 报告模板

### 6.1 分模块报告模板（mes-{module}-test-report.md）

```markdown
# MES {module} 模块回归测试报告

**日期**：2026-08-04
**模块**：{module}
**Controller 数**：N
**前端页面数**：N
**测试类型**：API / E2E / Frontend

## 一、测试概况

| 指标 | 数值 |
|---|---|
| API 测试用例 | N |
| 通过 | N |
| 失败 | N |
| 失败率 | N% |
| E2E 测试用例 | N |
| 通过 | N |
| 失败 | N |
| 失败率 | N% |

## 二、失败明细（按级别倒序）

### P0（核心流程）

| # | 测试 | 错误信息 | 排查方向 |
|---|---|---|---|

### P1（数据/接口）

| # | 测试 | 错误信息 | 排查方向 |
|---|---|---|---|

### P2 / P3（UI / 性能）

（合并展示，避免列表过长）

## 三、通过项摘要

- 模块核心 Controller /list /add /edit /delete 全部正常
- 主要搜索字段响应 200
- 主要字典反查正常
- …

## 四、明早优先排查顺序

1. **P0**（如存在）
2. **P1**（按业务核心度排序）
3. **P2/P3**（批量处理）

## 五、原始日志

hermes/eagle-eye/state/{module}-*.log
```

### 6.2 总报告模板（mes-regression-test-report.md）

```markdown
# MES 全量回归测试报告 — 2026-08-04

**总测试数**：N API + N E2E + N 前端检查
**总失败数**：N（P0: N, P1: N, P2: N, P3: N）
**总通过率**：N%
**总耗时**：N 分钟

## 一、模块汇总

| 模块 | API | E2E | 前端 | 失败（P0/P1/P2/P3）| 报告 |
|---|:-:|:-:|:-:|:-:|---|

## 二、Top 10 失败（按级别排序）

| # | 级别 | 模块 | 测试 | 错误 |
|---|---|---|---|---|

## 三、跨模块问题

- （如有）跨模块共性问题

## 四、明早行动建议

1. **必处理**：所有 P0 + P1
2. **批量处理**：所有 P2/P3 一次性修
3. **回归**：修完后跑一次 `/test-all mes` 验证

## 五、产物清单

- 8 份模块报告
- 1 份总报告
- N 份原始日志（hermes/eagle-eye/state/）
```

---

## 7. 产物清单

```
hermes/eagle-eye/reports/2026-08-04/
├── mes-basic-test-report.md
├── mes-batch-test-report.md
├── mes-purchase-test-report.md
├── mes-sales-test-report.md
├── mes-stock-test-report.md
├── mes-manufacturing-test-report.md
├── mes-finance-test-report.md          # 新增（决策 B2）
├── mes-system-test-report.md           # 新增（决策 B2）
├── mes-frontend-test-report.md         # vue-tsc + build 结果
└── mes-regression-test-report.md       # 总报告

hermes/eagle-eye/state/                 # 原始日志（不归档，3 天后清理）
├── mes-regression.json                  # 状态快照
├── api-*.log
├── e2e-*.log
├── typecheck-*.log
└── build-*.log
```

---

## 8. 时间预算（总：~95-125 分钟）

| 阶段 | 估计耗时 |
|---|:-:|
| 0 环境 + 备份 + Orca 尝试 | 5-10 分钟 |
| 1 finance + system gen-tests | 10 分钟 |
| 2 前端构建 | 10 分钟 |
| 3 三路并行（max） | 60-90 分钟 |
| 4 DB 回滚 | 5 分钟 |
| 5 报告 | 5 分钟 |
| **合计** | **95-130 分钟** |

---

## 9. 用户操作清单（执行时按需）

执行过程中需要用户决策的点：

1. **阶段 0**：Orca 工作树创建失败时 → "降级继续 / 终止"
2. **阶段 1**：`gen-tests` 是否对所有 finance + system Controller 展开（可指定 Controller 名）
3. **阶段 3**：测试中发现 P0 时 → "立即停下来汇报 / 继续跑完全部"
4. **阶段 4**：DB 回滚前 → "确认回滚 / 保留当前数据（用于复现）"