//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 07 c_mes_completion_receipt_item（JOIN status!=2）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.manufacturing.completion.entity.MesCompletionReceiptItem;
import org.jeecg.modules.mes.manufacturing.completion.mapper.MesCompletionReceiptItemMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class CompletionReceiptItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesCompletionReceiptItemMapper mapper;

    @Override public String describe() { return "c_mes_completion_receipt_item"; }

    @Override
    public void assertNotReferenced(String materialId) {
        // 仅统计"未完结"（status != "2"）的完工入库单，避免误拦已入库历史单据
        QueryWrapper<MesCompletionReceiptItem> qw = new QueryWrapper<>();
        qw.eq("material_id", materialId)
          .apply("receipt_id IN (SELECT id FROM c_mes_completion_receipt WHERE status <> '2')");
        Long cnt = mapper.selectCount(qw);
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 行未完结的完工入库引用，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 07-----------
