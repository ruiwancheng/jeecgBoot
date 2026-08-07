//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 06 c_mes_bom_item（完全无行）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBomItem;
import org.jeecg.modules.mes.manufacturing.bom.mapper.MesBomItemMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BomItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesBomItemMapper mapper;

    @Override public String describe() { return "c_mes_bom_item"; }

    @Override
    public void assertNotReferenced(String materialId) {
        Long cnt = mapper.selectCount(new QueryWrapper<MesBomItem>().eq("material_id", materialId));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 个BOM子项引用，请先从BOM中移除该物料");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 06-----------
