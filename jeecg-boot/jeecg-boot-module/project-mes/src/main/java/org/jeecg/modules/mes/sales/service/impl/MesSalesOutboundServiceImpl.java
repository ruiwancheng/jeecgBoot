//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
package org.jeecg.modules.mes.sales.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.sales.entity.MesSalesOutbound;
import org.jeecg.modules.mes.sales.mapper.MesSalesOutboundMapper;
import org.jeecg.modules.mes.sales.service.IMesSalesOutboundService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Date;

@Service
public class MesSalesOutboundServiceImpl extends ServiceImpl<MesSalesOutboundMapper, MesSalesOutbound> implements IMesSalesOutboundService {

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean save(MesSalesOutbound entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("出库单编码不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("出库单编码长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("出库仓库不能为空");
        entity.setStatus("1"); // 强制草稿

        QueryWrapper<MesSalesOutbound> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("出库单编码已存在");

        MesSalesOutbound old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
            return true;
        }
        try { return super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("出库单编码已存在"); }
    }

    @Override
    public boolean updateById(MesSalesOutbound entity) {
        if (entity.getId() == null) throw new JeecgBootException("出库单ID不能为空");
        MesSalesOutbound exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态禁止编辑");
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("出库单编码不能为空");
        entity.setStatus("1"); // 保持草稿
        QueryWrapper<MesSalesOutbound> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("出库单编码已存在");
        return super.updateById(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeById(java.io.Serializable id) {
        MesSalesOutbound exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态禁止删除");
        return super.removeById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        for (Object id : list) this.removeById((java.io.Serializable) id);
        return true;
    }

    private String getCurrentUsername() {
        try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; }
        catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
