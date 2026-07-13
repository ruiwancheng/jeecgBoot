//update-begin---author:admin---date:2026-07-13---for: MES基础设置-货架Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesShelf;

public interface MesShelfMapper extends BaseMapper<MesShelf> {
    @Select("SELECT * FROM c_mes_shelf WHERE zone_id = #{zoneId} AND code = #{code} AND del_flag = 1 LIMIT 1")
    MesShelf selectDeletedByZoneAndCode(@Param("zoneId") String zoneId, @Param("code") String code);

    @Update("UPDATE c_mes_shelf SET zone_id=#{zoneId}, warehouse_id=#{warehouseId}, code=#{code}, name=#{name}, sort_no=#{sortNo}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id}")
    void resurrect(MesShelf entity);
}
//update-end---author:admin---date:2026-07-13---for: MES基础设置-货架Mapper-----------
