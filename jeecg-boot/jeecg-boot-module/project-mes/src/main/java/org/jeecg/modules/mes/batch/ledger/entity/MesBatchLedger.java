//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水实体-----------
package org.jeecg.modules.mes.batch.ledger.entity;

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

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_batch_ledger")
@Schema(description = "MES-批次流水")
public class MesBatchLedger implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;

    @Schema(description = "批次ID")
    private String batchId;

    @Schema(description = "批次号(冗余)")
    private String batchNo;

    @Dict(dictTable = "c_mes_material", dicText = "code", dicCode = "id")
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
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水实体-----------
