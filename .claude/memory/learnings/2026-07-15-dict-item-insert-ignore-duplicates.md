---
name: dict-item-insert-ignore-duplicates
description: INSERT IGNORE + SELECT + UUID() 在 sys_dict_item 无唯一约束时会重复——改用 DELETE + INSERT VALUES 保证幂等
metadata:
  type: reference
---

# SQL 字典项幂等——INSERT IGNORE 不防重

## 问题

`sys_dict_item` 缺少 `(dict_id, item_value)` 唯一约束。`INSERT IGNORE ... SELECT REPLACE(UUID(), ...)` 每次部署都生成新的 UUID → 新记录 → 字典项越积越多。

物料模块经历 4 次部署后：`mes_material_unit` 从 8 条膨胀到 117 条。

## 根因

`INSERT IGNORE` 只跳过**完全相同的完整行**（所有列值都匹配）。但 `REPLACE(UUID(),'-','')` 每次生成不同的 UUID，导致每行都是新行 → 不会被跳过。

## 修复

```sql
-- 旧写法：每次部署追加重复
INSERT IGNORE INTO sys_dict_item (...) 
SELECT REPLACE(UUID(), ...), ... FROM sys_dict d WHERE d.dict_code = 'xxx';

-- 新写法：先删后插，无论部署多少次都只有 N 条
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'xxx');
INSERT INTO sys_dict_item (...) VALUES (...), (...), (...);
```

## How to apply

所有 `sys_dict_item` 的数据初始化都必须用 DELETE + INSERT VALUES 模式，禁止用 INSERT IGNORE + SELECT + UUID()。

来源：物料模块 4 次部署累积 160+ 条重复，价格模块 3 次部署累积 6 条重复
