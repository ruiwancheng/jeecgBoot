//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Mapper-----------
package org.jeecg.modules.mes.purchase.apply.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApply;

public interface MesPurchaseApplyMapper extends BaseMapper<MesPurchaseApply> {
    @Select("SELECT * FROM c_mes_purchase_apply WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPurchaseApply selectDeletedByCode(String code);

    @Update("UPDATE c_mes_purchase_apply SET code=#{code}, dept_id=#{deptId}, applicant_id=#{applicantId}, apply_date=#{applyDate}, required_date=#{requiredDate}, budget_subject=#{budgetSubject}, total_amount=#{totalAmount}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesPurchaseApply entity);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Mapper-----------
