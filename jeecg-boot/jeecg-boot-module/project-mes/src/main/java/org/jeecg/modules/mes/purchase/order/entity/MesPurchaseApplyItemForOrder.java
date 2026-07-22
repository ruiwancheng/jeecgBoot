//update-begin---author:ruisuyun---date:2026-07-22---for: 链路P0-从已审核申请加载明细用于生成订单-----------
package org.jeecg.modules.mes.purchase.order.entity;

import lombok.Data;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.math.BigDecimal;

@Data
@Accessors(chain = true)
public class MesPurchaseApplyItemForOrder implements Serializable {
    private static final long serialVersionUID = 1L;
    private String itemId;
    private String materialId;
    private BigDecimal applyQty;
    private BigDecimal unitPrice;
    private BigDecimal taxRate;
}
//update-end---author:ruisuyun---date:2026-07-22---for: 链路P0-从已审核申请加载明细-----------
