//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Service实现-----------
package org.jeecg.modules.mes.purchase.order.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrder;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItem;
import org.jeecg.modules.mes.purchase.order.mapper.MesPurchaseOrderItemMapper;
import org.jeecg.modules.mes.purchase.order.mapper.MesPurchaseOrderMapper;
import org.jeecg.modules.mes.purchase.order.service.IMesPurchaseOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;
import java.util.Date;
import java.util.List;

@Service
public class MesPurchaseOrderServiceImpl extends ServiceImpl<MesPurchaseOrderMapper, MesPurchaseOrder> implements IMesPurchaseOrderService {

    @Autowired
    private MesPurchaseOrderItemMapper itemMapper;

    @Override
    public MesPurchaseOrder queryWithItems(String id) {
        MesPurchaseOrder order = baseMapper.selectById(id);
        if (order != null) {
            LambdaQueryWrapper<MesPurchaseOrderItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesPurchaseOrderItem::getOrderId, id).orderByAsc(MesPurchaseOrderItem::getLineNo);
            order.setItems(itemMapper.selectList(qw));
        }
        return order;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesPurchaseOrder entity) {
        validateOrder(entity);
        if (entity.getStatus() == null) entity.setStatus("1");
        calcTotal(entity);
        QueryWrapper<MesPurchaseOrder> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("订单编号已存在");
        MesPurchaseOrder old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesPurchaseOrderItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesPurchaseOrderItem::getOrderId, old.getId());
            itemMapper.delete(delQw);
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("订单编号已存在"); }
        }
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesPurchaseOrder entity) {
        if (entity.getId() == null) throw new JeecgBootException("订单ID不能为空");
        checkStatus(entity, "edit");
        validateOrder(entity);
        calcTotal(entity);
        QueryWrapper<MesPurchaseOrder> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("订单编号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesPurchaseOrderItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseOrderItem::getOrderId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        checkStatus(id, "delete");
        LambdaQueryWrapper<MesPurchaseOrderItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseOrderItem::getOrderId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    //update-begin---author:ruiwancheng---date:2026-07-16---for: P0修复-批量删除改为批量SQL避免自调用-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        // 批量查状态
        List<MesPurchaseOrder> existing = baseMapper.selectBatchIds((Collection<String>) (Collection<?>) list);
        for (MesPurchaseOrder e : existing) {
            if (!"1".equals(e.getStatus()))
                throw new JeecgBootException("非草稿状态订单[" + e.getCode() + "]禁止删除");
        }
        // 批量删明细行
        LambdaQueryWrapper<MesPurchaseOrderItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesPurchaseOrderItem::getOrderId, list);
        itemMapper.delete(delQw);
        // 批量删主表
        return super.removeByIds(list);
    }
    //update-end---author:ruiwancheng---date:2026-07-16---for: P0修复-批量删除改为批量SQL避免自调用-----------

    private void validateOrder(MesPurchaseOrder entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("订单编号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("订单编号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getSupplierId())) throw new JeecgBootException("供应商不能为空");
        if (entity.getDeliveryDate() != null && entity.getOrderDate() != null
                && entity.getDeliveryDate().before(entity.getOrderDate()))
            throw new JeecgBootException("交货日期不能早于订单日期");
        List<MesPurchaseOrderItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个订单行");
        for (int i = 0; i < items.size(); i++) {
            MesPurchaseOrderItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getQuantity() == null || item.getQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行数量必须大于0");
            if (item.getUnitPrice() == null || item.getUnitPrice().compareTo(BigDecimal.ZERO) < 0)
                throw new JeecgBootException("第" + (i+1) + "行单价不能为负数");
            if (item.getTaxRate() == null) item.setTaxRate(new BigDecimal("0.13"));
            item.setLineNo(i + 1);
            item.setOrderId(entity.getId());
            // 后端强制重算金额: 不含税金额 = 数量 × 单价
            item.setAmount(item.getQuantity().multiply(item.getUnitPrice()).setScale(2, RoundingMode.HALF_UP));
        }
    }

    private void calcTotal(MesPurchaseOrder entity) {
        BigDecimal total = BigDecimal.ZERO;
        BigDecimal taxTotal = BigDecimal.ZERO;
        for (MesPurchaseOrderItem item : entity.getItems()) {
            if (item.getAmount() != null) total = total.add(item.getAmount());
            // P0修复：逐行计算税额 = 行金额 × 行税率，支持多税率混在同一订单
            BigDecimal rowTaxRate = item.getTaxRate() != null ? item.getTaxRate() : new BigDecimal("0.13");
            if (item.getAmount() != null) {
                taxTotal = taxTotal.add(item.getAmount().multiply(rowTaxRate));
            }
        }
        entity.setTotalAmount(total.setScale(2, RoundingMode.HALF_UP));
        entity.setTaxAmount(taxTotal.setScale(2, RoundingMode.HALF_UP));
        entity.setTotalWithTax(total.add(entity.getTaxAmount()).setScale(2, RoundingMode.HALF_UP));
    }

    private void checkStatus(MesPurchaseOrder entity, String action) {
        if (entity.getId() == null) return;
        MesPurchaseOrder exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态订单禁止" + action);
        }
    }

    private void checkStatus(String id, String action) {
        MesPurchaseOrder exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态订单禁止" + action);
        }
    }

    private void saveItems(MesPurchaseOrder entity) {
        for (MesPurchaseOrderItem item : entity.getItems()) {
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
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Service实现-----------
