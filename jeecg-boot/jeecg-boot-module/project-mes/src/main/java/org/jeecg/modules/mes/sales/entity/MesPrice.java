//update-begin---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格管理实体-----------
package org.jeecg.modules.mes.sales.entity;

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
@TableName("c_mes_price")
@Schema(description = "MES-价格管理")
public class MesPrice implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "价格编码", width = 15)
    @Schema(description = "价格编码")
    private String code;
    @Excel(name = "物料名称", width = 20)
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;
    @Excel(name = "客户名称", width = 20)
    @Dict(dictTable = "c_mes_customer", dicText = "name", dicCode = "id")
    @Schema(description = "客户ID(空=标准售价)")
    private String customerId;
    @Excel(name = "价格", width = 15)
    @Schema(description = "价格")
    private BigDecimal price;
    @Excel(name = "价格类型", width = 15, dicCode = "mes_price_type")
    @Dict(dicCode = "mes_price_type")
    @Schema(description = "价格类型")
    private String type;
    @Excel(name = "生效日期", width = 15)
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "生效日期")
    private Date beginDate;
    @Excel(name = "失效日期", width = 15)
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "失效日期")
    private Date endDate;
    @Excel(name = "状态", width = 10, dicCode = "yn")
    @Dict(dicCode = "yn")
    @Schema(description = "状态 1启用 0停用")
    private String status;
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
//update-end---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格管理实体-----------
