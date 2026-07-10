//update-begin---author:ruiwancheng---date:2026-07-11---for: 审计修复#12-必填字段校验-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesCustomerFollowUp;
import org.jeecg.modules.mes.basic.mapper.MesCustomerFollowUpMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerFollowUpService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class MesCustomerFollowUpServiceImpl extends ServiceImpl<MesCustomerFollowUpMapper, MesCustomerFollowUp> implements IMesCustomerFollowUpService {

    @Override
    @Transactional
    public boolean save(MesCustomerFollowUp entity) {
        validate(entity);
        return super.save(entity);
    }

    @Override
    @Transactional
    public boolean updateById(MesCustomerFollowUp entity) {
        validate(entity);
        return super.updateById(entity);
    }

    private void validate(MesCustomerFollowUp e) {
        if (!StringUtils.hasText(e.getFollowType())) {
            throw new JeecgBootException("跟进方式不能为空");
        }
        if (e.getFollowDate() == null) {
            throw new JeecgBootException("跟进日期不能为空");
        }
        if (!StringUtils.hasText(e.getContent())) {
            throw new JeecgBootException("跟进内容不能为空");
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-11---for: 审计修复#12-必填字段校验-----------
