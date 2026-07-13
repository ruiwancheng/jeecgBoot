//update-begin---author:admin---date:2026-07-13---for: MES基础设置-库区Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesZone;

public interface MesZoneMapper extends BaseMapper<MesZone> {
    @Select("SELECT * FROM c_mes_zone WHERE warehouse_id = #{warehouseId} AND code = #{code} AND del_flag = 1 LIMIT 1")
    MesZone selectDeletedByWhAndCode(@Param("warehouseId") String warehouseId, @Param("code") String code);

    @Update("UPDATE c_mes_zone SET warehouse_id=#{warehouseId}, code=#{code}, name=#{name}, sort_no=#{sortNo}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id}")
    void resurrect(MesZone entity);
}
//update-end---author:admin---date:2026-07-13---for: MES基础设置-库区Mapper-----------
