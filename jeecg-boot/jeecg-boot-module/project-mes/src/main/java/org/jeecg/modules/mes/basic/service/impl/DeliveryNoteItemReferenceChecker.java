//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 09 c_mes_delivery_note_item（JOIN status!=3）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNoteItem;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteItemMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class DeliveryNoteItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesDeliveryNoteItemMapper mapper;

    @Override public String describe() { return "c_mes_delivery_note_item"; }

    @Override
    public void assertNotReferenced(String materialId) {
        // 仅统计"未发货完结"（status != "3"）的发货单
        QueryWrapper<MesDeliveryNoteItem> qw = new QueryWrapper<>();
        qw.eq("material_id", materialId)
          .apply("delivery_id IN (SELECT id FROM c_mes_delivery_note WHERE status <> '3')");
        Long cnt = mapper.selectCount(qw);
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 行未发货完结的发货单引用，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 09-----------
