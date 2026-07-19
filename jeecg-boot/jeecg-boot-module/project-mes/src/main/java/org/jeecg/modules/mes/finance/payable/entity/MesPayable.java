//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应付单实体-----------
package org.jeecg.modules.mes.finance.payable.entity;

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

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_payable")
@Schema(description = "MES-应付单")
public class MesPayable implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Excel(name = "应付单号", width = 15) @Schema(description = "应付单号") private String code;
    @Excel(name = "供应商", width = 20, dictTable = "c_mes_supplier", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_supplier", dicText = "name", dicCode = "id") @Schema(description = "供应商ID") private String supplierId;
    @Schema(description = "来源类型") private String sourceType;
    @Schema(description = "来源单据ID") private String sourceBillId;
    @Excel(name = "来源单据号", width = 15) @Schema(description = "来源单据号") private String sourceBillNo;
    @Excel(name = "应付金额", width = 15) @Schema(description = "应付金额") private BigDecimal amount;
    @Excel(name = "已付金额", width = 15) @Schema(description = "已付金额") private BigDecimal paidAmount;
    @Excel(name = "未付金额", width = 15) @Schema(description = "未付金额") private BigDecimal unsettledAmount;
    @Excel(name = "税额", width = 15) @Schema(description = "税额") private BigDecimal taxAmount;
    @Schema(description = "账期(天)") private Integer creditPeriod;
    @Excel(name = "到期日", width = 15) @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") @Schema(description = "到期日") private Date dueDate;
    @Excel(name = "状态", width = 10, dicCode = "mes_payable_status") @Dict(dicCode = "mes_payable_status") @Schema(description = "状态") private String status;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") @Schema(description = "结清日期") private Date settlementDate;
    @Excel(name = "备注", width = 30) @Schema(description = "备注") private String remark;
    @Schema(description = "创建人") private String createBy; @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy; @Schema(description = "更新时间") private Date updateTime;
    @TableLogic @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应付单实体-----------
