//update-begin---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——启动自动注册组件-----------
package org.jeecg.modules.mes.config.init;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.modules.system.entity.SysPermission;
import org.jeecg.modules.system.entity.SysRolePermission;
import org.jeecg.modules.system.mapper.SysPermissionMapper;
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
 * 幂等：每个菜单先查后插，重启多次不会产生重复数据。
 * 容错：单条失败记录日志后继续，不阻塞应用启动。
 */
@Slf4j
@Component
public class MesMenuAutoRegisterRunner implements ApplicationRunner {

    @Autowired
    private SysPermissionMapper sysPermissionMapper;

    @Autowired
    private SysRolePermissionMapper sysRolePermissionMapper;

    @Override
    public void run(ApplicationArguments args) {
        List<MesMenuDefinition> menus = MesMenuRegistry.getMenus();
        String roleId = MesMenuRegistry.PROJECT_ROLE_ID;
        log.info("--- MES 菜单自动注册开始（共 {} 条，角色: {}）---", menus.size(), roleId);

        int created = 0, skipped = 0, errors = 0;
        for (MesMenuDefinition def : menus) {
            try {
                if (registerMenu(def)) created++; else skipped++;
                if (bindRole(def, roleId)) created++; else skipped++;
            } catch (Exception e) {
                log.error("MES 菜单注册失败: id={}, name={}", def.getId(), def.getName(), e);
                errors++;
            }
        }
        log.info("--- MES 菜单自动注册完成: 新建 {} 项, 跳过 {} 项, 失败 {} 项 ---",
                created, skipped, errors);
    }

    /**
     * 注册单条菜单到 sys_permission，已存在则跳过。
     * @return true=本次新建, false=已存在跳过
     */
    private boolean registerMenu(MesMenuDefinition def) {
        LambdaQueryWrapper<SysPermission> qw = new LambdaQueryWrapper<>();
        qw.eq(SysPermission::getId, def.getId());
        if (sysPermissionMapper.selectCount(qw) > 0) {
            log.debug("MES 菜单已存在，跳过: id={}, name={}", def.getId(), def.getName());
            return false;
        }

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
        return true;
    }

    /**
     * 绑定菜单到项目角色，已绑定则跳过。
     * @return true=本次新建, false=已存在跳过
     */
    private boolean bindRole(MesMenuDefinition def, String roleId) {
        LambdaQueryWrapper<SysRolePermission> qw = new LambdaQueryWrapper<>();
        qw.eq(SysRolePermission::getRoleId, roleId);
        qw.eq(SysRolePermission::getPermissionId, def.getId());
        if (sysRolePermissionMapper.selectCount(qw) > 0) {
            return false;
        }

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
//update-end---author:ruiwancheng ---date:2026-07-08  for：MES菜单自动注册——启动自动注册组件-----------
