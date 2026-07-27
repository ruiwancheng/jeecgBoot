# JeecgBoot Harness 开发管道

> 最后更新：2026-07-28
> 命令/技能的依赖关系和执行顺序

## 开发流程（从 idea 到生产）

```
                         开发阶段                          验证阶段                      部署阶段
                   ┌─────────────────────┐    ┌──────────────────────────┐    ┌────────────────┐
                   │                     │    │                          │    │                │
  需求         /brainstorm    /plan    写代码    /verify    /pre-commit-gate    git commit      /deploy-verify
  ──●──────────●─────────────●─────────●───────●───────────●────────────────●──────────────────●──────▶
   │           │              │         │       │           │                │                  │
   │           │              │         │       │           │                │                  │
   │     orca-review    orca-review     │  /visual-check   │           /test-loop          /chain-test
   │     (第二意见)     (方案评审)       │  (页面截图)     │           (自动修复)          (链路验证)
   │                                    │                 │
   │                                    │           ┌─────┴──────┐
   │                                    │           │ human-gate │ ← 需要人判断的节点
   │                                    │           │ (硬阻断)    │
   │                                    │           └────────────┘
```

## 命令矩阵

| 阶段 | 命令 | 触发时机 | 输入 | 输出 |
|------|------|---------|------|------|
| 需求 | `/brainstorm` | 新需求到来 | 用户描述 | 验收标准 |
| 方案 | `/plan` | brainstorm 完成 | 验收标准 | 文件清单 + 步骤 |
| 评审 | `orca-review` | plan 完成 | 草案 | 评审意见 |
| 实现 | — | 人工 | plan | 代码 |
| 自验 | `/verify` | 代码写完后 | git diff | curl/截图证据 |
| 页面 | `/visual-check` | verify 后/部署前 | 模块名 | 截图对比 |
| 门控 | `/pre-commit-gate` | git commit 前 | git diff --cached | PASS/WARN/BLOCKED |
| 提交 | `git commit` | gate 通过 | — | commit |
| 修复 | `/test-loop` | 测试失败后 | 失败日志 | 修复 diff |
| 链路 | `/chain-test` | ≥2 模块变更 | 链路名 | 通过/断裂 |
| 部署 | `/deploy-verify` | 部署完成后 | .last-deploy-commit | PASS/NEEDS WORK/BLOCKED |

## 人工介入点

```
/brainstorm ──→ /plan ──→ orca-review ──→ 代码 ──→ /verify
                                                     │
                                          ┌──────────┘
                                          ▼
                                   /visual-check
                                          │
                                   [发现 UI 差异?]
                                    ├─ 无 → 继续
                                    └─ 有 → 🛑 human-gate (visual-diff)

                                   /pre-commit-gate
                                          │
                                   [P0 阻断?]
                                    ├─ 无 → git commit
                                    └─ 有 → 🛑 human-gate (commit-block)

                                   /test-loop
                                          │
                                   [修复成功?]
                                    ├─ 是 → 🛑 human-gate (auto-fix)
                                    └─ 否 → 3 轮后人工

                                   /chain-test
                                          │
                                   [链路断裂?]
                                    ├─ 无 → 继续
                                    └─ 有 → 🛑 human-gate (chain-break)

                                   /deploy-verify
                                          │
                                   [异常?]
                                    ├─ 无 → PASS
                                    └─ 有 → 🛑 human-gate (deploy-anomaly)
```

## Skills 引用关系

```
human-gate ← 被 5 个命令共用
  ├── /visual-check   → visual-diff gate
  ├── /test-loop      → auto-fix gate
  ├── /chain-test     → chain-break gate
  ├── /deploy-verify  → deploy-anomaly gate
  └── /pre-commit-gate → commit-block gate

local-dev ← 被 2 个命令共用
  ├── /start
  └── /client-start

onboard ← 被 client-start 引用（工具安装矩阵）
client-setup ← 被 client-start 引用（架构说明）
_os-detect.sh ← 被多个技能引用（OS 检测）
```

## 安全检查清单统一来源

| 规则/技能 | 包含什么 | 引用链 |
|---------|------|------|
| `quality-gates.md` | P0/P1 安全门控定义（权威来源） | ← pre-commit-gate 技能引用 |
| `pre-commit-gate/SKILL.md` | 逐项检查命令（实现细节） | ← deploy-verify 交叉引用 |
| `deploy-verify/SKILL.md` | 三路并行编排（不重复检查清单） | → 引用 pre-commit-gate |
| `pre-commit-check.sh` | 秒级阻断（hook 实现） | → 与 pre-commit-gate 互补 |
