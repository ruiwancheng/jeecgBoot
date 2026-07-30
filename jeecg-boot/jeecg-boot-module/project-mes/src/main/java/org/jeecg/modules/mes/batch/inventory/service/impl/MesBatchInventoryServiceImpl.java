//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存ServiceImpl-----------
package org.jeecg.modules.mes.batch.inventory.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;
import org.jeecg.modules.mes.batch.inventory.mapper.MesBatchInventoryMapper;
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.jeecg.modules.mes.batch.ledger.service.IMesBatchLedgerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class MesBatchInventoryServiceImpl extends ServiceImpl<MesBatchInventoryMapper, MesBatchInventory> implements IMesBatchInventoryService {

    @Autowired private IMesBatchLedgerService ledgerService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void stockIn(String batchId, String warehouseId, BigDecimal qty, String bizType, String bizId, String bizNo) {
        // 1. 累加批次库存（同 batch+warehouse）
        QueryWrapper<MesBatchInventory> qw = new QueryWrapper<>();
        qw.eq("batch_id", batchId).eq("warehouse_id", warehouseId).eq("del_flag", 0);
        MesBatchInventory inv = this.getOne(qw);
        if (inv == null) {
            inv = new MesBatchInventory();
            inv.setBatchId(batchId).setWarehouseId(warehouseId).setQty(BigDecimal.ZERO);
            this.save(inv);
        }
        inv.setQty(inv.getQty().add(qty));
        this.updateById(inv);

        // 2. 写流水
        ledgerService.writeLedger(batchId, inv.getBatchNo(), inv.getMaterialId(), warehouseId,
            bizType, bizId, bizNo, qty, BigDecimal.ZERO, inv.getUnitCost(), "批次入库");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<BatchOutDetail> stockOutFifo(String materialId, String warehouseId, BigDecimal qty,
                                             String bizType, String bizId, String bizNo) {
        // 1. FIFO 拉取（按创建时间升序）
        List<MesBatchInventory> invs = baseMapper.selectFifoByMaterial(materialId, warehouseId);
        BigDecimal remaining = qty;
        List<BatchOutDetail> outDetails = new ArrayList<>();
        for (MesBatchInventory inv : invs) {
            if (remaining.compareTo(BigDecimal.ZERO) <= 0) break;
            BigDecimal available = inv.getQty();
            if (available.compareTo(BigDecimal.ZERO) <= 0) continue;
            BigDecimal outQty = remaining.min(available);
            inv.setQty(available.subtract(outQty));
            this.updateById(inv);
            remaining = remaining.subtract(outQty);
            outDetails.add(new BatchOutDetail(inv.getBatchId(), inv.getBatchNo(), outQty, inv.getUnitCost()));
            // 写流水
            ledgerService.writeLedger(inv.getBatchId(), inv.getBatchNo(), inv.getMaterialId(), warehouseId,
                bizType, bizId, bizNo, BigDecimal.ZERO, outQty, inv.getUnitCost(), "批次出库");
        }
        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            throw new JeecgBootException("批次库存不足：缺 " + remaining);
        }
        return outDetails;
    }
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存ServiceImpl-----------
