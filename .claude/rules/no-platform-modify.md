---
name: no-platform-modify
description: 发现框架问题只记录不修改
glob: "**/*"
version: 1.0
---

# 平台保护

发现标品/框架 Bug 时：
1. 不修改框架代码
2. 记录到 `.claude/memory/platform-issues.md`
3. 在项目模块中用覆盖机制绕过
4. 通知技术负责人

记录格式：`[日期] 问题 | 文件 | 现象 | 临时绕过方案`
