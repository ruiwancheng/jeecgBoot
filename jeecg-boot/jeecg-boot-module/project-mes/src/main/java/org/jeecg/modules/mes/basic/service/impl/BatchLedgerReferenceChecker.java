//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 05 c_mes_batch_ledger（完全无行）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.batch.ledger.entity.MesBatchLedger;
import org.jeecg.modules.mes.batch.ledger.mapper.MesBatchLedgerMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BatchLedgerReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesBatchLedgerMapper mapper;

    @Override public String describe() { return "c_mes_batch_ledger"; }

    @Override
    public void assertNotReferenced(String materialId) {
        Long cnt = mapper.selectCount(new QueryWrapper<MesBatchLedger>().eq("material_id", materialId));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料在 c_mes_batch_ledger 仍有 " + cnt + " 行批次流水，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 05-----------
