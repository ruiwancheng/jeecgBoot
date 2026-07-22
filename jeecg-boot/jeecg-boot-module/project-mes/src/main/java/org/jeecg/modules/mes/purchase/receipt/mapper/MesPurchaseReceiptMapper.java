//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Mapper-----------
package org.jeecg.modules.mes.purchase.receipt.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceipt;

import java.util.Date;

public interface MesPurchaseReceiptMapper extends BaseMapper<MesPurchaseReceipt> {
    @Select("SELECT * FROM c_mes_purchase_receipt WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPurchaseReceipt selectDeletedByCode(String code);

    @Update("UPDATE c_mes_purchase_receipt SET code=#{code}, purchase_order_id=#{purchaseOrderId}, supplier_id=#{supplierId}, warehouse_id=#{warehouseId}, receipt_date=#{receiptDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    int resurrect(MesPurchaseReceipt entity);

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-----------
    @Update("UPDATE c_mes_purchase_receipt SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    //update-begin---author:ruisuyun---date:2026-07-22---for: 链路P1-入库反审核(已审核→草稿)-----------
    @Update("UPDATE c_mes_purchase_receipt SET status = '1', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '2'")
    int unauditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
    //update-end---author:ruisuyun---date:2026-07-22---for: 链路P1-入库反审核-----------

    //update-begin P0-3 收货编辑/删除 FOR UPDATE 行锁
    @Select("SELECT * FROM c_mes_purchase_receipt WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesPurchaseReceipt selectByIdForUpdate(@Param("id") String id);
    //update-end P0-3
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Mapper-----------
