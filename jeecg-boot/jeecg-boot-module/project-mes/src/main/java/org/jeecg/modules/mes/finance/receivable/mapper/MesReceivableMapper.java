//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应收单Mapper-----------
package org.jeecg.modules.mes.finance.receivable.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.finance.receivable.entity.MesReceivable;

public interface MesReceivableMapper extends BaseMapper<MesReceivable> {
    @Select("SELECT * FROM c_mes_receivable WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesReceivable selectDeletedByCode(String code);

    @Update("UPDATE c_mes_receivable SET code=#{code}, customer_id=#{customerId}, source_type=#{sourceType}, source_bill_id=#{sourceBillId}, source_bill_no=#{sourceBillNo}, amount=#{amount}, received_amount=#{receivedAmount}, unsettled_amount=#{unsettledAmount}, credit_period=#{creditPeriod}, due_date=#{dueDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesReceivable entity);

    @Select("SELECT * FROM c_mes_receivable WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesReceivable selectByIdForUpdate(@Param("id") String id);

    //update-begin O2D2O sign联动应收: 原子确认+按来源单号查
    @Update("UPDATE c_mes_receivable SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int confirmWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") java.util.Date updateTime);

    @Select("SELECT * FROM c_mes_receivable WHERE source_bill_id = #{sourceBillId} AND del_flag = 0 LIMIT 1")
    MesReceivable selectBySourceBillId(@Param("sourceBillId") String sourceBillId);
    //update-end O2D2O
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应收单Mapper-----------
