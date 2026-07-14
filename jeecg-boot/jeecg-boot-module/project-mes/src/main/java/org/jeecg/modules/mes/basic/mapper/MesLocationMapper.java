//update-begin---author:admin---date:2026-07-06---for: MES基础设置-库位Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesLocation;

public interface MesLocationMapper extends BaseMapper<MesLocation> {
    @Select("SELECT * FROM c_mes_location WHERE warehouse_id = #{warehouseId} AND code = #{code} AND del_flag = 1 LIMIT 1")
    MesLocation selectDeletedByWhAndCode(@Param("warehouseId") String warehouseId, @Param("code") String code);

    @Update("UPDATE c_mes_location SET warehouse_id=#{warehouseId}, code=#{code}, name=#{name}, type=#{type}, area=#{area}, passage_row=#{passageRow}, passage_col=#{passageCol}, shelf_row=#{shelfRow}, shelf_col=#{shelfCol}, max_capacity=#{maxCapacity}, load_capacity=#{loadCapacity}, storage_limit=#{storageLimit}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id}")
    void resurrect(MesLocation entity);
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Mapper-----------
