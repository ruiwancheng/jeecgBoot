//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】审计实体(阶段 2)-----------
package org.jeecg.modules.mes.basic.cleanup.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_inventory_cleanup_audit")
@Schema(description = "MES-孤儿库存清理审计")
public class MesInventoryCleanupAudit implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    @Schema(description = "主键") private Long id;

    @Schema(description = "清理批次 ID（ui-single/ui-batch/sql-emergency）") private String batchId;
    @Schema(description = "被清理的 c_mes_inventory.id") private String inventoryId;
    @Schema(description = "物料 ID（可空）") private String materialId;
    @Schema(description = "仓库 ID（可空）") private String warehouseId;
    @Schema(description = "清理时的 current_qty") private BigDecimal currentQty;
    @Schema(description = "风险类型 A2=硬删 B2=软删") private String riskType;
    @Schema(description = "操作人") private String operator;
    @Schema(description = "清理时间") private Date cleanedAt;
    @Schema(description = "是否已回滚 0/1") private Integer rolledBack;
    @Schema(description = "回滚时间") private Date rollbackAt;
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】审计实体-----------
