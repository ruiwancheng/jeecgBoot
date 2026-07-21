//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单行Mapper-----------
package org.jeecg.modules.mes.purchase.order.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItem;

public interface MesPurchaseOrderItemMapper extends BaseMapper<MesPurchaseOrderItem> {
    //update-begin P0-4 原子扣减：入库审核时单SQL防超收
    @Update("UPDATE c_mes_purchase_order_item SET received_qty = received_qty + #{qty} WHERE order_id = #{orderId} AND material_id = #{materialId} AND received_qty + #{qty} <= quantity")
    int atomicReceive(@Param("orderId") String orderId, @Param("materialId") String materialId, @Param("qty") java.math.BigDecimal qty);
    //update-end P0-4
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单行Mapper-----------
