//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 16 c_mes_purchase_receipt_item（JOIN status!=2）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceiptItem;
import org.jeecg.modules.mes.purchase.receipt.mapper.MesPurchaseReceiptItemMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class PurchaseReceiptItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesPurchaseReceiptItemMapper mapper;

    @Override public String describe() { return "c_mes_purchase_receipt_item"; }

    @Override
    public void assertNotReferenced(String materialId) {
        QueryWrapper<MesPurchaseReceiptItem> qw = new QueryWrapper<>();
        qw.eq("material_id", materialId)
          .apply("receipt_id IN (SELECT id FROM c_mes_purchase_receipt WHERE status <> '2')");
        Long cnt = mapper.selectCount(qw);
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 行未完结的采购入库单引用，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 16-----------
