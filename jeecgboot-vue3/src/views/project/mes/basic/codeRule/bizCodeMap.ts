/**
 * MES 单据 ↔ 编码规则 统一映射（全项目唯一映射点）
 * 规则编码与字典 mes_code_biz_type、表 c_mes_code_rule.rule_code 保持一致。
 * 新增单据需要自动编码时：在此加常量 → 数据库补规则 → 页面 Drawer 调 getNextCode。
 */
export const MES_BIZ_CODE = {
  /** 销售订单 — views/project/mes/sales/order */
  SALES_ORDER: 'SO',
  /** 采购订单 — views/project/mes/purchase/order */
  PURCHASE_ORDER: 'PO',
  /** 生产订单 — views/project/mes/manufacturing/order */
  PRODUCTION_ORDER: 'MO',
  /** 发货单 — views/project/mes/sales/delivery */
  DELIVERY_NOTE: 'DN',
  /** 销售出库单 — views/project/mes/sales/outbound */
  SALES_OUTBOUND: 'OB',
  /** 采购收货单 — views/project/mes/purchase/receipt */
  PURCHASE_RECEIPT: 'PR',
  /** 生产领料单 — views/project/mes/manufacturing/picking */
  PRODUCTION_PICKING: 'PP',
  /** 完工入库单 — views/project/mes/manufacturing/completion */
  COMPLETION_RECEIPT: 'MC',
  /** 销售发票 — views/project/mes/finance/invoice */
  SALES_INVOICE: 'SI',
  /** 采购发票 — views/project/mes/finance/purchaseInvoice */
  PURCHASE_INVOICE: 'PI',
} as const;
