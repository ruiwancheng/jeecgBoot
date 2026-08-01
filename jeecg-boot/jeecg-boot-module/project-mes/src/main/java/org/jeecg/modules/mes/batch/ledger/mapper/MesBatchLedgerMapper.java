//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Mapper-----------
package org.jeecg.modules.mes.batch.ledger.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.jeecg.modules.mes.batch.ledger.entity.MesBatchLedger;

import java.util.List;

public interface MesBatchLedgerMapper extends BaseMapper<MesBatchLedger> {
    //update-begin---author:ruiwancheng---date:2026-07-31---for: P0-2 铁拳团-LedgerMapper补@Select注解（无SQL实现→运行时BindingException）-----------
    /**
     * 按批次ID查流水
     */
    @Select("SELECT * FROM c_mes_batch_ledger " +
            "WHERE batch_id = #{batchId} AND del_flag = 0 " +
            "ORDER BY occur_time DESC")
    List<MesBatchLedger> selectByBatchId(@Param("batchId") String batchId);

    /**
     * 按业务单据查流水（批次追溯用）
     */
    @Select("SELECT * FROM c_mes_batch_ledger " +
            "WHERE biz_type = #{bizType} AND biz_id = #{bizId} AND del_flag = 0 " +
            "ORDER BY occur_time DESC")
    List<MesBatchLedger> selectByBiz(@Param("bizType") String bizType, @Param("bizId") String bizId);
    //update-end---author:ruiwancheng---date:2026-07-31---for: P0-2 铁拳团-LedgerMapper补@Select注解-----------
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Mapper-----------
