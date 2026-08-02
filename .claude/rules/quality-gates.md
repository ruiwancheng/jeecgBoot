---
name: quality-gates
description: 质量门控全规则——通过标准+安全清单+严重度分级+自动升级，PASS/NEEDS WORK/BLOCKED 判定
glob: "**/*"
version: 1.1.0
---

# 质量门控

> 合并自 `quality-gate-criteria.md` + `security-gate-checklist.md` + `quality-escalation.md`（2026-07-24 token 降本）

## 一、通过标准

基于 agency-agents Reality Checker 的"默认不通过"哲学。

- **默认不通过**：没有证据的变更是未验证的变更
- **零发现即失败**：扫描结果为零个问题 = 扫描未生效，自动降级为 WARN
- **证据驱动**：所有判定基于实际输出（curl 响应、git diff、测试结果），不做推断

### 证据分工

| 步骤 | 负责命令 | 说明 |
|------|---------|------|
| 逐项收集证据（curl/编译/页面） | `/verify` | 开发中快速自检 |
| 检查 verify 结果 + 安全扫描 + 综合判定 | `/quality-gate` | 提交前最终判定 |

### 现实核查判定（基于 /verify 结果）

| verify 结果 | quality-gate 判定 |
|:--|:--|
| 全部 ✓ | PASS |
| 部分 ✗（非核心端点） | NEEDS WORK |
| 核心端点 ✗ | BLOCKED |
| 未跑 verify | NEEDS WORK（强制要求先跑 /verify） |

### 自动失败触发器

**NEEDS WORK**（任一满足）：
1. 空洞结论：输出"一切正常，未发现问题"但无具体证据条目
2. 模糊措辞：用"应该""可能""看起来""似乎"等词描述验证结果
3. 虚假完美：声称"完美""零缺陷""100%通过"但无测试输出佐证
4. 证据不足：变更涉及 ≥5 个文件但只验证了 1 个文件
5. 跳过验证：本地后端在运行（8080 端口在侦听）但未执行 curl 验证

**BLOCKED**（任一满足）：
1. 编译失败：`mvn compile` 报错
2. 核心端点 404/500：curl 返回 HTTP 404 或 500
3. 响应格式异常：`result.code != 200` 或 `result.success != true`

### 质量评级

| 评级 | 条件 | 允许操作 |
|:--:|------|:--:|
| PASS | 所有变更类型有对应证据 + 安全扫描 0 个 P0 + API 验证通过 | 提交 + 部署 |
| NEEDS WORK | 部分变更缺证据 / 安全扫描有 P1 / API 验证非关键失败 | 可提交，部署需谨慎 |
| BLOCKED | 编译失败 / 核心端点不可用 / 安全扫描有 P0 / 审计 P0（正式模式） | 禁止提交，必须先修复 |

---

## 二、安全门控检查清单

基于 STRIDE 威胁模型，适配 JeecgBoot 技术栈。

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

### STRIDE 威胁模型 — JeecgBoot 映射

| 威胁类型 | JeecgBoot 防护机制 | 检查点 |
|----------|-------------------|--------|
| Spoofing（仿冒） | Shiro + JWT 认证 | `@RequiresPermissions` 完整 |
| Tampering（篡改） | `@Valid` 参数校验 | Controller 参数有 `@Valid` + Service 非空检查 |
| Repudiation（抵赖） | `@Log` 操作日志 | 写操作（POST/PUT/DELETE）有 `@Log` |
| Info Disclosure（泄露） | 脱敏 + `@JsonIgnore` | 敏感字段有脱敏注解或 JSON 忽略 |
| DoS（拒绝服务） | 上限保护 | `queryAll` 有上限（1000），导出有上限 |
| Elevation（提权） | 角色判断 | 用 `hasRole()` 而非硬编码用户名 |

> 以下检查已由其他规则/钩子覆盖：受保护目录写操作（`pre-write-check.sh` + `boundary.md`）、SQL DROP/TRUNCATE（`pre-commit-check.sh`）、前端 TS 语法（`pre-commit-check.sh`）

---

## 三、缺陷严重度与自动升级

| 等级 | 定义 | review 对应 | test-all 对应 |
|:--:|------|:--:|:--:|
| **P0** | 阻断 — 核心功能不可用、数据安全风险、编译失败 | CRITICAL | P0 |
| **P1** | 高危 — 重要功能异常、性能严重退化、安全漏洞 | HIGH | P1 |
| **P2** | 一般 — 次要功能异常、UI 问题、性能轻微退化 | MEDIUM | P2 |
| **P3** | 建议 — 优化建议、代码风格、文档补充 | LOW | — |

### 自动升级规则

| 条件 | 动作 |
|------|------|
| P1 缺陷 > 7 天未修复 | 自动升级为 P0 |
| P2 缺陷 > 30 天未修复 | 自动升级为 P1 |
| 同一模块累计 ≥ 3 个 P0 | 标记红色模块，强制全面审计 |
| 连续 2 个周期趋势下降 | 其中 P1→P0 |
| 安全扫描发现 CRITICAL | 直接 BLOCKED |

### 门控判定映射

| quality-gate | 对应升级 |
|:--|------|
| PASS | 无升级 |
| NEEDS WORK | P1 → 7 天倒计时启动 |
| BLOCKED | 对应 P0，阻断操作 |

---

## 关联规则

- `deploy-quality-gate.md` — 部署后自动质量门控
- `workflow.md` — 开发流程（分级测试 + 防失忆触发）

## 协调者代发机制（2026-08-02 沉淀）

> 适用于 /delegate 派工场景：当 pi 工人完成所有工作但忘了发 worker_done 时，协调者（Claude Code）可手动代发。

### 代发判定条件（同时满足）

1. 产物文件已确认存在（任务范围路径下）
2. pi 工人 5+ 分钟未发 worker_done（polling 检测确认）
3. 协调者（Claude Code 终端）可访问终端 buffer，能从 buffer 提取任务结果

### 代发命令模板

```bash
orca orchestration send \
  --to <协调者自己或主终端> \
  --type worker_done \
  --subject "[<任务名>] 协调者代发·产物到位" \
  --body "工人未发 worker_done，但产物已确认存在：<path1, path2>
关键结果：<从产物提取>
phase: completed"
```

### 与正常 worker_done 的区别

| 维度 | 工人发 | 协调者代发 |
|---|---|---|
| from_handle | pi 工人 handle | Claude Code handle |
| 适用场景 | 工人按 v4.0 preamble 正常发 | 工人忘了发但产物到位 |
| 内容来源 | 工人从自己工作结果提取 | 协调者从终端 buffer + 产物提取 |
| 可靠性 | 高（工人报告） | 中（需协调者判定产物完整性） |

### polling 检测兼容性

代发的 worker_done 仍能被 polling 检测到，但**不能只信 `from_handle == 工人 handle`**：
- 必须同时检查 `to_handle == 协调者 handle` + 关键词匹配
- 完整逻辑见 `.claude/skills/delegate/SKILL.md`（已在 2026-08-02 修复 polling bug）

**详细案例**：见 `.claude/memory/learnings/2026-08-02-delegate-worker-done-must-emit-hard-rule.md`（v4 观察）。
