//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库单Mapper-----------
package org.jeecg.modules.mes.manufacturing.completion.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.manufacturing.completion.entity.MesCompletionReceipt;

public interface MesCompletionReceiptMapper extends BaseMapper<MesCompletionReceipt> {

    @Select("SELECT * FROM mes_completion_receipt WHERE code = #{code} AND del_flag = 1")
    MesCompletionReceipt selectDeletedByCode(@Param("code") String code);

    @Update("UPDATE mes_completion_receipt SET code=#{code}, production_order_id=#{productionOrderId}, production_order_code=#{productionOrderCode}, " +
            "warehouse_id=#{warehouseId}, warehouse_name=#{warehouseName}, status=#{status}, receipt_date=#{receiptDate}, remark=#{remark}, " +
            "del_flag=0, update_by=#{updateBy}, update_time=#{updateTime} WHERE id=#{id}")
    void resurrect(MesCompletionReceipt entity);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库单Mapper-----------
