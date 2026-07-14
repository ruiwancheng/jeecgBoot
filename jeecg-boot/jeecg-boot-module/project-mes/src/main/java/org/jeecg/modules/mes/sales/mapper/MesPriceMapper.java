//update-begin---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Mapper-----------
package org.jeecg.modules.mes.sales.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.sales.entity.MesPrice;

public interface MesPriceMapper extends BaseMapper<MesPrice> {
    @Select("SELECT * FROM c_mes_price WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPrice selectDeletedByCode(String code);

    @Update("UPDATE c_mes_price SET code=#{code}, material_id=#{materialId}, customer_id=#{customerId}, price=#{price}, type=#{type}, begin_date=#{beginDate}, end_date=#{endDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesPrice entity);
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Mapper-----------
