//update-begin---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户管理实体-----------
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
@TableName("c_mes_customer")
@Schema(description = "MES-客户")
public class MesCustomer implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "客户编码", width = 15)
    @Schema(description = "客户编码")
    private String code;
    @Excel(name = "客户名称", width = 20)
    @Schema(description = "客户名称")
    private String name;
    @Excel(name = "客户类型", width = 15, dicCode = "mes_customer_type")
    @Dict(dicCode = "mes_customer_type")
    @Schema(description = "客户类型")
    private String type;
    @Excel(name = "联系人", width = 15)
    @Schema(description = "联系人")
    private String contact;
    @Excel(name = "联系电话", width = 15)
    @Schema(description = "联系电话")
    private String phone;
    @Excel(name = "地址", width = 30)
    @Schema(description = "地址")
    private String address;
    @Excel(name = "状态", width = 10, dicCode = "yn")
    @Dict(dicCode = "yn")
    @Schema(description = "状态 1启用 0停用")
    private Integer status;
    @Excel(name = "备注", width = 30)
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间") private Date updateTime;
    @TableLogic
    @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户管理实体-----------
