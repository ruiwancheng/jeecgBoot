//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人实体-----------
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
import java.io.Serializable;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_customer_contact")
@Schema(description = "MES-客户联系人")
public class MesCustomerContact implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "姓名", width = 15)
    @Schema(description = "姓名")
    private String name;
    @Excel(name = "职务", width = 15)
    @Schema(description = "职务")
    private String title;
    @Excel(name = "手机", width = 15)
    @Schema(description = "手机")
    private String phone;
    @Excel(name = "邮箱", width = 20)
    @Schema(description = "邮箱")
    private String email;
    @Excel(name = "QQ/微信", width = 15)
    @Schema(description = "QQ/微信")
    private String social;
    @Excel(name = "是否默认", width = 10)
    @Schema(description = "是否默认")
    private Integer isDefault;
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
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人实体-----------
