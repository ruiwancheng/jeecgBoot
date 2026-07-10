//update-begin---author:ruiwancheng---date:2026-07-11---for: 审计修复#4-确保同客户只有一个默认地址-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesCustomerAddress;
import org.jeecg.modules.mes.basic.mapper.MesCustomerAddressMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerAddressService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class MesCustomerAddressServiceImpl extends ServiceImpl<MesCustomerAddressMapper, MesCustomerAddress> implements IMesCustomerAddressService {

    @Override
    @Transactional
    public boolean save(MesCustomerAddress entity) {
        validate(entity);
        if (entity.getIsDefault() != null && entity.getIsDefault() == 1) {
            cancelOtherDefaults(entity.getCustomerId(), null);
        }
        return super.save(entity);
    }

    @Override
    @Transactional
    public boolean updateById(MesCustomerAddress entity) {
        validate(entity);
        if (entity.getIsDefault() != null && entity.getIsDefault() == 1) {
            cancelOtherDefaults(entity.getCustomerId(), entity.getId());
        }
        return super.updateById(entity);
    }

    private void validate(MesCustomerAddress e) {
        if (!StringUtils.hasText(e.getAddressType())) {
            throw new JeecgBootException("地址类型不能为空");
        }
        if (!StringUtils.hasText(e.getContact())) {
            throw new JeecgBootException("地址联系人不能为空");
        }
        if (!StringUtils.hasText(e.getDetail())) {
            throw new JeecgBootException("详细地址不能为空");
        }
    }

    private void cancelOtherDefaults(String customerId, String excludeId) {
        LambdaQueryWrapper<MesCustomerAddress> qw = new LambdaQueryWrapper<>();
        qw.eq(MesCustomerAddress::getCustomerId, customerId)
          .eq(MesCustomerAddress::getIsDefault, 1);
        if (excludeId != null) {
            qw.ne(MesCustomerAddress::getId, excludeId);
        }
        MesCustomerAddress other = getOne(qw);
        if (other != null) {
            other.setIsDefault(0);
            super.updateById(other);
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-11---for: 审计修复#4-确保同客户只有一个默认地址-----------
