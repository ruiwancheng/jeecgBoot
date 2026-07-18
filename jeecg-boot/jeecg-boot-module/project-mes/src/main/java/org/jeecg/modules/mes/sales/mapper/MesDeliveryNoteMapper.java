//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Mapper-----------
package org.jeecg.modules.mes.sales.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;

import java.util.Date;

public interface MesDeliveryNoteMapper extends BaseMapper<MesDeliveryNote> {
    @Select("SELECT * FROM c_mes_delivery_note WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesDeliveryNote selectDeletedByCode(String code);

    @Update("UPDATE c_mes_delivery_note SET code=#{code}, sales_order_id=#{salesOrderId}, warehouse_id=#{warehouseId}, customer_id=#{customerId}, delivery_date=#{deliveryDate}, total_amount=#{totalAmount}, status=#{status}, logistics_company=#{logisticsCompany}, tracking_no=#{trackingNo}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesDeliveryNote entity);

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------
    @Update("UPDATE c_mes_delivery_note SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int submitWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_delivery_note SET status = '4', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '3'")
    int signWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_delivery_note SET status = '0', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int cancelWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------

    //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-02 出库审核联动更新发货单状态-----------
    @Update("UPDATE c_mes_delivery_note SET status = #{newStatus}, update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = #{oldStatus}")
    int updateStatus(@Param("id") String id, @Param("newStatus") String newStatus, @Param("oldStatus") String oldStatus, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
    //update-end---author:ruiwancheng---date:2026-07-19---for: P0-02 出库审核联动更新发货单状态-----------
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Mapper-----------
