//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料单实体-----------
package org.jeecg.modules.mes.manufacturing.picking.entity;

import com.baomidou.mybatisplus.annotation.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecgframework.poi.excel.annotation.Excel;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Data
@TableName("mes_production_picking")
@Accessors(chain = true)
@EqualsAndHashCode(callSuper = false)
@Schema(description = "生产领料单")
public class MesProductionPicking implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键")
    private String id;

    @Excel(name = "领料单号", width = 20)
    @Schema(description = "领料单号")
    private String code;

    @Excel(name = "生产订单号", width = 20)
    @Schema(description = "生产订单ID")
    private String productionOrderId;

    @Excel(name = "生产订单号", width = 20)
    @Schema(description = "生产订单号")
    private String productionOrderCode;

    @Excel(name = "仓库ID", width = 20)
    @Schema(description = "仓库ID")
    private String warehouseId;

    @Excel(name = "仓库", width = 20)
    @Schema(description = "仓库名称")
    private String warehouseName;

    @Excel(name = "状态", width = 15, dicCode = "yn")
    @Schema(description = "状态：1-草稿")
    private String status;

    @Excel(name = "领料日期", width = 20, format = "yyyy-MM-dd")
    @Schema(description = "领料日期")
    private Date pickDate;

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

    @TableField(exist = false)
    @Schema(description = "领料明细")
    private List<MesProductionPickingItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料单实体-----------
