//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它入库Mapper-----------
package org.jeecg.modules.mes.stock.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.stock.entity.MesOtherStockIn;

import java.util.Date;

public interface MesOtherStockInMapper extends BaseMapper<MesOtherStockIn> {
    @Select("SELECT * FROM c_mes_other_stock_in WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesOtherStockIn selectDeletedByCode(String code);

    @Update("UPDATE c_mes_other_stock_in SET code=#{code}, in_type=#{inType}, warehouse_id=#{warehouseId}, total_amount=#{totalAmount}, reason=#{reason}, stock_date=#{stockDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    int resurrect(MesOtherStockIn entity);

    @Update("UPDATE c_mes_other_stock_in SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_other_stock_in SET status = '1', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '2'")
    int unauditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Select("SELECT * FROM c_mes_other_stock_in WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesOtherStockIn selectByIdForUpdate(@Param("id") String id);
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它入库Mapper-----------
