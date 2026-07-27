---
name: sql-default-dict-code
description: SQL DEFAULT 必须与 Java 端字典编码一致，不能用字典显示文本
metadata:
  type: reference
---

# SQL DEFAULT 值与字典编码不一致——'潜在' vs '1'

## 问题

建表 SQL 中 `status VARCHAR(20) DEFAULT '潜在'`，但 Java 端 `VALID_STATUSES = {"1","2","3","4","5","6"}` 校验的是字典编码值（数字），不是显示文本（中文）。当应用层未显式设置 status 时，数据库写入 `'潜在'`（中文），后续任何 update 操作都会在校验中抛出 `"供应商状态值无效"`。

## 根因

SQL 的 `DEFAULT` 写的是 `sys_dict_item.item_text`（显示给用户的中文标签），而业务代码用的是 `sys_dict_item.item_value`（存储的字典编码）。两者是两套体系。

## 修复

```sql
-- 错误
ALTER TABLE c_mes_supplier MODIFY COLUMN status VARCHAR(20) DEFAULT '潜在';

-- 正确
ALTER TABLE c_mes_supplier MODIFY COLUMN status VARCHAR(20) DEFAULT '1';
```

**How to apply:** 建表时所有字典字段的 DEFAULT 必须用 `item_value`（字典编码），不能用 `item_text`（显示文本）。审代码时重点检查 SQL 中 `DEFAULT '中文'` 的场景。

---

## 追加：sys_dict_item 没有 del_flag 列

### 问题

`sys_dict_item` 表结构不含 `del_flag` 字段。INSERT 列列表中如果包含 `del_flag`，MySQL 报 "Unknown column"，INSERT IGNORE 静默失败——字典项为空，前端下拉无选项。

```sql
-- 错误：12列含 del_flag，但 sys_dict_item 只有 11 列
INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID()), d.id, '标准售价', '1', '...', 1, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_price_type';

-- 正确：11列，无 del_flag
INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID()), d.id, '标准售价', '1', '...', 1, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict d WHERE d.dict_code = 'mes_price_type';
```

**后果：** 字典母表正常（`sys_dict` 有记录），但字典项为空。前端 `JDictSelectTag` 下拉框无选项、回写失败。部署控制台校验码认为 SQL 已执行，后续部署不重跑。需要手动通过 API 插入字典项。

**How to apply:** 写 `sys_dict_item` 的 INSERT 前，先用 `DESCRIBE sys_dict_item` 确认列清单。不要假设它有 `del_flag`。
