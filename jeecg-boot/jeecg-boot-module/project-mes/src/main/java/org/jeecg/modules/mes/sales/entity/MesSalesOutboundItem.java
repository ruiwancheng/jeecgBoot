//update-begin---author:ruiwancheng---date:2026-07-16---for: MES销售管理-销售出库明细实体-----------
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

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_sales_outbound_item")
@Schema(description = "MES-销售出库明细")
public class MesSalesOutboundItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Schema(description = "出库单ID") private String outboundId;
    @Schema(description = "物料ID")
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    private String materialId;
    @Schema(description = "发货数量") private BigDecimal deliveryQty;
    @Schema(description = "实出数量") private BigDecimal actualQty;
    @Schema(description = "批次") private String batch;
    @Schema(description = "库位") private String location;
    @Schema(description = "备注") private String remark;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private java.util.Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private java.util.Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES销售管理-销售出库明细实体-----------
