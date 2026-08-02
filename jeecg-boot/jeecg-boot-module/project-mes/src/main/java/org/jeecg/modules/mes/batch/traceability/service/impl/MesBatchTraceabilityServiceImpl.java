//update-begin---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-ServiceImpl加批次级聚合查询实现-----------
package org.jeecg.modules.mes.batch.traceability.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceabilityVO;
import org.jeecg.modules.mes.batch.traceability.mapper.MesBatchTraceabilityMapper;
import org.jeecg.modules.mes.batch.traceability.service.IMesBatchTraceabilityService;
import org.springframework.stereotype.Service;

/**
 * 批次追溯视图 ServiceImpl。
 *
 * <p>V10.0.3 改造：实现 {@link IMesBatchTraceabilityService#queryBatchPage}。
 * 列表搜索走 Controller 层 QueryGenerator + BaseMapper 组合（与 ledger/inventory 模块
 * 列表查询保持一致）。</p>
 */
@Service
public class MesBatchTraceabilityServiceImpl
        extends ServiceImpl<MesBatchTraceabilityMapper, MesBatchTraceability>
        implements IMesBatchTraceabilityService {

    @Override
    public IPage<MesBatchTraceabilityVO> queryBatchPage(
            Page<MesBatchTraceabilityVO> page,
            QueryWrapper<MesBatchTraceabilityVO> wrapper) {
        return baseMapper.queryBatchPage(page, wrapper);
    }

    @Override
    public long countBatchMasters() {
        return baseMapper.countBatchMasters();
    }
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-ServiceImpl加批次级聚合查询实现-----------
