//update-begin---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-Mapper加批次级聚合查询方法-----------
package org.jeecg.modules.mes.batch.traceability.mapper;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Constants;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceabilityVO;

public interface MesBatchTraceabilityMapper extends BaseMapper<MesBatchTraceability> {

    /**
     * 批次级聚合分页查询（V10.0.3 列表改造）。
     *
     * <p>从 c_mes_batch 主档 LEFT JOIN c_mes_batch_ledger 流水聚合，
     * GROUP BY batch_id。LEFT JOIN 保留无流水批次（ledger_count=0 仍展示）。
     * IFNULL 防 NULL 聚合。</p>
     *
     * <p>用 {@code @Select} + {@code <script>} 支持动态 SQL（QueryWrapper 条件）。
     * 默认按 last_occur_time DESC 排序（MySQL NULL 排在最后，业务直觉）。</p>
     */
    @Select("<script>"
            + "SELECT "
            + "    b.id                        AS id, "
            + "    b.batch_no                  AS batch_no, "
            + "    b.material_id               AS material_id, "
            + "    b.origin_type               AS origin_type, "
            + "    b.origin_bill_no            AS origin_bill_no, "
            + "    b.qty                       AS qty, "
            + "    b.production_date           AS production_date, "
            + "    b.expiry_date               AS expiry_date, "
            + "    b.unit_cost                 AS unit_cost, "
            + "    b.status                    AS status, "
            + "    IFNULL(SUM(l.in_qty), 0)    AS total_in_qty, "
            + "    IFNULL(SUM(l.out_qty), 0)   AS total_out_qty, "
            + "    COUNT(l.id)                 AS ledger_count, "
            + "    MAX(l.occur_time)           AS last_occur_time "
            + "FROM c_mes_batch b "
            + "LEFT JOIN c_mes_batch_ledger l "
            + "    ON l.batch_id = b.id AND l.del_flag = 0 "
            + "WHERE b.del_flag = 0 "
            + "<if test=\"ew != null and ew.sqlSegment != null and ew.sqlSegment != ''\">"
            + "    AND ${ew.sqlSegment}"
            + "</if> "
            + "GROUP BY b.id "
            + "ORDER BY last_occur_time DESC"
            + "</script>")
    IPage<MesBatchTraceabilityVO> queryBatchPage(
            Page<MesBatchTraceabilityVO> page,
            @Param(Constants.WRAPPER) QueryWrapper<MesBatchTraceabilityVO> wrapper);

    /**
     * 批次级总数（导出阈值检查用）。
     *
     * <p>COUNT(DISTINCT b.id) 在 c_mes_batch WHERE del_flag=0 情况下等价于直接 COUNT。
     * 之所以用 DISTINCT 是为了和 V10.0.3 聚合语义一致未来扩展时有预留（例如按业务类型筛选时）。</p>
     */
    @Select("SELECT COUNT(DISTINCT id) FROM c_mes_batch WHERE del_flag = 0")
    long countBatchMasters();
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-Mapper加批次级聚合查询方法-----------
