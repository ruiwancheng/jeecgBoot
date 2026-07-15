//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单实体-----------
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
import java.util.List;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_delivery_note")
@Schema(description = "MES-发货单")
public class MesDeliveryNote implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "发货单编码", width = 15)
    @Schema(description = "发货单编码")
    private String code;
    @Excel(name = "销售订单", width = 20, dictTable = "c_mes_sales_order", dicText = "code", dicCode = "id")
    @Dict(dictTable = "c_mes_sales_order", dicText = "code", dicCode = "id")
    @Schema(description = "销售订单ID")
    private String salesOrderId;
    @Excel(name = "仓库", width = 15, dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Schema(description = "发货仓库ID")
    private String warehouseId;
    @Schema(description = "客户ID(冗余)")
    private String customerId;
    @Excel(name = "发货日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "发货日期")
    private Date deliveryDate;
    @Excel(name = "状态", width = 10, dicCode = "mes_delivery_status")
    @Dict(dicCode = "mes_delivery_status")
    @Schema(description = "状态:1草稿 2待出库 3已出库 4已签收 0已取消")
    private String status;
    @Excel(name = "物流公司", width = 15)
    @Schema(description = "物流公司")
    private String logisticsCompany;
    @Excel(name = "运单号", width = 20)
    @Schema(description = "运单号")
    private String trackingNo;
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

    @Schema(description = "发货明细")
    private transient List<MesDeliveryNoteItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单实体-----------
