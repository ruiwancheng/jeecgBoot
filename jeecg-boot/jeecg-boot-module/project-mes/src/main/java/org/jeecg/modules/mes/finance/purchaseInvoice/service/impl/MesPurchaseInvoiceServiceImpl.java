//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 进项发票Service实现-----------
package org.jeecg.modules.mes.finance.purchaseInvoice.service.impl;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.finance.purchaseInvoice.entity.MesPurchaseInvoice;
import org.jeecg.modules.mes.finance.purchaseInvoice.mapper.MesPurchaseInvoiceMapper;
import org.jeecg.modules.mes.finance.purchaseInvoice.service.IMesPurchaseInvoiceService;
import org.springframework.stereotype.Service; import org.springframework.transaction.annotation.Transactional; import org.springframework.util.StringUtils;
import java.math.BigDecimal; import java.math.RoundingMode;
@Service
public class MesPurchaseInvoiceServiceImpl extends ServiceImpl<MesPurchaseInvoiceMapper, MesPurchaseInvoice> implements IMesPurchaseInvoiceService {
    @Override @Transactional(rollbackFor=Exception.class) public boolean save(MesPurchaseInvoice e) {
        if(!StringUtils.hasText(e.getCode())) throw new JeecgBootException("发票单号不能为空");
        if(e.getInvoiceDate()==null) e.setInvoiceDate(new java.util.Date()); e.setStatus("1");
        if(e.getAmount()!=null && e.getTaxRate()!=null) { e.setTaxAmount(e.getAmount().multiply(e.getTaxRate()).setScale(2,RoundingMode.HALF_UP)); e.setTotalWithTax(e.getAmount().add(e.getTaxAmount())); }
        return super.save(e);
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 进项发票Service实现-----------
