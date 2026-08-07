//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】审计 Service 实现(阶段 2)-----------
package org.jeecg.modules.mes.basic.cleanup.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.modules.mes.basic.cleanup.entity.MesInventoryCleanupAudit;
import org.jeecg.modules.mes.basic.cleanup.mapper.MesInventoryCleanupAuditMapper;
import org.jeecg.modules.mes.basic.cleanup.service.IMesInventoryCleanupAuditService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Slf4j
@Service
public class MesInventoryCleanupAuditServiceImpl extends ServiceImpl<MesInventoryCleanupAuditMapper, MesInventoryCleanupAudit> implements IMesInventoryCleanupAuditService {

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void log(String source, String inventoryId, String materialId, String warehouseId, BigDecimal currentQty, String riskType, String operator) {
        MesInventoryCleanupAudit row = new MesInventoryCleanupAudit();
        row.setBatchId(source);
        row.setInventoryId(inventoryId);
        row.setMaterialId(materialId);
        row.setWarehouseId(warehouseId);
        row.setCurrentQty(currentQty);
        row.setRiskType(riskType);
        row.setOperator(operator == null ? "system" : operator);
        row.setRolledBack(0);
        // 注意：cleaned_at 由 DB DEFAULT CURRENT_TIMESTAMP 生成，避免时区漂移
        this.save(row);
        log.info("[orphan-cleanup] audit log: batchId={}, invId={}, risk={}, op={}", source, inventoryId, riskType, operator);
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】审计 Service 实现-----------
