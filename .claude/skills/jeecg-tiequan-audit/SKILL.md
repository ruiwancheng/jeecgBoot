---
name: jeecg-tiequan-audit
description: "Use when you need to perform a multi-agent quality audit (Iron Fist team mode) on a JeecgBoot module. Spawns 10 specialized agents across product, R&D, and QA perspectives to find risks without modifying code. Outputs reports to hermes/audits/."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [jeecg, tiequan, audit, quality-control, mes, lowcode]
    related_skills: [github-harness-scan, plan, jeecg-boot]
---

# JeecgBoot 铁拳团质量审计

## Overview

对 JeecgBoot 项目的指定模块启动多 AI 智能体质控审计（铁拳团模式）。
- **只查不改**：所有智能体仅做风险检测、分析、报告，不修改任何代码。
- **10 人团队**：3 个产品风控 + 3 个研发风控 + 4 个交付测试，360° 无死角评审。
- **共识判定**：≥2 个智能体检出同一问题 → 标记高危必改，直接阻断流程。
- **输出规范**：报告统一归档到 `hermes/audits/{日期}/{模块名}/`。

## When to Use

- 新模块开发完成后，发布前做质量兜底审计
- 重大重构/接口变更前，评估影响面和风险
- 线上问题根因分析
- 平台规范升级后的合规检查
- 用户明确说“对这个模块启动铁拳团审计”

## When NOT to Use

- 不需要修改代码（修改权限归属人工/修复团）
- 不需要对低优先级问题做深度审计
- 不是 JeecgBoot 项目模块（用通用 ai-quality-control-team skill）

## Team Structure

```
┌─────────────────────────────────────────┐
│              总调度：赤兔                  │
│         （任务分发、结果汇总、风险判定）      │
└─────────────────────────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
┌────────┐    ┌────────┐    ┌────────┐
│第一梯队 │    │第二梯队 │    │第三梯队 │
│产品风控组│    │研发风控组│    │交付测试组│
│  3人   │    │  3人   │    │  4人   │
└────────┘    └────────┘    └────────┘
```

## Roles

### 总调度（赤兔）
- 读取目标模块代码（后端 Java、前端 Vue3、数据库脚本）
- 并行派发 10 个智能体
- 汇总风险结果，按共识规则判定等级
- 生成统一风控总报告和成员产出统计

### 第一梯队：产品风控组（3人）

| 代号 | 视角 | 核心关注 |
|---|---|---|
| 产品大佬1号 | 客户真实视角 | 正向业务流程完整性、操作习惯贴合度 |
| 产品大佬2号 | 边界异常视角 | 并发、逆向操作、临界值、上下游联动 |
| 产品大佬3号 | 资损合规视角 | 资金、库存、金额计算、对账逻辑 |

### 第二梯队：研发风控组（3人）

| 代号 | 视角 | 核心关注 |
|---|---|---|
| 研发大牛1号 | 架构全局视角 | 事务边界、服务分层、性能隐患、JeecgBoot 规范合规 |
| 研发大牛2号 | 代码细节视角 | 接口入参校验、SQL 注入、空值、精度、硬编码、VO 匹配 |
| 研发大牛3号 | 并发安全视角 | 超卖、重复提交、分布式锁、隔离级别、幂等 |

### 第三梯队：交付测试组（4人）

| 代号 | 视角 | 核心关注 |
|---|---|---|
| 测试牛马1号 | 基础功能测试 | 正向/逆向流程、增删改查、状态流转 |
| 测试牛马2号 | 边界异常测试 | 极值、空值、非法参数、并发异常 |
| 测试牛马3号 | 性能压测 | 接口响应、数据库性能、并发压力、N+1 查询 |
| 测试牛马4号 | 资损对账专项 | 金额一致性、库存准确性、对账逻辑、回写机制 |

## Core Rules (不可违反)

1. **只查不改**：所有智能体仅有风险检测、分析、报告权限，禁止修改代码、文档、接口、测试数据。
2. **多智能体交叉**：同岗位多 AI 并行评审，交叉复核。
3. **共识判定**：
   - ≥2 个 AI 检出同一问题 → **高危必改，阻断流程**
   - 仅 1 个 AI 检出 → **可疑风险，人工复核**
   - 意见完全对立 → **升级人工兜底专家**
4. **人工兜底**：所有缺陷最终修改权限归属人工。

## Execution Steps

1. **确认审计目标**
   - 用户指定模块名，如 `project-mes` 的 `warehouse`（仓库）或 `inventory`（库存）
   - 明确后端包路径、前端页面路径、数据库脚本路径

2. **收集目标代码**
   - 后端：`jeecg-boot/jeecg-boot-module/.../modules/mes/` 下的 Entity/Mapper/Service/Controller/VO
   - 前端：`jeecgboot-vue3/src/views/mes/.../` 下的 List.vue、Modal.vue、api.ts、data.ts
   - 数据库脚本：`jeecg-boot/db/` 或模块内的 SQL 文件

3. **并行派发 10 个智能体**
   - 使用 `delegate_task` 同时启动 10 个任务
   - 每个智能体只负责一个视角

4. **汇总结果**
   - 收集 10 份专项报告
   - 按共识规则判定风险等级
   - 标记共识高危问题

5. **输出报告**
   - 汇总目录：`hermes/audits/{YYYY-MM-DD}/{module-name}/`
   - 总报告：`01_风控总报告.md`
   - 统计报告：`02_成员产出统计.md`
   - 专项报告：`03_产品大佬1号_客户视角.md` 等
   - 索引：`index.md`

## Risk Levels

| 等级 | 标识 | 说明 |
|---|---|---|
| 致命 | 🔴 P0 | 必须立即修复，否则禁止上线 |
| 高危 | 🟠 P1 | 强烈建议修复，存在资损/数据风险 |
| 中危 | 🟡 P2 | 建议修复，影响用户体验或长期稳定性 |
| 低危 | 🟢 P3 | 提示优化，技术债务 |

## JeecgBoot Specific Checks

每个智能体在审计时，除了通用视角外，必须检查以下 JeecgBoot 规范：

| 检查项 | 说明 |
|---|---|
| 字段名 camelCase | 所有 Java 字段必须首字母小写 |
| 数据类型匹配 | BigDecimal/Integer/String/Date 与数据库列一致 |
| 系统字段完整 | createBy/createTime/updateBy/updateTime/sysOrgCode |
| 多子表参数冲突 | 子表字段命名是否避免首字母缩写冲突 |
| 子实体 Service 完整 | 是否具备 Service + Impl，而非仅 Mapper |
| 代码修改标记 | 新增/修改代码是否用 `update-begin`/`update-end` 包裹 |
| 数据库边界 | SQL 脚本是否直接操作 JeecgBoot 系统核心表 |
| 前后端接口对齐 | 后端 Controller 与前端 api.ts 是否一致 |
| 路由布局重复 | 前端子模块是否重复嵌套 LAYOUT |
| 事务注解 | Service 层是否正确使用 `@Transactional` |
| 权限注解 | Controller 是否使用 `@RequiresPermissions` 或 `@PermissionData` |
| 数据权限 | 是否考虑 sysOrgCode 等数据隔离 |

## Report Directory

```
hermes/audits/
└── {YYYY-MM-DD}/
    └── {module-name}/
        ├── 01_风控总报告.md
        ├── 02_成员产出统计.md
        ├── index.md
        ├── 03_产品大佬1号_客户视角.md
        ├── 04_产品大佬2号_边界异常视角.md
        ├── 05_产品大佬3号_资损合规视角.md
        ├── 06_研发大牛1号_架构全局视角.md
        ├── 07_研发大牛2号_代码细节视角.md
        ├── 08_研发大牛3号_并发安全视角.md
        ├── 09_测试牛马1号_基础功能测试.md
        ├── 10_测试牛马2号_边界异常测试.md
        ├── 11_测试牛马3号_性能压测.md
        └── 12_测试牛马4号_资损对账专项.md
```

## Report Naming

- 总报告：`01_风控总报告.md`
- 统计报告：`02_成员产出统计.md`
- 专项报告：`{序号}_{角色代号}_{审计视角}.md`
- 索引：`index.md`

## Common Pitfalls

1. **误用“启动整改”等词汇**：铁拳团只查不改，应使用“审计完成”“报告已生成”“请人工评估”。
2. **报告放在代码目录**：必须放到 `hermes/audits/`，避免污染源码。
3. **代码收集不完整**：JeecgBoot 是前后端分离，必须同时收集后端 Java、前端 Vue3、数据库 SQL。
4. **忽略低代码规范**：需要对照 CLAUDE.md 和 harness 工程规范检查。
5. **对低分问题过度投入**：借鉴在精不在多，P0/P1 优先。

## Verification Checklist

- [ ] 已确认审计模块名和代码路径
- [ ] 已收集后端、前端、数据库三类文件
- [ ] 10 个智能体已并行派发
- [ ] 已按共识规则判定风险等级
- [ ] 报告已归档到 `hermes/audits/{日期}/{模块}/`
- [ ] 已生成总报告、统计报告、索引
- [ ] 未修改任何代码或文档

## Example Trigger

用户说：
> “对 project-mes 的 warehouse 模块启动铁拳团审计。”

赤兔执行：
1. 读取 `jeecg-boot/jeecg-boot-module/jeecg-module-demo/.../mes/warehouse/` 代码
2. 读取 `jeecgboot-vue3/src/views/mes/warehouse/` 代码
3. 并行派发 10 个智能体
4. 汇总并输出到 `hermes/audits/2026-07-07/warehouse/`

---

*本地化版本：JeecgBoot 项目专用，基于通用 ai-quality-control-team skill 适配。*
