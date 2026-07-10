package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.modules.mes.basic.entity.MesCustomerAddress;
import org.jeecg.modules.mes.basic.mapper.MesCustomerAddressMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerAddressService;
import org.springframework.stereotype.Service;

@Service
public class MesCustomerAddressServiceImpl extends ServiceImpl<MesCustomerAddressMapper, MesCustomerAddress> implements IMesCustomerAddressService {
}
