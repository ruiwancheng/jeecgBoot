//update-begin---author:ruiwancheng---date:2026-07-16---for: P0修复-字段对齐DDL-----------
package org.jeecg.modules.mes.manufacturing.completion.entity;

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
    private String createBy; private Date createTime;
    private String updateBy; private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: P0修复-字段对齐DDL-----------
