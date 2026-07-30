//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Mapper-----------
package org.jeecg.modules.mes.batch.ledger.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.jeecg.modules.mes.batch.ledger.entity.MesBatchLedger;

import java.util.List;

public interface MesBatchLedgerMapper extends BaseMapper<MesBatchLedger> {
    /**
     * 按批次ID查流水
     */
    List<MesBatchLedger> selectByBatchId(@Param("batchId") String batchId);

    /**
     * 按业务单据查流水（批次追溯用）
     */
    List<MesBatchLedger> selectByBiz(@Param("bizType") String bizType, @Param("bizId") String bizId);
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Mapper-----------
