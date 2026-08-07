# Harness 自动化任务（cron）

本目录包含 Harness 体系的自动化任务脚本。

## weekly-evolve.sh — 每周自动跑 /evolve

**用途**：每周日 23:00 自动跑 /evolve 流程，检测未规则化的 learnings，输出健康度报告。

### 配置（macOS / Linux）

```bash
# 1. 编辑 crontab
crontab -e

# 2. 添加（每周日 23:00）
0 23 * * 0 cd /Users/ruisuyun/Documents/GitHub/jeecgBoot && bash harness/scripts/cron/weekly-evolve.sh >> /tmp/evolve.log 2>&1
```

### 验证

```bash
# 测试运行
bash harness/scripts/cron/weekly-evolve.sh

# 查看输出
cat /tmp/evolve.log

# 或查看 .claude/cron/evolve-*.log
ls -lt .claude/cron/
```

### 日志位置

- 临时：`/tmp/evolve.log`（cron 输出）
- 永久：`.claude/cron/evolve-YYYYMMDD-HHMMSS.log`

### 报告内容

每次跑会输出：
- learnings 数量
- rules/ 行数 + 章节数
- 待规则化 learnings 清单
- 健康度评估

**如果输出 `⚠️ 待规则化数: N > 0` → 手动跑 /evolve**（cron 任务不自动修改 rules/，避免误改）。

详见 `memory/learnings/2026-08-07-orchestration-taskid-required.md` + `coordinator-git-status-fallback.md`。
