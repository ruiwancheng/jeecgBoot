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

        return list;
    }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
