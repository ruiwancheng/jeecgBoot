//update-begin---author:ruiwancheng ---date:2026-07-08  for：菜单自动注册——菜单注册表（项目模板，含 TEMPLATE 占位符）-----------
package org.jeecg.modules.template.config.init;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 项目菜单注册表 —— 集中定义所有项目菜单的唯一入口。
 * <p>
 * TEMPLATE 为占位符，执行 /new-project 时自动替换为实际项目名。
 * 新增页面只需在此加一行 {@code list.add(...)}，重启后端即可自动注册并授权。
 */
public final class MesMenuRegistry {

    /** 项目管理员角色 ID */
    public static final String PROJECT_ROLE_ID = "TEMPLATE_role_001";

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
        list.add(MesMenuDefinition.folder("TEMPLATE_menu_001", "",
                        "TEMPLATE系统", "/project/TEMPLATE", "/project/TEMPLATE/index")
                .sortNo(90.0)
                .icon("ant-design:appstore-outlined"));

        // ==================== 后续新页面在此添加 ====================

        return list;
    }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：菜单自动注册——菜单注册表（项目模板，含 TEMPLATE 占位符）-----------
