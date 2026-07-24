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

    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存接口升级-增加单价金额参数-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void stockIn(String materialId, String warehouseId, BigDecimal qty, BigDecimal unitCost, BigDecimal amount, String bizType, String bizId) {
        if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("入库数量必须大于0");
        String username = getUsername();
        MesInventory inv = inventoryMapper.selectForUpdate(materialId, warehouseId);
        BigDecimal before = inv != null ? inv.getCurrentQty() : BigDecimal.ZERO;
        BigDecimal after = before.add(qty);
        String id = inv != null ? inv.getId() : UUID.randomUUID().toString().replace("-", "");
        inventoryMapper.upsertWithDelta(id, materialId, warehouseId, before, qty, username, username);
        writeLedger(materialId, warehouseId, before, qty, BigDecimal.ZERO, after, unitCost, amount, null, bizType, bizId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void stockOut(String materialId, String warehouseId, BigDecimal qty, BigDecimal unitCost, BigDecimal amount, String bizType, String bizId) {
        if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("出库数量必须大于0");
        MesInventory inv = inventoryMapper.selectForUpdate(materialId, warehouseId);
        BigDecimal before = inv != null ? inv.getCurrentQty() : BigDecimal.ZERO;
        if (before.compareTo(qty) < 0) throw new JeecgBootException("库存不足：当前库存" + before + "，出库" + qty);
        BigDecimal after = before.subtract(qty);
        String username = getUsername();
        String id = inv != null ? inv.getId() : UUID.randomUUID().toString().replace("-", "");
        inventoryMapper.upsertWithDelta(id, materialId, warehouseId, before, qty.negate(), username, username);
        writeLedger(materialId, warehouseId, before, BigDecimal.ZERO, qty, after, unitCost, null, amount, bizType, bizId);
    }

    private void writeLedger(String materialId, String warehouseId,
            BigDecimal beginningQty, BigDecimal inQty, BigDecimal outQty, BigDecimal endingQty,
            BigDecimal unitCost, BigDecimal inAmount, BigDecimal outAmount,
            String bizType, String bizId) {
        MesInventoryLedger ledger = new MesInventoryLedger();
        ledger.setMaterialId(materialId);
        ledger.setWarehouseId(warehouseId);
        ledger.setBeginningQty(beginningQty);
        ledger.setInQty(inQty);
        ledger.setOutQty(outQty);
        ledger.setEndingQty(endingQty);
        ledger.setUnitCost(unitCost);
        ledger.setInAmount(inAmount);
        ledger.setOutAmount(outAmount);
        // TODO Phase2: 期初/期末金额需累计计算
        ledger.setBeginningAmount(BigDecimal.ZERO);
        ledger.setEndingAmount(BigDecimal.ZERO);
        ledger.setRecordDate(new Date());
        ledger.setBizType(bizType);
        ledger.setBizId(bizId);
        ledgerService.save(ledger);
    }
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存接口升级-增加单价金额参数-----------

    private String getUsername() {
        try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Service实现-----------
