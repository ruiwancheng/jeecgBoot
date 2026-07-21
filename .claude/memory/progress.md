# Harness 工程进度

## 工作流阶段追踪

| 字段 | 值 | 说明 |
|------|-----|------|
| phase | done | 编码规则绑定任务完成（含审计+2个P1修复） |
| last_verify | 2026-07-21 | 编译通过，API测试20/20 |
| last_test | 2026-07-21 | 10规则取号+流水连续性验证通过 |
| pending_step | 待确认 | Step 3 业财联动已完成（用户确认+代码核实 2026-07-21），下一任务待用户指定 |

## 会话收尾（2026-07-21 session-wrap）
- 编码规则绑定任务全闭环：功能+测试+审计+2个P1修复+经验固化+工程自愈+代码审查
- learnings 累计 71 条，规则覆盖率 100%，harness 健康度 35/35
- 遗留小事：vue-tsc 与 TS 版本不兼容（仓库既有，不影响构建）；图谱 MCP 不可用
- 下一主线：MES Phase 2 Step 3 业财联动（建议新会话开始）

## 历史状态（2026-07-19）
- 活跃项目：MES
- Phase 2 Step 1 + Step 2 完成
- 4个业务模块全部完成审计+库存联动

## 本次完成（2026-07-18~19）

### Step 1 补课
- 7个状态流转API + 6列金额字段 + 价格自动带出
- 前端批量操作栏（checkbox勾选+顶部按钮）

### Step 2 库存闭环
- 新建库存基础设施（实体/Mapper/Service，FOR UPDATE+UPSERT+台账）
- 4模块集成：销售出库/采购收货/生产领料/完工入库 audit端点+库存联动
- 铁拳团审计 → 3P0修复

### 工程规范
- docs/迁移到hermes/，补建INDEX.md，规范覆盖率100%
- harness-check自检同步，速查表追加新模式

## 待推进
- Step 3: 会计科目+应收应付+凭证生成
- 前端列表totalAmount列展示

## 经验记录
- 2026-07-18: calcTotal必须在save之前调用，否则totalAmount不持久化
- 2026-07-18: useListPage的rowSelection需tableProps+BasicTable prop双配置
- 2026-07-19: auditWithGuard必须先于stockOut执行（先改状态再扣库存）
