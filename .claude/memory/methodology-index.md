---
name: methodology-index
description: 方法论/运维/架构类 learnings 分类索引 — 不适合纳入规则但值得保留的经验
metadata:
  type: reference
---

# 方法论 & 运维经验索引

以下 learnings 不满足纳入规则文件的条件（非"代码行为约束"），但作为方法论、架构模式或运维经验保留。

## 方法论

| 日期 | 经验 | 核心洞察 |
|------|------|------|
| 2026-07-20 | [开源项目分析→Harness增强四步法](learnings/2026-07-20-opensource-harness-pattern-extraction.md) | 结构对标→代码深读→可行性过滤→降级嵌入 |
| 2026-07-16 | [PRD核心逻辑和操作演示必须同时阅读](learnings/2026-07-16-prd-demo-is-data-model.md) | 操作演示里的交互动词决定数据结构设计 |
| 2026-07-09 | [Vite worker 死锁](learnings/2026-07-09-vite-worker-deadlock.md) | Less编译超时→Atomics.wait 5s→patch到60s |
| 2026-07-05 | [参考腐烂 (Reference Rot)](learnings/2026-07-05-reference-rot.md) | HAR-REF: 硬编码外部引用随版本失效 |
| 2026-07-05 | [新增vs修改范围锚定](learnings/2026-07-05-scope-add-vs-modify.md) | 优先新增文件而非修改已有文件 |
| 2026-07-05 | [元文档角色定义](learnings/2026-07-05-meta-document-role.md) | 层级入口+索引+约束+知识四层文档模型 |

## 架构模式

| 日期 | 经验 | 核心洞察 |
|------|------|------|
| 2026-07-20 | [增量增强+降级策略模式](learnings/2026-07-20-incremental-enhance-with-degradation.md) | 每项增强=新增能力+守卫条件+文档化降级 |
| 2026-07-05 | [命令/技能边界分离](learnings/2026-07-05-command-skill-split.md) | 命令=工作流编排;技能=领域知识 |
| 2026-07-05 | [Harness工程化](learnings/2026-07-04-harness-engineering.md) | 规则/Skills/Hooks标准化 |
| 2026-07-04 | [业务用户沟通语言](learnings/2026-07-04-business-user-flow.md) | 面向业务人员，避免技术术语 |

## 运维 & 环境

| 日期 | 经验 | 核心洞察 |
|------|------|------|
| 2026-07-20 | [Claude Code沙箱Git推送Keychain隔离](learnings/2026-07-20-claude-code-sandbox-git-push.md) | 沙箱无法访问macOS Keychain→HTTPS push失败 |
| 2026-07-09 | [Bash set -e 重试陷阱](learnings/2026-07-09-bash-set-e-retry-trap.md) | set -e下编译失败直接退出，重试循环被跳过 |
| 2026-07-08 | [Tailscale DNS + git push](learnings/2026-07-08-tailscale-dns-git-push.md) | VPN DNS解析延迟导致git push超时 |
| 2026-07-08 | [客户端-服务端开发工作流](learnings/2026-07-08-client-server-dev-workflow.md) | Tailscale VPN + Vite代理直连 |
| 2026-07-06 | [登录超时诊断](learnings/2026-07-06-login-timeout-diagnosis.md) | timeout of 10000ms → MySQL/Redis未启动 |
| 2026-07-04 | [Hook测试方法](learnings/2026-07-04-hook-testing.md) | 逐个hook模拟触发→验证行为 |

**Why:** 方法论/架构/运维类经验不适合写入代码规范（code-style.md）或组件规范（frontend.md），但同样是宝贵的工程积累。分索引避免散落在learnings/目录难以发现。
**How to apply:** 每次 /learn 后判断新经验的类别。代码行为→写入对应规则；方法论/架构/运维→更新此索引。
