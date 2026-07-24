//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请行实体-----------
package org.jeecg.modules.mes.purchase.apply.entity;

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
@TableName("c_mes_purchase_apply_item")
@Schema(description = "MES-采购申请行")
public class MesPurchaseApplyItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "申请单ID")
    private String applyId;
    @Schema(description = "行号")
    private Integer lineNo;
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;
    @Schema(description = "申请数量")
    private BigDecimal quantity;
    //update-begin---author:ruisuyun---date:2026-07-23---for: 采购申请明细加单价/金额字段-----------
    @Schema(description = "单价")
    private BigDecimal unitPrice;
    @Schema(description = "金额")
    private BigDecimal amount;
    //update-end---author:ruisuyun---date:2026-07-23---for: 采购申请明细加单价/金额字段-----------
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-申请行加税率-----------
    @Schema(description = "税率")
    private BigDecimal taxRate;
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-申请行加税率-----------
    @Schema(description = "单位")
    private String unit;
    @Schema(description = "用途说明")
    private String purpose;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请行实体-----------
