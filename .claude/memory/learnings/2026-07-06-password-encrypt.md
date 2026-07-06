---
name: password-encrypt
description: JeecgBoot 用户密码加密算法 — PBEWithMD5AndDES，参数顺序 username,password,salt
metadata:
  type: reference
---

# JeecgBoot 密码加密算法

## 调用方式

```java
PasswordUtil.encrypt(username, password, salt)
//                    明文      密钥      盐值
```

- **第一个参数 `username`**：被加密的明文（登录用户名），用 UTF-8 编码
- **第二个参数 `password`**：PBE 加密密钥（用户输入的明文密码）
- **第三个参数 `salt`**：盐值，随机字符串

## 算法细节

- 算法：`PBEWithMD5AndDES`
- 迭代次数：1000（硬编码在 `PasswordUtil.ITERATIONCOUNT`）
- 密文输出：小写十六进制字符串

## 验证

以 admin 用户为例（password=cb362cfeefbf3d8d, salt=RCGTeGiH）：

```java
PasswordUtil.encrypt("admin", "123456", "RCGTeGiH")  // → "cb362cfeefbf3d8d"
```

**Why:** 错误理解参数顺序会导致生成的密码哈希与数据库不匹配，用户无法登录。第一次尝试时把 username 和 password 参数搞反了（以为 encrypt(password, key, salt)），导致验证失败。

**How to apply:** 创建新用户时，使用 `PasswordUtil.encrypt(username, rawPassword, salt)` 生成加密密码存入 `sys_user.password` 字段。
