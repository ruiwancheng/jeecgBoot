//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Service实现（含checkCanClose+closeBatchSwitch原子操作）-----------
package org.jeecg.modules.mes.system.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.system.entity.MesGlobalSwitch;
import org.jeecg.modules.mes.system.mapper.MesGlobalSwitchMapper;
import org.jeecg.modules.mes.system.service.IMesGlobalSwitchService;
import org.jeecg.modules.mes.system.vo.CloseCheckResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
public class MesGlobalSwitchServiceImpl extends ServiceImpl<MesGlobalSwitchMapper, MesGlobalSwitch> implements IMesGlobalSwitchService {

    /** 生产批次管理总开关 key */
    public static final String SWITCH_KEY_BATCH = "mes_batch_enabled";

    @Override
    public CloseCheckResult checkCanClose(String switchKey) {
        if (!SWITCH_KEY_BATCH.equals(switchKey)) {
            return CloseCheckResult.ok();
        }
        CloseCheckResult result = new CloseCheckResult();

        // L1：批次库存表有余额的记录数
        Long invCount = baseMapper.countBatchInventoryWithQty();
        if (invCount != null && invCount > 0) {
            result.addError("L1", "批次库存余额",
                    String.format("存在 %d 条批次库存余额（qty > 0），请先通过批次出库或库存调整消化", invCount));
        }

        // L3：关联了未完结业务单据的批次记录数
        Long openDocCount = baseMapper.countOpenBatchRelatedDocs();
        if (openDocCount != null && openDocCount > 0) {
            result.addError("L3", "未完结业务单据",
                    String.format("存在 %d 个批次关联了未完结业务单据，请先审核/作废", openDocCount));
        }

        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public CloseCheckResult closeBatchSwitch() {
        // 1. 校验
        CloseCheckResult check = checkCanClose(SWITCH_KEY_BATCH);
        if (check.hasError()) {
            log.warn("[GlobalSwitch] 关闭批次总开关被阻断：{}", check.getErrors());
            return check;
        }

        // 2. 总开关置 0
        int updated = baseMapper.update(null,
                Wrappers.<MesGlobalSwitch>lambdaUpdate()
                        .set(MesGlobalSwitch::getSwitchValue, 0)
                        .eq(MesGlobalSwitch::getSwitchKey, SWITCH_KEY_BATCH));
        if (updated == 0) {
            throw new JeecgBootException("生产批次总开关记录不存在，请先初始化种子数据");
        }

        // 3. 批量将所有物料的 batch_enabled 置 0（解决 P1-4 并发竞态）
        int materialUpdated = baseMapper.turnOffAllBatchEnabled();
        log.info("[GlobalSwitch] 关闭批次总开关完成，影响物料 {} 条", materialUpdated);

        return CloseCheckResult.ok();
    }

    @Override
    public boolean isEnabled(String switchKey) {
        MesGlobalSwitch sw = getOne(new LambdaQueryWrapper<MesGlobalSwitch>()
                .eq(MesGlobalSwitch::getSwitchKey, switchKey));
        return sw != null && Integer.valueOf(1).equals(sw.getSwitchValue());
    }
}
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Service实现（含checkCanClose+closeBatchSwitch原子操作）-----------