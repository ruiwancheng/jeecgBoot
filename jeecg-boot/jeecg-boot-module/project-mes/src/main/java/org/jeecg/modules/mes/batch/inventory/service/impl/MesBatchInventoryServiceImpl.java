//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存ServiceImpl-----------
package org.jeecg.modules.mes.batch.inventory.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;
import org.jeecg.modules.mes.batch.inventory.mapper.MesBatchInventoryMapper;
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.jeecg.modules.mes.batch.ledger.service.IMesBatchLedgerService;
import org.jeecg.modules.mes.batch.master.mapper.MesBatchMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class MesBatchInventoryServiceImpl extends ServiceImpl<MesBatchInventoryMapper, MesBatchInventory> implements IMesBatchInventoryService {

    @Autowired private IMesBatchLedgerService ledgerService;
    @Autowired private MesBatchMapper batchMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void stockIn(String batchId, String warehouseId, BigDecimal qty, String bizType, String bizId, String bizNo) {
        // 1. 累加批次库存（同 batch+warehouse）
        //update-begin---author:ruiwancheng---date:2026-07-31---for: V8.0.0.2 MES批次管理-stockIn使用批次库存行锁-----------
        MesBatchInventory inv = baseMapper.selectForUpdate(batchId, warehouseId);
        //update-end---author:ruiwancheng---date:2026-07-31---for: V8.0.0.2 MES批次管理-stockIn使用批次库存行锁-----------
        if (inv == null) {
            inv = new MesBatchInventory();
            //update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-stockIn补batchNo（避免NOT NULL报错）-----------
            // 从主档同步 batchNo/materialId（避免 NOT NULL 报错）
            org.jeecg.modules.mes.batch.master.entity.MesBatch batch = batchMapper.selectById(batchId);
            if (batch != null) {
                inv.setBatchNo(batch.getBatchNo())
                   .setMaterialId(batch.getMaterialId())
                   .setUnitCost(batch.getUnitCost());
            }
            //update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-stockIn补batchNo-----------
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
        // 1. FIFO 拉取（按创建时间升序，并在当前事务内锁定待扣减行）
        //update-begin---author:ruiwancheng---date:2026-07-31---for: V8.0.0.3 MES批次管理-stockOutFifo使用批次库存行锁-----------
        List<MesBatchInventory> invs = baseMapper.selectFifoByMaterialForUpdate(materialId, warehouseId);
        //update-end---author:ruiwancheng---date:2026-07-31---for: V8.0.0.3 MES批次管理-stockOutFifo使用批次库存行锁-----------
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
