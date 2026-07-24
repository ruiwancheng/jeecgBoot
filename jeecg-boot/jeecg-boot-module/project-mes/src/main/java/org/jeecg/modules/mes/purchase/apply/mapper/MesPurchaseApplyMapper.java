//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Mapper-----------
package org.jeecg.modules.mes.purchase.apply.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.Date;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApply;

public interface MesPurchaseApplyMapper extends BaseMapper<MesPurchaseApply> {
    @Select("SELECT * FROM c_mes_purchase_apply WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesPurchaseApply selectDeletedByCode(String code);

    @Update("UPDATE c_mes_purchase_apply SET code=#{code}, dept_id=#{deptId}, applicant_id=#{applicantId}, apply_date=#{applyDate}, required_date=#{requiredDate}, budget_subject=#{budgetSubject}, total_amount=#{totalAmount}, status=#{status}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    int resurrect(MesPurchaseApply entity);

    //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-编辑/删除用FOR UPDATE行锁防并发击穿(照抄采购订单+入库修复)-----------
    @Select("SELECT * FROM c_mes_purchase_apply WHERE id = #{id} AND del_flag = 0 FOR UPDATE")
    MesPurchaseApply selectByIdForUpdate(@Param("id") String id);

    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-审核1→3(对齐采购订单模式)+驳回1→4+反审核3→1-----------
    @Update("UPDATE c_mes_purchase_apply SET status = '3', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_purchase_apply SET status = '4', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int rejectWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);

    @Update("UPDATE c_mes_purchase_apply SET status = '1', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '3'")
    int unauditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-状态机修正-----------
    //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-编辑/删除用FOR UPDATE行锁防并发击穿-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Mapper-----------
