//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Mapper-----------
package org.jeecg.modules.mes.stock.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.stock.entity.MesStocktake;

import java.util.Date;
import java.util.List;
import java.util.Map;

public interface MesStocktakeMapper extends BaseMapper<MesStocktake> {
    @Select("SELECT * FROM c_mes_stocktake WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesStocktake selectDeletedByCode(String code);

    @Update("UPDATE c_mes_stocktake SET code=#{code}, warehouse_id=#{warehouseId}, take_type=#{takeType}, status=#{status}, take_date=#{takeDate}, snapshot_time=#{snapshotTime}, total_diff_amount=#{totalDiffAmount}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    int resurrect(MesStocktake entity);

    @Update("UPDATE c_mes_stocktake SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Select("SELECT * FROM c_mes_stocktake WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesStocktake selectByIdForUpdate(@Param("id") String id);

    /** 全盘快照：普通 SELECT 不加锁（评审 P1：快照是 best-effort 读取，加锁只会白阻塞出入库） */
    @Select("SELECT i.material_id AS materialId, i.current_qty AS bookQty, m.moving_avg_cost AS unitCost " +
            "FROM c_mes_inventory i " +
            "LEFT JOIN c_mes_material m ON i.material_id = m.id AND m.del_flag = 0 " +
            "WHERE i.warehouse_id = #{warehouseId} AND i.current_qty > 0 ORDER BY i.material_id")
    List<Map<String, Object>> snapshotByWarehouse(@Param("warehouseId") String warehouseId);
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Mapper-----------
