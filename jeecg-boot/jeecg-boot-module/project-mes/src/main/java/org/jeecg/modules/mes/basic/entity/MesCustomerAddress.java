//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址实体-----------
package org.jeecg.modules.mes.basic.entity;

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

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_customer_address")
@Schema(description = "MES-客户地址")
public class MesCustomerAddress implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "地址类型", width = 12, dicCode = "address_type")
    @Dict(dicCode = "address_type")
    @Schema(description = "地址类型")
    private String addressType;
    @Excel(name = "联系人", width = 15)
    @Schema(description = "联系人")
    private String contact;
    @Excel(name = "联系电话", width = 15)
    @Schema(description = "联系电话")
    private String phone;
    @Schema(description = "省") private String province;
    @Schema(description = "市") private String city;
    @Schema(description = "区") private String district;
    @Excel(name = "详细地址", width = 30)
    @Schema(description = "详细地址")
    private String detail;
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
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址实体-----------
