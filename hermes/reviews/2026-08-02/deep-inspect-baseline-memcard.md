# 记忆卡片 — /deep-inspect 巡检基线任务

## 当前阶段

`implement`（跑命令建基线）

## 行为指令

跑 /deep-inspect 建立首次巡检基线。

## 任务上下文

### 触发原因

/quality-dashboard 显示"无 deep-inspect 报告"。首次建基线，不做趋势对比。

### 工具链摸底（工人端已确认）

| 工具 | 状态 | 路径 |
|---|---|---|
| k6 | ❌ 不可用 | — |
| Playwright | ❌ 不可用 | — |
| axe-core | ❌ 不可用 | — |
| curl | ✅ 可用 | Windows 系统 |
| 后端 :8080 | ✅ HTTP 200 | 已确认 |
| 前端 :3100 | ✅ HTTP 200 | 已确认 |

### 任务规格

跑 /deep-inspect，按降级路径：

1. **Step 1 性能基准（curl 降级）**：
   - 5 个核心 API 端点 × 5 次采样
   - 计算 p50/p95 + 错误率
   - 输出到 `hermes/eagle-eye/benchmarks/baseline.json`

2. **Step 2 视觉证据**：
   - Playwright 不可用 → 手动截图指引清单
   - 不阻塞，列"待人工截图"清单即可

3. **Step 3 无障碍审计**：
   - axe-core 不可用 → 输出 WCAG 检查清单 + "建议安装 axe-core"提示
   - 不阻塞

### 产物

| 路径 | 内容 |
|---|---|
| `hermes/eagle-eye/reports/2026-08-02/deep-inspect-baseline.md` | 报告（3 段 + 总体 + 缺口说明） |
| `hermes/eagle-eye/benchmarks/baseline.json` | 性能基线 JSON |

### 关键约束

- 基于当前 HEAD = c4bc65e（不依赖未提交变更）
- 不 git stash
- **不 commit + push**（产物由协调者决定是否入仓）
- **不涉及代码改动** → 跳过 orca-review

### 风险等级

🟢 **低**（纯命令 + 文件生成，无代码改动）

- 分级测试：**轻量**
- orca-review：**跳过**

## 下一步

1. 跑 /deep-inspect（降级路径）
2. 生成 2 个产物（报告 + 基线 JSON）
3. 报告含 3 段（性能基准 / 视觉证据 / 无障碍）+ 总体 + 工具缺口说明
4. worker_done 发回（含产物路径）

## 完成标志

- ✅ `hermes/eagle-eye/reports/2026-08-02/deep-inspect-baseline.md` 存在
- ✅ `hermes/eagle-eye/benchmarks/baseline.json` 存在
- ✅ 报告含降级说明（哪些工具不可用 → 降级到 curl / 手动截图 / WCAG 清单）
- ✅ worker_done **已发**（必须发，含两个产物路径）

## 关键资源

- 命令：`.claude/commands/quality/deep-inspect.md`
- skill 权威源：`.claude/skills/deep-inspect/SKILL.md`
- 上次质量门控：`hermes/eagle-eye/reports/2026-08-02/quality-gate-baseline.md`
- /quality-dashboard 输出：本会话刚跑的（数据缺口第 3 条建议）