//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单实体-----------
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
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_sales_order")
@Schema(description = "MES-销售订单")
public class MesSalesOrder implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "订单编码", width = 15)
    @Schema(description = "订单编码")
    private String code;
    @Excel(name = "客户", width = 20, dictTable = "c_mes_customer", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_customer", dicText = "name", dicCode = "id")
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "订单日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "订单日期")
    private Date orderDate;
    @Excel(name = "交货日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "交货日期")
    private Date deliveryDate;
    @Excel(name = "订单状态", width = 12, dicCode = "mes_order_status")
    @Dict(dicCode = "mes_order_status")
    @Schema(description = "订单状态")
    private String status;
    @Excel(name = "总金额", width = 15)
    @Schema(description = "订单总金额")
    private BigDecimal totalAmount;
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

    @Schema(description = "订单行列表")
    private transient List<MesSalesOrderItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单实体-----------
