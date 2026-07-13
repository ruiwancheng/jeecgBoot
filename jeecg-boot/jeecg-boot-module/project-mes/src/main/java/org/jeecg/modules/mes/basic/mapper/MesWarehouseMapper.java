//update-begin---author:admin---date:2026-07-06---for: MES基础设置-仓库Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesWarehouse;

public interface MesWarehouseMapper extends BaseMapper<MesWarehouse> {
    @Select("SELECT * FROM c_mes_warehouse WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesWarehouse selectDeletedByCode(String code);

    @Update("UPDATE c_mes_warehouse SET code=#{code}, name=#{name}, type=#{type}, address=#{address}, manager=#{manager}, phone=#{phone}, factory=#{factory}, workshop=#{workshop}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id}")
    void resurrect(MesWarehouse entity);
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-仓库Mapper-----------
