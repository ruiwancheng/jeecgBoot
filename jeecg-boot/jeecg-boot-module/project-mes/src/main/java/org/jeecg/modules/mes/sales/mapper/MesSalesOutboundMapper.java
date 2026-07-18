//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Mapper-----------
package org.jeecg.modules.mes.sales.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.sales.entity.MesSalesOutbound;

import java.util.Date;

public interface MesSalesOutboundMapper extends BaseMapper<MesSalesOutbound> {
    @Select("SELECT * FROM c_mes_sales_outbound WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesSalesOutbound selectDeletedByCode(String code);

    @Update("UPDATE c_mes_sales_outbound SET code=#{code}, delivery_note_id=#{deliveryNoteId}, sales_order_id=#{salesOrderId}, warehouse_id=#{warehouseId}, customer_id=#{customerId}, outbound_date=#{outboundDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesSalesOutbound entity);

    //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-08 audit/cancel原子UPDATE防并发-----------
    @Update("UPDATE c_mes_sales_outbound SET status = '3', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_sales_outbound SET status = '0', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status IN ('1', '2')")
    int cancelWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
    //update-end---author:ruiwancheng---date:2026-07-18---for: P0-08 audit/cancel原子UPDATE防并发-----------
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Mapper-----------
