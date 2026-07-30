//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档Service接口-----------
package org.jeecg.modules.mes.batch.master.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.batch.master.entity.MesBatch;

import java.math.BigDecimal;
import java.util.Date;

public interface IMesBatchService extends IService<MesBatch> {
    /**
     * 创建批次（系统自动生成批次号）
     * @param materialId 物料ID
     * @param originType 来源类型(1采购/2生产/3手工)
     * @param originBillId 来源单据ID
     * @param originBillNo 来源单据号
     * @param qty 初始数量
     * @param unitCost 批次单位成本
     * @param productionDate 生产日期
     * @param expiryDate 有效期(可空)
     * @return 新批次ID
     */
    String createBatch(String materialId, String originType, String originBillId, String originBillNo,
                       BigDecimal qty, BigDecimal unitCost, Date productionDate, Date expiryDate);

    /**
     * 冻结/解冻批次
     */
    void freeze(String id, String operator);
    void unfreeze(String id, String operator);
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档Service接口-----------
