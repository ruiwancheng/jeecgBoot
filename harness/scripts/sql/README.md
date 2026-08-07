# /debug 库存孤儿行清理工具

> **用途**：清理 `c_mes_inventory` 中指向已删除物料的孤儿行
> **生成原因**：物料删除时无前置校验，导致 LEFT JOIN 不匹配，前端显示"（物料已删除）"
> **版本**：2026-08-07

## 📋 文件清单

| 文件 | 用途 |
|---|---|
| `diagnose-orphan-inventory.sql` | 探针 SQL（只读，5 个查询看规模/分类/详情） |
| `cleanup-orphan-inventory.sh` | 清理脚本（DRY-RUN 默认开启，必须显式才真删） |
| `README.md` | 本文档 |

## 🚦 强制流程（6 步）

```
① probe      → 看规模（只读）
② backup     → 备份 c_mes_inventory（mysqldump）
③ clean-zero → 清零库存孤儿行（DRY-RUN → 真实执行）
④ clean-nonzero → 清有库存孤儿行（必须业务签字 + 每批≤100）
⑤ verify     → 验证清理效果
（可选）rollback → 误删一键回滚
```

## 🚀 快速开始

### 1. 探针（零风险）

```bash
cd harness/scripts/sql
./cleanup-orphan-inventory.sh probe
```

输出 5 段结果：
- 孤儿行总数 + 总库存
- 风险分组（A1/A2/B1/B2）
- 有库存孤儿详情（top 100）
- 零库存孤儿列表（top 100）
- 清理策略预估

### 2. 备份

```bash
./cleanup-orphan-inventory.sh backup
# 生成 backup_c_mes_inventory_YYYYMMDD_HHMMSS.sql
# 务必把此文件传到安全存储再继续
```

### 3. 清零库存（低风险，可立即执行）

```bash
# 3.1 先 DRY-RUN 看 SQL
./cleanup-orphan-inventory.sh clean-zero --dry-run

# 3.2 确认无误后真实执行
DRY_RUN=0 ./cleanup-orphan-inventory.sh clean-zero
```

### 4. 清有库存（高风险，必须业务签字）

```bash
# 4.1 DRY-RUN 列出本批 100 行
./cleanup-orphan-inventory.sh clean-nonzero \
  --batch-id biz-sign-2026-08-07 \
  --limit 100 \
  --dry-run

# 4.2 业务人员核对清单（仓库盘点结果）后真实执行
DRY_RUN=0 ./cleanup-orphan-inventory.sh clean-nonzero \
  --batch-id biz-sign-2026-08-07 \
  --limit 100

# 4.3 还有剩余，继续下一批（用新 batch-id）
DRY_RUN=0 ./cleanup-orphan-inventory.sh clean-nonzero \
  --batch-id biz-sign-2026-08-07-batch2 \
  --limit 100
```

### 5. 验证

```bash
./cleanup-orphan-inventory.sh verify
```

### 6. 回滚（如误删）

```bash
./cleanup-orphan-inventory.sh rollback --batch-id biz-sign-2026-08-07
```

## 🔐 安全机制

| 机制 | 实现 |
|---|---|
| 默认 DRY-RUN | 不显式 `DRY_RUN=0` 不会真删 |
| 审计表 | 所有删除写入 `c_mes_inventory_cleanup_audit` |
| 业务签字 | `clean-nonzero` 必须 `--batch-id` + 交互确认 `YES` |
| 批次限制 | `clean-nonzero` 默认每批 100 行 |
| 一键回滚 | `rollback` 用审计表恢复原行 |
| 备份优先 | `backup` 子命令强制生成 mysqldump |

## ⚙️ 配置（环境变量）

| 变量 | 默认 | 说明 |
|---|---|---|
| `MES_DB_HOST` | 127.0.0.1 | DB 地址 |
| `MES_DB_PORT` | 3306 | DB 端口 |
| `MES_DB_NAME` | jeecg-boot | DB 名 |
| `MES_DB_USER` | root | DB 用户 |
| `MES_DB_PASS` | (空) | DB 密码 |

线上执行：
```bash
MES_DB_HOST=prod-mysql.xxx.com \
MES_DB_USER=ops_user \
MES_DB_PASS='your_password' \
./cleanup-orphan-inventory.sh probe
```

## 📊 风险分级标准

| 风险等级 | 条件 | 处置 |
|---|---|---|
| 🟢 A2 | 物料硬删 + qty=0 | 直接清 |
| 🟢 B2 | 物料软删 + qty=0 | 直接清（推荐） |
| 🔴 A1 | 物料硬删 + qty>0 | 业务盘点后逐批清 |
| 🔴 B1 | 物料软删 + qty>0 | 业务盘点 + `resurrect` 优先 |

**B1 优先 resurrect**（用同名 code 重建物料，系统自动复用原 ID）：
```
物料管理页面 → 新建 → 编码填原 code → 系统自动复活（见 MesMaterialServiceImpl.save）
→ 库存行的 material_id 自动生效 → "（物料已删除）"消失
```

## 🧪 测试场景（建议先在测试环境跑通）

1. 在测试库制造几条孤儿行（手工 SQL 或删物料）
2. 跑完整 6 步流程
3. 测试 rollback 是否能恢复
4. 测试 DRY_RUN 不会真删

## � 审计表结构

`c_mes_inventory_cleanup_audit`：

| 字段 | 说明 |
|---|---|
| id | 自增主键 |
| batch_id | 清理批次号（业务签字标识） |
| inventory_id | 被删库存行 ID |
| material_id | 原物料 ID（已删/已复活） |
| warehouse_id | 仓库 ID |
| current_qty | 删除时的库存数 |
| risk_type | A1/A2/B1/B2 |
| operator | 操作人（环境变量 USER） |
| cleaned_at | 删除时间 |
| rolled_back | 是否已回滚 |
| rollback_at | 回滚时间 |

## 🔗 相关

- 诊断文档：`hermes/eagle-eye/reports/2026-08-07/diagnosis-port-4173.md`（同款风格）
- 根因分析：`/debug` 会话输出
- 长期修复：物料删除 API 加前置校验（待排期）
