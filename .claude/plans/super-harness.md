# Super Harness：KA 定制场景 AI 开发安全管控方案

**状态**：待评审
**版本**：v1.2
**日期**：2026-07-04

**v1.1 更新**：第3层从"物理隔离"修正为"写隔离 + 读开放"——AI 可以读取全项目代码用于参考和学习，但写操作只能落在客户专属目录。
**v1.2 更新**：第3层升级为"基座 + 覆盖层"策略。
**v1.3 更新**：整合 MR 项目 Harness 经验——规则文件化、features.json、自改进机制。

---

## 一、背景

### 1.1 业务场景

JeecgBoot ERP 平台的 KA（大客户）定制开发。每个客户需要基于标准 ERP 模块做深度功能定制，交付周期紧，需求迭代频繁。

### 1.2 工作模式

- 业务人员（售前/项目经理）每人独立负责一个 KA 客户
- 使用 Claude Code + DeepSeek 做 AI 辅助开发
- 核心工具：`jeecg-codegen` 技能（自然语言描述需求 → 自动生成前后端代码）
- 工作流：需求沟通 → 生成代码 → 与客户核对 → 快速修改 → 反复迭代 → 交付

### 1.3 核心风险

业务人员不具备代码判断能力，AI 可能越界修改平台核心框架代码，导致：

| 风险等级 | 后果 |
|----------|------|
| 致命 | 修改核心框架代码（`jeecg-boot-base-core/`、`jeecg-module-system/`），导致登录、权限、菜单等基础设施崩溃 |
| 致命 | 误改其他客户的定制代码，导致数据错乱或功能异常 |
| 严重 | 生成的代码质量不合格，客户验收时大量返工 |

---

## 二、方案概述

Super Harness 是一套 AI 行为管控工程体系，通过三层防线确保 AI 辅助开发的安全性和可控性。

核心理念：**AI 可以自由阅读项目全部代码来学习参考，但只能往客户专属目录写入代码。用 Hooks 拦截写操作，用 CLAUDE.md 引导行为。**

```
┌─────────────────────────────────────────────────┐
│                  云端 GitHub 仓库                 │
│  Harness 工程文件（团队统一维护）                   │
│  ├── CLAUDE.md（AI 行为规则）                    │
│  ├── Commands（标准化操作流程）                    │
│  ├── Skills（jeecg-codegen 等工具封装）           │
│  ├── Hooks（写操作路径拦截 + 提交检查）            │
│  └── 客户模块脚手架模板                           │
├─────────────────────────────────────────────────┤
│                  业务人员本地                      │
│  ├── git pull 同步 Harness 文件                   │
│  ├── Claude Code + DeepSeek 开发                  │
│  │   ├── 读：全项目可读（参考框架和已有代码）       │
│  │   ├── 写：只允许客户专属目录（Hook拦截）         │
│  │   └── CLAUDE.md 引导去哪读、往哪写              │
│  ├── Hermes(Kimi-Code-2.7) 代码审查               │
│  └── git push 提交客户模块产物                     │
├─────────────────────────────────────────────────┤
│                  云端集成验证                      │
│  ├── GitHub Actions 自动编译检查                  │
│  ├── 文件范围检查（禁止核心模块变更）               │
│  └── PR 审核 + 合并                              │
└─────────────────────────────────────────────────┘
```

---

## 三、三层防线详解

### 第3层（地基）：基座 + 覆盖层 — 共享是默认，覆盖是例外

**核心思路**：标品代码所有客户共享，默认不改。必须改时，客户模块里覆盖标品的特定部分（Bean/路由/页面），并在 `.manifest.yml` 里记录下来。不是"每个客户复制一份标品"，而是"客户模块覆盖标品的特定点"。

**定制策略分层**：

| 定制类型 | 做法 | 标品升级影响 |
|----------|------|-------------|
| 新增：加按钮、加页面、加接口 | 客户目录下新建文件 | 无影响 |
| 新增：加数据库字段 | 客户目录下建扩展表，1:1 关联标品表主键 | 标品表结构变化时检查 |
| 覆盖：改业务逻辑 | 客户模块 Spring Bean 替换标品 Bean（`@Primary`） | 标品逻辑改了要对照 |
| 覆盖：替换整个页面 | 客户目录下同名路由覆盖标品路由 | 标品页面改了要对照 |
| 覆盖：改表结构 | 扩展表加字段，不碰标品表 | 无影响 |
| 覆盖：改核心流程 | 客户自实现替换 Bean，记录在 `.manifest.yml` | 必须人工对照 |

**目录结构**：

```
jeecg-boot/
├── jeecg-boot-base-core/          ← 共享只读
├── jeecg-module-system/           ← 共享只读
├── jeecg-boot-module/
│   ├── order/                     ← 标品订单模块（共享只读）
│   ├── customer-a-haier/          ← 海尔定制（可写）
│   │   ├── entity/                ← 扩展表实体（新表，非复制）
│   │   ├── controller/            ← 客户专属新接口
│   │   ├── service/               ← 继承或替换标品 Service
│   │   └── .manifest.yml          ← 覆盖清单
│   ├── customer-b-midea/          ← 美的定制（可写）
│   └── customer-c-gree/           ← 格力定制（可写）
└── jeecgboot-vue3/src/views/
    ├── order/                     ← 标品订单页面（共享只读）
    ├── customer/a-haier/          ← 海尔前端（可写，含覆盖路由）
    ├── customer/b-midea/          ← 美的前端（可写）
    └── system/                    ← 共享只读
```

**标品版本锚定 `.manifest.yml`**：每个客户模块记录基于哪个标品版本定制、覆盖了哪些文件。

```yaml
# customer-a-haier/.manifest.yml
customer: 海尔
base_version: 3.9.2
overrides:
  - type: bean
    original: org.jeecg.modules.order.service.OrderServiceImpl
    replacement: org.jeecg.modules.customer.haier.service.HaierOrderServiceImpl
    reason: 替换巡仓规则逻辑
  - type: route
    original: /order/list
    replacement: /customer-a/order/list
    reason: 替换订单列表页，增加定制筛选
  - type: page
    original: src/views/order/OrderList.vue
    replacement: src/views/customer/a-haier/order/OrderList.vue
    reason: 替换标品订单列表页
additions:
  - table: c_haier_order_ext（订单扩展表，关联标品 order 表）
  - controller: HaierOrderController
  - entity: HaierOrderExt
```

**标品升级流程**：标品发新版本 → 扫描所有客户的 `.manifest.yml` → 对每个被覆盖的文件，人工或 AI 判断是否受标品改动影响 → 受影响则手动同步。

**效果**：共享是默认，覆盖是例外。标品升级能快速定位影响范围。AI 知道哪些地方可以直接改、哪些地方需要用覆盖机制。

---

### 第2层（保险）：自动化护栏 — Hooks 拦截写操作

**目标**：第3层依赖 CLAUDE.md 的引导，AI 可能不遵守（尤其是 DeepSeek）。Hooks 在文件系统和 Git 层面强制执行"写操作只能落在客户目录"。

**两层 Hooks：**

**Pre-tool Hook（写操作前检查）**：
- AI 调用 Write/Edit 工具时，Hook 检查目标文件路径
- 如果路径在禁区（`jeecg-boot-base-core/`、`jeecg-module-system/`、其他客户模块），直接拒绝并返回：
  > "此目录受 Super Harness 保护，不允许写入。请在客户模块目录（customer-xxx/）下操作。如需修改框架代码，请联系技术人员。"
- 读操作（Read/Grep/Glob）不受限制

**Pre-commit Hook（提交前检查）**：
- `git diff --cached` 扫描暂存区变更文件
- 发现禁区文件 → 阻止提交，列出违规文件
- 发现多个客户模块同时被修改 → 警告并阻止

**效果**：即使 AI 忽略 CLAUDE.md 的引导，Hooks 在文件系统层面无法绕过。读操作不受影响。

---

### 第1层（引导）：行为规则 — CLAUDE.md + Commands + Skills

**目标**：减少 AI "尝试越界"的次数，让它从一开始就去对的地方读、往对的地方写。

**CLAUDE.md 规则声明**：
```markdown
## AI 开发边界（强制）

你是 JeecgBoot ERP 的 KA 定制开发助手。当前客户：[客户名称]。

**读操作（不限）**：你可以阅读项目中的任意文件，了解框架结构、参考已有写法。

**写操作（限制）**：只能在以下目录新建或修改文件：
- 后端：`jeecg-boot/jeecg-boot-module/customer-{当前客户}/`
- 前端：`jeecgboot-vue3/src/views/customer/{当前客户}/`

**关键参考文件**（生成代码前先查阅）：
- `jeecg-boot-base-core/.../JeecgController.java` — 控制器基类
- `jeecg-boot-base-core/.../Result.java` — API 响应格式
- `jeecg-boot/CLAUDE.md` — 后端开发规范
- `jeecgboot-vue3/CLAUDE.md` — 前端开发规范
```

**Commands 标准化操作**：
- `/new-module <模块名>` — 在当前客户目录下新建业务模块
- `/gen-code <表描述>` — 调用 jeecg-codegen 生成 CRUD 代码（自动落到客户目录）
- `/review-changes` — 让 Hermes 审查当前改动
- `/submit` — 提交当前客户模块的代码

**Skills 工具封装**：
- `jeecg-codegen`：限定只生成在客户目录下
- `jeecg-bpmn`：操作流程设计器，不改代码
- `jeecg-system`：查询系统配置（只读），不修改

---

## 四、各层职责总结

| 防线 | 机制 | 读操作 | 写操作 | 失效后果 |
|------|------|--------|--------|----------|
| 第3层 — 基座+覆盖层 | 标品共享 + 客户覆盖清单 + `.manifest.yml` | 全项目放开 | 标品部分用覆盖机制替代；客户目录自由写 | 覆盖清单不维护时，标品升级无法追踪影响面 |
| 第2层 — Hooks 拦截 | Pre-tool + Pre-commit Hook | 不限 | 物理拦截标品目录的写操作；客户目录不限 | 被拦截后业务人员需找技术人员协助 |
| 第1层 — 行为引导 | CLAUDE.md 参考文件清单 + Commands | 引导去哪看 | 引导往哪写；判断该新建还是覆盖 | 无严重后果，AI 走弯路后自行纠正 |

**关键关系**：第1层告诉 AI "去这里读、去那里写，需要覆盖标品时用覆盖机制"，第2层确保"标品目录绝对写不进去（覆盖通过 Bean 替换和路由覆盖，不是直接改标品文件）"，第3层是组织保障（每个客户有独立目录 + 覆盖清单，互不干扰，标品升级有据可查）。

---

## 五、Harness 文件清单

### 5.1 规则（.claude/rules/）

每个规则文件独立，带 YAML 前置元数据定义 glob 作用范围，AI 只在匹配路径时才加载：

| 文件 | glob 范围 | 内容 |
|------|----------|------|
| `file-scope.md` | `**/*` | 读写边界：只能写客户目录，框架/系统/其他客户只读 |
| `backend-first.md` | `**/*.java` | 业务逻辑在 Service 层，Controller 精简，前端不做数据验证 |
| `code-style.md` | `**/*.{java,vue,ts}` | 命名规范、函数长度、禁止 any、修改标记格式 |
| `no-platform-modify.md` | `**/*` | 发现框架问题只记录到 PLATFORM_ISSUES.md，不直接修改 |
| `frontend.md` | `**/*.{vue,ts}` | 前端组件使用规范、表单布局、字典接入、路由定义 |
| `security.md` | `**/*` | 禁止改 .env、禁止 push --force、SQL 参数化、依赖说明 |
| `testing.md` | `**/*.test.*` | 测试标准：从 Controller/Service 自动推导测试用例 |

### 5.2 命令（.claude/commands/）

| 文件 | 用途 |
|------|------|
| `start-task.md` | 任务启动：澄清范围 → 读代码库 → Sprint 合约 → 执行 |
| `new-customer.md` | 创建新客户模块脚手架 + 注册 Maven + 初始化 manifest |
| `gen-code.md` | 调用 jeecg-codegen 在客户目录下生成 CRUD 代码 |
| `override.md` | 覆盖标品 Bean/路由/页面的标准操作 |
| `review.md` | 代码审查：盘点变更 → 质量检查 → 边界情况 → 裁决 |
| `test-api.md` | 运行 API 测试 |
| `test-all.md` | 运行全部测试（API + 前端） |
| `session-wrap.md` | 会话收尾：总结 → 模式发现 → Harness 健康检查 |
| `learn.md` | 从会话提取经验，记录到 learnings/ |
| `harness-check.md` | Harness 自诊断：6 轴评估 → 演进检查 → 改进建议 |
| `submit.md` | 代码提交前检查（含 manifest 更新提醒） |

### 5.3 功能注册表（.claude/features.json）

结构化清单，每个 ERP 模块一条记录。AI 通过查表快速定位文件：

```json
{
  "id": "order",
  "name": "订单管理",
  "category": "erp",
  "backendPath": "jeecg-boot-module/order/",
  "frontendPath": "src/views/order/",
  "apiBase": "/order",
  "hasTest": false,
  "kaCustomers": ["haier", "midea"]
}
```

### 5.4 记忆（.claude/memory/）

| 文件 | 用途 |
|------|------|
| `plan.md` | 当前 Sprint 合约（目标、范围内外、风险、完成标准） |
| `todo.md` | 当前任务检查清单 |
| `progress.md` | 跨会话进度：已完成、待解决、关键决策、修改文件清单 |

### 5.5 钩子 + 配置

| 文件 | 类型 | 内容 |
|------|------|------|
| `settings.json` | Config | PreToolUse 写拦截 + Pre-commit 文件检查 + 权限白名单 |
| `settings.local.json` | Config | 个人权限（gitignore 排除） |
| `hooks/pre-write-check.sh` | Hook | 写操作路径拦截 |
| `hooks/pre-commit-check.sh` | Hook | Git 提交前检查受保护目录 |
| `hooks/block-dangerous.sh` | Hook | 拦截危险命令（push --force、DROP TABLE、rm -rf） |
| `hooks/session-start.sh` | Hook | 检查依赖环境是否就绪 |

### 5.6 客户模块（每个客户一份）

| 文件 | 用途 |
|------|------|
| `jeecg-boot-module/customer-{name}/.manifest.yml` | 覆盖清单：基准版本、覆盖文件、新增内容 |
| `jeecg-boot-module/customer-{name}/pom.xml` | Maven 模块配置 |
| `jeecgboot-vue3/src/views/customer/{name}/` | 前端定制页面 |

---

## 六、自改进循环

```
每次开发会话
    │
    ▼
/session-wrap
    ├── 总结做了什么
    ├── 发现重复操作 → 建议新 Command
    ├── 发现重复错误 → 建议新 Rule
    ├── 发现非明显经验 → /learn 记录
    └── 发现陈旧假设 → 建议更新/删除规则
         │
         ▼
/harness-check（定期）
    ├── 6 轴诊断：结构、上下文、规划、执行、验证、改进
    ├── 检查每个规则/命令是否还编码了有效假设
    ├── 更新 features.json
    └── 输出成熟度评分报告
```

---

## 七、工程产物隔离

Harness/Hermes 的工程产出物与平台项目代码完全隔离：

| 目录 | 用途 | 产出者 |
|------|------|--------|
| `harness/` | 测试用例、自动化测试框架、构建脚本、数据迁移脚本 | Claude Code |
| `hermes/` | 代码审查报告、质量评估、测试覆盖报告 | Hermes Agent |
| `.claude/` | Claude Code 原生配置（settings/hooks/commands） | Harness 维护者 |

平台项目目录（`jeecg-boot/`、`jeecgboot-vue3/`）不受污染。

---

## 八、待评估事项

| 事项 | 说明 | 优先级 |
|------|------|--------|
| DeepSeek 指令遵循度 | CLAUDE.md + 独立规则文件能否被 DeepSeek 遵守 | 高 |
| Hook 拦截误拦率 | Pre-tool Hook 是否影响正常开发 | 高 |
| features.json 维护成本 | 加新模块时是否记得更新 features.json | 中 |
| Hermes(Kimi-Code-2.7) 审查 | Kimi-Code-2.7 对 JeecgBoot 规范的识别能力 | 中 |
| 规则文件 glob 匹配 | YAML 前置元数据的 glob 是否被 Claude Code 正确解析 | 中 |
| 自改进循环的实效 | session-wrap / harness-check 是否真的推动了改进 | 低 |

---

## 八、实施路线

| 阶段 | 内容 | 时间 |
|------|------|------|
| P0 | ✅ Git hooks + CLAUDE.md 规则 + /new-customer + 客户模板 | 已完成 |
| P1 | 规则文件化：拆分 CLAUDE.md 规则段为独立 .md 文件 | 第1周 |
| P1 | 创建 features.json + 填充现有 ERP 模块 | 第1周 |
| P2 | 编写 Commands：start-task、review、session-wrap、learn | 第2周 |
| P2 | 配置 block-dangerous + session-start hooks | 第2周 |
| P3 | 接入 Hermes 代码审查 + 云端集成验证 | 第3周 |
| P3 | 创建 memory/ 目录 + progress.md 模板 | 第3周 |
| P4 | 实测：从需求到交付走完整流程，收集改进点 | 持续 |
| P4 | harness-check 6 轴诊断 + 成熟度评分 | 持续 |
