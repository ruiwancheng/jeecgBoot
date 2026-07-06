---
name: tablelogic-resurrection
description: @TableLogic 软删除记录复活 — 查/改都必须用原始 SQL 绕过
metadata:
  type: reference
---

# MyBatis-Plus @TableLogic 软删除记录的"借尸还魂"

## 问题

数据库唯一索引 `UNIQUE(code)` + MyBatis-Plus `@TableLogic`。场景：
```
新建 ck001 → 软删除 → 重建 ck001 → 再删 → ❌ 唯一索引冲突
```

## 根因

`@TableLogic` 自动向所有 CRUD 追加 `AND del_flag=0`：

| 操作 | MP 实际 SQL | 结果 |
|------|-----------|------|
| `selectOne(qw)` | `WHERE code='ck001' AND del_flag=0` | 找不到软删除记录 |
| `updateById(entity)` | `SET ... WHERE id=? AND del_flag=0` | 软删除记录改不了 |

## 解决方案："借尸还魂"

新增时如果编码已存在于软删除记录中，不新增、不物理删，直接复用旧记录：

```java
// 1. 查活跃记录 → @TableLogic 自动过滤，正常
if (baseMapper.selectCount(activeQw) > 0) throw exception("已存在");

// 2. 查软删除记录 → 必须原始 SQL 绕过
MesWarehouse old = baseMapper.selectDeletedByCode(code);

// 3. 有则复活 → 必须原始 SQL 绕过
if (old != null) {
    entity.setId(old.getId());          // 保留 ID
    entity.setCreateBy(old.getCreateBy()); // 保留创建人
    entity.setCreateTime(old.getCreateTime()); // 保留创建时间
    baseMapper.resurrect(entity);       // 原始 SQL: UPDATE ... SET del_flag=0
    return true;
}

// 4. 没有 → 正常新增
return super.save(entity);
```

**Mapper 原始 SQL：**
```java
@Select("SELECT * FROM c_mes_warehouse WHERE code = #{code} AND del_flag = 1 LIMIT 1")
MesWarehouse selectDeletedByCode(String code);

@Update("UPDATE c_mes_warehouse SET code=#{code}, name=#{name}, ..., del_flag=0 WHERE id=#{id}")
void resurrect(MesWarehouse entity);
```

**Why:** ID 不变 → 库存/报表等历史关联数据不中断。唯一索引保持 `(code)` 不动。不限次数循环。

**How to apply:** 任何需要软删除 + 重建 + 保留历史关联的实体，都用此模式。
