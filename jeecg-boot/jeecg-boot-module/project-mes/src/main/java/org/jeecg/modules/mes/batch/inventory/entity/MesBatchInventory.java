//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存实体-----------
package org.jeecg.modules.mes.batch.inventory.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
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
@TableName("c_mes_batch_inventory")
@Schema(description = "MES-批次库存")
public class MesBatchInventory implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;

    @Schema(description = "批次ID")
    private String batchId;

    @Schema(description = "批次号(冗余)")
    private String batchNo;

    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;

    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Schema(description = "仓库ID")
    private String warehouseId;

    @Schema(description = "当前数量")
    private BigDecimal qty;

    @Schema(description = "批次单位成本(冗余便于出库取值)")
    private BigDecimal unitCost;

    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;

    @TableLogic
    @Schema(description = "删除标记") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存实体-----------
