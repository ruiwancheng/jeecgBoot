//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单Service实现-----------
package org.jeecg.modules.mes.sales.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.sales.entity.MesSalesOrder;
import org.jeecg.modules.mes.sales.entity.MesSalesOrderItem;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderMapper;
import org.jeecg.modules.mes.sales.service.IMesSalesOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Service
public class MesSalesOrderServiceImpl extends ServiceImpl<MesSalesOrderMapper, MesSalesOrder> implements IMesSalesOrderService {

    @Autowired
    private MesSalesOrderItemMapper itemMapper;

    @Override
    public MesSalesOrder queryWithItems(String id) {
        MesSalesOrder order = baseMapper.selectById(id);
        if (order != null) {
            LambdaQueryWrapper<MesSalesOrderItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesSalesOrderItem::getOrderId, id).orderByAsc(MesSalesOrderItem::getLineNo);
            order.setItems(itemMapper.selectList(qw));
        }
        return order;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesSalesOrder entity) {
        validateOrder(entity);
        if (entity.getStatus() == null) entity.setStatus("1"); // 默认草稿
        calcTotal(entity);
        // 编码回收
        QueryWrapper<MesSalesOrder> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("订单编码已存在");
        MesSalesOrder old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("订单编码已存在"); }
        }
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesSalesOrder entity) {
        if (entity.getId() == null) throw new JeecgBootException("订单ID不能为空");
        validateOrder(entity);
        calcTotal(entity);
        QueryWrapper<MesSalesOrder> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("订单编码已存在");
        super.updateById(entity);
        // 删除旧行，插入新行
        LambdaQueryWrapper<MesSalesOrderItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesSalesOrderItem::getOrderId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        LambdaQueryWrapper<MesSalesOrderItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesSalesOrderItem::getOrderId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    private void validateOrder(MesSalesOrder entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("订单编码不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("订单编码长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getCustomerId())) throw new JeecgBootException("客户不能为空");
        List<MesSalesOrderItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个订单行");
        for (int i = 0; i < items.size(); i++) {
            MesSalesOrderItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getQuantity() == null || item.getQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行数量必须大于0");
            if (item.getUnitPrice() == null || item.getUnitPrice().compareTo(BigDecimal.ZERO) < 0)
                throw new JeecgBootException("第" + (i+1) + "行单价不能为负数");
            item.setLineNo(i + 1);
            item.setOrderId(entity.getId());
            item.setAmount(item.getQuantity().multiply(item.getUnitPrice()).setScale(2, java.math.RoundingMode.HALF_UP));
        }
    }

    private void calcTotal(MesSalesOrder entity) {
        BigDecimal total = BigDecimal.ZERO;
        for (MesSalesOrderItem item : entity.getItems()) {
            if (item.getQuantity() != null && item.getUnitPrice() != null)
                total = total.add(item.getQuantity().multiply(item.getUnitPrice()));
        }
        entity.setTotalAmount(total.setScale(2, java.math.RoundingMode.HALF_UP));
    }

    private void saveItems(MesSalesOrder entity) {
        for (MesSalesOrderItem item : entity.getItems()) {
            item.setOrderId(entity.getId());
            itemMapper.insert(item);
        }
    }

    private String getCurrentUsername() {
        try {
            LoginUser user = (LoginUser) SecurityUtils.getSubject().getPrincipal();
            return user != null ? user.getUsername() : "system";
        } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单Service实现-----------
