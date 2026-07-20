//update-begin---author:ruiwancheng---date:2026-07-21  for：【编码规则】新增编码规则实体-----------
package org.jeecg.modules.mes.basic.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecgframework.poi.excel.annotation.Excel;

@Data
@TableName("c_mes_code_rule")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Schema(description = "MES编码规则")
public class MesCodeRule implements java.io.Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键")
    private String id;

    @Excel(name = "规则编码", width = 15)
    @Schema(description = "规则编码")
    private String ruleCode;

    @Excel(name = "规则名称", width = 20)
    @Schema(description = "规则名称")
    private String ruleName;

    @Excel(name = "前缀", width = 10)
    @Schema(description = "前缀")
    private String prefix;

    @Excel(name = "日期格式", width = 12)
    @Schema(description = "日期格式")
    private String dateFormat;

    @Excel(name = "流水号位数", width = 12)
    @Schema(description = "流水号位数")
    private Integer seqLength;

    @Excel(name = "重置周期", width = 12)
    @Schema(description = "重置周期: NONE/DAILY/MONTHLY/YEARLY")
    private String resetCycle;

    @Schema(description = "当前流水号")
    private Integer currentSeq;

    @Schema(description = "当前日期")
    private String currentDate;

    @Excel(name = "备注", width = 20)
    @Schema(description = "备注")
    private String remark;

    @Schema(description = "创建人")
    private String createBy;

    @Schema(description = "创建时间")
    private java.util.Date createTime;

    @Schema(description = "更新人")
    private String updateBy;

    @Schema(description = "更新时间")
    private java.util.Date updateTime;

    @TableLogic
    @Schema(description = "删除标记")
    private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-21  for：【编码规则】新增编码规则实体-----------
