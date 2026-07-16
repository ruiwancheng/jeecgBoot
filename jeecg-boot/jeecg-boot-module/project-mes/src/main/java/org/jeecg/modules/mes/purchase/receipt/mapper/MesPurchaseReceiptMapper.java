//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Mapper-----------
package org.jeecg.modules.mes.purchase.receipt.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceipt;

public interface MesPurchaseReceiptMapper extends BaseMapper<MesPurchaseReceipt> {
    @Select("SELECT * FROM c_mes_purchase_receipt WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPurchaseReceipt selectDeletedByCode(String code);

    @Update("UPDATE c_mes_purchase_receipt SET code=#{code}, purchase_order_id=#{purchaseOrderId}, supplier_id=#{supplierId}, warehouse_id=#{warehouseId}, receipt_date=#{receiptDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesPurchaseReceipt entity);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Mapper-----------
