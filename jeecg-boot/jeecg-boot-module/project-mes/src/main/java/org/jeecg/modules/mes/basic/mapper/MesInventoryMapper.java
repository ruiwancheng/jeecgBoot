//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesInventory;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface MesInventoryMapper extends BaseMapper<MesInventory> {

    @Select("SELECT * FROM c_mes_inventory WHERE material_id = #{materialId} AND warehouse_id = #{warehouseId} FOR UPDATE")
    MesInventory selectForUpdate(@Param("materialId") String materialId, @Param("warehouseId") String warehouseId);

    @Update("INSERT INTO c_mes_inventory (id, material_id, warehouse_id, current_qty, create_by, create_time, update_by, update_time) VALUES (#{id}, #{materialId}, #{warehouseId}, #{delta}, #{createBy}, NOW(), #{updateBy}, NOW()) ON DUPLICATE KEY UPDATE current_qty = current_qty + #{delta}, update_by = #{updateBy}, update_time = NOW()")
    int upsertWithDelta(@Param("id") String id, @Param("materialId") String materialId, @Param("warehouseId") String warehouseId, @Param("currentQty") BigDecimal currentQty, @Param("delta") BigDecimal delta, @Param("createBy") String createBy, @Param("updateBy") String updateBy);

    //update-begin---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-联表查询-----------
    @Select("SELECT i.id, i.material_id, i.warehouse_id, i.current_qty, " +
            "m.code AS material_code, m.name AS material_name, m.moving_avg_cost, m.del_flag AS material_del_flag, " +
            "w.name AS warehouse_name, w.del_flag AS warehouse_del_flag, " +
            //update-begin---author:ruiwancheng---date:20260807---for:【P0-1】selectInventoryWithMaterial 加 isOrphan 字段契约（前端 record.isOrphan === '1' 才显示孤儿标签/按钮）-----------
            "CASE WHEN (m.id IS NULL OR m.del_flag = 1 OR w.id IS NULL OR w.del_flag = 1) THEN '1' ELSE '0' END AS isOrphan " +
            //update-end---author:ruiwancheng---date:20260807---for:【P0-1】isOrphan 字段契约-----------
            "FROM c_mes_inventory i " +
            //update-begin---author:ruiwancheng---date:20260807---for:【P0-1】LEFT JOIN 移除 del_flag 过滤，否则软删物料的 m.id 会被滤成 NULL 而 m.del_flag 也读不到，isOrphan 判定不完整-----------
            "LEFT JOIN c_mes_material m ON i.material_id = m.id " +
            "LEFT JOIN c_mes_warehouse w ON i.warehouse_id = w.id " +
            //update-end---author:ruiwancheng---date:20260807---for:【P0-1】LEFT JOIN 移除 del_flag 过滤-----------
            "WHERE (m.code LIKE CONCAT('%',#{keyword},'%') OR m.name LIKE CONCAT('%',#{keyword},'%') OR #{keyword} IS NULL) " +
            "AND (i.warehouse_id = #{warehouseId} OR #{warehouseId} IS NULL) " +
            //update-begin---author:ruiwancheng---date:2026-07-29---for: /debug 盘点抽盘账面数拉取-materialId过滤支持-----------
            "AND (i.material_id = #{materialId} OR #{materialId} IS NULL) " +
            //update-end---author:ruiwancheng---date:2026-07-29---for: materialId过滤-----------
            "ORDER BY m.code, w.name")
    java.util.List<java.util.Map<String, Object>> selectInventoryWithMaterial(@Param("keyword") String keyword, @Param("warehouseId") String warehouseId, @Param("materialId") String materialId);
    //update-end---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-联表查询-----------

    //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】4 个 select（阶段 2，Mapper XML 实现）-----------
    /** 单条孤儿行查询：含 material/warehouse 联表信息 + del_flag，供 risk_type 派生 */
    Map<String, Object> selectOrphanById(@Param("id") String id);

    /** 批量孤儿行查询：必须用 XML foreach 走预编译参数化（Codex P0：严禁 ${ids}） */
    List<Map<String, Object>> selectOrphansByIds(@Param("ids") List<String> ids);

    /** 导出专用：含 LIMIT #{limit}，防止 OOM */
    List<Map<String, Object>> selectOrphansForExport(@Param("limit") int limit);

    /** 孤儿行总数 */
    Long countOrphans();
    //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】4 个 select-----------
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Mapper-----------
