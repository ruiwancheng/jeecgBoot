//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 14 c_mes_purchase_apply_item（JOIN status!=2）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApplyItem;
import org.jeecg.modules.mes.purchase.apply.mapper.MesPurchaseApplyItemMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class PurchaseApplyItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesPurchaseApplyItemMapper mapper;

    @Override public String describe() { return "c_mes_purchase_apply_item"; }

    @Override
    public void assertNotReferenced(String materialId) {
        QueryWrapper<MesPurchaseApplyItem> qw = new QueryWrapper<>();
        qw.eq("material_id", materialId)
          .apply("apply_id IN (SELECT id FROM c_mes_purchase_apply WHERE status <> '2')");
        Long cnt = mapper.selectCount(qw);
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 行未完结的采购申请引用，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 14-----------
