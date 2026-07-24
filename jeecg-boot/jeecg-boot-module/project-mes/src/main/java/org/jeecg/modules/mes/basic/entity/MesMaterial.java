//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料管理实体-----------
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
@TableName("c_mes_material")
@Schema(description = "MES-物料")
public class MesMaterial implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "物料编码", width = 15)
    @Schema(description = "物料编码")
    private String code;
    @Excel(name = "物料名称", width = 20)
    @Schema(description = "物料名称")
    private String name;
    @Excel(name = "物料类型", width = 15, dicCode = "mes_material_type")
    @Dict(dicCode = "mes_material_type")
    @Schema(description = "物料类型")
    private String type;
    @Excel(name = "规格型号", width = 20)
    @Schema(description = "规格型号")
    private String spec;
    @Excel(name = "单位", width = 10, dicCode = "mes_material_unit")
    @Dict(dicCode = "mes_material_unit")
    @Schema(description = "单位")
    private String unit;
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.6.0 轻量化价格体系-物料标准售价-----------
    @Excel(name = "标准售价", width = 12)
    @Schema(description = "标准售价")
    private java.math.BigDecimal standardPrice;
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.6.0 轻量化价格体系-物料标准售价-----------
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-移动平均成本+最近采购价-----------
    @Excel(name = "移动平均成本", width = 12)
    @Schema(description = "移动平均成本")
    private java.math.BigDecimal movingAvgCost;

    @Excel(name = "最近采购价", width = 12)
    @Schema(description = "最近采购价(含税)")
    private java.math.BigDecimal lastPurchasePrice;

    @Excel(name = "最近采购日期", width = 15, format = "yyyy-MM-dd HH:mm:ss")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "最近采购日期")
    private java.util.Date lastPurchaseDate;
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-移动平均成本+最近采购价-----------
    //update-begin---author:ruiwancheng---date:2026-07-20---for: Phase3 库存预警-----------
    @Excel(name = "安全库存", width = 10) @Schema(description = "安全库存") private java.math.BigDecimal safetyStock;
    @Excel(name = "最高库存", width = 10) @Schema(description = "最高库存") private java.math.BigDecimal maxStock;
    //update-end---author:ruiwancheng---date:2026-07-20---for: Phase3 库存预警-----------
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
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料管理实体-----------
