---
name: mysql-hex-encoding-check
description: 使用 MySQL HEX() 函数诊断 UTF-8 中文是否双重编码
metadata:
  type: reference
---

# MySQL HEX() 诊断 UTF-8 编码问题

## 问题

通过 `docker exec` 向 MySQL 插入中文后，前端显示乱码，不确定是数据库存储问题还是应用层问题。

## 方法

用 `HEX()` 函数直接查看字段的原始字节：

```sql
SELECT realname, HEX(realname) FROM sys_user WHERE username = 'mes_admin';
```

## 判断标准

以"管理员"三个字为例：

| 编码状态 | HEX 值 | 长度 |
|---------|--------|:--:|
| ✅ 正确的 UTF-8 | `E7AEA1 E79086 E59198` | 9 字节 |
| ❌ 双重编码 | `C3A7C2AE C2A1C3A7 C290E280A0 C3A5E28098 CB9C` | 21 字节 |

**Why:** 
- 正确 UTF-8：每个中文字符 3 字节（`E7 AE A1` = 管）
- 双重编码：UTF-8 字节被当作 Latin-1 再次编码为 UTF-8，导致每个原始字节变成 2-3 字节（`E7` → `C3 A7`）

**How to apply:** 遇到中文乱码先跑 `SELECT HEX(column)`，确认是存储层还是应用层问题。字节数约等于字符数×3 = 正常，远超 = 双重编码。
