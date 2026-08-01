//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Mapper-----------
package org.jeecg.modules.mes.batch.inventory.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;

import java.util.List;

public interface MesBatchInventoryMapper extends BaseMapper<MesBatchInventory> {
    //update-begin---author:ruiwancheng---date:2026-07-31---for: V8.0.0.2 MES批次管理-stockIn批次库存行锁-----------
    /**
     * 锁定同批次同仓库库存行，防止并发入库读改写丢失更新。
     */
    @Select("SELECT * FROM c_mes_batch_inventory " +
            "WHERE batch_id = #{batchId} AND warehouse_id = #{warehouseId} AND del_flag = 0 " +
            "FOR UPDATE")
    MesBatchInventory selectForUpdate(@Param("batchId") String batchId, @Param("warehouseId") String warehouseId);
    //update-end---author:ruiwancheng---date:2026-07-31---for: V8.0.0.2 MES批次管理-stockIn批次库存行锁-----------

    /**
     * FIFO 查询：按批次创建时间升序（@Select 注解方式，避免 XML mapper 缺失）
     */
    @Select("SELECT * FROM c_mes_batch_inventory " +
            "WHERE material_id = #{materialId} AND warehouse_id = #{warehouseId} AND del_flag = 0 AND qty > 0 " +
            "ORDER BY create_time ASC")
    List<MesBatchInventory> selectFifoByMaterial(@Param("materialId") String materialId, @Param("warehouseId") String warehouseId);

    //update-begin---author:ruiwancheng---date:2026-07-31---for: V8.0.0.3 MES批次管理-FIFO批次库存行锁-----------
    /**
     * FIFO 查询并锁定待扣减批次行，防止并发出库重复读取同一库存。
     */
    @Select("SELECT * FROM c_mes_batch_inventory " +
            "WHERE material_id = #{materialId} AND warehouse_id = #{warehouseId} AND del_flag = 0 AND qty > 0 " +
            "ORDER BY create_time ASC, id ASC FOR UPDATE")
    List<MesBatchInventory> selectFifoByMaterialForUpdate(@Param("materialId") String materialId, @Param("warehouseId") String warehouseId);
    //update-end---author:ruiwancheng---date:2026-07-31---for: V8.0.0.3 MES批次管理-FIFO批次库存行锁-----------
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Mapper-----------
