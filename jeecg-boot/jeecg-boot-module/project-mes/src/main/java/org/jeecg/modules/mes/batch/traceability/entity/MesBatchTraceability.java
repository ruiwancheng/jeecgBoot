//update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-追溯视图实体（复用 c_mes_batch_ledger）-----------
package org.jeecg.modules.mes.batch.traceability.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;
import org.springframework.format.annotation.DateTimeFormat;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

/**
 * MES-批次追溯视图。
 *
 * <p>本实体是批次流水（c_mes_batch_ledger）的"追溯视角"——底层数据复用 ledger，
 * 但作为独立 Entity 暴露，便于未来扩展追溯专有字段（如追溯链层级、关联销售单号等）
 * 而不污染 ledger 模块。列表字段对齐前端 traceability.data.ts 的 columns。</p>
 *
 * <p>当前实现：{@link #bizType} 与 {@code biz_id} 一一对应，可基于此字段关联上游
 * 业务单据（采购入库/完工入库/领料/销售出库）做反向追溯（forward），
 * 详见后续切片 trace-2-detail。</p>
 */
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_batch_ledger")
@Schema(description = "MES-批次追溯")
public class MesBatchTraceability implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;

    @Schema(description = "批次ID")
    private String batchId;

    @Schema(description = "批次号(冗余)")
    private String batchNo;

    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;

    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Schema(description = "仓库ID")
    private String warehouseId;

    @Schema(description = "业务类型(采购入库/生产入库/领料/销售出库)")
    private String bizType;

    @Schema(description = "业务单据ID")
    private String bizId;

    @Schema(description = "业务单据号")
    private String bizNo;

    @Schema(description = "入库数量")
    private BigDecimal inQty;

    @Schema(description = "出库数量")
    private BigDecimal outQty;

    @Schema(description = "批次单位成本")
    private BigDecimal unitCost;

    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "发生时间")
    private Date occurTime;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;

    @TableLogic
    @Schema(description = "删除标记") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-追溯视图实体（复用 c_mes_batch_ledger）-----------