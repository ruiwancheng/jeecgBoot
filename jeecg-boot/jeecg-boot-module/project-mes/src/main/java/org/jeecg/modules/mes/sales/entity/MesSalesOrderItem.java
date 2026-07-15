//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单行实体-----------
package org.jeecg.modules.mes.sales.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_sales_order_item")
@Schema(description = "MES-销售订单行")
public class MesSalesOrderItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "订单ID")
    private String orderId;
    @Schema(description = "行号")
    private Integer lineNo;
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;
    @Schema(description = "数量")
    private BigDecimal quantity;
    @Schema(description = "单价")
    private BigDecimal unitPrice;
    @Schema(description = "金额")
    private BigDecimal amount;
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单行实体-----------
