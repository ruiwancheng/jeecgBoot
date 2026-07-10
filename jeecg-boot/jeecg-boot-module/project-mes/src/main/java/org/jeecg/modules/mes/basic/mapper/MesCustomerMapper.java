//update-begin---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.basic.entity.MesCustomer;

public interface MesCustomerMapper extends BaseMapper<MesCustomer> {
    @Select("SELECT * FROM c_mes_customer WHERE code = #{code} AND del_flag = 1 LIMIT 1")
    MesCustomer selectDeletedByCode(String code);

    @Update("UPDATE c_mes_customer SET code=#{code}, name=#{name}, type=#{type}, " +
            "grade=#{grade}, credit_limit=#{creditLimit}, salesman_id=#{salesmanId}, " +
            "industry=#{industry}, region=#{region}, scale=#{scale}, " +
            "invoice_title=#{invoiceTitle}, tax_no=#{taxNo}, bank_name=#{bankName}, " +
            "bank_account=#{bankAccount}, invoice_address=#{invoiceAddress}, " +
            "invoice_phone=#{invoicePhone}, invoice_type=#{invoiceType}, " +
            "contact=#{contact}, phone=#{phone}, address=#{address}, status=#{status}, " +
            "remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id}")
    void resurrect(MesCustomer entity);
}
//update-end---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户Mapper-----------
