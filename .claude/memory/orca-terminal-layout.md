---
name: orca-terminal-layout
description: Orca终端布局标准 — JeecgBoot开发四终端标准布局（后端/前端/构建/测试）
metadata:
  type: reference
---

# Orca 终端布局标准

JeecgBoot 开发需要同时运行多个服务，标准布局如下：

## 主工作树（日常开发）四终端布局

```
┌──────────────────────┬──────────────────────┐
│  Tab 1: 后端服务       │  Tab 2: 前端服务       │
│  mvn spring-boot:run  │  pnpm dev             │
│  端口: 8080           │  端口: 3100           │
│  日志输出: 实时        │  热更新: 实时          │
├──────────────────────┼──────────────────────┤
│  Tab 3: 构建终端       │  Tab 4: 测试/数据库     │
│  mvn compile/package  │  vitest / playwright   │
│  git 操作             │  mysql / redis-cli     │
│  临时命令             │  日志查看 tail -f       │
└──────────────────────┴──────────────────────┘
```

## 各终端职责

| Tab | 名称 | 命令 | 说明 |
|:--:|------|------|------|
| 1 | 后端服务 | `mvn spring-boot:run -DskipTests` | 常驻，开发期间保持运行 |
| 2 | 前端服务 | `pnpm dev` | 常驻，热更新即时生效 |
| 3 | 构建/Git | 自由命令 | 编译、提交、Maven 操作 |
| 4 | 测试/数据 | vitest / playwright / mysql | 跑测试、查数据库、看日志 |

## 特殊场景终端

### 铁拳团审计工作树

```
Tab 1: 审计执行   — Claude Code 运行铁拳团审计
Tab 2: 代码查看   — 搜索/阅读审计目标代码
```

### 鹰眼团测试工作树

```
Tab 1: 测试执行   — vitest run (API) / playwright test (E2E)
Tab 2: 结果查看   — 测试报告、失败分析
```

## 终端管理命令

```bash
# 创建后端服务终端
orca terminal create --worktree active --command "cd jeecg-boot/jeecg-module-system/jeecg-system-start && mvn spring-boot:run -DskipTests"

# 创建前端服务终端
orca terminal create --worktree active --command "cd jeecgboot-vue3 && pnpm dev"

# 查看所有终端状态
orca terminal list

# 等待终端退出（用于判断构建是否完成）
orca terminal wait --terminal term_xxx --for exit --timeout-ms 300000

# 读取终端最后 30 行输出
orca terminal read --terminal term_xxx --lines 30
```

## 禁止事项

- 禁止在同一 Tab 混跑后端和前端（日志混杂难排查）
- 禁止用 `Ctrl+C` 杀终端后不检查服务是否真停了（用 `orca terminal stop` 干净关闭）
- 禁止在生产数据库终端执行无 WHERE 的 UPDATE/DELETE

**Why:** 标准化终端布局减少"哪个窗口在跑什么"的认知负担，后端/前端/构建分离确保日志清晰可追溯。
**How to apply:** 每次新开工作树时按此布局创建终端。日常开发主工作树保持四个 Tab 布局。
