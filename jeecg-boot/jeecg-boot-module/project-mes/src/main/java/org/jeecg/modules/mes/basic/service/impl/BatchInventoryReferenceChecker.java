//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 04 c_mes_batch_inventory（完全无行）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;
import org.jeecg.modules.mes.batch.inventory.mapper.MesBatchInventoryMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BatchInventoryReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesBatchInventoryMapper mapper;

    @Override public String describe() { return "c_mes_batch_inventory"; }

    @Override
    public void assertNotReferenced(String materialId) {
        Long cnt = mapper.selectCount(new QueryWrapper<MesBatchInventory>().eq("material_id", materialId));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料在 c_mes_batch_inventory 仍有 " + cnt + " 行批次库存，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 04-----------
