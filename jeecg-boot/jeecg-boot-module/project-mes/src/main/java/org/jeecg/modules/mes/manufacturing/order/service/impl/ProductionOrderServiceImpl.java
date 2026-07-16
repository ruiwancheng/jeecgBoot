//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Service实现-----------
package org.jeecg.modules.mes.manufacturing.order.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.manufacturing.order.entity.MesProductionOrder;
import org.jeecg.modules.mes.manufacturing.order.mapper.MesProductionOrderMapper;
import org.jeecg.modules.mes.manufacturing.order.service.IProductionOrderService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.*;

@Service
public class ProductionOrderServiceImpl extends ServiceImpl<MesProductionOrderMapper, MesProductionOrder> implements IProductionOrderService {

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean save(MesProductionOrder entity) {
        validate(entity);
        entity.setStatus("1");
        if (entity.getCompletedQty() == null) entity.setCompletedQty(BigDecimal.ZERO);
        QueryWrapper<MesProductionOrder> qw = new QueryWrapper<>(); qw.eq("code", entity.getCode());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("订单编号已存在");
        MesProductionOrder old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId()); entity.setCreateBy(old.getCreateBy()); entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername()); entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { return super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("订单编号已存在"); }
        }
        return true;
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean updateById(MesProductionOrder entity) {
        if (entity.getId() == null) throw new JeecgBootException("订单ID不能为空");
        checkStatus(entity, "edit");
        validate(entity);
        entity.setStatus("1");
        QueryWrapper<MesProductionOrder> qw = new QueryWrapper<>(); qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("订单编号已存在");
        return super.updateById(entity);
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean removeById(Serializable id) { checkStatus((String) id, "delete"); return super.removeById(id); }

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        List<MesProductionOrder> existing = baseMapper.selectBatchIds((Collection<String>) (Collection<?>) list);
        for (MesProductionOrder e : existing) {
            if (!"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态订单[" + e.getCode() + "]禁止删除");
        }
        return super.removeByIds(list);
    }

    private void validate(MesProductionOrder entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("订单编号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("订单编号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getProductId())) throw new JeecgBootException("生产产品不能为空");
        if (entity.getPlanQty() == null || entity.getPlanQty().compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("计划数量必须大于0");
        if (entity.getEndDate() != null && entity.getStartDate() != null && entity.getEndDate().before(entity.getStartDate()))
            throw new JeecgBootException("完工日期不能早于开工日期");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
    }

    private void checkStatus(MesProductionOrder entity, String action) {
        if (entity.getId() == null) return;
        MesProductionOrder exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void checkStatus(String id, String action) {
        MesProductionOrder exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private String getCurrentUsername() {
        try { return ((LoginUser) SecurityUtils.getSubject().getPrincipal()).getUsername(); } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Service实现-----------
