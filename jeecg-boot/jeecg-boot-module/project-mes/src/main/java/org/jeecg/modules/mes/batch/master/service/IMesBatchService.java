//update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 生产批次号手工录入模式——拆 createBatchWithManualNo，createBatch 标 Deprecated 保留兼容-----------
package org.jeecg.modules.mes.batch.master.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.batch.master.entity.MesBatch;

import java.math.BigDecimal;
import java.util.Date;

public interface IMesBatchService extends IService<MesBatch> {
    /**
     * 【已废弃】创建批次（自动生成 batchNo）
     * 保留原因：MesBatchController.add 仍可能用，外部系统兼容。
     * @deprecated 业务侧（采购/完工入库）改用 {@link #createBatchWithManualNo} ；
     *             Controller 走兜底（batchNo 为空时用此方法）
     * @see #createBatchWithManualNo
     */
    @Deprecated
    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-创建批次服务接口（自动 batchNo）扩展保质期参数-----------
    String createBatch(String materialId, String originType, String originBillId, String originBillNo,
                       BigDecimal qty, BigDecimal unitCost, Date productionDate, Date expiryDate,
                       Integer shelfLife);
    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-创建批次服务接口（自动 batchNo）扩展保质期参数-----------

    /**
     * 创建批次（手工录入 batchNo）
     *
     * @param batchNo        手工录入批次号（必填，≤50 字符；不同物料可重号，同一物料内不可重复）
     * @param productionDate 生产日期（可空）
     * @param expiryDate     有效期至（可空；V10.0.0 起从来源明细透传，不再由本方法计算）
     * @param shelfLife      保质期(天)（可空；V10.0.0 起从来源明细透传，允许批次独立于物料的保质期）
     * @throws org.jeecg.common.exception.JeecgBootException 当 batchNo 为空/超长/同物料重复时
     */
    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-创建批次服务接口（手工 batchNo）扩展保质期参数-----------
    String createBatchWithManualNo(String materialId, String batchNo, String originType,
                                    String originBillId, String originBillNo,
                                    BigDecimal qty, BigDecimal unitCost,
                                    Date productionDate, Date expiryDate,
                                    Integer shelfLife);
    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-创建批次服务接口（手工 batchNo）扩展保质期参数-----------

    /**
     * 冻结/解冻批次
     */
    void freeze(String id, String operator);
    void unfreeze(String id, String operator);
}
//update-end---author:ruiwancheng---date:20260801---for: V8.0.3 生产批次号手工录入模式--------
