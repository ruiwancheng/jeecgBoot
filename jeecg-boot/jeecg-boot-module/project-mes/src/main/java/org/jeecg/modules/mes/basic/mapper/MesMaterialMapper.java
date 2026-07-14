//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesMaterial;

public interface MesMaterialMapper extends BaseMapper<MesMaterial> {
    @Select("SELECT * FROM c_mes_material WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesMaterial selectDeletedByCode(String code);

    @Update("UPDATE c_mes_material SET code=#{code}, name=#{name}, type=#{type}, spec=#{spec}, unit=#{unit}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesMaterial entity);
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Mapper-----------
