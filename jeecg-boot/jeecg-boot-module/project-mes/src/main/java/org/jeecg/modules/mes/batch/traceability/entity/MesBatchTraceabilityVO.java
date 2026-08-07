//update-begin---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-批次级汇总VO（自c_mes_batch+c_mes_batch_ledger聚合）-----------
package org.jeecg.modules.mes.batch.traceability.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;
import org.jeecgframework.poi.excel.annotation.Excel;
import org.springframework.format.annotation.DateTimeFormat;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

/**
 * MES-批次追溯(批次级汇总 VO)。
 *
 * <p>本 VO 是批次追溯"列表视图"的承载实体——由 c_mes_batch（主档）+ c_mes_batch_ledger（流水）
 * LEFT JOIN 后 GROUP BY batch_id 聚合而成。原始设计 V10.0.2 复用 MesBatchTraceability 实体
 * 暴露 ledger 行，导致列表粒度变成"流水级"，用户看不懂。</p>
 *
 * <p>V10.0.3 改造：通过本 VO 暴露批次级 + 聚合字段（totalInQty / totalOutQty / ledgerCount /
 * lastOccurTime），让列表粒度语义清晰。{@code id} 字段语义 = batch_id（与前端 drawer
 * 期望一致，也顺带修复了抽屉"空白"问题——之前 id 字段语义错配）。</p>
 *
 * <p>{@code @Dict} 注解由 DictAspect 反射运行时 class 触发，<b>不依赖 @TableName</b>，
 * 非物理表 VO 也支持。{@code @Excel} 注解支持导出 Excel。</p>
 */
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Schema(description = "MES-批次追溯(批次级汇总)")
public class MesBatchTraceabilityVO implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "批次ID")
    private String id;

    @Excel(name = "批次号", width = 25)
    @Schema(description = "批次号")
    private String batchNo;

    @Dict(dictTable = "c_mes_material", dicText = "code", dicCode = "id")
    @Excel(name = "物料ID", width = 15)
    @Schema(description = "物料ID")
    private String materialId;

    @Dict(dicCode = "mes_batch_origin_type")
    @Excel(name = "来源类型", width = 12)
    @Schema(description = "来源类型(dict:mes_batch_origin_type)")
    private String originType;

    @Excel(name = "来源单据号", width = 20)
    @Schema(description = "来源单据号")
    private String originBillNo;

    @Excel(name = "初始数量", width = 12)
    @Schema(description = "初始批次数量")
    private BigDecimal qty;

    @Excel(name = "生产日期", width = 12, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "生产日期")
    private Date productionDate;

    @Excel(name = "有效期至", width = 12, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "有效期至")
    private Date expiryDate;

    @Excel(name = "批次单位成本", width = 14)
    @Schema(description = "批次单位成本")
    private BigDecimal unitCost;

    @Dict(dicCode = "mes_batch_status")
    @Excel(name = "状态", width = 10)
    @Schema(description = "状态(dict:mes_batch_status)")
    private String status;

    // === 聚合字段（来自 GROUP BY c_mes_batch_ledger） ===

    @Excel(name = "累计入库", width = 12)
    @Schema(description = "累计入库数量")
    private BigDecimal totalInQty;

    @Excel(name = "累计出库", width = 12)
    @Schema(description = "累计出库数量")
    private BigDecimal totalOutQty;

    @Excel(name = "流水条数", width = 10)
    @Schema(description = "流水条数")
    private Integer ledgerCount;

    @Excel(name = "最新发生时间", width = 18, format = "yyyy-MM-dd HH:mm:ss")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "最新发生时间")
    private Date lastOccurTime;
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-批次级汇总VO（自c_mes_batch+c_mes_batch_ledger聚合）-----------
