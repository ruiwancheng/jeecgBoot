//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库明细实体-----------
package org.jeecg.modules.mes.manufacturing.completion.entity;

import com.baomidou.mybatisplus.annotation.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecgframework.poi.excel.annotation.Excel;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@TableName("mes_completion_receipt_item")
@Accessors(chain = true)
@EqualsAndHashCode(callSuper = false)
@Schema(description = "完工入库明细")
public class MesCompletionReceiptItem implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键")
    private String id;

    @Schema(description = "入库单ID")
    private String receiptId;

    @Excel(name = "物料ID", width = 20)
    @Schema(description = "物料ID")
    private String materialId;

    @Excel(name = "物料编码", width = 20)
    @Schema(description = "物料编码")
    private String materialCode;

    @Excel(name = "物料名称", width = 20)
    @Schema(description = "物料名称")
    private String materialName;

    @Excel(name = "入库数量", width = 15)
    @Schema(description = "入库数量")
    private BigDecimal receiptQty;

    @Excel(name = "单位", width = 15)
    @Schema(description = "单位ID")
    private String unitId;

    @Schema(description = "行号")
    private Integer lineNo;

    @Excel(name = "备注", width = 30)
    @Schema(description = "备注")
    private String remark;

    @Schema(description = "创建人")
    private String createBy;

    @Schema(description = "创建时间")
    private Date createTime;

    @Schema(description = "更新人")
    private String updateBy;

    @Schema(description = "更新时间")
    private Date updateTime;

    @TableLogic
    @Schema(description = "删除标记")
    private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库明细实体-----------
