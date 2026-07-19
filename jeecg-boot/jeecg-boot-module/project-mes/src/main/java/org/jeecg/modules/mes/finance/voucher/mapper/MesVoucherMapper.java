//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证Mapper-----------
package org.jeecg.modules.mes.finance.voucher.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.finance.voucher.entity.MesVoucher;
import java.util.Date;
public interface MesVoucherMapper extends BaseMapper<MesVoucher> {
    @Update("UPDATE c_mes_voucher SET status = '2', update_by = #{updateBy}, update_time = #{updateTime} WHERE id = #{id} AND status = '1'")
    int auditWithGuard(@Param("id") String id, @Param("updateBy") String updateBy, @Param("updateTime") Date updateTime);
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证Mapper-----------
