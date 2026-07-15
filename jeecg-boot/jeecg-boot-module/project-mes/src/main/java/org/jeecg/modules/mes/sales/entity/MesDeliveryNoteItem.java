//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单明细实体-----------
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
@TableName("c_mes_delivery_note_item")
@Schema(description = "MES-发货单明细")
public class MesDeliveryNoteItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "发货单ID")
    private String deliveryId;
    @Schema(description = "订单明细ID")
    private String salesOrderItemId;
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;
    @Schema(description = "订单数量")
    private BigDecimal orderedQty;
    @Schema(description = "本次发货数量")
    private BigDecimal deliveryQty;
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private java.util.Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private java.util.Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单明细实体-----------
