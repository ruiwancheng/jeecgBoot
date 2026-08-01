//update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-ServiceImpl（复用 c_mes_batch_ledger）-----------
package org.jeecg.modules.mes.batch.traceability.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;
import org.jeecg.modules.mes.batch.traceability.mapper.MesBatchTraceabilityMapper;
import org.jeecg.modules.mes.batch.traceability.service.IMesBatchTraceabilityService;
import org.springframework.stereotype.Service;

/**
 * 批次追溯视图 ServiceImpl。
 *
 * <p>当前切片（trace-1-list）只透传 BaseMapper 的 CRUD；列表搜索由 Controller 层
 * 通过 {@code QueryGenerator.initQueryWrapper} 直接驱动 {@code baseMapper.page}。
 * 后续切片（trace-2-detail / trace-3-export）按需补具体业务方法。</p>
 */
@Service
public class MesBatchTraceabilityServiceImpl
        extends ServiceImpl<MesBatchTraceabilityMapper, MesBatchTraceability>
        implements IMesBatchTraceabilityService {
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-ServiceImpl（复用 c_mes_batch_ledger）-----------