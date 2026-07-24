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

    @Update("INSERT INTO c_mes_inventory (id, material_id, warehouse_id, current_qty, create_by, create_time, update_by, update_time) VALUES (#{id}, #{materialId}, #{warehouseId}, #{delta}, #{createBy}, NOW(), #{updateBy}, NOW()) ON DUPLICATE KEY UPDATE current_qty = current_qty + #{delta}, update_by = #{updateBy}, update_time = NOW()")
    int upsertWithDelta(@Param("id") String id, @Param("materialId") String materialId, @Param("warehouseId") String warehouseId, @Param("currentQty") BigDecimal currentQty, @Param("delta") BigDecimal delta, @Param("createBy") String createBy, @Param("updateBy") String updateBy);

    //update-begin---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-联表查询-----------
    @Select("SELECT i.id, i.material_id, i.warehouse_id, i.current_qty, " +
            "m.code AS material_code, m.name AS material_name, m.moving_avg_cost, " +
            "w.name AS warehouse_name " +
            "FROM c_mes_inventory i " +
            "LEFT JOIN c_mes_material m ON i.material_id = m.id AND m.del_flag = 0 " +
            "LEFT JOIN c_mes_warehouse w ON i.warehouse_id = w.id AND w.del_flag = 0 " +
            "WHERE (m.code LIKE CONCAT('%',#{keyword},'%') OR m.name LIKE CONCAT('%',#{keyword},'%') OR #{keyword} IS NULL) " +
            "AND (i.warehouse_id = #{warehouseId} OR #{warehouseId} IS NULL) " +
            "ORDER BY m.code, w.name")
    java.util.List<java.util.Map<String, Object>> selectInventoryWithMaterial(@Param("keyword") String keyword, @Param("warehouseId") String warehouseId);
    //update-end---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-联表查询-----------
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Mapper-----------
