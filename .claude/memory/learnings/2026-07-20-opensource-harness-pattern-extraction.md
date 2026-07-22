# [2026-07-20] [方法论] 开源项目分析→Harness增强的四步法

## 触发条件
分析任何开源项目的代码结构和设计模式，评估是否能优化 JeecgBoot Harness。

## 四步法

1. **结构对标** — 列出双方能力矩阵，找出重叠和差距
2. **代码深读** — 读取核心源码文件（非 README），提取具体实现模式
3. **可行性过滤** — 区分"可落地"（改 Skill/Hook 文件）vs"受限"（需 SDK 支持）
4. **降级嵌入** — 每个增强加 `command -v orca` 守卫 + 文档化降级路径

## 本会话实例
分析 Strix（Python AI渗透测试工具）→ 提取 4 项可落地模式：
- D1: Skill 按类别子目录重组 (借鉴 `skills/{category}/{name}.md`)
- D2: 测试报告 JUnit XML + SARIF (借鉴 `report/sarif.py`)
- D3: 测试失败智能去重 (借鉴 `report/dedupe.py`)
- D4: 原子写入 + 状态快照 (借鉴 `report/writer.py` + `agents.py`)

过滤掉的模式: 运行时 skill 加载、Todo 工具、Think 工具 (受限于 Claude Code SDK)

## 关键教训
- 不要照搬代码，要提取**模式**而非**实现**（Strix 是 Python asyncio，JeecgBoot 是 Bash/Markdown）
- 优先提取"确定性"模式（去重键规则）而非"LLM依赖"模式（LLM去重）
- `find /repo -name "*.py" | sort` → 先看文件清单建立心智模型 → 再深读核心文件
## 关联
- ✅ 已覆盖: methodology-index.md
