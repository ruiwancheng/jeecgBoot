//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Mapper-----------
package org.jeecg.modules.mes.sales.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;

public interface MesDeliveryNoteMapper extends BaseMapper<MesDeliveryNote> {
    @Select("SELECT * FROM c_mes_delivery_note WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesDeliveryNote selectDeletedByCode(String code);

    @Update("UPDATE c_mes_delivery_note SET code=#{code}, sales_order_id=#{salesOrderId}, warehouse_id=#{warehouseId}, customer_id=#{customerId}, delivery_date=#{deliveryDate}, status=#{status}, logistics_company=#{logisticsCompany}, tracking_no=#{trackingNo}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesDeliveryNote entity);
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Mapper-----------
