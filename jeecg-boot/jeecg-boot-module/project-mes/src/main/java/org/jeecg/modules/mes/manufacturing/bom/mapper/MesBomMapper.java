//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Mapper-----------
package org.jeecg.modules.mes.manufacturing.bom.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBom;

public interface MesBomMapper extends BaseMapper<MesBom> {
    @Select("SELECT * FROM c_mes_bom WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesBom selectDeletedByCode(String code);
    @Update("UPDATE c_mes_bom SET code=#{code}, product_id=#{productId}, version=#{version}, effective_date=#{effectiveDate}, expiry_date=#{expiryDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesBom entity);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Mapper-----------
