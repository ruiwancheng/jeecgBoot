//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Mapper-----------
package org.jeecg.modules.mes.purchase.order.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrder;

import java.util.Date;

public interface MesPurchaseOrderMapper extends BaseMapper<MesPurchaseOrder> {
    @Select("SELECT * FROM c_mes_purchase_order WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPurchaseOrder selectDeletedByCode(String code);

    @Update("UPDATE c_mes_purchase_order SET code=#{code}, supplier_id=#{supplierId}, purchase_type=#{purchaseType}, order_date=#{orderDate}, delivery_date=#{deliveryDate}, payment_terms=#{paymentTerms}, total_amount=#{totalAmount}, tax_amount=#{taxAmount}, total_with_tax=#{totalWithTax}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    int resurrect(MesPurchaseOrder entity);

    @Update("UPDATE c_mes_purchase_order SET status = '3', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Select("SELECT * FROM c_mes_purchase_order WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesPurchaseOrder selectByIdForUpdate(@Param("id") String id);

    //update-begin P0-4 入库审核后回写订单状态（部分到货4→已到货5）
    @Update("UPDATE c_mes_purchase_order SET status = '4', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status IN ('3','4')")
    int markPartiallyReceived(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") java.util.Date updateTime);

    @Update("UPDATE c_mes_purchase_order SET status = '5', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status IN ('3','4') AND NOT EXISTS (SELECT 1 FROM c_mes_purchase_order_item WHERE order_id = #{id} AND received_qty < quantity)")
    int markFullyReceived(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") java.util.Date updateTime);
    //update-end P0-4
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Mapper-----------
