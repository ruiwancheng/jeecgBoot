//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库实体-----------
package org.jeecg.modules.mes.sales.entity;

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
import org.jeecgframework.poi.excel.annotation.Excel;
import org.springframework.format.annotation.DateTimeFormat;

import java.io.Serializable;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_sales_outbound")
@Schema(description = "MES-销售出库单")
public class MesSalesOutbound implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "出库单编码", width = 15)
    @Schema(description = "出库单编码")
    private String code;
    @Excel(name = "发货单", width = 20, dictTable = "c_mes_delivery_note", dicText = "code", dicCode = "id")
    @Dict(dictTable = "c_mes_delivery_note", dicText = "code", dicCode = "id")
    @Schema(description = "关联发货单ID")
    private String deliveryNoteId;
    @Excel(name = "销售订单", width = 20, dictTable = "c_mes_sales_order", dicText = "code", dicCode = "id")
    @Dict(dictTable = "c_mes_sales_order", dicText = "code", dicCode = "id")
    @Schema(description = "关联销售订单ID")
    private String salesOrderId;
    @Excel(name = "仓库", width = 15, dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Schema(description = "出库仓库ID")
    private String warehouseId;
    @Schema(description = "客户ID(冗余)")
    private String customerId;
    @Excel(name = "出库日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "出库日期")
    private Date outboundDate;
    @Excel(name = "状态", width = 10, dicCode = "mes_outbound_status")
    @Dict(dicCode = "mes_outbound_status")
    @Schema(description = "状态:1草稿 2待审核 3已审核 0已取消")
    private String status;
    @Excel(name = "备注", width = 30)
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间") private Date updateTime;
    @TableLogic
    @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库实体-----------
