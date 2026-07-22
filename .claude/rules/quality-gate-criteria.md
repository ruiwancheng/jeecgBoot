---
name: quality-gate-criteria
description: 质量门控通过标准——变更证据要求、自动失败触发器和质量评级定义
glob: "**/*"
version: 1.0.0
---

# 质量门控通过标准

基于 agency-agents Reality Checker 的"默认不通过"哲学。

## 核心原则

- **默认不通过**：没有证据的变更是未验证的变更
- **零发现即失败**：扫描结果为零个问题 = 扫描未生效，自动降级为 WARN
- **证据驱动**：所有判定基于实际输出（curl 响应、git diff、测试结果），不做推断

## 证据要求

**/quality-gate 不重复收集证据**——它检查 /verify 是否已通过并追加安全扫描。
分工：

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

**注意：** quality-gate 自身只追加安全扫描（见 `security-gate-checklist.md`）。curl 验证和编译检查由 `/verify` 负责，不在 quality-gate 中重复执行。

## 自动失败触发器

以下任一条件满足时，自动判定为 NEEDS WORK：

1. **空洞结论**：输出"一切正常，未发现问题"但无具体证据条目
2. **模糊措辞**：用"应该""可能""看起来""似乎"等词描述验证结果
3. **虚假完美**：声称"完美""零缺陷""100%通过"但无测试输出佐证
4. **证据不足**：变更涉及 ≥5 个文件但只验证了 1 个文件
5. **跳过验证**：本地后端在运行（8080 端口在侦听）但未执行 curl 验证

以下条件满足时，自动判定为 BLOCKED：

1. **编译失败**：`mvn compile` 报错
2. **核心端点 404/500**：curl 返回 HTTP 404 或 500
3. **响应格式异常**：`result.code != 200` 或 `result.success != true`

## 质量评级

| 评级 | 条件 | 允许操作 |
|:--:|------|:--:|
| PASS | 所有变更类型有对应证据 + 安全扫描 0 个 P0 + API 验证通过 | 提交 + 部署 |
| NEEDS WORK | 部分变更缺证据 / 安全扫描有 P1 / API 验证非关键失败 | 可提交，部署需谨慎 |
| BLOCKED | 编译失败 / 核心端点不可用 / 安全扫描有 P0 | 禁止提交，必须先修复 |

## 关联规则

- `security-gate-checklist.md` — 安全专项检查清单
- `workflow.md` — 开发流程中的 /verify 和分级测试
