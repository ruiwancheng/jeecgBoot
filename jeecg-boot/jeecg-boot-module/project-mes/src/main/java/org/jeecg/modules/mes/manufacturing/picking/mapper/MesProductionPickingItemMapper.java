//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料明细Mapper-----------
package org.jeecg.modules.mes.manufacturing.picking.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.jeecg.modules.mes.manufacturing.picking.entity.MesProductionPickingItem;

import java.math.BigDecimal;

public interface MesProductionPickingItemMapper extends BaseMapper<MesProductionPickingItem> {
    //update-begin---author:ruiwancheng---date:2026-08-08---for: slice-4 领料 generateByOrder：按订单+物料聚合已领累计（草稿/已审核均算）-----------
    /**
     * 按订单+物料聚合已领数量（不含逻辑删除的领料单）
     * 用于补领场景：remain = BOM用量×planQty - 已领累计
     * 已审核领料单 + 草稿领料单均计入（避免补领量被重复扣减）
     */
    @Select("SELECT COALESCE(SUM(pi.quantity), 0) FROM c_mes_production_picking_item pi " +
            "JOIN c_mes_production_picking p ON pi.picking_id = p.id " +
            "WHERE p.production_order_id = #{orderId} AND pi.material_id = #{materialId} AND p.del_flag = 0")
    BigDecimal sumPickedByOrder(@Param("orderId") String orderId, @Param("materialId") String materialId);
    //update-end---author:ruiwancheng---date:2026-08-08---for: slice-4 领料 generateByOrder：按订单+物料聚合已领累计-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料明细Mapper-----------
