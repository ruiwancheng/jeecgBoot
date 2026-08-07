//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM子项Mapper-----------
package org.jeecg.modules.mes.manufacturing.bom.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBomItem;

import java.util.List;

public interface MesBomItemMapper extends BaseMapper<MesBomItem> {
    //update-begin---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 release 查 BOM 子件（用量×planQty 校验库存+生成草稿领料单）-----------
    @Select("SELECT * FROM c_mes_bom_item WHERE bom_id = #{bomId} ORDER BY line_no")
    List<MesBomItem> selectByMainId(@Param("bomId") String bomId);
    //update-end---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 release 查 BOM 子件-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM子项Mapper-----------
