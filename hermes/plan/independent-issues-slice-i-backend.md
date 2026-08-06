# 独立问题修复 Plan (Slice I) — traceability @Dict + listByBatchId 500

**作者**：pi
**日期**：2026-08-07
**前置**：Phase 1+2+3+4 + Slice A/B/C/D/E/F/G/H 全部完成。
**结论**：**Slice I 的目标在 Slice H 中已完整覆盖**（详见 §1 根因分析），无需独立 commit。

---

## 1. 现状分析

### 1.1 卡片对 Slice I 的目标

| 目标 | 状态 | 备注 |
|---|---|---|
| `MesBatchTraceability` 加 `@Dict(originType)` 和 `@Dict(status)` | ✅ 已覆盖 | 实际在 `MesBatchTraceabilityVO` 上已有 `@Dict(dicCode = "mes_batch_origin_type")` 和 `@Dict(dicCode = "mes_batch_status")` |
| `listByBatchId` 返回 500 | ✅ 已覆盖 | dev DB `c_mes_batch_ledger.remark` 列缺失导致 SQL 错误，Slice H 已 ALTER TABLE 修复 |

### 1.2 根因追溯（实测验证）

worker 根因分析提到的"traceability/list 缺 @Dict 注解"实际上是误判。

**实测 `MesBatchTraceabilityVO.java` 第 73-79 行**：
```java
@Dict(dicCode = "mes_batch_origin_type")
@Excel(name = "来源类型", width = 12)
@Schema(description = "来源类型(dict:mes_batch_origin_type)")
private String originType;
...
@Dict(dicCode = "mes_batch_status")
@Excel(name = "状态", width = 10)
@Schema(description = "状态(dict:mes_batch_status)")
private String status;
```

VO 上 `@Dict` 注解**已存在**，DictAspect 通过反射处理时能识别。

**真正缺失的是字典数据**：
```
mysql> SELECT dict_code FROM sys_dict WHERE dict_code IN ('mes_batch_origin_type','mes_batch_status');
(empty)
```

DictAspect.step3 逻辑：
```java
List<DictModel> dictModels = translText.get(fieldDictCode);
if(dictModels==null || dictModels.size()==0){
    continue;  // 字典查不到 → dictText 不输出
}
```

→ 字典缺失导致 dictText 不输出，但 `@Dict` 注解本身是有的。

### 1.3 `listByBatchId` 500 根因

实测 `harness/tests/modules/traceability-batch-level.test.js` 输出：
```
❌ 4.1 抽屉接口 200: code=500
   Cause: java.sql.SQLSyntaxErrorException: Unknown column 'remark' in 'field list'
   mapper: MesBatchLedgerMapper.java
```

`MesBatchLedgerMapper.selectByBatchId` 用 `SELECT * FROM c_mes_batch_ledger`，但 MyBatis-Plus 默认会用实体字段列表生成 SELECT 语句。`MesBatchLedger` 实体包含 `remark` 字段（`@Schema(description = "备注")`），但 dev DB `c_mes_batch_ledger` 表**没有** remark 列 → 触发 SQL 错误。

**修复**：Slice H 中 V10.0.6 已添加 remark 列。

---

## 2. 验证

### 2.1 `traceability/list` dictText 输出（post-Slice H）

```bash
curl "http://127.0.0.1:8080/jeecg-boot/mes/batch/traceability/list?pageNo=1&pageSize=2" \
  -H "X-Access-Token: <admin token>"
```

返回：
```json
{
  "id": "2085174002708414466",
  "batchNo": "BATCH-1785979197398",
  "materialId": "2085174002431590402",
  "originType": "1",
  "status": "1",
  "materialId_dictText": "批次料A",
  "originType_dictText": "采购入库",   // ← Slice H 修复
  "status_dictText": "正常"             // ← Slice H 修复
}
```

### 2.2 `listByBatchId` 端点（post-Slice H）

```bash
curl "http://127.0.0.1:8080/jeecg-boot/mes/batch/ledger/listByBatchId?batchId=non-existent" \
  -H "X-Access-Token: <admin token>"
```

返回：
```json
{"success":true,"code":200,"result":[]}
```

---

## 3. 决策

**Slice I 取消独立 commit**，原因：
- 类别 B 的两个目标（@Dict 缺失 + listByBatchId 500）均由 Slice H 完整覆盖
- 减少重复提交，避免 reviewer 混淆
- Slice H 的 commit message 已清晰说明影响范围（含 listByBatchId 修复 + dict 反查）

---

## 4. Slice H 已覆盖项回顾

| Slice I 目标 | Slice H 修复点 | 验证 |
|---|---|---|
| @Dict(originType) | sys_dict + sys_dict_item 插入 mes_batch_origin_type（4 项） | dictText "采购入库"/"完工入库"/"生产领料"/"销售出库" |
| @Dict(status) | sys_dict + sys_dict_item 插入 mes_batch_status（3 项） | dictText "正常"/"已冻结"/"已耗尽" |
| listByBatchId 500 | ALTER TABLE c_mes_batch_ledger ADD remark | 4.1/4.2/4.5/4.6 全部 ✅ |

---

## 5. 不做的（Out of Scope）

- `MesBatchTraceability` 实体（c_mes_batch_ledger 视图）本身无 @Dict（它复用 ledger，无业务含义）
- 其他 VO 的 @Dict 缺失（不在本次失败列表内）

---

## 6. 参考

- Slice H 文档：`hermes/plan/independent-issues-slice-h-schema.md`
- Slice H commit：`fix(mes): Slice H — c_mes_batch_ledger.remark 列补齐 + 批次字典初始化`
- VO 文件：`jeecg-boot/.../entity/MesBatchTraceabilityVO.java`
- Mapper：`jeecg-boot/.../mapper/MesBatchLedgerMapper.java`
- DictAspect：`jeecg-boot/jeecg-boot-base-core/src/main/java/org/jeecg/common/aspect/DictAspect.java`

---

## 7. Plan 修订记录

| 版本 | 日期 | 修订 | 来源 |
|---|---|---|---|
| v1 | 2026-08-07 | 初版（确认 Slice I 已被 Slice H 覆盖） | PI /plan |