---
description: 自有命令 — 质量门控：提交前执行三层检查（现实核查+安全扫描+API验证），输出 PASS/NEEDS WORK/BLOCKED 判定
---

# /quality-gate

对当前变更执行三层质量门控检查，输出统一判定报告。

## 流程

### 1. 加载领域知识

使用 `quality-gate` 技能获取：
- 门控判定规则（基于 /verify 结果的 PASS/NEEDS WORK/BLOCKED 映射）
- JeecgBoot 安全专项检查清单
- API 验证阈值和报告模板

### 2. 图形预分析（可选增强）

如果 MCP code-review-graph 可用：
- 调用 `get_minimal_context_tool` 获取风险评分
- 调用 `detect_changes_tool` 获取变更影响范围
- 如果不可用：降级为 `git diff --name-only` 分析

### 3. 执行三层检查

**Step 1 — 现实核查：**
- **不重新收集证据**——检查 /verify 是否已运行并输出结果
- 如果 verify 未跑：强制要求先跑 /verify（判定 NEEDS WORK）
- 如果 verify 有 ✗ 项：按 quality-gate-criteria.md 的判定表评级
- 如果 verify 全部 ✓：本步骤 PASS

**Step 2 — 安全扫描：**
- 对 `git diff` 运行安全专项检查清单
- 检测：`@RequiresPermissions` 缺失/移除、SQL 拼接、硬编码密钥、`@Transactional` 移除
- 输出 P0/P1 发现数量和建议修复方案

**Step 3 — API 验证：**
- 对新增/修改的 Controller 端点执行 curl 验证（如果本地 8080 端口在侦听）
- 检查：HTTP 状态码、响应格式、鉴权拦截
- 如果本地后端不在运行，标记为"跳过（后端未启动）"并降低判定权重

### 4. 输出报告

按 `quality-gate` 技能中的报告模板输出，含：
- 总体判定（PASS / NEEDS WORK / BLOCKED）
- 每层的详细证据表格
- 下一步建议动作

### 5. 保存报告

将报告写入 `hermes/eagle-eye/reports/YYYY-MM-DD/quality-gate-<module>.md`

## 判定结果对应的后续动作

| 判定 | 含义 | 动作 |
|:--:|------|------|
| PASS | 三层全部通过 | 可以继续提交/部署 |
| NEEDS WORK | 有问题但不阻塞 | 建议修复后重新检查，可继续提交但部署需谨慎 |
| BLOCKED | 核心问题必须修复 | 禁止提交/部署，修复后重新运行本命令 |
