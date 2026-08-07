//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 12 c_mes_price（del_flag=0 计数）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.sales.entity.MesPrice;
import org.jeecg.modules.mes.sales.mapper.MesPriceMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class PriceReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesPriceMapper mapper;

    @Override public String describe() { return "c_mes_price"; }

    @Override
    public void assertNotReferenced(String materialId) {
        // 仅排除已软删价格档，活跃价格仍需先归档
        Long cnt = mapper.selectCount(
            new QueryWrapper<MesPrice>().eq("material_id", materialId).eq("del_flag", 0));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 个活跃价格档（c_mes_price, del_flag=0）引用，请先归档");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 12-----------
