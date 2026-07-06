//update-begin---author:admin---date:2026-07-05---for: demo客户-库位明细实体-----------
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
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_demo_warehouse_location")
@Schema(description = "demo-库位明细")
public class DemoWarehouseLocation implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "所属仓库", width = 15)
    @Schema(description = "所属仓库ID")
    private String warehouseId;
    @Excel(name = "库位编码", width = 15)
    @Schema(description = "库位编码")
    private String code;
    @Excel(name = "库位类型", width = 10, dicCode = "demo_location_type")
    @Dict(dicCode = "demo_location_type")
    @Schema(description = "库位类型")
    private String locationType;
    @Excel(name = "容量", width = 10)
    @Schema(description = "容量")
    private BigDecimal capacity;
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
