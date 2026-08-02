//update-begin---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-Service接口加批次级聚合查询方法-----------
package org.jeecg.modules.mes.batch.traceability.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceabilityVO;

/**
 * 批次追溯视图 Service 接口。
 *
 * <p>V10.0.3 改造：新增批次级聚合查询方法 {@link #queryBatchPage}。
 * 旧方法（继承自 IService 的基础 CRUD）保留——后续 detail/export 端点可能用到。</p>
 */
public interface IMesBatchTraceabilityService extends IService<MesBatchTraceability> {

    /**
     * 批次级聚合分页查询（V10.0.3 列表改造）。
     *
     * <p>聚合自 c_mes_batch + c_mes_batch_ledger，详见
     * {@link org.jeecg.modules.mes.batch.traceability.mapper.MesBatchTraceabilityMapper#queryBatchPage}。</p>
     *
     * @param page    分页对象（pageSize=Integer.MAX_VALUE 时全表聚合）
     * @param wrapper 搜索条件（QueryGenerator.initQueryWrapper 转出）
     * @return 批次级汇总列表
     */
    IPage<MesBatchTraceabilityVO> queryBatchPage(
            Page<MesBatchTraceabilityVO> page,
            QueryWrapper<MesBatchTraceabilityVO> wrapper);

    /**
     * 批次级总数（导出阈值检查）。
     */
    long countBatchMasters();
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-Service接口加批次级聚合查询方法-----------
