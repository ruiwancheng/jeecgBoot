//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档ServiceImpl-----------
package org.jeecg.modules.mes.batch.master.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.jeecg.modules.mes.batch.ledger.service.IMesBatchLedgerService;
import org.jeecg.modules.mes.batch.master.entity.MesBatch;
import org.jeecg.modules.mes.batch.master.mapper.MesBatchMapper;
import org.jeecg.modules.mes.batch.master.service.IMesBatchService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.Date;

@Service
public class MesBatchServiceImpl extends ServiceImpl<MesBatchMapper, MesBatch> implements IMesBatchService {

    @Autowired private IMesBatchInventoryService inventoryService;
    @Autowired private IMesBatchLedgerService ledgerService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String createBatch(String materialId, String originType, String originBillId, String originBillNo,
                              BigDecimal qty, BigDecimal unitCost, Date productionDate, Date expiryDate) {
        // 1. 生成批次号 BT-{物料编码前6位}-{YYYYMMDD}-{当日序号}
        String prefix = "BT-" + (materialId != null ? materialId.substring(0, Math.min(6, materialId.length())) : "X") + "-";
        String date = new SimpleDateFormat("yyyyMMdd").format(new Date());
        QueryWrapper<MesBatch> seqQw = new QueryWrapper<>();
        seqQw.likeRight("batch_no", prefix + date);
        long seq = this.count(seqQw) + 1;
        String batchNo = prefix + date + String.format("%04d", seq);

        // 2. 写主档
        MesBatch batch = new MesBatch();
        batch.setBatchNo(batchNo)
             .setMaterialId(materialId)
             .setOriginType(originType)
             .setOriginBillId(originBillId)
             .setOriginBillNo(originBillNo)
             .setQty(qty)
             .setUnitCost(unitCost)
             .setProductionDate(productionDate)
             .setExpiryDate(expiryDate)
             .setStatus("1");
        this.save(batch);

        // 3. 同步写流水（在用=1）
        ledgerService.writeLedger(batch.getId(), batchNo, materialId, null,
            originType, originBillId, originBillNo, qty, BigDecimal.ZERO, unitCost, "批次创建");
        return batch.getId();
    }

    @Override
    public void freeze(String id, String operator) {
        MesBatch b = this.getById(id);
        if (b == null) throw new JeecgBootException("批次不存在");
        if ("3".equals(b.getStatus())) throw new JeecgBootException("已耗尽的批次不能冻结");
        b.setStatus("2");
        this.updateById(b);
    }

    @Override
    public void unfreeze(String id, String operator) {
        MesBatch b = this.getById(id);
        if (b == null) throw new JeecgBootException("批次不存在");
        b.setStatus("1");
        this.updateById(b);
    }
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档ServiceImpl-----------
