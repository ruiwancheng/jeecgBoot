---
name: deploy-verify
description: 部署后编排式验证 — 并行冒烟+视觉+链路，输出质量报告+human-gate判定，/deploy-verify 命令的领域知识
version: 1.1.0
---

# deploy-verify — 部署后编排式验证

## 与已有规则/技能的关系

| 规则/技能 | 关系 |
|---------|------|
| `deploy-quality-gate.md` | 本技能是其 Step 4 "执行验证"的 Orca 实现版，共享 changeClassification 和判定规则 |
| `pre-commit-gate/SKILL.md` | **安全检查清单的权威实现**（P0/P1 逐项检查命令），本技能引用其检查清单 |
| `quality-gates.md` | P0/P1 门控定义（权威来源），两个技能均引用 |

> 安全检查清单统一来源：`pre-commit-gate/SKILL.md` → 步骤 2。deploy-verify 不重复定义清单。

区别：
- 规则版：串行 curl + Playwright headless
- Orca 版：并行多 agent + 真实浏览器截图 + human-gate 硬阻断

## 步骤 1：获取变更差集

```bash
# 首次部署
if [ ! -f .last-deploy-commit ]; then
  CHANGED_FILES=$(git diff HEAD~1 --name-only)
else
  CHANGED_FILES=$(git diff .last-deploy-commit..HEAD --name-only)
fi

echo "$CHANGED_FILES"
```

## 步骤 2：变更分级

按 `hermes/business-chains.json` 的 `changeClassification` 判定：

| 等级 | 匹配规则 | 验证动作 |
|:--:|------|------|
| skip | 纯文案/注释/样式 | 跳过验证（仅写报告） |
| light | Vue script / GET Controller / .data.ts | Agent 2 (视觉) |
| standard | POST/PUT/DELETE Controller / ≥3 文件 | Agent 1+2 (API+视觉) |
| full | Entity/Service/Mapper/SQL / 跨模块 | Agent 1+2+3 (全三路) |

> 判定规则：取变更文件的最高等级。

## 步骤 3：三路并行编排

### Agent 1：冒烟 API

任务 spec（通过 orchestration dispatch 发送）：

```markdown
## 冒烟 API 验证

运行 4 核心冒烟用例：
1. 登录: curl POST /sys/login → 验证返回 token
2. 变更模块列表: curl GET /mes/<模块>/selectPage → 验证返回数据
3. 全局配置: curl GET /sys/randomImage/check → 验证服务存活
4. 权限验证: curl 无 token 请求 → 验证返回 401/403

每个接口输出: PASS/FAIL + HTTP 状态码 + 关键数据
```

### Agent 2：视觉截图

调用 `/visual-check` 命令的逻辑。对变更涉及的每个模块，Orca browser 截图 + 基线对比。

### Agent 3：链路冒烟

仅在 full 级执行。调用 `/chain-test` 逻辑，检查变更的链路有对应 chain test 文件 → 运行；无 chain test → 仅执行 criticalPaths 的 curl 验证。

### 编排派发

```bash
# 并行创建任务
PYTHON=$(command -v python3 || command -v python || echo python)
$PYTHON --version >/dev/null 2>&1 || PYTHON=$(command -v python || echo python)  # WindowsApps stub 实测过滤
TASK_API=$(orca orchestration task-create --spec "<Agent 1 spec>" --task-title "deploy-smoke-api" --json | $PYTHON -c "import sys,json; print(json.load(sys.stdin)['result']['id'])")
TASK_VISUAL=$(orca orchestration task-create --spec "<Agent 2 spec>" --task-title "deploy-visual-check" --json | $PYTHON -c "import sys,json; print(json.load(sys.stdin)['result']['id'])")
TASK_CHAIN=$(orca orchestration task-create --spec "<Agent 3 spec>" --task-title "deploy-chain-smoke" --json | $PYTHON -c "import sys,json; print(json.load(sys.stdin)['result']['id'])")

# 并行 dispatch
orca orchestration dispatch --task $TASK_API --to <agent_terminal_1> --inject &
orca orchestration dispatch --task $TASK_VISUAL --to <agent_terminal_2> --inject &
orca orchestration dispatch --task $TASK_CHAIN --to <agent_terminal_3> --inject &

wait
```

### 等待全部完成

轮询 `orca orchestration dispatch-show --task <id>` 直到全部 `status=completed`。
超时：每个 agent 最长 10 分钟。

## 步骤 4：聚合判定

```
📊 部署质量报告 — YYYY-MM-DD HH:MM

变更概况:
├─ 链路: 采购链路 (3/4 模块)
├─ purchase/order → 新增审核按钮 + 权限码
├─ purchase/receipt → 新增审核按钮 + 权限码
└─ 变更等级: standard

自动验证:
├─ 🟢 冒烟 API   → 4/4 通过 (8s)
├─ 🟡 视觉截图   → 2/3 通过（采购订单页面的表头有变化，/visual-check gate 等待中）
└─ 🟢 链路冒烟   → 2/2 段全通 (45s)

判定：🟡 NEEDS WORK
```

| 条件 | 判定 |
|------|:--:|
| 三路全 PASS | 🟢 PASS — 部署成功 |
| API 全通 + 视觉/链路有异常 | 🟡 NEEDS WORK — 不阻塞但需关注 |
| API 有失败 或 链路断裂 | 🔴 BLOCKED — 需回滚或修复 |

## 步骤 5：human-gate + 更新 .last-deploy-commit

🟡 或 🔴 时发 `deploy-anomaly` 类型的 decision_gate。

PASS → 自动更新：
```bash
git rev-parse HEAD > .last-deploy-commit
```

## 降级

Orca 不可用 → 退化为 deploy-quality-gate.md 的串行模式（curl + Playwright headless）：
- API 冒烟：手动 curl 4 核心用例
- 视觉截图：Playwright screenshot
- 链路：手动 curl criticalPaths

此时不触发 human-gate（无 Orca 无法发 gate），结果以文本报告呈现。
