//update-begin---author:ruiwancheng ---date:2026-07-08  for：菜单自动注册——菜单数据对象（项目模板）-----------
package org.jeecg.modules.template.config.init;

import lombok.Data;
import lombok.experimental.Accessors;

/**
 * 菜单定义——描述一条菜单的完整属性
 */
@Data
@Accessors(chain = true)
public class MesMenuDefinition {

    private String id;
    private String parentId = "";
    private String name;
    private String url;
    private String component;
    private String componentName = "";
    private String redirect = "";
    private Integer menuType = 1;
    private Double sortNo = 0.0;
    private String icon = "";
    private boolean leaf = true;
    private boolean route = true;
    private boolean keepAlive = false;
    private boolean alwaysShow = false;
    private boolean hidden = false;
    private boolean hideTab = false;
    private String roleId;

    public static MesMenuDefinition leaf(String id, String parentId, String name,
                                          String url, String component, String componentName) {
        return new MesMenuDefinition()
                .setId(id).setParentId(parentId).setName(name)
                .setUrl(url).setComponent(component).setComponentName(componentName)
                .setMenuType(1).setLeaf(true).setRoute(true);
    }

    public static MesMenuDefinition folder(String id, String parentId, String name,
                                            String url, String redirect) {
        return new MesMenuDefinition()
                .setId(id).setParentId(parentId).setName(name)
                .setUrl(url).setComponent("layouts/default/index").setRedirect(redirect)
                .setMenuType(parentId.isEmpty() ? 0 : 1).setLeaf(false).setRoute(true)
                .setKeepAlive(true);
    }

    public MesMenuDefinition icon(String icon) { this.icon = icon; return this; }
    public MesMenuDefinition sortNo(Double sortNo) { this.sortNo = sortNo; return this; }
    public MesMenuDefinition hidden(boolean hidden) { this.hidden = hidden; return this; }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：菜单自动注册——菜单数据对象（项目模板）-----------
