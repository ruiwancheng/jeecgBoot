//update-begin---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
package org.jeecg.modules.mes.config.init;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * MES 项目菜单注册表 —— 集中定义所有项目菜单的唯一入口。
 */
public final class MesMenuRegistry {

    public static final String PROJECT_ROLE_ID = "mes_role_001";

    private static volatile List<MesMenuDefinition> cached;

    private MesMenuRegistry() {}

    public static List<MesMenuDefinition> getMenus() {
        if (cached == null) {
            synchronized (MesMenuRegistry.class) {
                if (cached == null) {
                    cached = Collections.unmodifiableList(buildMenus());
                }
            }
        }
        return cached;
    }

    private static List<MesMenuDefinition> buildMenus() {
        List<MesMenuDefinition> list = new ArrayList<>();

        list.add(MesMenuDefinition.folder("mes_menu_001", "",
                        "MES系统", "/project/mes", "/project/mes/basic")
                .sortNo(90.0).icon("ant-design:appstore-outlined"));

        list.add(MesMenuDefinition.folder("mes_basic", "mes_menu_001",
                        "基础设置", "/project/mes/basic", "/project/mes/basic/warehouse")
                .sortNo(10.0).icon("ant-design:setting-outlined"));

        list.add(MesMenuDefinition.leaf("mes_basic_wh", "mes_basic",
                        "仓库管理", "/project/mes/basic/warehouse",
                        "project/mes/basic/warehouse/index", "MesBasicWarehouse")
                .sortNo(1.0).icon("ant-design:database-filled"));

        list.add(MesMenuDefinition.leaf("mes_basic_loc", "mes_basic",
                        "库位管理", "/project/mes/basic/location",
                        "project/mes/basic/location/index", "MesBasicLocation")
                .sortNo(2.0).icon("ant-design:environment-filled"));

        list.add(MesMenuDefinition.leaf("mes_basic_customer", "mes_basic",
                        "客户管理", "/project/mes/basic/customer",
                        "project/mes/basic/customer/index", "MesBasicCustomer")
                .sortNo(3.0).icon("ant-design:user-outlined"));

        list.add(MesMenuDefinition.leaf("mes_basic_supplier", "mes_basic",
                        "供应商管理", "/project/mes/basic/supplier",
                        "project/mes/basic/supplier/index", "MesBasicSupplier")
                .sortNo(4.0).icon("ant-design:shop-outlined"));

        // 商品
        list.add(MesMenuDefinition.folder("mes_product", "mes_menu_001",
                        "商品", "/project/mes/product", "/project/mes/product/material")
                .sortNo(20.0).icon("ant-design:shopping-outlined"));

        list.add(MesMenuDefinition.leaf("mes_basic_material", "mes_product",
                        "物料管理", "/project/mes/basic/material",
                        "project/mes/basic/material/index", "MesBasicMaterial")
                .sortNo(1.0).icon("ant-design:gold-outlined"));

        // 仓库权限
        list.add(MesMenuDefinition.permission("mes:warehouse:list", "mes_basic_wh", "仓库列表"));
        list.add(MesMenuDefinition.permission("mes:warehouse:add", "mes_basic_wh", "仓库新增"));
        list.add(MesMenuDefinition.permission("mes:warehouse:edit", "mes_basic_wh", "仓库编辑"));
        list.add(MesMenuDefinition.permission("mes:warehouse:delete", "mes_basic_wh", "仓库删除"));
        list.add(MesMenuDefinition.permission("mes:warehouse:deleteBatch", "mes_basic_wh", "仓库批量删除"));
        list.add(MesMenuDefinition.permission("mes:warehouse:export", "mes_basic_wh", "仓库导出"));
        list.add(MesMenuDefinition.permission("mes:warehouse:import", "mes_basic_wh", "仓库导入"));

        // 库位权限
        list.add(MesMenuDefinition.permission("mes:location:list", "mes_basic_loc", "库位列表"));
        list.add(MesMenuDefinition.permission("mes:location:add", "mes_basic_loc", "库位新增"));
        list.add(MesMenuDefinition.permission("mes:location:edit", "mes_basic_loc", "库位编辑"));
        list.add(MesMenuDefinition.permission("mes:location:delete", "mes_basic_loc", "库位删除"));
        list.add(MesMenuDefinition.permission("mes:location:deleteBatch", "mes_basic_loc", "库位批量删除"));
        list.add(MesMenuDefinition.permission("mes:location:export", "mes_basic_loc", "库位导出"));
        list.add(MesMenuDefinition.permission("mes:location:import", "mes_basic_loc", "库位导入"));

        // 供应商权限
        list.add(MesMenuDefinition.permission("mes:supplier:list", "mes_basic_supplier", "供应商列表"));
        list.add(MesMenuDefinition.permission("mes:supplier:add", "mes_basic_supplier", "供应商新增"));
        list.add(MesMenuDefinition.permission("mes:supplier:edit", "mes_basic_supplier", "供应商编辑"));
        list.add(MesMenuDefinition.permission("mes:supplier:delete", "mes_basic_supplier", "供应商删除"));
        list.add(MesMenuDefinition.permission("mes:supplier:deleteBatch", "mes_basic_supplier", "供应商批量删除"));
        list.add(MesMenuDefinition.permission("mes:supplier:export", "mes_basic_supplier", "供应商导出"));
        list.add(MesMenuDefinition.permission("mes:supplier:import", "mes_basic_supplier", "供应商导入"));

        // 物料权限
        list.add(MesMenuDefinition.permission("mes:material:list", "mes_basic_material", "物料列表"));
        list.add(MesMenuDefinition.permission("mes:material:add", "mes_basic_material", "物料新增"));
        list.add(MesMenuDefinition.permission("mes:material:edit", "mes_basic_material", "物料编辑"));
        list.add(MesMenuDefinition.permission("mes:material:delete", "mes_basic_material", "物料删除"));
        list.add(MesMenuDefinition.permission("mes:material:deleteBatch", "mes_basic_material", "物料批量删除"));
        list.add(MesMenuDefinition.permission("mes:material:export", "mes_basic_material", "物料导出"));
        list.add(MesMenuDefinition.permission("mes:material:import", "mes_basic_material", "物料导入"));

        // 销售管理
        list.add(MesMenuDefinition.folder("mes_sales", "mes_menu_001",
                        "销售管理", "/project/mes/sales", "/project/mes/sales/price")
                .sortNo(30.0).icon("ant-design:shopping-cart-outlined"));

        list.add(MesMenuDefinition.leaf("mes_sales_price", "mes_sales",
                        "价格管理", "/project/mes/sales/price",
                        "project/mes/sales/price/index", "MesSalesPrice")
                .sortNo(1.0).icon("ant-design:dollar-outlined"));

        // 价格权限
        list.add(MesMenuDefinition.permission("mes:price:list", "mes_sales_price", "价格列表"));
        list.add(MesMenuDefinition.permission("mes:price:add", "mes_sales_price", "价格新增"));
        list.add(MesMenuDefinition.permission("mes:price:edit", "mes_sales_price", "价格编辑"));
        list.add(MesMenuDefinition.permission("mes:price:delete", "mes_sales_price", "价格删除"));
        list.add(MesMenuDefinition.permission("mes:price:deleteBatch", "mes_sales_price", "价格批量删除"));
        list.add(MesMenuDefinition.permission("mes:price:export", "mes_sales_price", "价格导出"));
        list.add(MesMenuDefinition.permission("mes:price:import", "mes_sales_price", "价格导入"));

        // 销售订单
        list.add(MesMenuDefinition.leaf("mes_sales_order", "mes_sales",
                        "销售订单", "/project/mes/sales/order",
                        "project/mes/sales/order/index", "MesSalesOrder")
                .sortNo(2.0).icon("ant-design:file-text-outlined"));

        list.add(MesMenuDefinition.permission("mes:salesOrder:list", "mes_sales_order", "订单列表"));
        list.add(MesMenuDefinition.permission("mes:salesOrder:add", "mes_sales_order", "订单新增"));
        list.add(MesMenuDefinition.permission("mes:salesOrder:edit", "mes_sales_order", "订单编辑"));
        list.add(MesMenuDefinition.permission("mes:salesOrder:delete", "mes_sales_order", "订单删除"));
        list.add(MesMenuDefinition.permission("mes:salesOrder:deleteBatch", "mes_sales_order", "订单批量删除"));
        list.add(MesMenuDefinition.permission("mes:salesOrder:export", "mes_sales_order", "订单导出"));

        // 发货单
        list.add(MesMenuDefinition.leaf("mes_sales_delivery", "mes_sales",
                        "发货单", "/project/mes/sales/delivery",
                        "project/mes/sales/delivery/index", "MesSalesDelivery")
                .sortNo(3.0).icon("ant-design:car-outlined"));

        list.add(MesMenuDefinition.permission("mes:delivery:list", "mes_sales_delivery", "发货单列表"));
        list.add(MesMenuDefinition.permission("mes:delivery:add", "mes_sales_delivery", "发货单新增"));
        list.add(MesMenuDefinition.permission("mes:delivery:edit", "mes_sales_delivery", "发货单编辑"));
        list.add(MesMenuDefinition.permission("mes:delivery:delete", "mes_sales_delivery", "发货单删除"));
        list.add(MesMenuDefinition.permission("mes:delivery:deleteBatch", "mes_sales_delivery", "发货单批量删除"));
        list.add(MesMenuDefinition.permission("mes:delivery:export", "mes_sales_delivery", "发货单导出"));

        // 销售出库
        list.add(MesMenuDefinition.leaf("mes_sales_outbound", "mes_sales",
                        "销售出库", "/project/mes/sales/outbound",
                        "project/mes/sales/outbound/index", "MesSalesOutbound")
                .sortNo(4.0).icon("ant-design:export-outlined"));

        list.add(MesMenuDefinition.permission("mes:outbound:list", "mes_sales_outbound", "出库列表"));
        list.add(MesMenuDefinition.permission("mes:outbound:add", "mes_sales_outbound", "出库新增"));
        list.add(MesMenuDefinition.permission("mes:outbound:edit", "mes_sales_outbound", "出库编辑"));
        list.add(MesMenuDefinition.permission("mes:outbound:delete", "mes_sales_outbound", "出库删除"));
        list.add(MesMenuDefinition.permission("mes:outbound:deleteBatch", "mes_sales_outbound", "出库批量删除"));
        list.add(MesMenuDefinition.permission("mes:outbound:export", "mes_sales_outbound", "出库导出"));

        return list;
    }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
