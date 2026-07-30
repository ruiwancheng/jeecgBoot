//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水ServiceImpl-----------
package org.jeecg.modules.mes.batch.ledger.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.modules.mes.batch.ledger.entity.MesBatchLedger;
import org.jeecg.modules.mes.batch.ledger.mapper.MesBatchLedgerMapper;
import org.jeecg.modules.mes.batch.ledger.service.IMesBatchLedgerService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Service
public class MesBatchLedgerServiceImpl extends ServiceImpl<MesBatchLedgerMapper, MesBatchLedger> implements IMesBatchLedgerService {

    @Override
    public void writeLedger(String batchId, String batchNo, String materialId, String warehouseId,
                             String bizType, String bizId, String bizNo,
                             BigDecimal inQty, BigDecimal outQty,
                             BigDecimal unitCost, String remark) {
        MesBatchLedger entry = new MesBatchLedger();
        entry.setBatchId(batchId)
             .setBatchNo(batchNo)
             .setMaterialId(materialId)
             .setWarehouseId(warehouseId)
             .setBizType(bizType)
             .setBizId(bizId)
             .setBizNo(bizNo)
             .setInQty(inQty != null ? inQty : BigDecimal.ZERO)
             .setOutQty(outQty != null ? outQty : BigDecimal.ZERO)
             .setUnitCost(unitCost != null ? unitCost : BigDecimal.ZERO)
             .setOccurTime(new Date())
             .setRemark(remark);
        this.save(entry);
    }

    @Override
    public List<MesBatchLedger> listByBatchId(String batchId) {
        QueryWrapper<MesBatchLedger> qw = new QueryWrapper<>();
        qw.eq("batch_id", batchId).orderByDesc("occur_time");
        return this.list(qw);
    }

    @Override
    public List<MesBatchLedger> listByBiz(String bizType, String bizId) {
        return baseMapper.selectByBiz(bizType, bizId);
    }
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水ServiceImpl-----------
