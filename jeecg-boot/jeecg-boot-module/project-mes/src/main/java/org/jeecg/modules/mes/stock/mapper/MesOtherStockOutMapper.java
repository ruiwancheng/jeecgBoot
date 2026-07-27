//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它出库Mapper-----------
package org.jeecg.modules.mes.stock.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.stock.entity.MesOtherStockOut;

import java.util.Date;

public interface MesOtherStockOutMapper extends BaseMapper<MesOtherStockOut> {
    @Select("SELECT * FROM c_mes_other_stock_out WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesOtherStockOut selectDeletedByCode(String code);

    @Update("UPDATE c_mes_other_stock_out SET code=#{code}, out_type=#{outType}, reason=#{reason}, stock_date=#{stockDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    int resurrect(MesOtherStockOut entity);

    @Update("UPDATE c_mes_other_stock_out SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_other_stock_out SET status = '1', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '2'")
    int unauditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Select("SELECT * FROM c_mes_other_stock_out WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesOtherStockOut selectByIdForUpdate(@Param("id") String id);
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它出库Mapper-----------
