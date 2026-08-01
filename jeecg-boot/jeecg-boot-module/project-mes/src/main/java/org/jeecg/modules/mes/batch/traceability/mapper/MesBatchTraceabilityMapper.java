//update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-Mapper（复用 c_mes_batch_ledger）-----------
package org.jeecg.modules.mes.batch.traceability.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;

/**
 * 批次追溯视图 Mapper。
 *
 * <p>当前切片（trace-1-list）只暴露列表分页查询，由 Controller 层通过
 * {@code QueryGenerator.initQueryWrapper} + {@code BaseMapper.page()} 组合实现，
 * 后续切片（trace-2-detail / trace-3-export）若需要反查特定业务单据的所有流水，
 * 再补 {@code @Select} 注解方法（参考 MesBatchLedgerMapper.selectByBiz）。</p>
 */
public interface MesBatchTraceabilityMapper extends BaseMapper<MesBatchTraceability> {
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-Mapper（复用 c_mes_batch_ledger）-----------