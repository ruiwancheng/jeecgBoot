---
description: 自有命令 — 制定实施计划：查模块、锚定模式、列文件
---

# /plan <任务描述>

需求确认后制定实施计划。

**铁律：禁止"TODO"、"TBD"、"适当处理"。每步必须指定具体文件和操作。**

## 流程

### 0. 读取 brainstorm 产物（2026-08-09 新增）

查找最新 spec 文件（30 分钟内）：

```bash
# 确保目录存在 + 获取最新 spec
mkdir -p .claude/specs
SPEC=$(find .claude/specs -name "*.md" -not -name ".gitkeep" -mmin -30 2>/dev/null | sort -r | head -1)
if [ -n "$SPEC" ]; then
  echo "📋 检测到 /brainstorm 产物（$(stat -f %Sm -t '%Y-%m-%d %H:%M' "$SPEC" 2>/dev/null || stat -c %y "$SPEC" 2>/dev/null | cut -d. -f1)），自动复用..."
  cat "$SPEC"
fi
```

**判定逻辑**：
- **存在且新鲜**（`-mmin -30`）→ 读取验收标准作为 plan 输入
- **过期**（≥30 分钟）→ 提示 `⚠️ /brainstorm 产物已过期，是否重新确认需求？`
- **不存在** → 正常继续，不阻塞

> 此步骤为**推荐**而非强制。无 spec 文件时 plan 仍可正常执行。

### 1. 加载领域知识
使用 `plan` 技能获取：features.json 结构说明、标品概念、三种策略判断标准（纯新增/覆盖标品/加字段）。

### 2. 查模块
查 features.json 找到相关标品模块位置。

### 3. 模式锚定
读标品类似代码，引用具体文件和行号作为参照。

### 4. 判断策略
按技能中的三种策略标准判断。

### 4.5. orca-review（强制，仅文案/注释/样式免评）

无论 delegate 还是直接模式，**任何代码改动（Java/Vue/TS/SQL）都必须先 orca-review**：

| 模式 | 代码改动（Java/Vue/TS/SQL） | 纯文案/注释/样式 |
|------|:--:|:--:|
| delegate | 强制评审（worker preamble 自动执行，协调者派 Claude 评审终端） | 免评 |
| 直接 | **强制评审（主会话必须调用 `orca-review` skill）** | 免评 |

> **直接模式+代码改动 ≠ 免评。** 这是本次排查发现的盲区——原规则"直接模式（仅限文案/注释/样式）：免评"未覆盖直接模式做代码改动的场景，导致 orca-review 被系统性跳过。

如果 Orca 不可用，标注"外部评审未完成"并直接展示草案给用户确认。**禁止手工替代——自己审自己等于没审。**

### 5. 输出计划
文件清单 + 任务步骤（含具体代码和验证命令）+ 范围外 + 风险。

### 5.5 测试三件套（新模块/新功能必填，testing.md v2）
计划涉及新模块或新业务流时，输出必须含：
1. **API 业务流测试**：`harness/tests/<项目>/<模块>.test.js`（创建→审核→状态→副作用）
2. **E2E 完整业务流**：`harness/e2e/<项目>/<模块>.spec.ts`（创建→编辑→审核→结果页）
3. **关键 payload 抓包保真**：标明哪些 payload 需从 DevTools 复制
4. **5 断言锚点**：创建/状态流转/数据传递/显示值(裸ID判负)/清理，逐项列出本模块的具体断言
5. **关键路径注册**：`hermes/business-chains.json` 对应链路补充 `criticalPaths`（只增不减）

### 6. 用户确认后执行

### 6.5. 写入 plan 缓存（供 /decompose 自动复用）

将本次 plan 的完整输出写入 `.claude/.last-plan.json`：

```bash
mkdir -p .claude
TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date -Iseconds 2>/dev/null || date)
echo "{
  \"task\": \"<任务描述>\",
  \"plan_output\": \"<完整 plan 内容（文件清单+步骤+风险+测试三件套）>\",
  \"timestamp\": \"$TIMESTAMP\"
}" > .claude/.last-plan.json
```

**用途：** 后续 `/decompose` 会自动检测此缓存，避免用户重复描述任务。

**失效条件：** 缓存超过 30 分钟视为过期（`/decompose` 会提示重新描述）。

> `.claude/.last-plan.json` 已在根 `.gitignore` 中忽略。
