---
name: quality-gate
description: 质量门控 — 提交/部署前的三层质量检查（现实核查+安全扫描+API验证），输出 PASS/NEEDS WORK/BLOCKED 判定
version: 1.0.0
---

# 质量门控

基于 agency-agents 的 Reality Checker、Security Engineer、API Tester 三个代理角色，在提交和部署前执行三层质量检查。

## 铁律

- **默认不通过**：继承 Reality Checker 哲学——"默认判定 NEEDS WORK，需要铁证才给 PASS"
- **零问题检出即失败**：如果扫描结果为零个问题发现，视为扫描未生效，自动降级为 WARN
- **不猜测**：所有判定基于实际证据（git diff、测试输出、curl 响应），不做推断

## 三层检查

### Step 1：现实核查（Reality Checker）

检查变更是否真的生效，而不是"看起来应该没问题"。

**证据要求：**

| 变更类型 | 最低证据要求 |
|----------|------------|
| Java Controller 新增/修改 | curl 返回 HTTP 200 + `result.code == 200` |
| Service 方法修改 | 通过 Controller 间接 curl 验证 |
| Vue 组件修改 | Playwright 页面元素存在性检查 |
| SQL 迁移脚本 | 确认表/字段存在（DESCRIBE 或查询） |
| 配置文件修改 | 目标功能点 curl 验证 |

**自动失败触发器：**
- 输出"一切正常，未发现问题"但没有提供具体证据
- 用"应该""可能""看起来"等不确定词汇描述验证结果
- 声称"完美""零缺陷""100%通过"但无测试输出佐证
- 变更涉及 ≥5 个文件但只验证了 1 个文件

**质量评级：**
- **PASS**：所有变更类型均提供了对应的具体证据，且证据表明功能正常
- **NEEDS WORK**：部分变更缺少证据，或证据表明功能不完整
- **BLOCKED**：核心功能验证失败（HTTP 非 200、curl 报错、编译失败）

### Step 2：安全扫描（Security Engineer）

对变更做 STRIDE 威胁建模和安全检查。

**JeecgBoot 专项检查项：**

| 检查项 | 检测方法 | 严重度 |
|--------|---------|:--:|
| 新增 Controller 方法缺少 `@RequiresPermissions` | git diff 中 `+public.*Result` 行附近无 `@RequiresPermissions` | P0 |
| 移除 `@RequiresPermissions` 注解 | git diff 含 `-@RequiresPermissions` | P0 |
| 移除 `@Transactional` 注解 | git diff 含 `-@Transactional` | P1 |
| SQL 字符串拼接 | git diff 含 `+.*"SELECT.*" +` 或 `+.*"INSERT.*" +` | P0 |
| 硬编码密钥/密码 | git diff 含 `password\s*=\s*"[^"]+"` 或 `secret\s*=\s*"` | P0 |
| 新增 Mapper XML 无参数化 | git diff 含 `${` 而非 `#{` | P0 |
| 文件上传无类型校验 | 新增 `MultipartFile` 参数但无 `getContentType` 检查 | P1 |

**STRIDE 威胁模型速查（JeecgBoot 映射）：**

| 威胁 | JeecgBoot 对应 | 检查点 |
|------|---------------|--------|
| Spoofing（仿冒） | Shiro 认证绕过 | `@RequiresPermissions` 存在 |
| Tampering（篡改） | 请求参数未校验 | Controller 参数 `@Valid` / Service 非空检查 |
| Repudiation（抵赖） | 操作无日志 | `@Log` 注解 |
| Info Disclosure（泄露） | 脱敏未做 | `@Dict` 脱敏 / 敏感字段 `@JsonIgnore` |
| DoS（拒绝服务） | 无上限查询 | `queryAll` 上限、导出上限 |
| Elevation（提权） | 角色判断用硬编码 | `hasRole("mes_admin")` 而非 `"admin".equals(username)` |

### Step 3：API 验证（API Tester）

验证 API 接口的功能正确性、性能和契约合规。

**最低验证要求（每个新增/修改的 Controller 方法）：**

| 测试维度 | 要求 | 阈值 |
|----------|------|:--:|
| 功能正确 | 1 次正常请求 + 1 次边界请求 | HTTP 200 |
| 鉴权 | 1 次无 Token 请求 | HTTP 401/403 |
| 响应格式 | 检查 `result.code` `result.success` `result.message` | code=200, success=true |
| 响应时间 | curl `-w` 输出 `time_total` | < 2000ms（非性能环境） |

**证据格式要求：**
```bash
curl -s -w "\nHTTP:%{http_code} Time:%{time_total}s" \
  -H "X-Access-Token: $TOKEN" \
  "http://localhost:8080/jeecg-boot/<endpoint>" | tail -5
```

## 判定逻辑

```
现实核查 PASS + 安全扫描 0 个 P0 + API 验证 PASS → 总体 PASS
现实核查 NEEDS WORK → 总体 NEEDS WORK
安全扫描有 P0 → 总体 BLOCKED
API 验证失败 → 总体 NEEDS WORK（非性能环境）或 BLOCKED（生产部署前）
```

## 报告模板

```markdown
# 质量门控报告：<模块名>
**时间：** YYYY-MM-DD HH:MM
**变更：** <简要描述>
**判定：** PASS / NEEDS WORK / BLOCKED

## 1. 现实核查
| 变更文件 | 检查项 | 证据 | 结果 |
|----------|--------|------|:--:|
| xxx.java | curl 验证 | HTTP 200, code=200 | ✅ |
| xxx.vue | 页面渲染 | 元素可见 | ✅ |

评级：PASS / NEEDS WORK / BLOCKED

## 2. 安全扫描
| 检查项 | 结果 | 严重度 |
|--------|:--:|:--:|
| @RequiresPermissions 完整 | ✅ | - |

P0 发现：N 个 | P1 发现：N 个

## 3. API 验证
| 端点 | 功能 | 鉴权 | 响应格式 | 耗时 | 结果 |
|------|:--:|:--:|:--:|:--:|:--:|
| GET /xxx | ✅ | ✅ | ✅ | 45ms | ✅ |

通过率：N/N

## 总体判定：PASS / NEEDS WORK / BLOCKED
下一步：<建议动作>
```

## 对接 agency-agents 代理

本技能集成以下三个 agency-agents 代理的方法论：

- `~/.claude/agents/testing-reality-checker.md` — 现实核查哲学、自动失败触发器、质量评级
- `~/.claude/agents/engineering-security-engineer.md` — STRIDE 威胁模型、安全检查清单
- `~/.claude/agents/testing-api-tester.md` — API 四维测试（功能+鉴权+格式+性能）

## 相关技能

- `verify` — 变更自验证（curl 证据收集）
- `review` — 7 维代码审查（安全维度增强）
- `test-api` — API 测试执行
- `harness-check` — Harness 健康评分（本技能注册后需更新文件清单）

## 相关规则

- `quality-gate-criteria.md` — 门控通过标准（证据要求、自动失败触发器、质量评级）
- `security-gate-checklist.md` — 安全专项检查清单（P0/P1 规则+STRIDE 映射）
- `workflow.md` — 开发流程中的 /verify 和分级测试
