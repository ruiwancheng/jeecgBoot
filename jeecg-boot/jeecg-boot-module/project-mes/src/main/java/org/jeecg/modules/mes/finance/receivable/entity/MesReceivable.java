//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应收单实体-----------
package org.jeecg.modules.mes.finance.receivable.entity;

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
@TableName("c_mes_receivable")
@Schema(description = "MES-应收单")
public class MesReceivable implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Excel(name = "应收单号", width = 15) @Schema(description = "应收单号") private String code;
    @Excel(name = "客户", width = 20, dictTable = "c_mes_customer", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_customer", dicText = "name", dicCode = "id") @Schema(description = "客户ID") private String customerId;
    @Schema(description = "来源类型") private String sourceType;
    @Schema(description = "来源单据ID") private String sourceBillId;
    @Excel(name = "来源单据号", width = 15) @Schema(description = "来源单据号") private String sourceBillNo;
    @Excel(name = "应收金额", width = 15) @Schema(description = "应收金额") private BigDecimal amount;
    @Excel(name = "已收金额", width = 15) @Schema(description = "已收金额") private BigDecimal receivedAmount;
    @Excel(name = "未结金额", width = 15) @Schema(description = "未结金额") private BigDecimal unsettledAmount;
    @Schema(description = "账期(天)") private Integer creditPeriod;
    @Excel(name = "到期日", width = 15) @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") @Schema(description = "到期日") private Date dueDate;
    @Excel(name = "状态", width = 10, dicCode = "mes_receivable_status") @Dict(dicCode = "mes_receivable_status") @Schema(description = "状态") private String status;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") @Schema(description = "结清日期") private Date settlementDate;
    @Excel(name = "备注", width = 30) @Schema(description = "备注") private String remark;
    @Schema(description = "创建人") private String createBy; @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy; @Schema(description = "更新时间") private Date updateTime;
    @TableLogic @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应收单实体-----------
