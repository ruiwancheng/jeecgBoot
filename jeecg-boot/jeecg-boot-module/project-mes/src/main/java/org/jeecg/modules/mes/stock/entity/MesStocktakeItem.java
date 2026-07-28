//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-行实体-----------
package org.jeecg.modules.mes.stock.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_stocktake_item")
@Schema(description = "MES-盘点单行")
public class MesStocktakeItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "盘点单ID")
    private String takeId;
    @Schema(description = "行号")
    private Integer lineNo;
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;
    @Schema(description = "账面数量(快照,只读)")
    private BigDecimal bookQty;
    @Schema(description = "实盘数量(全盘默认=账面,抽盘必填)")
    private BigDecimal actualQty;
    @Schema(description = "差异数量(实盘-账面)")
    private BigDecimal diffQty;
    @Schema(description = "成本单价(快照移动平均)")
    private BigDecimal unitCost;
    @Schema(description = "差异金额(diff_qty*unit_cost)")
    private BigDecimal diffAmount;
    @Schema(description = "盘盈生成的入库单ID")
    private String generatedInId;
    @Schema(description = "盘亏生成的出库单ID")
    private String generatedOutId;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-行实体-----------
