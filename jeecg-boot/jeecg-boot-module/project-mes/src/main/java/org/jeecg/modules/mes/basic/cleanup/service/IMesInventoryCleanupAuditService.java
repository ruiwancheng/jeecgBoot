//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】审计 Service 接口(阶段 2)-----------
package org.jeecg.modules.mes.basic.cleanup.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.cleanup.entity.MesInventoryCleanupAudit;

import java.math.BigDecimal;

public interface IMesInventoryCleanupAuditService extends IService<MesInventoryCleanupAudit> {
    /**
     * 记录一次清理审计（用于 ui-single / ui-batch / sql-emergency 三种来源）。
     *
     * @param source      来源标识：ui-single / ui-batch / sql-emergency
     * @param inventoryId 被清理的 c_mes_inventory.id
     * @param materialId  物料 ID（可空）
     * @param warehouseId 仓库 ID（可空）
     * @param currentQty  清理时的 current_qty（可空）
     * @param riskType    风险类型 A2/B2（可空，由调用方基于 row 派生）
     * @param operator    操作人
     */
    void log(String source, String inventoryId, String materialId, String warehouseId, BigDecimal currentQty, String riskType, String operator);
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】审计 Service 接口-----------
