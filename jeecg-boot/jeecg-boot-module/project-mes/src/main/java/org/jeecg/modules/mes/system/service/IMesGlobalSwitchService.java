//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Service接口-----------
package org.jeecg.modules.mes.system.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.system.entity.MesGlobalSwitch;
import org.jeecg.modules.mes.system.vo.CloseCheckResult;

public interface IMesGlobalSwitchService extends IService<MesGlobalSwitch> {

    /**
     * 检查开关是否可关闭
     * @param switchKey 开关标识
     * @return 检查结果（含 errors 清单）
     */
    CloseCheckResult checkCanClose(String switchKey);

    /**
     * 关闭生产批次管理总开关（原子操作）
     * 1. 校验 L1/L3 检查
     * 2. 总开关置 0
     * 3. 所有物料的 batch_enabled 批量置 0（解决并发竞态）
     * @return 检查结果（用于确认是否真的关闭成功）
     */
    CloseCheckResult closeBatchSwitch();

    /**
     * 判断开关是否开启（业务层使用）
     * @param switchKey 开关标识
     * @return true=开 false=关
     */
    boolean isEnabled(String switchKey);
}
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Service接口-----------