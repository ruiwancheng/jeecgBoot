//update-begin---author:admin---date:2026-07-13---for: MES基础设置-库区实体-----------
package org.jeecg.modules.mes.basic.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecgframework.poi.excel.annotation.Excel;
import org.springframework.format.annotation.DateTimeFormat;
import java.io.Serializable;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_zone")
@Schema(description = "MES-库区")
public class MesZone implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @NotNull(message = "所属仓库不能为空")
    @Excel(name = "所属仓库ID", width = 20)
    @Schema(description = "所属仓库ID")
    private String warehouseId;
    @NotBlank(message = "库区编码不能为空")
    @Size(max = 50, message = "库区编码长度不能超过50")
    @Excel(name = "库区编码", width = 15)
    @Schema(description = "库区编码")
    private String code;
    @Size(max = 100, message = "库区名称长度不能超过100")
    @Excel(name = "库区名称", width = 20)
    @Schema(description = "库区名称")
    private String name;
    @Excel(name = "排序号", width = 10)
    @Schema(description = "排序号")
    private Integer sortNo;
    @Excel(name = "状态", width = 10, dicCode = "yn")
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
//update-end---author:admin---date:2026-07-13---for: MES基础设置-库区实体-----------
