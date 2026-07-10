//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-跟进记录实体-----------
package org.jeecg.modules.mes.basic.entity;

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
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_customer_follow_up")
@Schema(description = "MES-客户跟进记录")
public class MesCustomerFollowUp implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "跟进方式", width = 12, dicCode = "follow_type")
    @Dict(dicCode = "follow_type")
    @Schema(description = "跟进方式")
    private String followType;
    @Excel(name = "跟进日期", width = 15)
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "跟进日期")
    private Date followDate;
    @Excel(name = "跟进内容", width = 30)
    @Schema(description = "跟进内容")
    private String content;
    @Schema(description = "跟进人")
    private String follower;
    @Excel(name = "下次跟进日期", width = 15)
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "下次跟进日期")
    private Date nextDate;
    @Schema(description = "附件路径")
    private String attachment;
    @Excel(name = "备注", width = 20)
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
    @TableLogic
    @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-跟进记录实体-----------
