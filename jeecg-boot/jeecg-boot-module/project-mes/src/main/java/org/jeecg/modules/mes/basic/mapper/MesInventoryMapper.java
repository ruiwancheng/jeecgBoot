//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesInventory;

import java.math.BigDecimal;

public interface MesInventoryMapper extends BaseMapper<MesInventory> {

    @Select("SELECT * FROM c_mes_inventory WHERE material_id = #{materialId} AND warehouse_id = #{warehouseId} FOR UPDATE")
    MesInventory selectForUpdate(@Param("materialId") String materialId, @Param("warehouseId") String warehouseId);

    @Update("INSERT INTO c_mes_inventory (id, material_id, warehouse_id, current_qty, create_by, create_time, update_by, update_time) VALUES (#{id}, #{materialId}, #{warehouseId}, #{currentQty}, #{createBy}, NOW(), #{updateBy}, NOW()) ON DUPLICATE KEY UPDATE current_qty = current_qty + #{delta}, update_by = #{updateBy}, update_time = NOW()")
    int upsertWithDelta(@Param("id") String id, @Param("materialId") String materialId, @Param("warehouseId") String warehouseId, @Param("currentQty") BigDecimal currentQty, @Param("delta") BigDecimal delta, @Param("createBy") String createBy, @Param("updateBy") String updateBy);
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Mapper-----------
