//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目实体-----------
package org.jeecg.modules.mes.finance.subject.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;
import org.jeecgframework.poi.excel.annotation.Excel;

import java.io.Serializable;
import java.util.Date;
import java.util.List;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_account_subject")
@Schema(description = "MES-会计科目")
public class MesAccountSubject implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) @Schema(description = "id") private String id;
    @Excel(name = "科目编码", width = 15) @Schema(description = "科目编码") private String code;
    @Excel(name = "科目名称", width = 30) @Schema(description = "科目名称") private String name;
    @Excel(name = "科目类别", width = 15, dicCode = "mes_subject_category") @Dict(dicCode = "mes_subject_category") @Schema(description = "科目类别") private String category;
    @Schema(description = "科目级别") private Integer level;
    @Schema(description = "上级科目ID") private String parentId;
    @Excel(name = "余额方向", width = 10, dicCode = "mes_balance_direction") @Dict(dicCode = "mes_balance_direction") @Schema(description = "余额方向") private String balanceDirection;
    @Excel(name = "状态", width = 10, dicCode = "yn") @Dict(dicCode = "yn") @Schema(description = "状态") private String status;
    @Schema(description = "是否叶子科目") private Integer isLeaf;
    @Excel(name = "备注", width = 30) @Schema(description = "备注") private String remark;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
    @TableLogic @Schema(description = "删除状态") private Integer delFlag;
    @Schema(description = "子科目") private transient List<MesAccountSubject> children;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目实体-----------
