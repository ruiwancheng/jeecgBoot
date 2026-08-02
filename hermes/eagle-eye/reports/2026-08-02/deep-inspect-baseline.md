# 深度巡检报告 — 首次基线

**时间：** 2026-08-02 03:58
**变更基线：** HEAD = `c4bc65e`（已 push）
**模块：** mes
**类型：** 首次基线（无趋势对比）
**巡检工具链：** 降级路径（curl + 手动清单，无 k6 / Playwright / axe-core）

---

## 执行摘要

| 维度 | 状态 | 说明 |
|------|:--:|------|
| 性能基准 | ✅ PASS | 5 端点 × 5 采样，p95 最大 29.554ms，远低于 dev 阈值 2000ms |
| 视觉证据 | ⚠️ DEFERRED | Playwright 不可用 → 输出手动截图检查清单（见 §2） |
| 无障碍审计 | ⚠️ DEFERRED | axe-core 不可用 → 输出 WCAG 2.2 AA 检查清单（见 §3） |
| 总体判定 | ✅ **PASS**（基线建立成功） |

**工具链缺口：** k6 / Playwright / axe-core 均不可用，已走降级路径。详见 §4。

---

## 1. 性能基准（Performance Benchmarker）

### 1.1 采样方法（降级路径）

- **工具：** curl `-w "%{time_total}"` × 5 次/端点
- **认证：** admin 登录获取 `X-Access-Token`
- **阈值：** p95 < 2000ms（dev）/ 200ms（prod）；错误率 < 1%
- **数据源：** `hermes/eagle-eye/benchmarks/baseline.json`

### 1.2 端点采样结果

| # | 端点 | p50 (ms) | p95 (ms) | 错误率 | 响应行数 | 判定 |
|--:|------|:--------:|:--------:|:------:|:--------:|:----:|
| 1 | `GET /sys/getEncryptedString` | 2.908 | 4.243 | 0% | n/a | ✅ |
| 2 | `GET /mes/basic/material/list` | 20.209 | 26.290 | 0% | 10 | ✅ |
| 3 | `GET /mes/batch/master/list` | 13.608 | 16.200 | 0% | 4 | ✅ |
| 4 | `GET /mes/batch/ledger/list` | 15.230 | 29.554 | 0% | 4 | ✅ |
| 5 | `GET /mes/manufacturing/picking/list` | 7.118 | 7.753 | 0% | 0 | ✅ |

### 1.3 关键发现

- **最大 p95：** 29.554ms（`/mes/batch/ledger/list`） — 远低于 dev 阈值 2000ms（差 67 倍）
- **最小 p95：** 4.243ms（`/sys/getEncryptedString`）
- **错误率：** 全 5 端点 × 5 采样 = 25 次请求，0 错误
- **趋势对比：** 首次基线，无历史对照。后续 `/deep-inspect` 将以此为参考
- **退化判定：** N/A（首次）

### 1.4 性能判定

**✅ PASS** — 所有端点 p95 < 30ms，开发环境远在 SLA 内。

### 1.5 Frontend Core Web Vitals

| 指标 | 目标 | 实测 | 判定 |
|------|:----:|:----:|:----:|
| LCP | < 2500ms | null | ⚠️ 未测量 |
| FID | < 100ms | null | ⚠️ 未测量 |
| CLS | < 0.1 | null | ⚠️ 未测量 |

**说明：** Playwright / Lighthouse 不可用，Core Web Vitals 未自动采集。**建议** 安装 Playwright 后补齐（见 §4）。

---

## 2. 视觉证据采集（Evidence Collector）

### 2.1 执行状态

- **Playwright：** ❌ 不可用
- **降级路径：** 输出手动截图检查清单
- **采集目标：** 5 个核心 MES 模块的列表页 + 弹窗 + 详情页 × 3 视口

### 2.2 手动截图清单（待人工执行）

**存放路径约定：** `hermes/eagle-eye/evidence/mes/2026-08-02/<page>-<viewport>.png`

#### 模块 A — 物料基础（`/mes/material`）

| # | 页面 | 视口 | 检查要点 | 截图文件名 |
|--:|------|:--:|---------|-----------|
| A1 | 列表页（搜索区展开） | 1920×1080 | 搜索区 / 列表 / 操作列按钮 | `material-list-desktop.png` |
| A2 | 列表页（搜索区展开） | 768×1024 | 平板布局自适应 | `material-list-tablet.png` |
| A3 | 列表页 | 375×812 | 移动端折叠/横向滚动 | `material-list-mobile.png` |
| A4 | 新增弹窗 | 1920×1080 | 必填项红星 / 表单完整呈现 | `material-add-dialog.png` |
| A5 | 详情页 | 1920×1080 | 只读模式 / Tab 切换 | `material-detail.png` |

#### 模块 B — 批次主数据（`/mes/batch/master`）

| # | 页面 | 视口 | 检查要点 | 截图文件名 |
|--:|------|:--:|---------|-----------|
| B1 | 列表页 | 1920×1080 | 状态着色 / 批次号链接 | `batch-master-list.png` |
| B2 | 新增弹窗 | 1920×1080 | 物料下拉 / 数量校验 | `batch-master-add.png` |
| B3 | 详情页 | 1920×1080 | 关联展示（成品/工序） | `batch-master-detail.png` |

#### 模块 C — 批次台账（`/mes/batch/ledger`，P0-5 成本落点）

| # | 页面 | 视口 | 检查要点 | 截图文件名 |
|--:|------|:--:|---------|-----------|
| C1 | 列表页 | 1920×1080 | 成本列 / 入/出库区分 | `batch-ledger-list.png` |
| C2 | 详情页 | 1920×1080 | FIFO 链路展示 | `batch-ledger-detail.png` |

#### 模块 D — 生产领料（`/mes/manufacturing/picking`，P0-5 业务触发点）

| # | 页面 | 视口 | 检查要点 | 截图文件名 |
|--:|------|:--:|---------|-----------|
| D1 | 列表页 | 1920×1080 | 领料单状态 / FIFO 标记 | `picking-list.png` |
| D2 | 新增领料弹窗 | 1920×1080 | 物料选择 / 批次自动推荐 | `picking-add.png` |

#### 模块 E — 销售出库（`/mes/sales/outbound`，P0-5 业务触发点）

| # | 页面 | 视口 | 检查要点 | 截图文件名 |
|--:|------|:--:|---------|-----------|
| E1 | 列表页 | 1920×1080 | 出库单 / 批次回写 | `sales-outbound-list.png` |
| E2 | 新增出库弹窗 | 1920×1080 | 客户 / 批次选择 | `sales-outbound-add.png` |

### 2.3 截图执行步骤

```bash
# 1. 确保前后端运行
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/jeecg-boot/sys/getEncryptedString  # 应 200
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3100/                                  # 应 200

# 2. 创建证据目录
mkdir -p hermes/eagle-eye/evidence/mes/2026-08-02

# 3. 登录 admin/123456，使用 Chrome DevTools "Toggle device toolbar" 切换视口

# 4. 按清单逐张截图并保存到对应文件名

# 5. （可选）下次 /deep-inspect 用 pixel-diff 工具对比
```

### 2.4 视觉判定

**⚠️ DEFERRED** — 待人工截图后回填。基线阶段无历史对照，回归检测需第二次 /deep-inspect 才生效。

---

## 3. 无障碍审计（Accessibility Auditor）

### 3.1 执行状态

- **axe-core：** ❌ 不可用
- **Playwright：** ❌ 不可用
- **降级路径：** 输出 WCAG 2.2 AA 检查清单

### 3.2 WCAG 2.2 AA 检查清单（待人工/工具补齐）

| # | 检查项 | WCAG 标准 | 检测方式 | 严重度 | 状态 |
|--:|--------|----------|---------|:------:|:----:|
| 1 | 图片有 `alt` 属性 | 1.1.1 | DevTools / axe | Critical | ⏳ 待检查 |
| 2 | 表单 input 有 label 关联（`<label for>` 或 `aria-label`） | 1.3.1 | DevTools / axe | Serious | ⏳ 待检查 |
| 3 | 颜色对比度 ≥ 4.5:1（正文）/ 3:1（大字体） | 1.4.3 | axe / Lighthouse | Serious | ⏳ 待检查 |
| 4 | 键盘可达（Tab 顺序合理，无 `tabindex` 滥用） | 2.1.1 | 键盘 Tab 实测 | Critical | ⏳ 待检查 |
| 5 | 跳过导航链接（skip-link） | 2.4.1 | DevTools 检查 | Moderate | ⏳ 待检查 |
| 6 | 页面 `<title>` 非空且有意义 | 2.4.2 | DevTools | Moderate | ⏳ 待检查 |
| 7 | `<html lang="zh-CN">` | 3.1.1 | DevTools | Serious | ⏳ 待检查 |
| 8 | 焦点状态可见（focus ring） | 2.4.7 | 键盘 Tab + 截图 | Serious | ⏳ 待检查 |
| 9 | 弹窗焦点陷阱（focus trap） | 2.4.3 | 实测 | Serious | ⏳ 待检查 |
| 10 | 错误提示与表单关联（aria-describedby） | 1.3.1 / 3.3.1 | DevTools | Moderate | ⏳ 待检查 |
| 11 | 屏幕阅读器朗读验证 | 4.1.2 | NVDA / VoiceOver | Serious | ⏳ 待检查 |

### 3.3 人工验证清单（无法自动化）

```bash
# 1. Tab 顺序实测
- 打开 /mes/material 列表页
- 按 Tab 10 次，记录焦点元素，验证逻辑顺序

# 2. 焦点可见性截图
- Tab 到"新增"按钮
- 截图保存到 hermes/eagle-eye/evidence/mes/2026-08-02/a11y-focus-{page}.png

# 3. 屏幕阅读器
- 推荐 NVDA (Windows) / VoiceOver (Mac)
- 验证：列表页朗读、表单输入朗读、错误提示朗读
```

### 3.4 无障碍判定

**⚠️ DEFERRED** — 首次基线，无 axe 工具无法量化分值。后续接入 axe-core / Playwright 后自动评分。

**建议优先级：** 装 Playwright + axe-core（npm 包 `@axe-core/playwright`）一次性解决视觉 + 无障碍缺口。

---

## 4. 工具链缺口说明

| 工具 | 现状 | 影响 | 建议 |
|------|------|------|------|
| k6 | ❌ 不可用 | 无法跑高并发压测 / p99 / 持续负载 | `choco install k6` 或 Docker |
| Playwright | ❌ 不可用 | 无法自动截图 + pixel-diff + axe 联动 | `pnpm add -D @playwright/test && pnpm exec playwright install` |
| axe-core | ❌ 不可用 | 无障碍审计只能人工 | 通过 Playwright 安装 `@axe-core/playwright` |
| Lighthouse | ❌ 不可用 | Core Web Vitals 无法自动采集 | Chrome DevTools 已内置 / 或 CI 跑 `lighthouse-ci` |

**安装建议（一次性投资，性价比高）：**

```bash
# PowerShell (管理员)
choco install k6

# 项目内
cd jeecgboot-vue3
pnpm add -D @playwright/test @axe-core/playwright
pnpm exec playwright install chromium
```

**预期收益：** 解锁视觉证据（自动截图 + pixel-diff）+ 无障碍审计（自动评分）+ 前端性能（Lighthouse）三大缺口，使 `/deep-inspect` 从降级路径升级到全自动路径。

---

## 5. 综合判定

### 5.1 判定矩阵

| 维度 | 评级 | 关键数据 |
|------|:----:|---------|
| 性能基准 | ✅ PASS | p95 最大 29.554ms，0 错误 |
| 视觉证据 | ⚠️ DEFERRED | 手动清单已列，待人工 |
| 无障碍审计 | ⚠️ DEFERRED | WCAG 清单已列，待工具 |
| **总体** | ✅ **PASS** | 基线建立成功，2 项降级不阻塞 |

### 5.2 结论

✅ **首次基线已建立。** 性能维度达标，视觉与无障碍维度因工具链缺口走降级路径，已输出可执行清单待后续补齐。

### 5.3 下一步建议

| 优先级 | 动作 | 责任人 |
|:------:|------|--------|
| 🟡 中 | 安装 Playwright + axe-core（一次性投资，解锁视觉/无障碍自动巡检） | 协调者 |
| 🟡 中 | 安装 k6（性能压测升级到 p99 / 高并发） | 协调者 |
| 🟢 低 | 人工执行 §2.2 截图清单，落盘 `hermes/eagle-eye/evidence/mes/2026-08-02/` | 协调者 |
| 🟢 低 | 接入 `/quality-dashboard`，本次基线用于"数据缺口第 3 条"补齐 | 协调者 |
| 🟢 低 | 第二次 `/deep-inspect` 触发后启用趋势对比 | 协调者 |

---

## 附录 A：原始采样数据

### A.1 /sys/getEncryptedString（ms）

```
2.858, 2.908, 4.243, 2.927, 2.605
→ min=2.605, max=4.243, avg=3.108, p50=2.908, p95=4.243
```

### A.2 /mes/basic/material/list（ms）

```
26.290, 20.209, 23.310, 18.612, 18.066
→ min=18.066, max=26.290, avg=21.297, p50=20.209, p95=26.290
```

### A.3 /mes/batch/master/list（ms）

```
16.200, 13.608, 12.937, 13.480, 15.077
→ min=12.937, max=16.200, avg=14.260, p50=13.608, p95=16.200
```

### A.4 /mes/batch/ledger/list（ms）

```
17.344, 14.176, 29.554, 15.230, 12.848
→ min=12.848, max=29.554, avg=17.830, p50=15.230, p95=29.554
```

### A.5 /mes/manufacturing/picking/list（ms）

```
6.966, 6.762, 7.753, 7.118, 7.338
→ min=6.762, max=7.753, avg=7.187, p50=7.118, p95=7.753
```

---

## 附录 B：执行命令回放

```bash
# 1. 健康检查
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/jeecg-boot/sys/getEncryptedString  # 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/                                  # 200

# 2. 登录取 token
TOKEN=$(curl -s -X POST "http://localhost:8080/jeecg-boot/sys/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' \
  | grep -oP '"token":"[^"]+' | head -1 | cut -d'"' -f4)

# 3. 性能采样（5 端点 × 5 采样）
for endpoint in \
  "/sys/getEncryptedString" \
  "/mes/basic/material/list" \
  "/mes/batch/master/list" \
  "/mes/batch/ledger/list" \
  "/mes/manufacturing/picking/list"
do
  for i in 1 2 3 4 5; do
    if [ "$endpoint" = "/sys/getEncryptedString" ]; then
      curl -s -o /dev/null -w "code=%{http_code} time=%{time_total}s\n" \
        "http://localhost:8080/jeecg-boot${endpoint}"
    else
      curl -s -o /dev/null -w "code=%{http_code} time=%{time_total}s\n" \
        -H "X-Access-Token: $TOKEN" \
        "http://localhost:8080/jeecg-boot${endpoint}?pageNo=1&pageSize=10"
    fi
  done
done
```

---

## 附录 C：与质量门控基线的关系

- **上游：** `hermes/eagle-eye/reports/2026-08-02/quality-gate-baseline.md`（HEAD=c4bc65e）
- **本次：** 本报告基于同一 HEAD 跑出的巡检基线
- **数据缺口补齐：** 本次为 `/quality-dashboard` "无 deep-inspect 报告"缺口建立基线

---

**报告生成者：** deep-inspect worker（降级路径）
**报告版本：** baseline-v1.0
**下次巡检建议：** 协调者触发；接入 Playwright + axe-core 后升级为自动路径