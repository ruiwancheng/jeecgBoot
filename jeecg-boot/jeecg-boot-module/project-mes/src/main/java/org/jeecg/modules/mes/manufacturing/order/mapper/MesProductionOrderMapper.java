//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Mapper-----------
package org.jeecg.modules.mes.manufacturing.order.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.manufacturing.order.entity.MesProductionOrder;

public interface MesProductionOrderMapper extends BaseMapper<MesProductionOrder> {
    @Select("SELECT * FROM c_mes_production_order WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesProductionOrder selectDeletedByCode(String code);
    @Update("UPDATE c_mes_production_order SET code=#{code}, product_id=#{productId}, bom_id=#{bomId}, plan_qty=#{planQty}, completed_qty=#{completedQty}, start_date=#{startDate}, end_date=#{endDate}, warehouse_id=#{warehouseId}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesProductionOrder entity);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Mapper-----------
