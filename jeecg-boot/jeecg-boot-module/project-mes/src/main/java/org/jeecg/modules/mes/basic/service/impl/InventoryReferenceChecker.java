//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 01 c_mes_inventory（完全无行）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesInventory;
import org.jeecg.modules.mes.basic.mapper.MesInventoryMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class InventoryReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesInventoryMapper mapper;

    @Override public String describe() { return "c_mes_inventory"; }

    @Override
    public void assertNotReferenced(String materialId) {
        // P0：完全无行才放行（含零库存），否则软删后产生新孤儿
        Long cnt = mapper.selectCount(new QueryWrapper<MesInventory>().eq("material_id", materialId));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料在 c_mes_inventory 仍有 " + cnt + " 行引用（含零库存），请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 01-----------
