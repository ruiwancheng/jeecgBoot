//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Service接口-----------
package org.jeecg.modules.mes.batch.inventory.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;

import java.math.BigDecimal;
import java.util.List;

public interface IMesBatchInventoryService extends IService<MesBatchInventory> {
    /**
     * 批次入库：累加指定批次的库存
     */
    void stockIn(String batchId, String warehouseId, BigDecimal qty, String bizType, String bizId, String bizNo);

    /**
     * 批次出库：从最早批次（FIFO）扣减
     * @return 实际出库的批次元组 [(batchId, qty), ...]
     */
    List<BatchOutDetail> stockOutFifo(String materialId, String warehouseId, BigDecimal qty,
                                     String bizType, String bizId, String bizNo);

    /**
     * 出库明细
     */
    record BatchOutDetail(String batchId, String batchNo, BigDecimal qty, BigDecimal unitCost) {}
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Service接口-----------
