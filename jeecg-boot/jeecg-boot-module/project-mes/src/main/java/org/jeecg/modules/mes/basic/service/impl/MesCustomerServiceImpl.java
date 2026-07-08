//update-begin---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesCustomer;
import org.jeecg.modules.mes.basic.mapper.MesCustomerMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MesCustomerServiceImpl extends ServiceImpl<MesCustomerMapper, MesCustomer> implements IMesCustomerService {

    @Override
    @Transactional
    public boolean save(MesCustomer entity) {
        QueryWrapper<MesCustomer> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("客户编码已存在，请使用其他编码");
        }
        MesCustomer old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            baseMapper.resurrect(entity);
            return true;
        }
        return super.save(entity);
    }

    @Override
    public boolean updateById(MesCustomer entity) {
        QueryWrapper<MesCustomer> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("客户编码已存在，请使用其他编码");
        }
        return super.updateById(entity);
    }
}
//update-end---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户Service实现-----------
