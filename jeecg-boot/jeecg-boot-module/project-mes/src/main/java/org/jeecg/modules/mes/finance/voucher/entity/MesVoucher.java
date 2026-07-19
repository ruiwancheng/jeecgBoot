//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证实体-----------
package org.jeecg.modules.mes.finance.voucher.entity;

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
import java.util.List;

@Data @EqualsAndHashCode(callSuper = false) @Accessors(chain = true)
@TableName("c_mes_voucher") @Schema(description = "MES-凭证")
public class MesVoucher implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Excel(name = "凭证号", width = 15) @Schema(description = "凭证号") private String voucherNo;
    @Excel(name = "凭证日期", width = 15) @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") @Schema(description = "凭证日期") private Date voucherDate;
    @Excel(name = "状态", width = 10, dicCode = "mes_voucher_status") @Dict(dicCode = "mes_voucher_status") @Schema(description = "状态") private String status;
    @Excel(name = "来源类型", width = 10, dicCode = "mes_voucher_source") @Dict(dicCode = "mes_voucher_source") @Schema(description = "来源类型") private String sourceType;
    @Schema(description = "来源单据ID") private String sourceBillId;
    @Excel(name = "借方合计", width = 15) @Schema(description = "借方合计") private BigDecimal totalDebit;
    @Excel(name = "贷方合计", width = 15) @Schema(description = "贷方合计") private BigDecimal totalCredit;
    @Excel(name = "摘要", width = 30) @Schema(description = "摘要") private String remark;
    @Schema(description = "创建人") private String createBy; @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy; @Schema(description = "更新时间") private Date updateTime;
    @TableLogic @Schema(description = "删除状态") private Integer delFlag;
    @Schema(description = "凭证明细") private transient List<MesVoucherItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证实体-----------
