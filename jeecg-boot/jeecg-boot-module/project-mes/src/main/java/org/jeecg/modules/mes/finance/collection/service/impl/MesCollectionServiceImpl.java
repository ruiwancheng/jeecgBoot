//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 收款单Service实现-----------
package org.jeecg.modules.mes.finance.collection.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.finance.collection.entity.MesCollection;
import org.jeecg.modules.mes.finance.collection.mapper.MesCollectionMapper;
import org.jeecg.modules.mes.finance.collection.service.IMesCollectionService;
import org.jeecg.modules.mes.finance.receivable.entity.MesReceivable;
import org.jeecg.modules.mes.finance.receivable.service.IMesReceivableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;

@Service
public class MesCollectionServiceImpl extends ServiceImpl<MesCollectionMapper, MesCollection> implements IMesCollectionService {

    @Autowired private IMesReceivableService receivableService;

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean save(MesCollection entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("收款单号不能为空");
        if (entity.getAmount() == null || entity.getAmount().compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("收款金额必须大于0");
        if (entity.getCollectionDate() == null) entity.setCollectionDate(new Date());
        entity.setStatus("1");

        // 关联应收单：更新已收金额和状态
        if (StringUtils.hasText(entity.getReceivableId())) {
            MesReceivable ar = receivableService.getById(entity.getReceivableId());
            if (ar == null) throw new JeecgBootException("关联应收单不存在");
            BigDecimal unsettled = ar.getUnsettledAmount() != null ? ar.getUnsettledAmount() : ar.getAmount();
            if (entity.getAmount().compareTo(unsettled) > 0) throw new JeecgBootException("收款金额(" + entity.getAmount() + ")超过未结金额(" + unsettled + ")");
            BigDecimal newReceived = (ar.getReceivedAmount() != null ? ar.getReceivedAmount() : BigDecimal.ZERO).add(entity.getAmount());
            ar.setReceivedAmount(newReceived);
            ar.setUnsettledAmount(ar.getAmount().subtract(newReceived));
            ar.setStatus(newReceived.compareTo(BigDecimal.ZERO) > 0 && newReceived.compareTo(ar.getAmount()) < 0 ? "2" : "3");
            if ("3".equals(ar.getStatus())) ar.setSettlementDate(new Date());
            receivableService.updateById(ar);
        }
        return super.save(entity);
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 收款单Service实现-----------
