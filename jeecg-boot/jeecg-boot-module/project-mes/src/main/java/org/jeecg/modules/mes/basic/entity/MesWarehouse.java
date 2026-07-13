//update-begin---author:admin---date:2026-07-06---for: MES基础设置-仓库管理实体-----------
package org.jeecg.modules.mes.basic.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
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
@TableName("c_mes_warehouse")
@Schema(description = "MES-仓库")
public class MesWarehouse implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @NotBlank(message = "仓库编码不能为空")
    @Size(max = 50, message = "仓库编码长度不能超过50")
    @Excel(name = "仓库编码", width = 15)
    @Schema(description = "仓库编码")
    private String code;
    @NotBlank(message = "仓库名称不能为空")
    @Size(max = 100, message = "仓库名称长度不能超过100")
    @Excel(name = "仓库名称", width = 20)
    @Schema(description = "仓库名称")
    private String name;
    @Excel(name = "仓库类型", width = 15, dicCode = "mes_warehouse_type")
    @Dict(dicCode = "mes_warehouse_type")
    @Schema(description = "仓库类型")
    private String type;
    @Size(max = 300, message = "仓库地址长度不能超过300")
    @Excel(name = "仓库地址", width = 30)
    @Schema(description = "仓库地址")
    private String address;
    @Size(max = 50, message = "负责人长度不能超过50")
    @Excel(name = "负责人", width = 15)
    @Schema(description = "负责人")
    private String manager;
    @Size(max = 20, message = "联系电话长度不能超过20")
    @Excel(name = "联系电话", width = 15)
    @Schema(description = "联系电话")
    private String phone;
    @Excel(name = "所属工厂", width = 15)
    @Schema(description = "所属工厂")
    private String factory;
    @Excel(name = "所属车间", width = 15)
    @Schema(description = "所属车间")
    private String workshop;
    @Excel(name = "状态", width = 10, dicCode = "yn")
    @Dict(dicCode = "yn")
    @Schema(description = "状态 1启用 0停用")
    private Integer status;
    @Size(max = 500, message = "备注长度不能超过500")
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
//update-end---author:admin---date:2026-07-06---for: MES基础设置-仓库管理实体-----------
