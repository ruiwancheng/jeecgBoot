//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 付款单Service实现-----------
package org.jeecg.modules.mes.finance.payment.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.finance.payable.entity.MesPayable;
import org.jeecg.modules.mes.finance.payable.service.IMesPayableService;
import org.jeecg.modules.mes.finance.payment.entity.MesPayment;
import org.jeecg.modules.mes.finance.payment.mapper.MesPaymentMapper;
import org.jeecg.modules.mes.finance.payment.service.IMesPaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;

@Service
public class MesPaymentServiceImpl extends ServiceImpl<MesPaymentMapper, MesPayment> implements IMesPaymentService {

    @Autowired private IMesPayableService payableService;

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean save(MesPayment entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("付款单号不能为空");
        if (entity.getAmount() == null || entity.getAmount().compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("付款金额必须大于0");
        if (entity.getPaymentDate() == null) entity.setPaymentDate(new Date());
        entity.setStatus("1");

        if (StringUtils.hasText(entity.getPayableId())) {
            MesPayable ap = payableService.getById(entity.getPayableId());
            if (ap == null) throw new JeecgBootException("关联应付单不存在");
            BigDecimal unsettled = ap.getUnsettledAmount() != null ? ap.getUnsettledAmount() : ap.getAmount();
            if (entity.getAmount().compareTo(unsettled) > 0) throw new JeecgBootException("付款金额(" + entity.getAmount() + ")超过未付金额(" + unsettled + ")");
            BigDecimal newPaid = (ap.getPaidAmount() != null ? ap.getPaidAmount() : BigDecimal.ZERO).add(entity.getAmount());
            ap.setPaidAmount(newPaid);
            ap.setUnsettledAmount(ap.getAmount().subtract(newPaid));
            ap.setStatus(newPaid.compareTo(BigDecimal.ZERO) > 0 && newPaid.compareTo(ap.getAmount()) < 0 ? "2" : "3");
            if ("3".equals(ap.getStatus())) ap.setSettlementDate(new Date());
            payableService.updateById(ap);
        }
        return super.save(entity);
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 付款单Service实现-----------
