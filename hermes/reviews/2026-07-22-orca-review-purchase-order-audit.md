# Orca Review：采购订单审核记录增强方案

**评审日期**：2026-07-22  
**评审人**：Claude Code (Orca Worker)  
**评审对象**：采购订单新增 auditorId/auditTime 审核记录字段（5文件，已实现）  
**评审结论**：✅ **通过（有建议，无阻塞问题）**

---

## 一、变更总览

| # | 文件 | 实际改动 | 状态 |
|---|------|---------|:--:|
| 1 | `db/V9.5.4__mes_purchase_order_audit_fields.sql` (新建) | ALTER TABLE 新增 auditor_id、audit_time | ✅ 正确 |
| 2 | `MesPurchaseOrder.java` | 新增 auditorId/auditTime 字段+注解 | ✅ 正确 |
| 3 | `MesPurchaseOrderMapper.java` | auditWithGuard SQL 新增两列写入 | ✅ 正确 |
| 4 | `MesPurchaseOrderServiceImpl.java` | 无需改动（复用现有参数） | ✅ 正确 |
| 5 | `order.data.ts` | 列表新增审核人、审核时间两列 | ✅ 正确 |

---

## 二、逐项审查

### 1. SQL 迁移脚本 ✅

```sql
ALTER TABLE c_mes_purchase_order
    ADD COLUMN auditor_id VARCHAR(50) COMMENT '审核人ID',
    ADD COLUMN audit_time DATETIME COMMENT '审核时间';
```

- 字段命名符合现有风格（snake_case，无保留字）
- 类型合理：`auditor_id VARCHAR(50)` 与 `create_by`/`update_by` 一致，`audit_time DATETIME` 与 `create_time`/`update_time` 一致
- ⚠️ 不含 `IF NOT EXISTS`（MySQL 5.7 不支持），依赖部署控制台文件校验码去重 — **符合项目模式，非问题**

### 2. Entity 字段 ✅

```java
@Excel(name = "审核人", width = 15)
@Schema(description = "审核人ID")
private String auditorId;
@Excel(name = "审核时间", width = 20, format = "yyyy-MM-dd HH:mm:ss")
@JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
@Schema(description = "审核时间")
private Date auditTime;
```

- 注解完整：`@Excel`（导出用）、`@JsonFormat`/`@DateTimeFormat`（日期序列化）
- 位置合理：放在 `status` 和 `remark` 之间
- 审核人字段用 `String` 存用户名，无 `@Dict` 注解（不需要字典翻译）— **正确，auditorId 存的是用户名而非字典编码**

### 3. Mapper auditWithGuard ✅

```java
@Update("UPDATE c_mes_purchase_order SET status = '3', auditor_id = #{updateBy}, audit_time = #{updateTime}, update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
```

**方法签名未变，参数复用**：`auditor_id = #{updateBy}` 和 `audit_time = #{updateTime}` 复用现有参数 — 审核人即操作人，审核时间即操作时间，业务语义一致。

🟡 **建议**（非阻塞）：`#{updateBy}` 绑定到 `auditor_id` 列在功能上完全正确，但语义上不够直观。建议添加显式的 `@Param("auditorId")` 和 `@Param("auditTime")`，让参数名与列名对应：

```java
int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, 
                   @Param("updateTime") Date updateTime,
                   @Param("auditorId") String auditorId, @Param("auditTime") Date auditTime);
```

优先级低 — 不影响功能，纯粹的代码可读性改进。

### 4. Service — 确认无需改动 ✅

```java
public void audit(String id) {
    String username = getCurrentUsername(); Date now = new Date();
    int rows = baseMapper.auditWithGuard(id, username, now);
    if (rows == 0) throw new JeecgBootException("审核失败：订单不存在或状态已变更，请刷新后重试");
}
```

- `username` 和 `now` 已捕获，Mapper 复用同一组参数写入四列 — **逻辑正确**
- `markPartiallyReceived` / `markFullyReceived` 不改 audit 字段 — **正确**，入库触发的状态变更不应覆盖人工审核记录

### 5. 前端列表 ✅

```typescript
{ title: '审核人', dataIndex: 'auditorId', width: 100 },
{ title: '审核时间', dataIndex: 'auditTime', width: 160 },
```

- 只加列表展示，不加表单编辑 — **正确**，审核字段应由后端 audit 方法写入，不应由用户编辑
- 宽度合理

---

## 三、风险评估

### 未发现的风险点 ✅

| 检查项 | 结论 |
|--------|:--:|
| 会破坏现有查询吗？ | ❌ 不会，新增列不影响已有 SELECT/DML |
| 会破坏录入/编辑流程吗？ | ❌ 不会，新字段仅在 audit 时写入 |
| 会影响导出吗？ | ❌ 不会，`@Excel` 自动加入导出列 |
| `resurrect` 会误清 audit 字段吗？ | ❌ 不会，resurrect SQL 是显式列清单，不含 audit 两列 |
| 并发安全？ | ✅ `auditWithGuard` 有 `WHERE status = '1'` 守卫，单次状态原子更新 |
| `markPartiallyReceived`/`markFullyReceived` 会误写 audit 吗？ | ❌ 不会，这两个方法不改 audit 字段 |

### 🟢 低风险边缘场景 — resurrect 保留旧 audit 数据

当前 `resurrect` SQL 不包含 `auditor_id`/`audit_time`，这意味着软删除后再复活的订单会保留删除前的审核记录。这在功能上无影响（复活后的订单 status=草稿，审核人信息只是历史残留），但从数据清洁度来看略有瑕疵。

**影响**：极低（复活订单的业务场景罕见，且复活后仍需重新审核）  
**建议**：可在后续迭代时考虑是否在 resurrect 时清空 audit 字段，当前不阻塞。

---

## 四、代码规范检查

| 规范 | 状态 |
|------|:--:|
| `update-begin`/`update-end` 标记 | ⚠️ Entity 新增字段缺少独立标记 |
| 实体注解完整 (`@TableName` + `@TableId` + `@TableLogic`) | ✅ N/A（非新增实体） |
| 参数校验 (非空/长度) | ✅ N/A（非用户输入） |
| SQL 无保留字冲突 | ✅ |
| 前端无 `any` 类型 | ✅ |

---

## 五、评审结论

### ✅ 通过 (Approved with Suggestions)

**优点**：
- 方案简洁，仅 3 个修改文件 + 1 个新建 SQL
- 与通用 `update_by`/`update_time` 完全分离，审核记录独立不干扰
- Mapper 参数复用巧妙，Service 零改动
- 不影响已有功能（录入、编辑、删除、入库回调、复活）

**建议改进**（非阻塞，可后续迭代）：
1. Mapper 参数显式命名 `@Param("auditorId")`/`@Param("auditTime")`，提升代码可读性
2. Entity 新增字段补齐 `update-begin`/`update-end` 标记
3. SQL 文件需 `git add` 纳入版本管理

**总评**：方案设计合理，实现质量良好，可以提交。
