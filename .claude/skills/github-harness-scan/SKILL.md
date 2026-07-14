---
name: github-harness-scan
description: "Use when you need to scan GitHub for high-quality Harness engineering repositories (.claude/ structure) and produce reports for the JeecgBoot low-code platform. Handles token/no-token modes, deduplication, incremental scanning, and index generation."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [github, harness, scan, claude-code, research, lowcode]
    related_skills: [plan, github-repo-management]
---

# GitHub Harness 工程扫描

## Overview

扫描 GitHub 上含 `.claude/` 工程规范（commands / rules / hooks）的优质仓库，生成 Markdown 报告并归档到 `hermes/scans/`，为 JeecgBoot 低代码平台的 Harness 工程规范提供外部参考。

## When to Use

- 需要发现更多 `.claude/` 结构的参考仓库时
- 需要更新 `hermes/scans/INDEX.md` 索引时
- 平台管理员要求汇总外部 Harness 工程经验时
- 每周/每月定期补充扫描结果时

## When NOT to Use

- 不需要精读低分仓库（借鉴在精不在多）
- 不需要将结果直接转化为 `.claude/rules` 或 `.claude/commands`（需平台管理员决定）

## Prerequisites

- Python 3 已安装
- `requests` 库已安装（`pip3 install requests`）
- 可选：`GITHUB_TOKEN` 环境变量（提升速度 3 倍）

## Assets

| 资产 | 路径 |
|---|---|
| 扫描脚本 | `hermes/tasks/scripts/github_harness_scan.py` |
| 任务说明 | `hermes/tasks/scan-github-task.md` |
| 结果目录 | `hermes/scans/` |
| 索引文件 | `hermes/scans/INDEX.md` |

## Execution Steps

1. 检查当前已有报告数量：
   ```bash
   ls hermes/scans/2026-*.md | wc -l
   ```

2. 选择运行模式：

   **无 Token（慢但稳）：**
   ```bash
   cd /mnt/d/project/JeecgBoot
   unset GITHUB_TOKEN
   python3 hermes/tasks/scripts/github_harness_scan.py
   ```

   **带 Token（快）：**
   ```bash
   cd /mnt/d/project/JeecgBoot
   export GITHUB_TOKEN="<your-token>"
   python3 hermes/tasks/scripts/github_harness_scan.py
   ```

   **快速试跑（每查询前 3 个）：**
   ```bash
   cd /mnt/d/project/JeecgBoot
   unset GITHUB_TOKEN
   python3 hermes/tasks/scripts/github_harness_scan.py 3
   ```

3. 脚本执行后会自动：
   - 去重、增量扫描
   - 生成新仓库报告到 `hermes/scans/`
   - 更新 `hermes/scans/INDEX.md`

4. 检查输出：
   ```bash
   cat hermes/scans/INDEX.md
   ```

## Result Interpretation

- `INDEX.md` 按评分倒序、Star 数倒序排列
- 每个仓库报告含 Commands / Rules / Hooks 列表和评分
- 精读总结见 `hermes/scans/insights-top5.md`

## Common Pitfalls

1. **无 Token 时速度慢**：每 6 秒一个请求，默认单次最多 30 个新仓库。超时风险低，但全量更新需多次运行。
2. **GitHub Token 容易 401**：Classic Token 必须勾选 `public_repo` 或 `repo` 权限；Fine-grained Token 暂不支持 Search API 全部功能。
3. **重复仓库**：不同搜索查询会命中同一仓库，脚本已自动去重，无需担心。
4. **增量判断依据文件名**：如果已存在 `2026-07-07-owner_repo-starsN.md`，则跳过该仓库。

## Automation

已创建定时任务（默认暂停）：
- 任务 ID：`b79a7a58f3bb`
- 周期：每周一 09:00
- 操作命令：
  ```bash
  hermes cronjob resume b79a7a58f3bb   # 启用
  hermes cronjob pause b79a7a58f3bb    # 暂停
  hermes cronjob run b79a7a58f3bb      # 立即跑一次
  hermes cronjob list                  # 查看状态
  ```

## Verification Checklist

- [ ] 脚本路径存在：`hermes/tasks/scripts/github_harness_scan.py`
- [ ] `requests` 库已安装
- [ ] 运行后 `hermes/scans/` 新增报告文件
- [ ] `hermes/scans/INDEX.md` 已更新
- [ ] 新增仓库无重复
- [ ] 定时任务状态符合预期（启用/暂停）
