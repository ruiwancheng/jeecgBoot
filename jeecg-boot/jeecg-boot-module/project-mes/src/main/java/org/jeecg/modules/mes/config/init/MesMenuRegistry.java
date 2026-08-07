//update-begin---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
package org.jeecg.modules.mes.config.init;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class MesMenuRegistry {
    public static final String PROJECT_ROLE_ID = "mes_role_001";
    private static volatile List<MesMenuDefinition> cached;
    private MesMenuRegistry() {}

    public static List<MesMenuDefinition> getMenus() {
        if (cached == null) {
            synchronized (MesMenuRegistry.class) {
                if (cached == null) cached = Collections.unmodifiableList(buildMenus());
            }
        }
        return cached;
    }

    private static List<MesMenuDefinition> buildMenus() {
        List<MesMenuDefinition> list = new ArrayList<>();
        list.add(MesMenuDefinition.folder("mes_menu_001", "", "MES系统", "/project/mes", "/project/mes/basic").sortNo(90.0).icon("ant-design:appstore-outlined"));

        buildBasicMenus(list);
        buildProductMenus(list);
        buildWarehouseMenus(list);
        buildSalesMenus(list);
        buildPurchaseMenus(list);
        buildManufacturingMenus(list);
        buildFinanceMenus(list);

        return list;
    }

    //update-begin---author:pi---date:2026-08-06---for:【SLICE-B】buildMenus 拆分：按 7 大业务域分私有方法--------
    /** 基础设置：客户/供应商/编码规则/通用设置 */
    private static void buildBasicMenus(List<MesMenuDefinition> list) {
        list.add(MesMenuDefinition.folder("mes_basic", "mes_menu_001", "基础设置", "/project/mes/basic", "/project/mes/basic/customer").sortNo(10.0).icon("ant-design:setting-outlined"));
        list.add(MesMenuDefinition.leaf("mes_basic_customer", "mes_basic", "客户管理", "/project/mes/basic/customer", "project/mes/basic/customer/index", "MesBasicCustomer").sortNo(1.0).icon("ant-design:user-outlined"));
        //update-begin---author:pi---date:2026-08-04---for:【TKT-002】补充 mes:basic:* 权限码（MesCustomerController 引用）-----------
        addPerms(list, "mes:basic:", "mes_basic_customer", new String[]{"list","add","edit","delete","deleteBatch","import","export"});
        //update-end---author:pi---date:2026-08-04---for:【TKT-002】补充 mes:basic:* 权限码（MesCustomerController 引用）-----------
        list.add(MesMenuDefinition.leaf("mes_basic_supplier", "mes_basic", "供应商管理", "/project/mes/basic/supplier", "project/mes/basic/supplier/index", "MesBasicSupplier").sortNo(2.0).icon("ant-design:shop-outlined"));
        addPerms(list, "mes:supplier:", "mes_basic_supplier", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        addPerms(list, "mes:customerAddress:", "mes_basic_customer", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        addPerms(list, "mes:customerContact:", "mes_basic_customer", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        addPerms(list, "mes:customerFollowUp:", "mes_basic_customer", new String[]{"list","add","edit","delete","deleteBatch","export"});
        addPerms(list, "mes:customerPrice:", "mes_basic_customer", new String[]{"list","add","edit","delete","deleteBatch","export"});
        //update-begin---author:ruiwancheng---date:2026-07-21  for：编码规则菜单注册-----------
        list.add(MesMenuDefinition.leaf("mes_basic_codeRule", "mes_basic", "编码规则", "/project/mes/basic/codeRule", "project/mes/basic/codeRule/index", "MesBasicCodeRule").sortNo(3.0).icon("ant-design:number-outlined"));
        addPerms(list, "mes:codeRule:", "mes_basic_codeRule", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        //update-end---author:ruiwancheng---date:2026-07-21  for：编码规则菜单注册-----------
        //update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】通用设置菜单注册（注意：菜单注册后需重启后端才能生效）-----------
        list.add(MesMenuDefinition.leaf("mes_basic_commonSetting", "mes_basic", "通用设置", "/project/mes/basic/commonSetting", "project/mes/basic/commonSetting/index", "MesBasicCommonSetting").sortNo(4.0).icon("ant-design:control-outlined"));
        addPerms(list, "mes:commonSetting:", "mes_basic_commonSetting", new String[]{"list","edit"});
        //update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】通用设置菜单注册-----------
    }

    /** 商品：物料管理 */
    private static void buildProductMenus(List<MesMenuDefinition> list) {
        list.add(MesMenuDefinition.folder("mes_product", "mes_menu_001", "商品", "/project/mes/product", "/project/mes/product/material").sortNo(20.0).icon("ant-design:shopping-outlined"));
        list.add(MesMenuDefinition.leaf("mes_basic_material", "mes_product", "物料管理", "/project/mes/basic/material", "project/mes/basic/material/index", "MesBasicMaterial").sortNo(1.0).icon("ant-design:gold-outlined"));
        addPerms(list, "mes:material:", "mes_basic_material", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
    }

    /** 仓储管理：仓库/库位/销售出库/库存预警 + 库存总览/台账/其它出入库/盘点 + 批次家族 */
    private static void buildWarehouseMenus(List<MesMenuDefinition> list) {
        list.add(MesMenuDefinition.folder("mes_warehouse", "mes_menu_001", "仓储管理", "/project/mes/warehouse", "/project/mes/basic/warehouse").sortNo(30.0).icon("ant-design:home-outlined"));
        list.add(MesMenuDefinition.leaf("mes_basic_wh", "mes_warehouse", "仓库管理", "/project/mes/basic/warehouse", "project/mes/basic/warehouse/index", "MesBasicWarehouse").sortNo(1.0).icon("ant-design:database-filled"));
        addPerms(list, "mes:warehouse:", "mes_basic_wh", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        list.add(MesMenuDefinition.leaf("mes_basic_loc", "mes_warehouse", "库位管理", "/project/mes/basic/location", "project/mes/basic/location/index", "MesBasicLocation").sortNo(2.0).icon("ant-design:environment-filled"));
        addPerms(list, "mes:location:", "mes_basic_loc", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        list.add(MesMenuDefinition.leaf("mes_sales_outbound", "mes_warehouse", "销售出库", "/project/mes/sales/outbound", "project/mes/sales/outbound/index", "MesSalesOutbound").sortNo(3.0).icon("ant-design:export-outlined"));
        addPerms(list, "mes:outbound:", "mes_sales_outbound", new String[]{"list","add","edit","delete","deleteBatch","export"});
        // 库存预警
        list.add(MesMenuDefinition.leaf("mes_basic_inventoryAlert", "mes_warehouse", "库存预警", "/project/mes/basic/inventoryAlert", "project/mes/basic/inventoryAlert/index", "MesInventoryAlert").sortNo(5.0).icon("ant-design:warning-outlined"));
        addPerms(list, "mes:inventoryAlert:", "mes_basic_inventoryAlert", new String[]{"list"});
        // 库存总览
        list.add(MesMenuDefinition.leaf("mes_inventory_overview", "mes_warehouse", "库存总览", "/project/mes/warehouse/inventory", "project/mes/basic/inventory/index", "MesInventoryOverview").sortNo(3.0).icon("ant-design:eye-outlined"));
        addPerms(list, "mes:inventory:", "mes_inventory_overview", new String[]{"list"});
        //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】注册 3 个新权限（阶段 2）-----------
        addPerms(list, "mes:inventory:", "mes_inventory_overview", new String[]{"deleteOrphan", "batchDeleteOrphan", "export"});
        //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】3 个新权限-----------
        // 库存台账
        list.add(MesMenuDefinition.leaf("mes_inventory_ledger", "mes_warehouse", "库存台账", "/project/mes/warehouse/ledger", "project/mes/purchase/ledger/index", "MesInventoryLedger").sortNo(4.0).icon("ant-design:table-outlined"));
        addPerms(list, "mes:inventoryLedger:", "mes_inventory_ledger", new String[]{"list","export"});
        //update-begin---author:ruiwancheng---date:2026-07-28---for: V9.8.0 其它出入库菜单(仓储管理下)-----------
        list.add(MesMenuDefinition.leaf("mes_other_stock_in", "mes_warehouse", "其它入库", "/project/mes/stock/other-in", "project/mes/stock/other-in/index", "MesOtherStockIn").sortNo(5.0).icon("ant-design:import-outlined"));
        addPerms(list, "mes:otherStockIn:", "mes_other_stock_in", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_other_stock_out", "mes_warehouse", "其它出库", "/project/mes/stock/other-out", "project/mes/stock/other-out/index", "MesOtherStockOut").sortNo(6.0).icon("ant-design:export-outlined"));
        addPerms(list, "mes:otherStockOut:", "mes_other_stock_out", new String[]{"list","add","edit","delete","deleteBatch","export"});
        //update-end---author:ruiwancheng---date:2026-07-28---for: V9.8.0 其它出入库菜单-----------
        //update-begin---author:ruiwancheng---date:2026-07-28---for: V9.9.0 盘点单菜单(仓储管理下)-----------
        list.add(MesMenuDefinition.leaf("mes_stocktake", "mes_warehouse", "盘点单", "/project/mes/stock/stocktake", "project/mes/stock/stocktake/index", "MesStocktake").sortNo(7.0).icon("ant-design:audit-outlined"));
        addPerms(list, "mes:stocktake:", "mes_stocktake", new String[]{"list","add","edit","delete","audit"});
        //update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 盘点单菜单-----------
        //update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-菜单注册-----------
        list.add(MesMenuDefinition.folder("mes_batch", "mes_warehouse", "批次管理", "/project/mes/batch", "/project/mes/batch/master").sortNo(4.5).icon("ant-design:barcode-outlined"));
        list.add(MesMenuDefinition.leaf("mes_batch_master", "mes_batch", "批次主档", "/project/mes/batch/master", "project/mes/batch/master/index", "MesBatchMaster").sortNo(1.0).icon("ant-design:profile-outlined"));
        addPerms(list, "mes:batchMaster:", "mes_batch_master", new String[]{"list","add","edit","delete","export"});
        list.add(MesMenuDefinition.leaf("mes_batch_inventory", "mes_batch", "批次库存", "/project/mes/batch/inventory", "project/mes/batch/inventory/index", "MesBatchInventory").sortNo(2.0).icon("ant-design:container-outlined"));
        addPerms(list, "mes:batchInventory:", "mes_batch_inventory", new String[]{"list","export"});
        list.add(MesMenuDefinition.leaf("mes_batch_ledger", "mes_batch", "批次流水", "/project/mes/batch/ledger", "project/mes/batch/ledger/index", "MesBatchLedger").sortNo(3.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:batchLedger:", "mes_batch_ledger", new String[]{"list","export"});
        list.add(MesMenuDefinition.leaf("mes_batch_traceability", "mes_batch", "批次追溯", "/project/mes/batch/traceability", "project/mes/batch/traceability/index", "MesBatchTraceability").sortNo(4.0).icon("ant-design:search-outlined"));
        addPerms(list, "mes:batchTraceability:", "mes_batch_traceability", new String[]{"list","export"});
        //update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-菜单注册-----------
    }

    /** 销售管理：价格/订单/发货单 */
    private static void buildSalesMenus(List<MesMenuDefinition> list) {
        list.add(MesMenuDefinition.folder("mes_sales", "mes_menu_001", "销售管理", "/project/mes/sales", "/project/mes/sales/price").sortNo(40.0).icon("ant-design:shopping-cart-outlined"));
        list.add(MesMenuDefinition.leaf("mes_sales_price", "mes_sales", "价格管理", "/project/mes/sales/price", "project/mes/sales/price/index", "MesSalesPrice").sortNo(1.0).icon("ant-design:dollar-outlined"));
        addPerms(list, "mes:price:", "mes_sales_price", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        list.add(MesMenuDefinition.leaf("mes_sales_order", "mes_sales", "销售订单", "/project/mes/sales/order", "project/mes/sales/order/index", "MesSalesOrder").sortNo(2.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:salesOrder:", "mes_sales_order", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_sales_delivery", "mes_sales", "发货单", "/project/mes/sales/delivery", "project/mes/sales/delivery/index", "MesSalesDelivery").sortNo(3.0).icon("ant-design:car-outlined"));
        addPerms(list, "mes:delivery:", "mes_sales_delivery", new String[]{"list","add","edit","delete","deleteBatch","export"});
    }

    /** 采购管理：申请/订单/入库 + costLog */
    private static void buildPurchaseMenus(List<MesMenuDefinition> list) {
        list.add(MesMenuDefinition.folder("mes_purchase", "mes_menu_001", "采购管理", "/project/mes/purchase", "/project/mes/purchase/apply").sortNo(50.0).icon("ant-design:shopping-outlined"));
        list.add(MesMenuDefinition.leaf("mes_purchase_apply", "mes_purchase", "采购申请", "/project/mes/purchase/apply", "project/mes/purchase/apply/index", "MesPurchaseApply").sortNo(1.0).icon("ant-design:form-outlined"));
        addPerms(list, "mes:purchaseApply:", "mes_purchase_apply", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_purchase_order", "mes_purchase", "采购订单", "/project/mes/purchase/order", "project/mes/purchase/order/index", "MesPurchaseOrder").sortNo(2.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:purchaseOrder:", "mes_purchase_order", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_purchase_receipt", "mes_purchase", "采购入库", "/project/mes/purchase/receipt", "project/mes/purchase/receipt/index", "MesPurchaseReceipt").sortNo(3.0).icon("ant-design:import-outlined"));
        addPerms(list, "mes:purchaseReceipt:", "mes_purchase_receipt", new String[]{"list","add","edit","delete","deleteBatch","export"});
        //update-begin---author:ruiwancheng---date:2026-08-06---for:【P0 bug 修复】mesCostLog 权限码未注册，所有用户访问 /list 端点 500-----------
        // 成本日志（只读 ledger，MesCostLogController 仅 /list 端点，无前端页面，挂权限不挂菜单）
        addPerms(list, "mes:purchase:costLog:", "mes_purchase", new String[]{"list"});
        //update-end---author:ruiwancheng---date:2026-08-06---for:【P0 bug 修复】mesCostLog 权限码未注册-----------
    }

    /** 生产制造：BOM/订单/领料/完工 + 开发工具组 */
    private static void buildManufacturingMenus(List<MesMenuDefinition> list) {
        //update-begin---author:ruiwancheng---date:2026-07-29---for: 黄金模板 Gallery 展示页菜单(开发工具组)-----------
        list.add(MesMenuDefinition.folder("mes_dev", "mes_menu_001", "开发工具", "/project/mes/dev", "/project/mes/dev/template-gallery").sortNo(90.0).icon("ant-design:layout-outlined"));
        list.add(MesMenuDefinition.leaf("mes_template_gallery", "mes_dev", "页面模板库", "/project/mes/dev/template-gallery", "project/mes/dev/template-gallery/index", "MesTemplateGallery").sortNo(1.0).icon("ant-design:layout-outlined"));
        //update-end---author:ruiwancheng---date:2026-07-29---for: Gallery菜单-----------
        list.add(MesMenuDefinition.folder("mes_manufacturing", "mes_menu_001", "生产制造", "/project/mes/manufacturing", "/project/mes/manufacturing/bom").sortNo(60.0).icon("ant-design:tool-outlined"));
        list.add(MesMenuDefinition.leaf("mes_bom", "mes_manufacturing", "BOM管理", "/project/mes/manufacturing/bom", "project/mes/manufacturing/bom/index", "MesBom").sortNo(1.0).icon("ant-design:cluster-outlined"));
        addPerms(list, "mes:bom:", "mes_bom", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_production_order", "mes_manufacturing", "生产订单", "/project/mes/manufacturing/order", "project/mes/manufacturing/order/index", "MesProductionOrder").sortNo(2.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:productionOrder:", "mes_production_order", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_production_picking", "mes_manufacturing", "生产领料", "/project/mes/manufacturing/picking", "project/mes/manufacturing/picking/index", "MesProductionPicking").sortNo(3.0).icon("ant-design:export-outlined"));
        //update-begin---author:patch-2026-08-04---for: 补齐生产领料权限码（修复 P1）-----------
        addPerms(list, "mes:productionPicking:", "mes_production_picking", new String[]{"list","add","edit","delete","deleteBatch","export"});
        //update-end---author:patch-2026-08-04---for: 补齐生产领料权限码-----------
        list.add(MesMenuDefinition.leaf("mes_completion_receipt", "mes_manufacturing", "完工入库", "/project/mes/manufacturing/completion", "project/mes/manufacturing/completion/index", "MesCompletionReceipt").sortNo(4.0).icon("ant-design:import-outlined"));
        //update-begin---author:patch-2026-08-04---for: 补齐完工入库权限码（修复 P1）-----------
        addPerms(list, "mes:completionReceipt:", "mes_completion_receipt", new String[]{"list","add","edit","delete","deleteBatch","export"});
        //update-end---author:patch-2026-08-04---for: 补齐完工入库权限码-----------
    }

    /** 业财管控：科目/应收应付/收付款/凭证/发票 */
    private static void buildFinanceMenus(List<MesMenuDefinition> list) {
        //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财管控菜单-----------
        list.add(MesMenuDefinition.folder("mes_finance", "mes_menu_001", "业财管控", "/project/mes/finance", "/project/mes/finance/receivable").sortNo(70.0).icon("ant-design:bank-outlined"));
        list.add(MesMenuDefinition.leaf("mes_finance_subject", "mes_finance", "会计科目", "/project/mes/finance/subject", "project/mes/finance/subject/index", "MesAccountSubject").sortNo(1.0).icon("ant-design:book-outlined"));
        addPerms(list, "mes:subject:", "mes_finance_subject", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_finance_receivable", "mes_finance", "应收账款", "/project/mes/finance/receivable", "project/mes/finance/receivable/index", "MesReceivable").sortNo(2.0).icon("ant-design:dollar-outlined"));
        addPerms(list, "mes:receivable:", "mes_finance_receivable", new String[]{"list","export"});
        list.add(MesMenuDefinition.leaf("mes_finance_payable", "mes_finance", "应付账款", "/project/mes/finance/payable", "project/mes/finance/payable/index", "MesPayable").sortNo(3.0).icon("ant-design:account-book-outlined"));
        addPerms(list, "mes:payable:", "mes_finance_payable", new String[]{"list","export"});
        list.add(MesMenuDefinition.leaf("mes_finance_collection", "mes_finance", "收款管理", "/project/mes/finance/collection", "project/mes/finance/collection/index", "MesCollection").sortNo(5.0).icon("ant-design:wallet-outlined"));
        addPerms(list, "mes:collection:", "mes_finance_collection", new String[]{"list","add","export"});
        list.add(MesMenuDefinition.leaf("mes_finance_payment", "mes_finance", "付款管理", "/project/mes/finance/payment", "project/mes/finance/payment/index", "MesPayment").sortNo(6.0).icon("ant-design:credit-card-outlined"));
        addPerms(list, "mes:payment:", "mes_finance_payment", new String[]{"list","add","export"});
        list.add(MesMenuDefinition.leaf("mes_finance_voucher", "mes_finance", "凭证管理", "/project/mes/finance/voucher", "project/mes/finance/voucher/index", "MesVoucher").sortNo(4.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:voucher:", "mes_finance_voucher", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_finance_salesInvoice", "mes_finance", "销项发票", "/project/mes/finance/invoice", "project/mes/finance/invoice/index", "MesSalesInvoice").sortNo(7.0).icon("ant-design:file-add-outlined"));
        addPerms(list, "mes:salesInvoice:", "mes_finance_salesInvoice", new String[]{"list","add","edit","delete","export"});
        list.add(MesMenuDefinition.leaf("mes_finance_purchaseInvoice", "mes_finance", "进项发票", "/project/mes/finance/purchaseInvoice", "project/mes/finance/purchaseInvoice/index", "MesPurchaseInvoice").sortNo(8.0).icon("ant-design:file-exclamation-outlined"));
        addPerms(list, "mes:purchaseInvoice:", "mes_finance_purchaseInvoice", new String[]{"list","add","edit","delete","export"});
        //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财管控菜单-----------
    }
    //update-end---author:pi---date:2026-08-06---for:【SLICE-B】buildMenus 拆分：按 7 大业务域分私有方法--------

    private static void addPerms(List<MesMenuDefinition> list, String prefix, String parentId, String[] actions) {
        for (String a : actions) list.add(MesMenuDefinition.permission(prefix + a, parentId, a));
    }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
