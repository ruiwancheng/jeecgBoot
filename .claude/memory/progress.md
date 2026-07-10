# Harness 工程进度

## 工作流阶段追踪

| 字段 | 值 | 说明 |
|------|-----|------|
| phase | done | MES 客户模块改造完成 |
| last_verify | 2026-07-10 | 10 个新 API 全部 200 |
| last_test | 2026-07-10 | 人工验证通过 |
| pending_step | 产品/物料模块 | PEND-001 折扣率机制待产品模块完成 |

## 当前状态
- 最后更新：2026-07-10
- 活跃项目：MES（mes）
- MES 基础数据：仓库管理、库位管理、客户管理（已完成改造）

## 本次完成

### MES 客户模块升级
- 数据库：c_mes_customer 新增 12 字段（等级/额度/业务员/行业/区域/规模/财务资料），新建 4 子表（联系人/地址/跟进记录/价格表）
- 后端：18 新文件 + 2 修改（Entity/Mapper/Service/Controller 标准四层）
- 前端：8 新文件 + 3 修改（CustomerDrawer 改造为 5 个 Tab，4 个子表组件）
- 字典：新建 7 个（客户等级/行业/区域/规模/地址类型/跟进方式/发票类型）
- API：10 个新接口（5 个 list + 5 个 add/edit/delete）

### Bug 修复
- MySQL 5.7 不支持 ADD COLUMN IF NOT EXISTS，改为 ADD COLUMN
- Switch 组件返回值 boolean→integer 转换（checkedValue/unCheckedValue）
- DatePicker 缺失 valueFormat 导致日期无法序列化
- TabPane 需显式 import 后使用 Tabs.TabPane 语法
- 子表 immediate 改为 true 以自动加载已有数据

### 测试数据
- 10 个客户（4 个等级 × 7 个行业 × 4 个区域 × 4 个规模）
- 8 个联系人 + 5 个地址 + 6 条跟进记录 + 10 条价格

## 关键决策
- 查价逻辑：价格表优先 → 等级折扣率兜底（折扣率机制暂未实现，依赖产品模块）
- 表变更策略：直接 ALTER TABLE 加字段（不拆扩展表）
- 前端布局：Tab 页签式（客户信息 + 4 个子表 Tab）

## 待推进
- PEND-001：客户等级折扣率机制（getPrice 方法，依赖产品/物料模块）
- 按 PRD 继续下一模块（仓库/物料/销售订单...）

## 经验记录
- 2026-07-10: 前端组件常见坑——Switch 整数型、DatePicker valueFormat、TabPane 显式导入、immediate 数据加载
- 2026-07-10: MySQL 5.7 不支持 ADD COLUMN IF NOT EXISTS，部署后 Docker 重建需重新执行迁移 SQL
