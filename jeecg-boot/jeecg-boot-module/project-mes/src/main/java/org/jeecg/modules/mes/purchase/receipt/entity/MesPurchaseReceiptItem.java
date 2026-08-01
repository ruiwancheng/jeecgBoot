//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库行实体-----------
package org.jeecg.modules.mes.purchase.receipt.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;
import org.springframework.format.annotation.DateTimeFormat;

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
    //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-01 采购入库金额字段-----------
    @Schema(description = "单价(不含税)") private BigDecimal unitPrice;
    @Schema(description = "金额") private BigDecimal amount;
    //update-end---author:ruiwancheng---date:2026-07-19---for: P0-01 采购入库金额字段-----------
    //update-begin---author:ruiwancheng---date:20260803---for: V10.0.1 入库明细税率字段（前端表单+Service 透传，audit 时落库存/应付税额）-----------
    @Schema(description = "税率(0~1,如0.13=13%)") private BigDecimal taxRate;
    //update-end---author:ruiwancheng---date:20260803---for: V10.0.1 入库明细税率字段-----------
    @Dict(dicCode = "mes_qc_result")
    @Schema(description = "质检结果")
    private String qcResult;
    //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 生产批次号手工录入模式——明细行加 batchNo + productionDate-----------
    @Schema(description = "生产批次号(手工录入, 总开关+物料开关开启时必填)")
    private String batchNo;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "生产日期(可选)")
    private Date productionDate;
    //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 生产批次号手工录入模式-----------
    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细增加保质期与有效期至-----------
    @Schema(description = "保质期(天,可空)")
    private Integer shelfLife;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "有效期至(可空)")
    private Date expiryDate;
    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细增加保质期与有效期至-----------
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库行实体-----------
