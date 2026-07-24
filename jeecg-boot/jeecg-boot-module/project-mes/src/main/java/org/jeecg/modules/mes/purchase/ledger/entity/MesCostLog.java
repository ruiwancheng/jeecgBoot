//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-成本变动日志实体-----------
package org.jeecg.modules.mes.purchase.ledger.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_cost_log")
@Schema(description = "MES-成本变动日志")
public class MesCostLog implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "物料ID")
    private String materialId;
    @Schema(description = "仓库ID")
    private String warehouseId;
    @Schema(description = "业务类型")
    private String bizType;
    @Schema(description = "业务单号")
    private String bizId;
    @Schema(description = "变动数量")
    private BigDecimal qty;
    @Schema(description = "单位成本")
    private BigDecimal unitCost;
    @Schema(description = "金额")
    private BigDecimal amount;
    @Schema(description = "变动前移动平均成本")
    private BigDecimal costBefore;
    @Schema(description = "变动后移动平均成本")
    private BigDecimal costAfter;
    @Schema(description = "变动前库存总数量")
    private BigDecimal qtyBefore;
    @Schema(description = "变动后库存总数量")
    private BigDecimal qtyAfter;
    @Schema(description = "创建人")
    private String createBy;
    @Schema(description = "创建时间")
    private Date createTime;
}
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-成本变动日志实体-----------
