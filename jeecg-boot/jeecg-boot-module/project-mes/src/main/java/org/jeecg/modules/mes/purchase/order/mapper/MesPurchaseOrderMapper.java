//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Mapper-----------
package org.jeecg.modules.mes.purchase.order.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrder;

public interface MesPurchaseOrderMapper extends BaseMapper<MesPurchaseOrder> {
    @Select("SELECT * FROM c_mes_purchase_order WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPurchaseOrder selectDeletedByCode(String code);

    @Update("UPDATE c_mes_purchase_order SET code=#{code}, supplier_id=#{supplierId}, purchase_type=#{purchaseType}, order_date=#{orderDate}, delivery_date=#{deliveryDate}, payment_terms=#{paymentTerms}, total_amount=#{totalAmount}, tax_amount=#{taxAmount}, total_with_tax=#{totalWithTax}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesPurchaseOrder entity);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Mapper-----------
