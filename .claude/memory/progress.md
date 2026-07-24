# Harness 工程进度

## 工作流阶段追踪

| 字段 | 值 | 说明 |
|------|-----|------|
| phase | idle | 跨平台修复+hooks硬约束+orca-review真双终端+多AI编排 |
| last_verify | 2026-07-24 | delegate四连测试+orca-review双终端验证通过 |
| last_test | 2026-07-24 | deploy quality gate PASS |
| pending_step | 无 | 待用户试用delegate+orca-review效果 |

## 会话收尾（2026-07-24 session-wrap #2）
- /delegate 工作流三轮迭代修复：orca-review强制触发+verify不卡死+worker_done必发
- /new-terminal 命令修复：记忆卡片加入会话上下文 + terminal send→--inject注入
- /cleanup-context 模板重构
- 采购模块增强：明细子表展开(3模块) + 入库单明细自动加载 + 审核按钮 + 仓库URL修复 + 关联采购订单编号查询
- 部署事故修复：MesCustomerController方法冲突
- learnings 累计 73 条(+4)，规则覆盖率 100%
- harness 健康度 40/40
- 待用户手工验证：16条测试用例（笔记空间/03测试/）

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
