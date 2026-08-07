# 库存总览孤儿行清理 v3 — 发版说明

> **版本**：v3 完整方案 9.2/10 评审通过
> **代码落地**：8 个 commit（a6d549f → 6147fde）
> **方案文档**：`hermes/plan/inventory-orphan-cleanup-2026-08-07.md` + `hermes/plan/inventory-orphan-cleanup-impl-2026-08-07.md`
> **适用环境**：生产 / 测试 / staging 同步部署

---

## 一句话总结

**8 个 commit 落地 6 阶段完整方案**：业务人员用"批量删除孤儿行"按钮自助清理 → 后端 3 端点 + P0 安全修复 → 19 张表守卫升级 → 性能优化（CRITICAL bug 修复 + UNION ALL + 启动自检） → 5-6 个回归测试 → 运维 Runbook。

---

## 📋 变更概览

### 代码变更（4 个模块）

| 模块 | 改动 |
|---|---|
| **前端（1 个页面 + 2 个文件）** | 库存总览页加 rowSelection / 批量删除孤儿行 / 导出孤儿清单 / orphanTag 标签 |
| **后端 inventory（5 个新文件 + 2 个修改）** | MesInventoryController 3 端点 + MesInventoryMapper XML（4 个新 select） + flyway V10.2.0 审计表 + cleanup 模块 5 个新文件 + MesMenuRegistry 3 权限 |
| **后端 material（22 个新文件 + 1 个修改）** | MaterialReferenceChecker 接口 + 19 个 checker bean + MaterialReferenceAggregator（UNION ALL）+ MaterialReferenceCoverageAssertor（启动自检）+ SysDictCache + CriticalTableLockService + MesMaterialServiceImpl 重写 |
| **测试 + 运维** | fixtures helper + 5-6 个回归测试 + archive-cleanup-audit.sh + runbook |

### 数据库变更

| 类型 | 文件 |
|---|---|
| 新表 | `c_mes_inventory_cleanup_audit`（活跃）+ `c_mes_inventory_cleanup_audit_his`（归档） |
| 索引 | idx_batch / idx_inventory / idx_cleaned + 归档表 idx_archived |
| 无 DML | 无数据迁移 |

### 权限变更（3 个新权限码）

- `mes:inventory:deleteOrphan`（单删）
- `mes:inventory:batchDeleteOrphan`（批量删）
- `mes:inventory:export`（导出）

### 行为变更（业务方需知）

| 项 | 旧行为 | 新行为 |
|---|---|---|
| 库存总览页"（物料已删除）"灰色行 | 永久显示 | **显示"孤儿行"标签**（可点击"批量删除"清理） |
| 物料被删除时 | 无任何检查，直接软删 | **守卫检查 19 张表引用**（任一引用 → 整批拒绝） |
| 物料删除接口 | 任意删 | 引用行存在 → 抛 JeecgBootException 含关联表清单 |
| 删除物料时的库存行 | 软删物料导致孤儿 | **守卫要求完全无引用**（避免产生新孤儿） |

---

## � P0/P1 修复完成度

| Codex 评审发现 | 修复 commit |
|---|---|
| P0-1 前后端契约错位（isOrphan 字段缺失） | `372500f` ✅ |
| P0-2 export xlsx 外衣 plain text | `372500f` ✅ |
| P0-3 removeByIds bypass 守卫 | `3daaa57` ✅ |
| P1-3 批量删除无 FOR UPDATE | `372500f` ✅ |
| P1-4 operator 三元化 | `372500f` ✅ |
| P1 preCheckDelete catch 仅 JeecgBootException | `3daaa57` ✅ |
| **P0 CRITICAL**：JdbcTemplate 参数绑定 bug | `c31eb60` ✅（用 NamedParameterJdbcTemplate） |

**3 轮 Codex 评审 + 2 轮修复** → 闭环通过

---

## 🚀 部署步骤

### 1. 预发环境验证

```bash
# 1) 拉取最新代码
git pull origin main
git log --oneline -8  # 验证 8 个 commit 在

# 2) flyway migration 自动执行（应用启动时）
#    - 新增 2 张表：c_mes_inventory_cleanup_audit + audit_his
#    - 新增 6 个索引

# 3) 起服务（dev profile）
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 4) 验证端点（curl）
curl -X POST http://localhost:8080/jeecg-boot/mes/warehouse/inventory/batchDeleteOrphan \
  -H 'Content-Type: application/json' \
  -d '{"ids": []}'
# 期望：400/500 含 'ids 不能为空'

# 5) 验证启动自检
# 应用启动日志应包含：
# [INFO] MaterialReferenceChecker 校验通过：19 张表全部覆盖
```

### 2. 业务人员 smoke test

| 测试 | 操作 | 期望 |
|---|---|---|
| T1 标签显示 | 库存总览页找"孤儿行"标签 | 标签可见，悬浮提示"物料已删除" |
| T2 批量删除 | 勾选 3 条孤儿行 → 点"批量删除" | Modal 确认 → 成功提示 → 行消失 |
| T3 物料删除守卫 | 删一个有库存引用的物料 | 抛错"物料被 c_mes_inventory 仍有 N 行引用" |
| T4 物料删除成功 | 删一个无引用的物料 | 删除成功（守卫通过） |

### 3. 生产部署

```bash
# 标准部署流程
mvn clean package -DskipTests
# 上传 jar 到生产
# 重启服务（保持向后兼容：旧代码不依赖新表/字段）
```

### 4. 部署后验证

```bash
# 1) 监控新权限码生效
mysql -e "SELECT permission_code FROM sys_permission WHERE permission_code LIKE 'mes:inventory:%'"

# 2) 监控审计表
mysql -e "SELECT COUNT(*) FROM c_mes_inventory_cleanup_audit"

# 3) 监控启动自检日志
grep "MaterialReferenceChecker 校验通过" app.log
```

---

## ⚠️ 回滚预案

### 单笔 rollback（误删某批次）

```bash
./harness/scripts/sql/cleanup-orphan-inventory.sh rollback --batch-id biz-sign-YYYY-MM-DD
```

### 紧急回滚到 v3 之前（若新功能导致严重问题）

```bash
# 1) git revert 8 个 commit
git revert --no-edit 6147fde 8a7e071 c31eb60 3daaa57 8422eb8 372500f e4e8aae a6d549f

# 2) 数据库层（如已创建 audit 表，可保留，不影响旧功能）
# 无需 DROP 表

# 3) 重新部署
```

### 仅回滚守卫（保留 UI + 后端 inventory 端点）

```bash
git revert --no-edit c31eb60 3daaa57 8422eb8  # 撤销阶段 3+4 守卫
# 此时 UI 仍可批量删孤儿行，但物料删除无守卫
```

---

## 📊 业务影响

### 业务人员

- ✅ **新增能力**：可在库存总览页自助清理孤儿行
- ✅ **可视化增强**：孤儿行有"孤儿行"标签 + 业务方能直观识别
- ⚠️ **新约束**：物料被引用时无法删除（需业务清理关联数据）
- ⚠️ **新约束**：物料删除前调用 preCheckDelete 显示关联数

### DBA

- ✅ **新工具**：`cleanup-orphan-inventory.sh`（DRY-RUN + 审计 + 回滚）
- ✅ **新工具**：`archive-cleanup-audit.sh`（月度归档 90 天 TTL）
- ⚠️ **新监控**：审计表行数 + 新增孤儿行/周
- ⚠️ **新 cron**：月度归档（建议每月 1 号 02:00）

### 开发

- ✅ **新接口**：`MaterialReferenceChecker` 列表模式（新增引用表只需加 bean）
- ✅ **新工具**：`MaterialReferenceCoverageAssertor` 启动自检（fail-fast）
- ✅ **新工具**：`SysDictCache` 字典缓存（守卫读字典 0 round-trip）
- ✅ **CRITICAL bug 修复**：JdbcTemplate → NamedParameterJdbcTemplate

---

## 📋 业务方沟通要点（公告模板）

> **【系统公告】库存总览页新增孤儿行清理功能（2026-08-XX 上线）**
>
> 各位同事好，
>
> 库存总览页面新增"孤儿行清理"功能，主要变化：
>
> 1. **页面变化**：原本显示灰色"(物料已删除)"的行现在显示"孤儿行"标签
> 2. **新增按钮**：勾选孤儿行 → 点击"批量删除孤儿行" → 确认 → 自动清理
> 3. **物料删除规则**：删除物料前系统会自动检查 19 张表的引用情况（如库存/批次/订单），有引用则拒绝删除并提示关联数
> 4. **回退路径**：若误删可通过 SQL 应急脚本一键回滚
>
> 如有疑问联系 @业务运维组。

---

## 🧪 测试覆盖

| 测试文件 | 覆盖 |
|---|---|
| `inventory-orphan-edge.test.js` | E1-E5 边界 case（空 ids / SQL 注入 / 超 500 / 单删 / 非孤儿拒绝） |
| `inventory-orphan-ui-delete.test.js` | U1-U4（单删 / 有库存拒绝 / 批量 / 审计断言） |
| `inventory-orphan-export.test.js` | E1-E2（orphanCount + export 占位） |
| `material-delete-guard.test.js` | S1-S6 守卫场景 |
| `material-reference-coverage-assertor.test.js` | T1-T2 schema 19 表校验 |

**6 个测试文件 / 203 行**，可在测试环境用 `node harness/tests/modules/{file}.test.js` 单独跑。

---

## 🔗 相关链接

- 方案文档：`hermes/plan/inventory-orphan-cleanup-2026-08-07.md`
- 实施草案：`hermes/plan/inventory-orphan-cleanup-impl-2026-08-07.md`
- 3 轮 Codex 评审报告：
  - v1 评审：`hermes/reviews/2026-08-07-review-inventory-orphan-cleanup.md`（7.5/10）
  - v2 评审：`hermes/reviews/2026-08-07-review-inventory-orphan-cleanup-v2.md`（8.7/10）
  - v3 评审：`hermes/reviews/2026-08-07-review-inventory-orphan-cleanup-v3.md`（9.2/10）
  - Slice 1+2 复评审：`hermes/reviews/2026-08-07-review-slice-1-2-fix.md`（8.6/10，pass）
  - Slice 3 复评审：`hermes/reviews/2026-08-07-review-slice-3-guard.md`（6.3 → 修复后闭环）
- 运维 Runbook：`.claude/docs/runbook-orphan-cleanup.md`
- 应急脚本：`harness/scripts/sql/cleanup-orphan-inventory.sh` + `archive-cleanup-audit.sh`

---

## ✅ 发版 checklist

- [x] 8 个 commit 全部 push origin/main
- [x] 3 轮 Codex 评审通过 + 修复闭环
- [ ] 预发环境验证（mvn spring-boot:run + curl）
- [ ] 业务人员 smoke test 4 项
- [ ] DBA 配置月度归档 cron
- [ ] 业务方公告发布
- [ ] 生产部署
- [ ] 部署后监控（审计表行数 + 新增孤儿行/周）
