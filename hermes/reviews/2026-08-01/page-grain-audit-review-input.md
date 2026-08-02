# Plan 评审输入 — 黄金模板命令按页面组织（2026-08-01）

## 任务

把 `.claude/commands/dev/vue-audit.md` + `.claude/commands/dev/vue-migrate.md` + `.claude/scripts/vue-audit.sh`
从"按单文件"粒度改造为"按页面目录"粒度，与 JeecgBoot 单据页实际开发单位（一个目录 = index.vue + Drawer.vue + data.ts + api.ts）对齐。

## 用户决策（已确认）

| 决策点 | 选择 |
|---|---|
| 命令范围 | Q1=B：`/vue-audit` + `/vue-migrate` 两个一起改 |
| 页面定义 | Q2=A 方案：目录单元（`<domain>/<module>/index.vue` 为锚点，同目录其他 vue/ts 归属） |
| 边界场景 | 用户表示"无"（无遗漏场景） |
| SubTable.vue | 不纳入审计 |
| changelog 标注 | 不需要 |

## 改动范围

| 文件 | 操作 | 大致改动 |
|---|---|---|
| `.claude/scripts/vue-audit.sh` | 改 | 新增"目录输入"分支 + 页面级聚合报告；提取 `audit_one_file` 函数复用；保留单文件用法 |
| `.claude/commands/dev/vue-audit.md` | 改 | 新增按页面用法段落、更新示例（"扫描 X 文件" → "扫描 X 页面"） |
| `.claude/commands/dev/vue-migrate.md` | 改 | 新增按页面聚合 diff 用法 |

## 现状背景（命令当前形态）

```bash
# 现状单文件用法
./vue-audit.sh <file.vue> [--strict]
./vue-audit.sh --all  # 内部用 find ... | xargs

# 现状命令文档核心段落
> /vue-audit jeecgboot-vue3/src/views/mes/receipt/index.vue
> /vue-audit --all
> /vue-audit --all --strict
```

## 目标草案（伪代码）

```bash
# 目录用法（新增）
./vue-audit.sh jeecgboot-vue3/src/views/project/mes/stock/other-out
# → 聚合该目录下 index.vue + OtherOutDrawer.vue + otherOut.data.ts + otherOut.api.ts
#   输出：单文件 PASS/WARN/FAIL 各自展示 + 页面汇总

# 单文件用法（向后兼容）
./vue-audit.sh jeecgboot-vue3/src/views/project/mes/stock/other-out/index.vue

# 全量（语义调整）
./vue-audit.sh --all
# → 改为：以"含 index.vue 的目录"为单元枚举
#   输出："扫描 X 个页面 / Y 个相关文件"
```

## 页面识别规则（草案）

```
<page-dir>/
  ├── index.vue                  # 锚点（必含）
  ├── *Drawer.vue                # 抽屉页（可选）
  ├── *.data.ts                  # schema（可选）
  ├── *.api.ts                   # 接口（可选）
  └── *SubTable.vue 等辅助组件    # 不纳入审计
```

目录里**没** index.vue → 报错"不是页面，请传文件路径"。

## 已查证项

- 样本目录 `jeecgboot-vue3/src/views/project/mes/stock/{other-out,other-in,stocktake}` 都是 5 文件结构（index + Drawer + data + api + SubTable）
- 全量 `find ... -name "index.vue" | wc -l = 149` 个页面
- 单文件用法目前被 `vue-audit.md` 的全量示例 + 内部调用引用 → 需保留兼容

## 待评审问题（请 Claude 重点审视）

### Q1：方案完整性
按这个目录单元方案，是否漏掉了"页面"应有的检查维度？比如：
- 跨文件一致性（如 api.ts 函数导出被 data.ts 引用，单独审计文件可能漏掉关联缺失）
- 模板版本对齐（`@generated-from` 标注在不同文件里版本必须一致）

### Q2：高风险点识别
- 把现有"单文件审计逻辑"重构为函数 + 加分支，是合理的演进吗？有没有更稳的写法？
- `--all` 输出口径从"文件数"变"页面数"，历史评审/铁拳团报告数字会漂移，要不要脚本内部提供 `--legacy-file-mode` 兼容开关？

### Q3：遗漏场景
用户说"无边界场景"，Claude 视角下是否漏了什么？比如：
- 页面目录嵌套子目录（罕见但可能：`<domain>/<module>/detail/index.vue`）
- Drawer.vue 但无 index.vue（如单纯详情页）的目录
- 同目录下多个 Drawer.vue（如复杂单据有多个抽屉）的边界

### Q4：orca-audit-fix vs orca-review 选择
本次是工具脚本（非业务代码）改造，规则上"shell 代码改动需 orca-review"是否过严？
或：脚本改造 vs 业务代码改造，评审粒度/视角应不同？

## 期望产出

按 orca-review skill 标准格式输出"通过/遗漏/建议"：
- 思路对齐：方案覆盖了哪些要点
- 遗漏：哪些风险/边界未覆盖
- 建议：可优化的实现细节

不要执行修改，只评审。