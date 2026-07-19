//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 销项发票Service实现-----------
package org.jeecg.modules.mes.finance.invoice.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.finance.invoice.entity.MesSalesInvoice;
import org.jeecg.modules.mes.finance.invoice.mapper.MesSalesInvoiceMapper;
import org.jeecg.modules.mes.finance.invoice.service.IMesSalesInvoiceService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class MesSalesInvoiceServiceImpl extends ServiceImpl<MesSalesInvoiceMapper, MesSalesInvoice> implements IMesSalesInvoiceService {
    @Override @Transactional(rollbackFor = Exception.class)
    public boolean save(MesSalesInvoice entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("发票单号不能为空");
        if (entity.getInvoiceDate() == null) entity.setInvoiceDate(new java.util.Date());
        entity.setStatus("1");
        // 自动计算税额和价税合计
        if (entity.getAmount() != null && entity.getTaxRate() != null) {
            entity.setTaxAmount(entity.getAmount().multiply(entity.getTaxRate()).setScale(2, RoundingMode.HALF_UP));
            entity.setTotalWithTax(entity.getAmount().add(entity.getTaxAmount()));
        }
        return super.save(entity);
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 销项发票Service实现-----------
