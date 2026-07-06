# KA 定制场景下 AI 开发安全管控方案

**状态：草案，待完善。** 整体方案尚未确定，以下是当前思路记录。

---

## 背景

- KA 定制场景：在 JeecgBoot ERP 已有功能基础上深度定制
- 核心工具：`jeecg-codegen` 生成代码 → 与客户核对 → 快速迭代 → 交付
- 用户：业务人员（售前、PM），不具备代码判断能力
- AI 环境：Claude Code + DeepSeek
- 风险：AI 越界修改核心框架代码，导致平台异常

---

## 方案演进

### 方案A：CLAUDE.md 边界声明 + Git 保护（当前浅层方案）

在 CLAUDE.md 里用自然语言声明 AI 开发边界，配合 Git 分支保护和 PR 审核。

**优点**：立即可做，零成本
**缺点**：依赖 AI 模型自觉遵守，DeepSeek 指令遵循能力有限，不可靠

详情见之前讨论的三层防线：CLAUDE.md 边界 → 迭代工作流 → Git 保护

### 方案B：Harness 工程体系（讨论中的目标架构）

```
云端（GitHub 仓库）
  ├── 需求文档 + 规范
  ├── Harness 工程文件（Skills / Rules / Commands / Hooks）
  ├── 接收本地提交的产物（页面 / 接口 / 实体）
  └── GitHub Actions 集成验证
              ↓ git pull / push
本地（业务人员机器）
  ├── Claude Code + DeepSeek + Harness 文件
  │   └── 用 jeecg-codegen 生成定制代码
  ├── Hermes（Kimi-Code-2.7）代码审查 + 测试验证
  └── 只提交最终产物到云端
```

**四个核心层：**

| 层 | 工具 | 职责 |
|----|------|------|
| Harness 工程文件 | Skills/Rules/Commands/Hooks | 从云端下发行为规则，业务人员 git pull 即用 |
| AI 辅助开发 | Claude Code + DeepSeek | 在 Harness 约束下，用 jeecg-codegen 生成定制代码 |
| 本地代码审查 | Hermes(Kimi-Code-2.7) | 独立审查 AI 产出的 diff，检查越界和规范合规 |
| 云端集成验证 | GitHub Actions | 编译检查、文件范围检查、自动合并/通知 |

**待解决问题：**
- [ ] DeepSeek 模型对 CLAUDE.md 规则的遵循度如何？需要实测
- [ ] Hermes(Kimi-Code-2.7) 的代码审查能力是否覆盖 JeecgBoot 的规范（update-begin/end 标记等）？
- [ ] Harness 文件如何版本管理和下发？放在 GitHub 仓库的 `.claude/` 目录是否足够？
- [ ] 业务人员的本地环境配置成本（装 Claude Code、pnpm、JDK 等）
- [ ] 如果 AI 产出的代码质量差，Hermes 拦截后业务人员不会修怎么办？

---

## 待评估

整个方案还缺关键环节的验证，需要先做小范围实测：
1. 用 DeepSeek 跑一遍 `jeecg-codegen` 生成代码，看看指令遵循度
2. 在 CLAUDE.md 加边界规则后，尝试诱导 AI 越界，看它是否遵守
3. 评估 Hermes 对 Java/Vue 代码的审查效果

---

## 当前结论

- 短期先用方案A（CLAUDE.md + Git 保护），成本最低
- 方案B 是目标方向，但需要先完成上述待解决问题和实测验证
- Harness 文件和 Hooks 是核心控制点，不依赖 AI 自觉
