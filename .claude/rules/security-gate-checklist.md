---
name: security-gate-checklist
description: 安全门控检查清单——提交时自动检测权限注解、SQL注入、硬编码密钥等安全问题
glob: "**/*.java"
version: 1.0.0
---

# 安全门控检查清单

基于 agency-agents Security Engineer 的 STRIDE 威胁模型，适配 JeecgBoot 技术栈。

## 提交时自动检查（pre-commit hook 执行）

### P0 级（检测到即阻断提交）

| # | 检查项 | 检测方法 |
|---|--------|---------|
| 1 | 新增 Controller 方法缺少 `@RequiresPermissions` | `git diff` 中新增的 `public.*Result` 方法上方无 `@RequiresPermissions` |
| 2 | 移除了 `@RequiresPermissions` 注解 | `git diff` 含 `-    @RequiresPermissions` |
| 3 | SQL 字符串拼接 | `git diff` 含 `+.*"SELECT.*" +` 或 `+.*"INSERT.*VALUES.*" +` |
| 4 | 硬编码密码/密钥 | `git diff` 含 `password\s*=\s*"[^"]{3,}"` 或 `secret\s*=\s*"[^"]{3,}"` |
| 5 | Mapper XML 使用 `${}` 而非 `#{}` | `git diff` 中 `.xml` 文件含 `${` |

### P1 级（检测到打印警告，允许提交）

| # | 检查项 | 检测方法 |
|---|--------|---------|
| 6 | 移除了 `@Transactional` 注解 | `git diff` 含 `-    @Transactional` |
| 7 | 文件上传无类型校验 | 新增 `MultipartFile` 参数方法中无 `getContentType()` 调用 |
| 8 | 查询无上限保护 | 新增 `queryAll` 类方法无 `limit` 或 `page` 参数 |
| 9 | 数据隔离用硬编码用户名 | 新增 `"admin".equals(username)` 而非 `hasRole("mes_admin")` |

## STRIDE 威胁模型 — JeecgBoot 映射

| 威胁类型 | JeecgBoot 防护机制 | 检查点 |
|----------|-------------------|--------|
| Spoofing（仿冒） | Shiro + JWT 认证 | `@RequiresPermissions` 完整 |
| Tampering（篡改） | `@Valid` 参数校验 | Controller 参数有 `@Valid` + Service 非空检查 |
| Repudiation（抵赖） | `@Log` 操作日志 | 写操作（POST/PUT/DELETE）有 `@Log` |
| Info Disclosure（泄露） | 脱敏 + `@JsonIgnore` | 敏感字段有脱敏注解或 JSON 忽略 |
| DoS（拒绝服务） | 上限保护 | `queryAll` 有上限（1000），导出有上限 |
| Elevation（提权） | 角色判断 | 用 `hasRole()` 而非硬编码用户名 |

## 不与现有规则重复

以下检查已由其他规则/钩子覆盖，本规则不重复：
- 受保护目录写操作 → `pre-write-check.sh` + `file-scope.md`
- SQL DROP/TRUNCATE 检测 → `pre-commit-check.sh`
- 前端 TypeScript 语法 → `pre-commit-check.sh`
- `@Transactional` 移除检测 → `pre-commit-check.sh`（本规则仅记录为 P1，实际检测逻辑在 hook 中）

## 相关文件

- `hooks/pre-commit-check.sh` — 提交前钩子（轻量静态检查在此实现）
- `skills/quality-gate/SKILL.md` — 质量门控技能（完整安全扫描流程）
