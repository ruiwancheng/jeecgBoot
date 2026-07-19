//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 付款单实体-----------
package org.jeecg.modules.mes.finance.payment.entity;

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

@Data @EqualsAndHashCode(callSuper = false) @Accessors(chain = true)
@TableName("c_mes_payment") @Schema(description = "MES-付款单")
public class MesPayment implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Excel(name = "付款单号", width = 15) @Schema(description = "付款单号") private String code;
    @Excel(name = "供应商", width = 20, dictTable = "c_mes_supplier", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_supplier", dicText = "name", dicCode = "id") @Schema(description = "供应商ID") private String supplierId;
    @Schema(description = "关联应付单ID") private String payableId;
    @Excel(name = "付款金额", width = 15) @Schema(description = "付款金额") private BigDecimal amount;
    @Excel(name = "付款日期", width = 15) @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") @Schema(description = "付款日期") private Date paymentDate;
    @Excel(name = "付款方式", width = 10, dicCode = "mes_payment_method") @Dict(dicCode = "mes_payment_method") @Schema(description = "付款方式") private String paymentMethod;
    @Excel(name = "状态", width = 10, dicCode = "yn") @Dict(dicCode = "yn") @Schema(description = "状态") private String status;
    @Excel(name = "备注", width = 30) @Schema(description = "备注") private String remark;
    @Schema(description = "创建人") private String createBy; @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy; @Schema(description = "更新时间") private Date updateTime;
    @TableLogic @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 付款单实体-----------
