//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Mapper-----------
package org.jeecg.modules.mes.batch.inventory.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;

import java.util.List;

public interface MesBatchInventoryMapper extends BaseMapper<MesBatchInventory> {
    /**
     * FIFO 查询：按批次创建时间升序（@Select 注解方式，避免 XML mapper 缺失）
     */
    @Select("SELECT * FROM c_mes_batch_inventory " +
            "WHERE material_id = #{materialId} AND warehouse_id = #{warehouseId} AND del_flag = 0 AND qty > 0 " +
            "ORDER BY create_time ASC")
    List<MesBatchInventory> selectFifoByMaterial(@Param("materialId") String materialId, @Param("warehouseId") String warehouseId);
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Mapper-----------
