---
name: pre-commit-gate
description: 提交前可视化门控 — 安全扫描 + Orca 页面截图 + 基线对比，/pre-commit-gate 命令的领域知识
version: 1.0.0
---

# pre-commit-gate — 提交前可视化门控

## 与 pre-commit-check.sh 的关系

| | pre-commit-check.sh | /pre-commit-gate |
|---|---|---|
| 触发 | git commit 自动 | 用户手动 |
| 检查项 | SQL/DROP + TS 语法 + 受保护目录 | 安全 + 视觉 + 视觉门控 |
| 耗时 | < 5 秒 | 15-60 秒 |
| 阻断 | 有（exit 1） | 有（human-gate） |
| 视觉 | ❌ | ✅ |

> `pre-commit-check.sh` 是第一道防线（秒级、自动），本命令是第二道（深度、手动）。

## 步骤 1：变更分级

```bash
git diff --cached --name-only
```

按 `hermes/business-chains.json` 的 `changeClassification` 判定：
- skip → 直接输出 PASS，结束
- light 以上 → 继续

## 步骤 2：安全检查

通过 Orca orchestration dispatch 到独立 agent：

```markdown
## 安全检查任务

对以下暂存文件做安全扫描：

<git diff --cached --name-only 的输出>

检查项（P0 阻断）：
1. 新增 Controller 方法缺少 @RequiresPermissions
2. 移除了 @RequiresPermissions
3. SQL 字符串拼接（"SELECT ..." + var）
4. 硬编码密码/密钥
5. Mapper XML 使用 ${} 而非 #{}

检查项（P1 警告）：
6. 移除 @Transactional
7. 文件上传无类型校验
8. 查询无上限保护
9. 数据隔离用硬编码用户名

输出: 每项的 PASS/WARN/BLOCK + 具体文件行号
```

## 步骤 3：视觉门控

对暂存的 Vue 页面文件：

```bash
# 提取变更的 Vue 页面
VUE_PAGES=$(git diff --cached --name-only | grep -E 'src/views/.*\.vue$')
```

对每个 Vue 页面：
1. Orca browser 导航到对应页面
2. `orca screenshot --format png`
3. 与 `hermes/visual-baselines/<模块名>/baseline.png` 对比
4. 差异 > 0.1% → 标记

## 步骤 4：输出判定

```
🔒 提交前门控报告

  变更文件：<N> 个（<等级>）
  
  安全检查：
  ├─ 🟢 P0 阻断项 — 0 个
  ├─ 🟡 P1 警告项 — <N> 个
  │   └─ <文件>:<行> — <问题描述>
  └─ 🟢 通过项 — <M> 个

  视觉门控：
  ├─ 🟢 <页面1> — 与基线一致
  └─ 🟡 <页面2> — 0.3% 差异（采购订单列表表头）

  判定：🟡 WARN — 可以提交，但请注意 P1 警告项

  继续提交：git commit -m "..."
  强制提交（跳过 gate）：git commit --no-verify
```

| 条件 | 判定 |
|------|:--:|
| P0 = 0 + 视觉一致 | 🟢 PASS |
| P0 = 0 + 视觉有差异或 P1 有项 | 🟡 WARN |
| P0 > 0 | 🔴 BLOCKED |

## 步骤 5：human-gate

🔴 BLOCKED → 发 `commit-block` 类型的 decision_gate：

```
🛑 提交被阻断 — <N> 个 P0 问题

  P0 问题：
  ├─ <文件>:<行> — <问题>
  └─ ...

  选项：
  [1] 修复问题后重新 /pre-commit-gate
  [2] 跳过检查 — git commit --no-verify（记录到 hermes/logs/skip-audit.log）
  [3] 放弃本次提交

  等待判定中...
```

🟡 WARN → 不阻断，仅输出报告。用户自行判断。

## 降级

Orca 不可用 → 仅执行安全检查（curl + grep），视觉检查跳过，输出"⚠️ Orca 不可用，跳过视觉门控"。
