//update-begin---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Mapper-----------
package org.jeecg.modules.mes.sales.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.sales.entity.MesPrice;

import java.util.Date;

public interface MesPriceMapper extends BaseMapper<MesPrice> {
    @Select("SELECT * FROM c_mes_price WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPrice selectDeletedByCode(String code);

    @Update("UPDATE c_mes_price SET code=#{code}, material_id=#{materialId}, customer_id=#{customerId}, price=#{price}, type=#{type}, begin_date=#{beginDate}, end_date=#{endDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesPrice entity);

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 价格自动带出-查有效价格-----------
    @Select("SELECT * FROM c_mes_price WHERE material_id = #{materialId} AND status = '1' AND del_flag = 0 AND (customer_id = #{customerId} OR customer_id IS NULL) AND begin_date <= #{date} AND (end_date IS NULL OR end_date >= #{date}) ORDER BY CASE WHEN customer_id = #{customerId} THEN 0 ELSE 1 END, type DESC LIMIT 1")
    MesPrice findActivePrice(@Param("materialId") String materialId, @Param("customerId") String customerId, @Param("date") Date date);
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 价格自动带出-查有效价格-----------
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Mapper-----------
