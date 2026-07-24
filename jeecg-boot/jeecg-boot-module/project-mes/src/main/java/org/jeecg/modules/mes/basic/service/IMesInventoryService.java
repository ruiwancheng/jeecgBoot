//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存接口升级-增加单价金额参数-----------
package org.jeecg.modules.mes.basic.service;

public interface IMesInventoryService {
    void stockIn(String materialId, String warehouseId, java.math.BigDecimal qty, java.math.BigDecimal unitCost, java.math.BigDecimal amount, String bizType, String bizId);
    void stockOut(String materialId, String warehouseId, java.math.BigDecimal qty, java.math.BigDecimal unitCost, java.math.BigDecimal amount, String bizType, String bizId);
}
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存接口升级-增加单价金额参数-----------
