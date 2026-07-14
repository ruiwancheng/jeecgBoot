//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Mapper-----------
//update-begin---author:ruiwancheng---date:2026-07-14---for: 审计修复#5-resurrect SQL加AND del_flag=1防并发覆盖-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesSupplier;

public interface MesSupplierMapper extends BaseMapper<MesSupplier> {
    @Select("SELECT * FROM c_mes_supplier WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesSupplier selectDeletedByCode(String code);

    @Update("UPDATE c_mes_supplier SET code=#{code}, name=#{name}, type=#{type}, status=#{status}, grade=#{grade}, blacklist_flag=#{blacklistFlag}, contact=#{contact}, phone=#{phone}, address=#{address}, invoice_title=#{invoiceTitle}, tax_no=#{taxNo}, bank_name=#{bankName}, bank_account=#{bankAccount}, remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id} AND del_flag=1")
    void resurrect(MesSupplier entity);
}
//update-end---author:ruiwancheng---date:2026-07-14---for: 审计修复#5-resurrect SQL加AND del_flag=1防并发覆盖-----------
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Mapper-----------
