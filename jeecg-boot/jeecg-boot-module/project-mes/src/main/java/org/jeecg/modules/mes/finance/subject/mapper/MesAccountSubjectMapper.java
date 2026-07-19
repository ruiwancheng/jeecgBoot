//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目Mapper-----------
package org.jeecg.modules.mes.finance.subject.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.finance.subject.entity.MesAccountSubject;

public interface MesAccountSubjectMapper extends BaseMapper<MesAccountSubject> {
    @Select("SELECT * FROM c_mes_account_subject WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesAccountSubject selectDeletedByCode(String code);

    @Update("UPDATE c_mes_account_subject SET code=#{code}, name=#{name}, category=#{category}, level=#{level}, parent_id=#{parentId}, balance_direction=#{balanceDirection}, status=#{status}, is_leaf=#{isLeaf}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesAccountSubject entity);
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目Mapper-----------
