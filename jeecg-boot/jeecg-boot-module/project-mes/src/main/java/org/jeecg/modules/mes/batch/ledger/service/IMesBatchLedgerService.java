//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Service接口-----------
package org.jeecg.modules.mes.batch.ledger.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.batch.ledger.entity.MesBatchLedger;

import java.util.List;

public interface IMesBatchLedgerService extends IService<MesBatchLedger> {
    /**
     * 写流水
     */
    void writeLedger(String batchId, String batchNo, String materialId, String warehouseId,
                     String bizType, String bizId, String bizNo,
                     java.math.BigDecimal inQty, java.math.BigDecimal outQty,
                     java.math.BigDecimal unitCost, String remark);

    /**
     * 按批次ID查流水
     */
    List<MesBatchLedger> listByBatchId(String batchId);

    /**
     * 按业务单据查流水（批次追溯用）
     */
    List<MesBatchLedger> listByBiz(String bizType, String bizId);
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Service接口-----------
