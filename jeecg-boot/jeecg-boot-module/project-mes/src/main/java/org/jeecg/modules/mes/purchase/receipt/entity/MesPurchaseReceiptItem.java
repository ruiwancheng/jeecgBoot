//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库行实体-----------
package org.jeecg.modules.mes.purchase.receipt.entity;

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
@TableName("c_mes_purchase_receipt_item")
@Schema(description = "MES-采购入库行")
public class MesPurchaseReceiptItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "入库单ID")
    private String receiptId;
    @Schema(description = "行号")
    private Integer lineNo;
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;
    @Schema(description = "采购数量")
    private BigDecimal orderQuantity;
    @Schema(description = "本次入库数量")
    private BigDecimal receiptQuantity;
    @Dict(dicCode = "mes_qc_result")
    @Schema(description = "质检结果")
    private String qcResult;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库行实体-----------
