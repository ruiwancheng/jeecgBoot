//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应付单Mapper-----------
package org.jeecg.modules.mes.finance.payable.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.finance.payable.entity.MesPayable;

public interface MesPayableMapper extends BaseMapper<MesPayable> {
    @Select("SELECT * FROM c_mes_payable WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPayable selectDeletedByCode(String code);

    @Update("UPDATE c_mes_payable SET code=#{code}, supplier_id=#{supplierId}, source_type=#{sourceType}, source_bill_id=#{sourceBillId}, source_bill_no=#{sourceBillNo}, amount=#{amount}, paid_amount=#{paidAmount}, unsettled_amount=#{unsettledAmount}, credit_period=#{creditPeriod}, due_date=#{dueDate}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesPayable entity);

    @Select("SELECT * FROM c_mes_payable WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesPayable selectByIdForUpdate(@Param("id") String id);
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应付单Mapper-----------
