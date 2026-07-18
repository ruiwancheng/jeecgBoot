//update-begin---author:ruiwancheng---date:2026-07-16---for: P0修复-表名+字段对齐-----------
package org.jeecg.modules.mes.manufacturing.completion.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.manufacturing.completion.entity.MesCompletionReceipt;

import java.util.Date;

public interface MesCompletionReceiptMapper extends BaseMapper<MesCompletionReceipt> {
    @Select("SELECT * FROM c_mes_completion_receipt WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesCompletionReceipt selectDeletedByCode(String code);

    @Update("UPDATE c_mes_completion_receipt SET code=#{code}, production_order_id=#{productionOrderId}, product_id=#{productId}, warehouse_id=#{warehouseId}, receipt_date=#{receiptDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesCompletionReceipt entity);

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-----------
    @Update("UPDATE c_mes_completion_receipt SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: P0修复-表名+字段对齐-----------
