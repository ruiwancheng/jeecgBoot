//update-begin---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——启动自动注册组件-----------
//update-begin---author:ruiwancheng ---date:2026-07-14  for：Runner自修复——已存在记录自动补齐perms/route/parentId/name-----------
package org.jeecg.modules.mes.config.init;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.modules.system.entity.SysPermission;
import org.jeecg.modules.system.entity.SysRole;
import org.jeecg.modules.system.entity.SysRolePermission;
import org.jeecg.modules.system.mapper.SysPermissionMapper;
import org.jeecg.modules.system.mapper.SysRoleMapper;
import org.jeecg.modules.system.mapper.SysRolePermissionMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.List;

/**
 * MES 菜单自动注册 —— 后端启动时自动将 {@link MesMenuRegistry} 中的菜单同步到数据库。
 * <p>
 * 同时授权给项目角色和 admin 角色，确保超级管理员能看到所有菜单。
 * <p>
 * 幂等+自修复：不存在则新建，已存在则检查并修复常见字段缺失（perms/route/parentId/name）。
 * 容错：单条失败记录日志后继续，不阻塞应用启动。
 */
@Slf4j
@Component
public class MesMenuAutoRegisterRunner implements ApplicationRunner {

    @Autowired
    private SysPermissionMapper sysPermissionMapper;

    @Autowired
    private SysRolePermissionMapper sysRolePermissionMapper;

    @Autowired
    private SysRoleMapper sysRoleMapper;

    @Override
    public void run(ApplicationArguments args) {
        List<MesMenuDefinition> menus = MesMenuRegistry.getMenus();
        String projectRoleId = MesMenuRegistry.PROJECT_ROLE_ID;
        String adminRoleId = getAdminRoleId();
        log.info("--- MES 菜单自动注册开始（共 {} 条，项目角色: {}，admin角色: {}）---",
                menus.size(), projectRoleId, adminRoleId);

        int created = 0, skipped = 0, errors = 0;
        for (MesMenuDefinition def : menus) {
            try {
                if (registerMenu(def)) created++; else skipped++;
                if (bindRole(def, projectRoleId)) created++; else skipped++;
                if (adminRoleId != null && bindRole(def, adminRoleId)) created++; else skipped++;
            } catch (Exception e) {
                log.error("MES 菜单注册失败: id={}, name={}", def.getId(), def.getName(), e);
                errors++;
            }
        }
        log.info("--- MES 菜单自动注册完成: 新建/修复 {} 项, 跳过 {} 项, 失败 {} 项 ---",
                created, skipped, errors);
    }

    private String getAdminRoleId() {
        try {
            LambdaQueryWrapper<SysRole> qw = new LambdaQueryWrapper<>();
            qw.eq(SysRole::getRoleCode, "admin");
            SysRole adminRole = sysRoleMapper.selectOne(qw);
            if (adminRole != null) return adminRole.getId();
        } catch (Exception e) {
            log.warn("MES 菜单注册: 无法查询admin角色", e);
        }
        return null;
    }

    /**
     * 注册菜单：不存在则新建，已存在则修复常见字段缺失。
     * @return true=有操作, false=无变化
     */
    private boolean registerMenu(MesMenuDefinition def) {
        SysPermission exist = sysPermissionMapper.selectById(def.getId());
        if (exist == null) {
            insertMenu(def);
            return true;
        }
        return fixIfNeeded(exist, def);
    }

    private void insertMenu(MesMenuDefinition def) {
        SysPermission p = new SysPermission();
        p.setId(def.getId());
        p.setParentId(def.getParentId());
        p.setName(def.getName());
        p.setUrl(def.getUrl());
        p.setComponent(def.getComponent());
        p.setComponentName(def.getComponentName());
        p.setRedirect(def.getRedirect());
        p.setMenuType(def.getMenuType());
        p.setSortNo(def.getSortNo());
        p.setIcon(def.getIcon());
        p.setLeaf(def.isLeaf());
        p.setRoute(def.isRoute());
        p.setKeepAlive(def.isKeepAlive());
        p.setPerms(def.getPerms());
        p.setAlwaysShow(def.isAlwaysShow());
        p.setHidden(def.isHidden());
        p.setHideTab(def.isHideTab());
        p.setPermsType("1");
        p.setStatus("1");
        p.setDelFlag(0);
        p.setRuleFlag(0);
        p.setInternalOrExternal(false);
        p.setCreateBy("admin");
        p.setCreateTime(new Date());
        p.setUpdateBy("admin");
        p.setUpdateTime(new Date());
        sysPermissionMapper.insert(p);
        log.info("MES 菜单已注册: id={}, name={}, url={}", def.getId(), def.getName(), def.getUrl());
    }

    /**
     * 修复已存在记录的常见字段缺失（SQL/API 创建时可能遗漏的关键字段）。
     */
    private boolean fixIfNeeded(SysPermission exist, MesMenuDefinition def) {
        boolean fixed = false;
        // perms 列为空 → Shiro 鉴权永远失败
        if (isEmpty(exist.getPerms()) && !isEmpty(def.getPerms())) {
            exist.setPerms(def.getPerms());
            fixed = true;
        }
        // route=false → 前端不生成路由 → 404
        if (!exist.isRoute() && def.isRoute()) {
            exist.setRoute(true);
            fixed = true;
        }
        // parentId 为空
        if (isEmpty(exist.getParentId()) && !isEmpty(def.getParentId())) {
            exist.setParentId(def.getParentId());
            fixed = true;
        }
        // name 为空
        if (isEmpty(exist.getName()) && !isEmpty(def.getName())) {
            exist.setName(def.getName());
            fixed = true;
        }
        if (fixed) {
            sysPermissionMapper.updateById(exist);
            log.info("MES 菜单字段已修复: id={}, perms={}, route={}, parentId={}",
                    def.getId(), exist.getPerms(), exist.isRoute(), exist.getParentId());
        }
        return fixed;
    }

    private boolean isEmpty(String s) { return s == null || s.isEmpty(); }

    /**
     * 绑定菜单到角色，已绑定则跳过。
     */
    private boolean bindRole(MesMenuDefinition def, String roleId) {
        LambdaQueryWrapper<SysRolePermission> qw = new LambdaQueryWrapper<>();
        qw.eq(SysRolePermission::getRoleId, roleId);
        qw.eq(SysRolePermission::getPermissionId, def.getId());
        if (sysRolePermissionMapper.selectCount(qw) > 0) return false;

        SysRolePermission rp = new SysRolePermission();
        rp.setRoleId(roleId);
        rp.setPermissionId(def.getId());
        rp.setOperateDate(new Date());
        rp.setOperateIp("127.0.0.1");
        sysRolePermissionMapper.insert(rp);
        log.info("MES 角色授权: role={}, menu={}", roleId, def.getId());
        return true;
    }
}
//update-end---author:ruiwancheng ---date:2026-07-14  for：Runner自修复——已存在记录自动补齐perms/route/parentId/name-----------
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——启动自动注册组件-----------
