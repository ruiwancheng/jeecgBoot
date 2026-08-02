//update-begin---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------
package org.jeecg.modules.mes.purchase.order.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 采购订单行-入库用DTO
 * 返回订单行的物料信息、订单数量、已入库数量及本次可入库数量
 */
@Data
@Accessors(chain = true)
@Schema(description = "采购订单行-入库用DTO")
public class MesPurchaseOrderItemForReceipt implements Serializable {
    private static final long serialVersionUID = 1L;

    @Schema(description = "订单行ID")
    private String itemId;

    @Schema(description = "物料ID")
    private String materialId;

    @Schema(description = "订单数量")
    private BigDecimal orderQty;

    @Schema(description = "已入库数量")
    private BigDecimal receivedQty;

    @Schema(description = "本次可入库数量(订单数量-已入库数量)")
    private BigDecimal remainQty;

    @Schema(description = "订单行单价")
    private BigDecimal unitPrice;

    @Schema(description = "税率")
    private BigDecimal taxRate;
}
//update-end---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------
