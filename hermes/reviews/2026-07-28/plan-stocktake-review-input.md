# 盘点单模块 plan 评审输入（2026-07-28）

## 背景
在 jeecgBoot MES（project-mes）新增「盘点单」页面。刚交付完其它出入库+B+A+成本联动（入库审核联动移动平均，出库快照不联动，台账有成本差异列）。盘点要复用这套基础设施。

## 草案（plan）

### 流程
创建盘点单(选仓库) → 快照账面库存为明细 → 录入实盘数 → 审核 → 差异行自动生成盘盈入库/盘亏出库单并审核（复用现有 OtherStockIn/OutService）→ 库存校准

### 数据模型 V9.9.0
- c_mes_stocktake：code(PD编码规则)/warehouse_id/take_type(1全盘2抽盘)/status(复用mes_other_stock_status:1草稿2已审核3已红冲)/take_date/remark/audit_by/audit_date
- c_mes_stocktake_item：material_id/book_qty(账面快照)/actual_qty(实盘)/diff_qty/unit_cost(快照移动平均)/diff_amount

### 关键策略
1. 审核时 diff>0 → 生成其它入库单(inType='1'盘盈)并审核；diff<0 → 生成其它出库单(outType='1'盘亏)并审核；diff=0 不动
2. unit_cost 快照=当前移动平均 → 盘盈按均价入账 avg 不变；盘亏按均价出库台账差异=0
3. V1 不锁仓（文档提示盘点期间勿出入库）；不做红冲（审核前可删单，审核后调整走普通其它出入库）
4. 菜单走 MesMenuRegistry Java Runner；前端照搬 OtherInDrawer 模式；bizCodeMap 加 STOCKTAKE:'PD'

### 已查证项
- 字典 mes_other_stock_in_type/out_type 的盘盈/盘亏(value='1')已存在于 V9.8.0 种子 SQL
- bizCodeMap 现有 OTHER_STOCK_IN:'QI'/OTHER_STOCK_OUT:'QO'，新增 STOCKTAKE:'PD'
- updateMovingAvgCostOnStockIn 方法签名与语义（入库联动，先成本后库存）
- OtherStockIn/OutService 的 audit/unaudit/delete 接口可直接调用
- selectPage 物料接口无 pageSize 上限

## 待评审问题
1. 审核时生成出入库单：是用【生成单据记录+调其audit】还是【直接调 inventoryService.stockIn/Out 跳过单据】？我选前者（留痕可溯），是否有坑？
2. 快照时点：创建盘点单时快照 book_qty，到审核期间若有出入库，审核按快照差异生成调整单，实际库存会被调成"实盘数"吗？（例：快照100，审核前又出了10，实盘95，审核生成盘亏5，最终90≠95）V1不锁仓下这个偏差怎么交代？是可接受的业务口径（差异以快照时点为准，后续出入库另算），还是应该审核时按"当前库存 vs 实盘"重新算差异？
3. unit_cost 快照取 movingAvgCost：盘盈入账成本用均价 → avg 不变，这是标准做法吗？还是盘盈应该用 0 成本或手工成本？
4. 前端「生成盘点明细」：全盘一键快照是放后端（创建时自动生成 items）还是前端按钮调接口刷新明细？我倾向后端创建时生成，简单可靠，但抽盘场景需要空明细+手工加行，两种创建路径会不会让代码分叉？
5. 有没有遗漏的高风险点？（事务边界/并发审核/审核失败部分单据已生成怎么回滚）

请按"通过/遗漏/建议"结构输出评审报告到 hermes/reviews/2026-07-28/orca-review-plan-stocktake.md
