//update-begin---author:ruiwancheng---date:2026-07-21  for：【编码规则】ServiceImpl+nextCode-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesCodeRule;
import org.jeecg.modules.mes.basic.mapper.MesCodeRuleMapper;
import org.jeecg.modules.mes.basic.service.IMesCodeRuleService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.SimpleDateFormat;
import java.util.Date;

@Slf4j
@Service
public class MesCodeRuleServiceImpl extends ServiceImpl<MesCodeRuleMapper, MesCodeRule> implements IMesCodeRuleService {

    @Override
    @Transactional(rollbackFor = Exception.class)
    public synchronized String nextCode(String ruleCode) {
        MesCodeRule rule = getOne(new LambdaQueryWrapper<MesCodeRule>().eq(MesCodeRule::getRuleCode, ruleCode));
        if (rule == null) {
            // 自动创建默认规则
            rule = new MesCodeRule();
            rule.setRuleCode(ruleCode);
            rule.setRuleName("自动创建-" + ruleCode);
            rule.setPrefix(ruleCode);
            rule.setDateFormat("yyyyMMdd");
            rule.setSeqLength(4);
            rule.setResetCycle("DAILY");
            rule.setCurrentSeq(0);
            save(rule);
            log.info("自动创建编码规则: {}", ruleCode);
        }

        String today = formatDate(rule.getDateFormat());
        int nextSeq;

        // 判断是否需要重置流水号
        boolean shouldReset = false;
        if ("DAILY".equals(rule.getResetCycle())) {
            shouldReset = !today.equals(rule.getCurrentDate());
        } else if ("MONTHLY".equals(rule.getResetCycle())) {
            String thisMonth = today.substring(0, 6);
            String lastMonth = rule.getCurrentDate() != null ? rule.getCurrentDate().substring(0, 6) : "";
            shouldReset = !thisMonth.equals(lastMonth);
        } else if ("YEARLY".equals(rule.getResetCycle())) {
            String thisYear = today.substring(0, 4);
            String lastYear = rule.getCurrentDate() != null ? rule.getCurrentDate().substring(0, 4) : "";
            shouldReset = !thisYear.equals(lastYear);
        }

        if (shouldReset || rule.getCurrentSeq() == null) {
            nextSeq = 1;
        } else {
            nextSeq = rule.getCurrentSeq() + 1;
        }

        // 更新数据库中的序号和日期
        rule.setCurrentSeq(nextSeq);
        rule.setCurrentDate(today);
        updateById(rule);

        String seqStr = String.format("%0" + rule.getSeqLength() + "d", nextSeq);
        return rule.getPrefix() + today + "-" + seqStr;
    }

    private String formatDate(String format) {
        try {
            return new SimpleDateFormat(format).format(new Date());
        } catch (Exception e) {
            return new SimpleDateFormat("yyyyMMdd").format(new Date());
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-21  for：【编码规则】ServiceImpl+nextCode-----------
