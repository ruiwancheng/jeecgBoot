//update-begin---author:admin---date:2026-07-06---for: MES基础设置-仓库管理实体-----------
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
@TableName("c_mes_warehouse")
@Schema(description = "MES-仓库")
public class MesWarehouse implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "仓库编码", width = 15)
    @Schema(description = "仓库编码")
    private String code;
    @Excel(name = "仓库名称", width = 20)
    @Schema(description = "仓库名称")
    private String name;
    @Excel(name = "仓库类型", width = 15, dicCode = "mes_warehouse_type")
    @Dict(dicCode = "mes_warehouse_type")
    @Schema(description = "仓库类型")
    private String type;
    @Excel(name = "仓库地址", width = 30)
    @Schema(description = "仓库地址")
    private String address;
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
