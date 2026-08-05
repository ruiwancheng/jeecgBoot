# MES 全量回归修复 Patch 包（2026-08-04）

## 📋 包含的 patch

| # | 文件 | 修复的 bug | 优先级 |
|:-:|---|---|:-:|
| 1 | `01-fix-vite-proxy.env.patch` | vite proxy 路径 `/jeecgboot` → `/jeecg-boot` | 🔴 P0 |
| 2 | `02-add-finance-routes.ts.patch` | finance 路由未注册到 vue-router | 🔴 P0 |
| 3 | `03-add-missing-permissions.java.patch` | 缺 `mes:productionPicking:` + `mes:completionReceipt:` 权限码 | 🟡 P1 |
| 4 | `04-add-customer-columns.sql` | c_mes_customer 表缺 6 列 | 🔴 P1 |

## 🚀 应用步骤

### 1. 备份当前状态（必须）

```bash
cd D:/vibecoding/jeecgBoot
git status                     # 看改了啥
git checkout -b fix/regression-2026-08-04   # 创建分支（隔离修复）
```

### 2. 应用 Patch 1 + 2（前端基础设施，必做）

```bash
# Patch 1: vite proxy
cd jeecgboot-vue3
patch -p1 < ../hermes/eagle-eye/patches/2026-08-04/01-fix-vite-proxy.env.patch

# Patch 2: finance 路由
patch -p1 < ../hermes/eagle-eye/patches/2026-08-04/02-add-finance-routes.ts.patch
cd ..
```

### 3. 应用 Patch 3（后端权限码）

```bash
cd jeecg-boot/jeecg-boot-module/project-mes
patch -p1 < ../../../hermes/eagle-eye/patches/2026-08-04/03-add-missing-permissions.java.patch
cd /d/vibecoding/jeecgBoot
mvn clean install -pl jeecg-boot-module/project-mes -am -DskipTests
# 重启后端（PID 91207）
```

### 4. 应用 Patch 4（DB schema 同步）

```bash
"/c/Program Files/MySQL/MySQL Server 8.4/bin/mysql.exe" -uroot -proot --host=127.0.0.1 --protocol=TCP jeecg-boot < hermes/eagle-eye/patches/2026-08-04/04-add-customer-columns.sql
```

### 5. 重启 vite dev

```bash
# 找到当前 vite 进程（PID 91677）
# Windows: taskkill /PID 91677 /F
cd jeecgboot-vue3
pnpm dev  # 重启
```

### 6. 验证（重跑 E2E）

```bash
cd harness
E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
  npx playwright test e2e/mes/manufacturing.spec.ts e2e/mes/finance.spec.ts --reporter=list --retries=0
```

期望：manufacturing 28 个 + finance 56 个 = 84 个 E2E **大部分通过**（之前 0/84）

### 7. 业务链路再跑

```bash
cd D:/vibecoding/jeecgBoot
node harness/tests/mes/purchase-payment-flow.test.js
node harness/tests/mes/sales-receipt-flow.test.js
```

期望：
- 采购链路 P1-A（supplier_id）会通过测试（修不了这 bug，因为是后端代码 + 实体设计问题，未在 patch 中）
- 销售链路 P1-B（Customer 6 列）会通过（patch 4 修了）

## ⚠️ 未包含在 Patch 中的修复

这些是业务代码 bug，需要单独修复：

| Bug | 修复方向 | 风险 |
|---|---|---|
| **采购入库 supplier_id 缺失** | MesPurchaseReceiptServiceImpl.audit() 内补 supplier_id（从关联 order 拉） | 中（可能影响其他逻辑） |
| **前端 742 个 TS 错误** | 批量修复 dictCode/dictTable 用法 + BatchMasterDrawer 类型 | 中 |
| **System GlobalSwitch.save SQL 异常** | Service 加参数校验或 Controller @Valid | 低 |

## 📊 修复后验证清单

- [ ] 后端 `mvn compile` 通过
- [ ] 前端 `pnpm dev` 启动无错
- [ ] 浏览器登录 admin/123456，左侧菜单有"业财管控"分类
- [ ] 点击"业财管控 → 收款管理"页面正常渲染
- [ ] E2E manufacturing 28 个测试 ≥ 24 通过
- [ ] E2E finance 56 个测试 ≥ 50 通过
- [ ] 业务链路采购链路 ≥ 21/22 通过（剩 1 个 supplier_id 真 bug）
- [ ] 业务链路销售链路 13/13 通过

## 🗑️ 修复后清理

```bash
# 验证完成后可以删除 patch 目录（但保留 git commit 记录）
rm -rf hermes/eagle-eye/patches/2026-08-04/
git add -A && git commit -m "fix(mes): regression 2026-08-04 — vite proxy + finance routes + permissions + customer schema"
```