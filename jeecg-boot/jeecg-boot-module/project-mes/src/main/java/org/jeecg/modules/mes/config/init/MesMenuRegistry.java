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

        // ==================== 基础设置 ====================
        list.add(MesMenuDefinition.folder("mes_basic", "mes_menu_001", "基础设置", "/project/mes/basic", "/project/mes/basic/customer").sortNo(10.0).icon("ant-design:setting-outlined"));
        list.add(MesMenuDefinition.leaf("mes_basic_customer", "mes_basic", "客户管理", "/project/mes/basic/customer", "project/mes/basic/customer/index", "MesBasicCustomer").sortNo(1.0).icon("ant-design:user-outlined"));
        list.add(MesMenuDefinition.leaf("mes_basic_supplier", "mes_basic", "供应商管理", "/project/mes/basic/supplier", "project/mes/basic/supplier/index", "MesBasicSupplier").sortNo(2.0).icon("ant-design:shop-outlined"));
        addPerms(list, "mes:supplier:", "mes_basic_supplier", new String[]{"list","add","edit","delete","deleteBatch","export","import"});

        // ==================== 商品 ====================
        list.add(MesMenuDefinition.folder("mes_product", "mes_menu_001", "商品", "/project/mes/product", "/project/mes/product/material").sortNo(20.0).icon("ant-design:shopping-outlined"));
        list.add(MesMenuDefinition.leaf("mes_basic_material", "mes_product", "物料管理", "/project/mes/basic/material", "project/mes/basic/material/index", "MesBasicMaterial").sortNo(1.0).icon("ant-design:gold-outlined"));
        addPerms(list, "mes:material:", "mes_basic_material", new String[]{"list","add","edit","delete","deleteBatch","export","import"});

        // ==================== 仓储管理 ====================
        list.add(MesMenuDefinition.folder("mes_warehouse", "mes_menu_001", "仓储管理", "/project/mes/warehouse", "/project/mes/basic/warehouse").sortNo(30.0).icon("ant-design:home-outlined"));
        list.add(MesMenuDefinition.leaf("mes_basic_wh", "mes_warehouse", "仓库管理", "/project/mes/basic/warehouse", "project/mes/basic/warehouse/index", "MesBasicWarehouse").sortNo(1.0).icon("ant-design:database-filled"));
        addPerms(list, "mes:warehouse:", "mes_basic_wh", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        list.add(MesMenuDefinition.leaf("mes_basic_loc", "mes_warehouse", "库位管理", "/project/mes/basic/location", "project/mes/basic/location/index", "MesBasicLocation").sortNo(2.0).icon("ant-design:environment-filled"));
        addPerms(list, "mes:location:", "mes_basic_loc", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        list.add(MesMenuDefinition.leaf("mes_sales_outbound", "mes_warehouse", "销售出库", "/project/mes/sales/outbound", "project/mes/sales/outbound/index", "MesSalesOutbound").sortNo(3.0).icon("ant-design:export-outlined"));
        addPerms(list, "mes:outbound:", "mes_sales_outbound", new String[]{"list","add","edit","delete","deleteBatch","export"});

        // ==================== 销售管理 ====================
        list.add(MesMenuDefinition.folder("mes_sales", "mes_menu_001", "销售管理", "/project/mes/sales", "/project/mes/sales/price").sortNo(40.0).icon("ant-design:shopping-cart-outlined"));
        list.add(MesMenuDefinition.leaf("mes_sales_price", "mes_sales", "价格管理", "/project/mes/sales/price", "project/mes/sales/price/index", "MesSalesPrice").sortNo(1.0).icon("ant-design:dollar-outlined"));
        addPerms(list, "mes:price:", "mes_sales_price", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
        list.add(MesMenuDefinition.leaf("mes_sales_order", "mes_sales", "销售订单", "/project/mes/sales/order", "project/mes/sales/order/index", "MesSalesOrder").sortNo(2.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:salesOrder:", "mes_sales_order", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_sales_delivery", "mes_sales", "发货单", "/project/mes/sales/delivery", "project/mes/sales/delivery/index", "MesSalesDelivery").sortNo(3.0).icon("ant-design:car-outlined"));
        addPerms(list, "mes:delivery:", "mes_sales_delivery", new String[]{"list","add","edit","delete","deleteBatch","export"});

        // ==================== 采购管理 ====================
        list.add(MesMenuDefinition.folder("mes_purchase", "mes_menu_001", "采购管理", "/project/mes/purchase", "/project/mes/purchase/apply").sortNo(50.0).icon("ant-design:shopping-outlined"));
        list.add(MesMenuDefinition.leaf("mes_purchase_apply", "mes_purchase", "采购申请", "/project/mes/purchase/apply", "project/mes/purchase/apply/index", "MesPurchaseApply").sortNo(1.0).icon("ant-design:form-outlined"));
        addPerms(list, "mes:purchaseApply:", "mes_purchase_apply", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_purchase_order", "mes_purchase", "采购订单", "/project/mes/purchase/order", "project/mes/purchase/order/index", "MesPurchaseOrder").sortNo(2.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:purchaseOrder:", "mes_purchase_order", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_purchase_receipt", "mes_purchase", "采购入库", "/project/mes/purchase/receipt", "project/mes/purchase/receipt/index", "MesPurchaseReceipt").sortNo(3.0).icon("ant-design:import-outlined"));
        addPerms(list, "mes:purchaseReceipt:", "mes_purchase_receipt", new String[]{"list","add","edit","delete","deleteBatch","export"});

        // 库存台账(仓储管理下)
        list.add(MesMenuDefinition.leaf("mes_inventory_ledger", "mes_warehouse", "库存台账", "/project/mes/warehouse/ledger", "project/mes/purchase/ledger/index", "MesInventoryLedger").sortNo(4.0).icon("ant-design:table-outlined"));
        addPerms(list, "mes:inventoryLedger:", "mes_inventory_ledger", new String[]{"list","export"});

        // ==================== 生产制造 ====================
        list.add(MesMenuDefinition.folder("mes_manufacturing", "mes_menu_001", "生产制造", "/project/mes/manufacturing", "/project/mes/manufacturing/bom").sortNo(60.0).icon("ant-design:tool-outlined"));
        list.add(MesMenuDefinition.leaf("mes_bom", "mes_manufacturing", "BOM管理", "/project/mes/manufacturing/bom", "project/mes/manufacturing/bom/index", "MesBom").sortNo(1.0).icon("ant-design:cluster-outlined"));
        addPerms(list, "mes:bom:", "mes_bom", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_production_order", "mes_manufacturing", "生产订单", "/project/mes/manufacturing/order", "project/mes/manufacturing/order/index", "MesProductionOrder").sortNo(2.0).icon("ant-design:file-text-outlined"));
        addPerms(list, "mes:productionOrder:", "mes_production_order", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_production_picking", "mes_manufacturing", "生产领料", "/project/mes/manufacturing/picking", "project/mes/manufacturing/picking/index", "MesProductionPicking").sortNo(3.0).icon("ant-design:export-outlined"));
        addPerms(list, "mes:productionPicking:", "mes_production_picking", new String[]{"list","add","edit","delete","deleteBatch","export"});
        list.add(MesMenuDefinition.leaf("mes_completion_receipt", "mes_manufacturing", "完工入库", "/project/mes/manufacturing/completion", "project/mes/manufacturing/completion/index", "MesCompletionReceipt").sortNo(4.0).icon("ant-design:import-outlined"));
        addPerms(list, "mes:completionReceipt:", "mes_completion_receipt", new String[]{"list","add","edit","delete","deleteBatch","export"});

        return list;
    }

    private static void addPerms(List<MesMenuDefinition> list, String prefix, String parentId, String[] actions) {
        for (String a : actions) list.add(MesMenuDefinition.permission(prefix + a, parentId, a));
    }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
