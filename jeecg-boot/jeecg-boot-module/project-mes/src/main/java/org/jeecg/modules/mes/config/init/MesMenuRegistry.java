//update-begin---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
package org.jeecg.modules.mes.config.init;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * MES 项目菜单注册表 —— 集中定义所有项目菜单的唯一入口。
 * <p>
 * 新增页面只需在此加一行 {@code list.add(...)}，重启后端即可自动注册并授权。
 * 列表按父子顺序排列（父菜单在前），保证注册时父菜单先入库。
 */
public final class MesMenuRegistry {

    /** MES 项目管理员角色 ID */
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

        // ==================== 一级菜单 ====================
        list.add(MesMenuDefinition.folder("mes_menu_001", "",
                        "MES系统", "/project/mes", "/project/mes/basic")
                .sortNo(90.0)
                .icon("ant-design:appstore-outlined"));

        // ==================== 基础设置 ====================
        list.add(MesMenuDefinition.folder("mes_basic", "mes_menu_001",
                        "基础设置", "/project/mes/basic", "/project/mes/basic/warehouse")
                .sortNo(10.0)
                .icon("ant-design:setting-outlined"));

        // -- 基础设置 > 仓库管理
        list.add(MesMenuDefinition.leaf("mes_basic_wh", "mes_basic",
                        "仓库管理", "/project/mes/basic/warehouse",
                        "project/mes/basic/warehouse/index", "MesBasicWarehouse")
                .sortNo(1.0)
                .icon("ant-design:database-filled"));

        // -- 基础设置 > 库位管理
        list.add(MesMenuDefinition.leaf("mes_basic_loc", "mes_basic",
                        "库位管理", "/project/mes/basic/location",
                        "project/mes/basic/location/index", "MesBasicLocation")
                .sortNo(2.0)
                .icon("ant-design:environment-filled"));

        // -- 基础设置 > 客户管理
        list.add(MesMenuDefinition.leaf("mes_basic_customer", "mes_basic",
                        "客户管理", "/project/mes/basic/customer",
                        "project/mes/basic/customer/index", "MesBasicCustomer")
                .sortNo(3.0)
                .icon("ant-design:user-outlined"));

        // ==================== 后续新页面在此添加 ====================

        return list;
    }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单注册表-----------
