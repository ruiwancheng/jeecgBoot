//update-begin---author:admin---date:2026-07-05---for: demo客户-仓库管理实体-----------
package org.jeecg.modules.customer.demo.entity;

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
@TableName("c_demo_warehouse")
@Schema(description = "demo-仓库")
public class DemoWarehouse implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "仓库编码", width = 15)
    @Schema(description = "仓库编码")
    private String code;
    @Excel(name = "仓库名称", width = 15)
    @Schema(description = "仓库名称")
    private String name;
    @Excel(name = "仓库地址", width = 30)
    @Schema(description = "仓库地址")
    private String address;
    @Excel(name = "负责人", width = 15)
    @Schema(description = "负责人")
    private String manager;
    @Excel(name = "联系电话", width = 15)
    @Schema(description = "联系电话")
    private String phone;
    @Excel(name = "状态", width = 10, dicCode = "yn")
    @Dict(dicCode = "yn")
    @Schema(description = "状态")
    private Integer status;
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
