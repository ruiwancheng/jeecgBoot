//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Service接口-----------
package org.jeecg.modules.mes.basic.service;

import java.math.BigDecimal;

public interface IMesInventoryService {
    void stockIn(String materialId, String warehouseId, BigDecimal qty, String bizType, String bizId);
    void stockOut(String materialId, String warehouseId, BigDecimal qty, String bizType, String bizId);
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存Service接口-----------
