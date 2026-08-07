//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 02 c_mes_inventory_ledger（完全无行）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.jeecg.modules.mes.purchase.ledger.entity.MesInventoryLedger;
import org.jeecg.modules.mes.purchase.ledger.mapper.MesInventoryLedgerMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class InventoryLedgerReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesInventoryLedgerMapper mapper;

    @Override public String describe() { return "c_mes_inventory_ledger"; }

    @Override
    public void assertNotReferenced(String materialId) {
        Long cnt = mapper.selectCount(new QueryWrapper<MesInventoryLedger>().eq("material_id", materialId));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料在 c_mes_inventory_ledger 仍有 " + cnt + " 行台账记录，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 02-----------
