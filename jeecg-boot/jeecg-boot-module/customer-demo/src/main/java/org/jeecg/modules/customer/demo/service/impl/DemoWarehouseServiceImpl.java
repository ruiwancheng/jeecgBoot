package org.jeecg.modules.customer.demo.service.impl;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.modules.customer.demo.entity.DemoWarehouse;
import org.jeecg.modules.customer.demo.mapper.DemoWarehouseMapper;
import org.jeecg.modules.customer.demo.service.IDemoWarehouseService;
import org.springframework.stereotype.Service;
@Service
public class DemoWarehouseServiceImpl extends ServiceImpl<DemoWarehouseMapper, DemoWarehouse> implements IDemoWarehouseService {}
