//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Mapper-----------
package org.jeecg.modules.mes.sales.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.sales.entity.MesSalesOutbound;

public interface MesSalesOutboundMapper extends BaseMapper<MesSalesOutbound> {
    @Select("SELECT * FROM c_mes_sales_outbound WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesSalesOutbound selectDeletedByCode(String code);

    @Update("UPDATE c_mes_sales_outbound SET code=#{code}, delivery_note_id=#{deliveryNoteId}, sales_order_id=#{salesOrderId}, warehouse_id=#{warehouseId}, customer_id=#{customerId}, outbound_date=#{outboundDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesSalesOutbound entity);
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Mapper-----------
