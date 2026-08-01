//update-begin---author:ruiwancheng---date:2026-07-16---for: P0修复-字段对齐DDL-----------
package org.jeecg.modules.mes.manufacturing.completion.entity;

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
@TableName("c_mes_completion_receipt_item")
@Schema(description = "MES-完工入库行")
public class MesCompletionReceiptItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) private String id;
    private String receiptId;
    private Integer lineNo;
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id") private String materialId;
    private BigDecimal planQty;
    private BigDecimal receiptQty;
    //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 生产批次号手工录入模式——明细行加 batchNo + productionDate-----------
    @Schema(description = "生产批次号(手工录入, 总开关+物料开关开启时必填)")
    private String batchNo;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "生产日期(可选)")
    private Date productionDate;
    //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 生产批次号手工录入模式-----------
    private String createBy; private Date createTime;
    private String updateBy; private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: P0修复-字段对齐DDL-----------
