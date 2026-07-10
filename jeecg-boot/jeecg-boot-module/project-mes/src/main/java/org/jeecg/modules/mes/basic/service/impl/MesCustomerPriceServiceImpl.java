//update-begin---author:ruiwancheng---date:2026-07-11---for: 审计修复#5-价格有效期重叠校验-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesCustomerPrice;
import org.jeecg.modules.mes.basic.mapper.MesCustomerPriceMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerPriceService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Date;
import java.util.List;

@Service
public class MesCustomerPriceServiceImpl extends ServiceImpl<MesCustomerPriceMapper, MesCustomerPrice> implements IMesCustomerPriceService {

    @Override
    @Transactional
    public boolean save(MesCustomerPrice entity) {
        validate(entity);
        checkOverlap(entity.getCustomerId(), entity.getProductId(), entity.getBeginDate(), entity.getEndDate(), null);
        return super.save(entity);
    }

    @Override
    @Transactional
    public boolean updateById(MesCustomerPrice entity) {
        validate(entity);
        checkOverlap(entity.getCustomerId(), entity.getProductId(), entity.getBeginDate(), entity.getEndDate(), entity.getId());
        return super.updateById(entity);
    }

    private void checkOverlap(String customerId, String productId, Date beginDate, Date endDate, String excludeId) {
        if (beginDate == null || endDate == null) {
            return; // 没有设置有效期则不校验
        }
        if (endDate.before(beginDate)) {
            throw new JeecgBootException("失效日期不能早于生效日期");
        }
        LambdaQueryWrapper<MesCustomerPrice> qw = new LambdaQueryWrapper<>();
        qw.eq(MesCustomerPrice::getCustomerId, customerId)
          .eq(MesCustomerPrice::getProductId, productId)
          .le(MesCustomerPrice::getBeginDate, endDate)
          .ge(MesCustomerPrice::getEndDate, beginDate);
        if (excludeId != null) {
            qw.ne(MesCustomerPrice::getId, excludeId);
        }
        long count = baseMapper.selectCount(qw);
        if (count > 0) {
            throw new JeecgBootException("该产品价格有效期与已有记录重叠，请调整时间范围");
        }
    }

    private void validate(MesCustomerPrice e) {
        if (!StringUtils.hasText(e.getProductId())) {
            throw new JeecgBootException("产品ID不能为空");
        }
        if (e.getPrice() == null) {
            throw new JeecgBootException("协议单价不能为空");
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-11---for: 审计修复#5-价格有效期重叠校验-----------
