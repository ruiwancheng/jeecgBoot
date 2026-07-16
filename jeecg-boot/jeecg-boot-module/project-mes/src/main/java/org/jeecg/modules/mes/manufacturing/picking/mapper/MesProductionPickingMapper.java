//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料单Mapper-----------
package org.jeecg.modules.mes.manufacturing.picking.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.manufacturing.picking.entity.MesProductionPicking;

public interface MesProductionPickingMapper extends BaseMapper<MesProductionPicking> {

    @Select("SELECT * FROM mes_production_picking WHERE code = #{code} AND del_flag = 1")
    MesProductionPicking selectDeletedByCode(@Param("code") String code);

    @Update("UPDATE mes_production_picking SET code=#{code}, production_order_id=#{productionOrderId}, production_order_code=#{productionOrderCode}, " +
            "warehouse_id=#{warehouseId}, warehouse_name=#{warehouseName}, status=#{status}, pick_date=#{pickDate}, remark=#{remark}, " +
            "del_flag=0, update_by=#{updateBy}, update_time=#{updateTime} WHERE id=#{id}")
    void resurrect(MesProductionPicking entity);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料单Mapper-----------
