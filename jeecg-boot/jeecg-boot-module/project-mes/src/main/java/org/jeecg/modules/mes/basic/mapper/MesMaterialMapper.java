//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesMaterial;

public interface MesMaterialMapper extends BaseMapper<MesMaterial> {
    @Select("SELECT * FROM c_mes_material WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesMaterial selectDeletedByCode(String code);

    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 resurrect补齐standardPrice+safetyStock+maxStock+成本字段-----------
    @Update("UPDATE c_mes_material SET code=#{code}, name=#{name}, type=#{type}, spec=#{spec}, unit=#{unit}, " +
            "standard_price=#{standardPrice}, safety_stock=#{safetyStock}, max_stock=#{maxStock}, " +
            "moving_avg_cost=#{movingAvgCost}, last_purchase_price=#{lastPurchasePrice}, last_purchase_date=#{lastPurchaseDate}, " +
            "status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 " +
            "WHERE id=#{id} AND del_flag=1")
    void resurrect(MesMaterial entity);
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 resurrect补齐字段-----------

    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本更新-FOR UPDATE行锁-----------
    @Select("SELECT * FROM c_mes_material WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesMaterial selectByIdForUpdate(@Param("id") String id);

    @Select("SELECT COALESCE(SUM(current_qty), 0) FROM c_mes_inventory WHERE material_id = #{materialId}")
    java.math.BigDecimal selectTotalStockQty(@Param("materialId") String materialId);
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本更新-FOR UPDATE行锁-----------
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Mapper-----------
