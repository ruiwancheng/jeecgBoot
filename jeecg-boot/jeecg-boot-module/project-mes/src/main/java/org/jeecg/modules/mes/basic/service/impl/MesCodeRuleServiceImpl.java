//update-begin---author:ruiwancheng---date:2026-07-21  for：【编码规则】ServiceImpl+nextCode-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesCodeRule;
import org.jeecg.modules.mes.basic.mapper.MesCodeRuleMapper;
import org.jeecg.modules.mes.basic.service.IMesCodeRuleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.SimpleDateFormat;
import java.util.Date;

@Slf4j
@Service
public class MesCodeRuleServiceImpl extends ServiceImpl<MesCodeRuleMapper, MesCodeRule> implements IMesCodeRuleService {

    @Autowired(required = false)
    private SqlSessionFactory sqlSessionFactory;

    @PostConstruct
    public void initTable() {
        try {
            getOne(new LambdaQueryWrapper<MesCodeRule>().last("LIMIT 0"));
        } catch (Exception e) {
            log.warn("c_mes_code_rule 表不存在，自动创建...");
            if (sqlSessionFactory != null) {
                try (SqlSession session = sqlSessionFactory.openSession()) {
                    session.getConnection().createStatement().execute(
                        "CREATE TABLE IF NOT EXISTS c_mes_code_rule (" +
                        " id VARCHAR(32) NOT NULL COMMENT '主键'," +
                        " rule_code VARCHAR(30) NOT NULL COMMENT '规则编码'," +
                        " rule_name VARCHAR(50) NOT NULL COMMENT '规则名称'," +
                        " prefix VARCHAR(20) NOT NULL COMMENT '前缀'," +
                        " date_format VARCHAR(20) DEFAULT 'yyyyMMdd'," +
                        " seq_length INT DEFAULT 4," +
                        " reset_cycle VARCHAR(10) DEFAULT 'DAILY'," +
                        " current_seq INT DEFAULT 0," +
                        " current_date VARCHAR(10)," +
                        " remark VARCHAR(200)," +
                        " create_by VARCHAR(50)," +
                        " create_time DATETIME," +
                        " update_by VARCHAR(50)," +
                        " update_time DATETIME," +
                        " del_flag INT DEFAULT 0," +
                        " PRIMARY KEY (id)," +
                        " UNIQUE INDEX uk_code_rule (rule_code, del_flag)" +
                        ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
                    );
                    session.getConnection().commit();
                    log.info("✅ c_mes_code_rule 自动建表成功");
                    // 初始化默认规则
                    initDefaultRules(session);
                } catch (Exception ex) {
                    log.error("自动建表失败: {}", ex.getMessage());
                }
            }
        }
    }

    private void initDefaultRules(SqlSession session) throws Exception {
        long count = getBaseMapper().selectCount(new LambdaQueryWrapper<>());
        if (count == 0) {
            java.sql.Connection conn = session.getConnection();
            conn.createStatement().execute("INSERT INTO c_mes_code_rule VALUES " +
              "(REPLACE(UUID(),'-',''),'SO','销售订单编码','SO','yyyyMMdd',4,'DAILY',0,NULL,NULL,'admin',NOW(),'admin',NOW(),0)");
            conn.createStatement().execute("INSERT INTO c_mes_code_rule VALUES " +
              "(REPLACE(UUID(),'-',''),'PO','采购订单编码','PO','yyyyMMdd',4,'DAILY',0,NULL,NULL,'admin',NOW(),'admin',NOW(),0)");
            conn.createStatement().execute("INSERT INTO c_mes_code_rule VALUES " +
              "(REPLACE(UUID(),'-',''),'MO','生产订单编码','MO','yyyyMMdd',4,'DAILY',0,NULL,NULL,'admin',NOW(),'admin',NOW(),0)");
            conn.commit();
            log.info("✅ 默认编码规则初始化完成(SO/PO/MO)");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public synchronized String nextCode(String ruleCode) {
        MesCodeRule rule = getOne(new LambdaQueryWrapper<MesCodeRule>().eq(MesCodeRule::getRuleCode, ruleCode));
        if (rule == null) {
            throw new JeecgBootException("编码规则不存在: " + ruleCode);
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
