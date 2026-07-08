//update-begin---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单数据对象-----------
package org.jeecg.modules.mes.config.init;

import lombok.Data;
import lombok.experimental.Accessors;

/**
 * MES 菜单定义——描述一条菜单的完整属性
 */
@Data
@Accessors(chain = true)
public class MesMenuDefinition {

    /** 菜单ID（语义化，如 mes_basic_wh） */
    private String id;
    /** 父菜单ID，空字符串表示根节点 */
    private String parentId = "";
    /** 菜单名称 */
    private String name;
    /** 前端路由路径 */
    private String url;
    /** 前端组件路径 */
    private String component;
    /** 组件名称 */
    private String componentName = "";
    /** 重定向路径（分组菜单用） */
    private String redirect = "";
    /** 菜单类型：0=一级菜单，1=子菜单 */
    private Integer menuType = 1;
    /** 排序号 */
    private Double sortNo = 0.0;
    /** 图标 */
    private String icon = "";
    /** 是否叶子节点 */
    private boolean leaf = true;
    /** 是否路由菜单 */
    private boolean route = true;
    /** 是否缓存页面 */
    private boolean keepAlive = false;
    /** 是否始终显示 */
    private boolean alwaysShow = false;
    /** 是否隐藏 */
    private boolean hidden = false;
    /** 是否隐藏Tab */
    private boolean hideTab = false;
    /** 绑定的角色ID */
    private String roleId;

    // ============ 静态工厂方法 ============

    /** 叶子页面（带组件路径的最终页面） */
    public static MesMenuDefinition leaf(String id, String parentId, String name,
                                          String url, String component, String componentName) {
        return new MesMenuDefinition()
                .setId(id).setParentId(parentId).setName(name)
                .setUrl(url).setComponent(component).setComponentName(componentName)
                .setMenuType(1).setLeaf(true).setRoute(true);
    }

    /** 分组菜单（LAYOUT壳，有 redirect 指向第一个子页面） */
    public static MesMenuDefinition folder(String id, String parentId, String name,
                                            String url, String redirect) {
        return new MesMenuDefinition()
                .setId(id).setParentId(parentId).setName(name)
                .setUrl(url).setComponent("layouts/default/index").setRedirect(redirect)
                .setMenuType(parentId.isEmpty() ? 0 : 1).setLeaf(false).setRoute(true)
                .setKeepAlive(true);
    }

    // ============ 便捷设置方法 ============

    public MesMenuDefinition icon(String icon) { this.icon = icon; return this; }
    public MesMenuDefinition sortNo(Double sortNo) { this.sortNo = sortNo; return this; }
    public MesMenuDefinition hidden(boolean hidden) { this.hidden = hidden; return this; }
}
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——菜单数据对象-----------
