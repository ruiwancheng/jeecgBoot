//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 08 c_mes_cost_log（完全无行）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.purchase.ledger.entity.MesCostLog;
import org.jeecg.modules.mes.purchase.ledger.mapper.MesCostLogMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class CostLogReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesCostLogMapper mapper;

    @Override public String describe() { return "c_mes_cost_log"; }

    @Override
    public void assertNotReferenced(String materialId) {
        Long cnt = mapper.selectCount(new QueryWrapper<MesCostLog>().eq("material_id", materialId));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料在 c_mes_cost_log 仍有 " + cnt + " 行成本变动记录，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 08-----------
