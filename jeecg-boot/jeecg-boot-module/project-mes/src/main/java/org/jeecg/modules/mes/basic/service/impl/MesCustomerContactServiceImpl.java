//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Service实现-----------
//update-begin---author:ruiwancheng---date:2026-07-11---for: 审计修复#12-必填字段校验-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesCustomerContact;
import org.jeecg.modules.mes.basic.mapper.MesCustomerContactMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerContactService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class MesCustomerContactServiceImpl extends ServiceImpl<MesCustomerContactMapper, MesCustomerContact> implements IMesCustomerContactService {

    @Override
    @Transactional
    public boolean save(MesCustomerContact entity) {
        validate(entity);
        return super.save(entity);
    }

    @Override
    @Transactional
    public boolean updateById(MesCustomerContact entity) {
        validate(entity);
        return super.updateById(entity);
    }

    private void validate(MesCustomerContact e) {
        if (!StringUtils.hasText(e.getName())) {
            throw new JeecgBootException("联系人姓名不能为空");
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-11---for: 审计修复#12-必填字段校验-----------
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Service实现-----------
