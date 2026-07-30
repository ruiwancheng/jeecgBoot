# Context Map — JeecgBoot Enterprise AI Low-Code Platform

> 多上下文项目地图。本次任务仅触及 MES 库存子域，其它上下文按需扩展。

## Contexts

- [MES 库存子域](./hermes/prd/mes/stock/CONTEXT.md) — 物料出入库、库存查询、盘点管理（**当前活跃**）
  - 架构决策：[ADR 0001](./hermes/prd/mes/stock/docs/adr/0001-other-stockout-audit-locks-moving-avg-cost.md) — 其它出库金额按物料移动平均成本锁定
- MES 销售子域 — *待建立*
- MES 采购子域 — *待建立*
- MES 生产制造子域 — *待建立*
- MES 业财子域 — *待建立*
- MES 基础数据子域 — *待建立*

## Relationships

- **MES 库存 ↔ MES 基础数据**：库存变动依赖物料档案、仓库档案、库位档案；术语上"物料""仓库""库位"是基础数据子域的实体
- **MES 库存 ↔ MES 生产制造**：生产领料/完工入库直接影响库存数量（生产领料单 → 库存减少；完工入库单 → 库存增加）
- **MES 库存 ↔ MES 销售**：销售出库直接扣减库存
- **MES 库存 ↔ MES 采购**：采购收货直接增加库存
- **MES 库存 ↔ MES 业财**：出入库金额自动生成财务凭证

> JeecgBoot 标品基座（用户/角色/权限/字典/菜单）不构成独立上下文，是所有子域的横切关注点。

---

*首次建立：2026-07-30（伴随其它出入库黄金模板对齐任务）*