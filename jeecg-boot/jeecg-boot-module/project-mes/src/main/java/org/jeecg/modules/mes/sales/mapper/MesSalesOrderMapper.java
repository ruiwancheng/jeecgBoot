//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单Mapper-----------
package org.jeecg.modules.mes.sales.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.sales.entity.MesSalesOrder;

import java.util.Date;

public interface MesSalesOrderMapper extends BaseMapper<MesSalesOrder> {

    //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-03 发货单并发超量校验——SELECT FOR UPDATE锁订单行-----------
    @Select("SELECT * FROM c_mes_sales_order WHERE id = #{id} FOR UPDATE")
    MesSalesOrder selectByIdForUpdate(@Param("id") String id);
    //update-end---author:ruiwancheng---date:2026-07-18---for: P0-03 发货单并发超量校验——SELECT FOR UPDATE锁订单行-----------
    @Select("SELECT * FROM c_mes_sales_order WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesSalesOrder selectDeletedByCode(String code);

    @Update("UPDATE c_mes_sales_order SET code=#{code}, customer_id=#{customerId}, order_date=#{orderDate}, delivery_date=#{deliveryDate}, status=#{status}, total_amount=#{totalAmount}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesSalesOrder entity);

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-销售订单-----------
    @Update("UPDATE c_mes_sales_order SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_sales_order SET status = '3', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '2'")
    int releaseWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_sales_order SET status = '5', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int closeWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_sales_order SET status = '6', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int cancelWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-销售订单-----------
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单Mapper-----------
