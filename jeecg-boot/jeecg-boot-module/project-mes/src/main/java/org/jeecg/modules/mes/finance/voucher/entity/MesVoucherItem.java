//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证明细实体-----------
package org.jeecg.modules.mes.finance.voucher.entity;

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

@Data @EqualsAndHashCode(callSuper = false) @Accessors(chain = true)
@TableName("c_mes_voucher_item") @Schema(description = "MES-凭证明细")
public class MesVoucherItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Schema(description = "凭证ID") private String voucherId;
    @Schema(description = "行号") private Integer lineNo;
    @Schema(description = "摘要") private String summary;
    @Dict(dictTable = "c_mes_account_subject", dicText = "name", dicCode = "id") @Schema(description = "科目ID") private String subjectId;
    @Schema(description = "借方金额") private BigDecimal debitAmount;
    @Schema(description = "贷方金额") private BigDecimal creditAmount;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证明细实体-----------
