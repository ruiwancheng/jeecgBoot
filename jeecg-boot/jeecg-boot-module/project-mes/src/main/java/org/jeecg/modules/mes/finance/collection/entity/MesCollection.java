//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 收款单实体-----------
package org.jeecg.modules.mes.finance.collection.entity;

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
@TableName("c_mes_collection") @Schema(description = "MES-收款单")
public class MesCollection implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Excel(name = "收款单号", width = 15) @Schema(description = "收款单号") private String code;
    @Excel(name = "客户", width = 20, dictTable = "c_mes_customer", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_customer", dicText = "name", dicCode = "id") @Schema(description = "客户ID") private String customerId;
    @Schema(description = "关联应收单ID") private String receivableId;
    @Excel(name = "收款金额", width = 15) @Schema(description = "收款金额") private BigDecimal amount;
    @Excel(name = "收款日期", width = 15) @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") @Schema(description = "收款日期") private Date collectionDate;
    @Excel(name = "收款方式", width = 10, dicCode = "mes_payment_method") @Dict(dicCode = "mes_payment_method") @Schema(description = "收款方式") private String paymentMethod;
    @Excel(name = "状态", width = 10, dicCode = "yn") @Dict(dicCode = "yn") @Schema(description = "状态") private String status;
    @Excel(name = "备注", width = 30) @Schema(description = "备注") private String remark;
    @Schema(description = "创建人") private String createBy; @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy; @Schema(description = "更新时间") private Date updateTime;
    @TableLogic @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 收款单实体-----------
