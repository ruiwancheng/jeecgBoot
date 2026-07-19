//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.entity.MesInventory;
import org.jeecg.modules.mes.basic.mapper.MesInventoryMapper;
import org.jeecg.modules.mes.basic.service.IMesInventoryService;
import org.jeecg.modules.mes.purchase.ledger.entity.MesInventoryLedger;
import org.jeecg.modules.mes.purchase.ledger.service.IMesInventoryLedgerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Date;
import java.util.UUID;

@Service
public class MesInventoryServiceImpl implements IMesInventoryService {

    @Autowired private MesInventoryMapper inventoryMapper;
    @Autowired private IMesInventoryLedgerService ledgerService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void stockIn(String materialId, String warehouseId, BigDecimal qty, String bizType, String bizId) {
        if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("入库数量必须大于0");
        String username = getUsername();
        // 行锁查库存快照（与stockOut保持一致）
        MesInventory inv = inventoryMapper.selectForUpdate(materialId, warehouseId);
        BigDecimal before = inv != null ? inv.getCurrentQty() : BigDecimal.ZERO;
        BigDecimal after = before.add(qty);
        // upsert
        String id = inv != null ? inv.getId() : UUID.randomUUID().toString().replace("-", "");
        inventoryMapper.upsertWithDelta(id, materialId, warehouseId, before, qty, username, username);
        // 写台账
        writeLedger(materialId, warehouseId, before, qty, BigDecimal.ZERO, after, bizType, bizId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void stockOut(String materialId, String warehouseId, BigDecimal qty, String bizType, String bizId) {
        if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("出库数量必须大于0");
        // 行锁查当前库存
        MesInventory inv = inventoryMapper.selectForUpdate(materialId, warehouseId);
        BigDecimal before = inv != null ? inv.getCurrentQty() : BigDecimal.ZERO;
        if (before.compareTo(qty) < 0) throw new JeecgBootException("库存不足：当前库存" + before + "，出库" + qty);
        BigDecimal after = before.subtract(qty);
        // upsert
        String username = getUsername();
        String id = inv != null ? inv.getId() : UUID.randomUUID().toString().replace("-", "");
        inventoryMapper.upsertWithDelta(id, materialId, warehouseId, before, qty.negate(), username, username);
        // 写台账
        writeLedger(materialId, warehouseId, before, BigDecimal.ZERO, qty, after, bizType, bizId);
    }

    private MesInventory findByMaterialAndWarehouse(String materialId, String warehouseId) {
        LambdaQueryWrapper<MesInventory> qw = new LambdaQueryWrapper<>();
        qw.eq(MesInventory::getMaterialId, materialId).eq(MesInventory::getWarehouseId, warehouseId);
        return inventoryMapper.selectOne(qw);
    }

    private void writeLedger(String materialId, String warehouseId, BigDecimal beginningQty, BigDecimal inQty, BigDecimal outQty, BigDecimal endingQty, String bizType, String bizId) {
        MesInventoryLedger ledger = new MesInventoryLedger();
        ledger.setMaterialId(materialId);
        ledger.setWarehouseId(warehouseId);
        ledger.setBeginningQty(beginningQty);
        ledger.setInQty(inQty);
        ledger.setOutQty(outQty);
        ledger.setEndingQty(endingQty);
        ledger.setRecordDate(new Date());
        ledger.setBizType(bizType);
        ledger.setBizId(bizId);
        ledgerService.save(ledger);
    }

    private String getUsername() {
        try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Service实现-----------
