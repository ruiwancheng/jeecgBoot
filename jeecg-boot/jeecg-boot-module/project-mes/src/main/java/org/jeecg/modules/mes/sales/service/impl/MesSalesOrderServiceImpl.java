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
import org.jeecg.modules.mes.sales.entity.MesPrice;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderMapper;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteMapper;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteItemMapper;
import org.jeecg.modules.mes.basic.mapper.MesWarehouseMapper;
import org.jeecg.modules.mes.basic.mapper.MesMaterialMapper;
import org.jeecg.modules.mes.basic.entity.MesMaterial;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNoteItem;
import org.jeecg.modules.mes.basic.service.IMesCodeRuleService;
import org.jeecg.modules.mes.sales.service.IMesPriceService;
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
    @Autowired
    private MesDeliveryNoteMapper deliveryNoteMapper;
    @Autowired
    private MesDeliveryNoteItemMapper deliveryNoteItemMapper;
    @Autowired
    private MesWarehouseMapper warehouseMapper;
    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 价格自动带出-----------
    @Autowired
    private IMesPriceService priceService;
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 价格自动带出-----------
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.6.0 价格兜底-直接从物料取标准售价-----------
    @Autowired
    private MesMaterialMapper materialMapper;
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.6.0 价格兜底-直接从物料取标准售价-----------

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
            // 清理旧订单行，避免复活时带入脏数据
            LambdaQueryWrapper<MesSalesOrderItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesSalesOrderItem::getOrderId, old.getId());
            itemMapper.delete(delQw);
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
        checkStatus(entity, "edit"); // 非草稿不可编辑
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
        checkStatus(id, "delete"); // 非草稿不可删除
        LambdaQueryWrapper<MesSalesOrderItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesSalesOrderItem::getOrderId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-04 批量删除改用super.removeByIds+批量删明细-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        for (Object id : list) checkStatus((String) id, "delete");
        // 批量删除明细行
        LambdaQueryWrapper<MesSalesOrderItem> itemQw = new LambdaQueryWrapper<>();
        itemQw.in(MesSalesOrderItem::getOrderId, list);
        itemMapper.delete(itemQw);
        return super.removeByIds(list);
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: P0-04 批量删除改用super.removeByIds+批量删明细-----------

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-销售订单-----------
    @Override @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：订单不存在或状态已变更，请刷新后重试");
    }
    @Override @Transactional(rollbackFor = Exception.class)
    //update-begin O2D2O 订单下达自动生成发货单
    public void release(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.releaseWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("下达失败：订单不存在或状态已变更（需为已审核），请刷新后重试");
        generateDraftDelivery(id, username, now);
    }
    //update-end O2D2O

    // O2D2O: 自动生成草稿发货单（幂等：已有草稿则跳过，全部已发完则跳过）
    private void generateDraftDelivery(String orderId, String username, Date now) {
        // 已有草稿发货单则跳过
        LambdaQueryWrapper<MesDeliveryNote> dnQw = new LambdaQueryWrapper<>();
        dnQw.eq(MesDeliveryNote::getSalesOrderId, orderId).eq(MesDeliveryNote::getStatus, "1");
        if (deliveryNoteMapper.selectCount(dnQw) > 0) return;
        // 查未完成的订单行
        LambdaQueryWrapper<MesSalesOrderItem> itemQw = new LambdaQueryWrapper<>();
        itemQw.eq(MesSalesOrderItem::getOrderId, orderId).orderByAsc(MesSalesOrderItem::getLineNo);
        List<MesSalesOrderItem> orderItems = itemMapper.selectList(itemQw);
        // 汇总已发货量
        java.util.Map<String, java.math.BigDecimal> shippedMap = new java.util.HashMap<>();
        LambdaQueryWrapper<MesDeliveryNote> allDnQw = new LambdaQueryWrapper<>();
        allDnQw.eq(MesDeliveryNote::getSalesOrderId, orderId).ne(MesDeliveryNote::getStatus, "0");
        for (MesDeliveryNote dn : deliveryNoteMapper.selectList(allDnQw)) {
            LambdaQueryWrapper<MesDeliveryNoteItem> dniQw = new LambdaQueryWrapper<>();
            dniQw.eq(MesDeliveryNoteItem::getDeliveryId, dn.getId());
            for (MesDeliveryNoteItem dni : deliveryNoteItemMapper.selectList(dniQw)) {
                shippedMap.merge(dni.getMaterialId(), dni.getDeliveryQty() != null ? dni.getDeliveryQty() : java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
            }
        }
        // 构建发货明细（未完成的物料行）
        java.util.List<MesDeliveryNoteItem> items = new java.util.ArrayList<>();
        for (MesSalesOrderItem oi : orderItems) {
            java.math.BigDecimal ordered = oi.getQuantity() != null ? oi.getQuantity() : java.math.BigDecimal.ZERO;
            java.math.BigDecimal shipped = shippedMap.getOrDefault(oi.getMaterialId(), java.math.BigDecimal.ZERO);
            java.math.BigDecimal remaining = ordered.subtract(shipped);
            if (remaining.compareTo(java.math.BigDecimal.ZERO) <= 0) continue;
            MesDeliveryNoteItem dni = new MesDeliveryNoteItem();
            dni.setSalesOrderItemId(oi.getId());
            dni.setMaterialId(oi.getMaterialId());
            dni.setOrderedQty(ordered);
            dni.setDeliveryQty(remaining);
            dni.setUnitPrice(oi.getUnitPrice());
            items.add(dni);
        }
        if (items.isEmpty()) return; // 全部已发完
        // 创建发货单
        MesDeliveryNote dn = new MesDeliveryNote();
        dn.setCode("DN" + new java.text.SimpleDateFormat("yyyyMMdd").format(now) + "-" + String.format("%04d", (int)(Math.random()*9000+1000)));
        dn.setSalesOrderId(orderId);
        dn.setCustomerId(baseMapper.selectById(orderId).getCustomerId());
        // 自动生成取系统第一个仓库为默认（草稿态可改）
        java.util.List<org.jeecg.modules.mes.basic.entity.MesWarehouse> whs = warehouseMapper.selectList(new QueryWrapper<>());
        dn.setWarehouseId(whs.isEmpty() ? "" : whs.get(0).getId());
        dn.setStatus("1");
        java.math.BigDecimal total = java.math.BigDecimal.ZERO;
        for (MesDeliveryNoteItem dni : items) {
            if (dni.getDeliveryQty() != null && dni.getUnitPrice() != null)
                total = total.add(dni.getDeliveryQty().multiply(dni.getUnitPrice()));
        }
        dn.setTotalAmount(total.setScale(2, java.math.RoundingMode.HALF_UP));
        dn.setCreateBy(username); dn.setCreateTime(now); dn.setUpdateBy(username); dn.setUpdateTime(now);
        try { deliveryNoteMapper.insert(dn); } catch (DuplicateKeyException ex) { return; }
        for (MesDeliveryNoteItem dni : items) {
            dni.setDeliveryId(dn.getId()); dni.setCreateBy(username); dni.setCreateTime(now);
            dni.setUpdateBy(username); dni.setUpdateTime(now);
            deliveryNoteItemMapper.insert(dni);
        }
    }
    @Override @Transactional(rollbackFor = Exception.class)
    public void close(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.closeWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("关闭失败：订单不存在或状态已变更，请刷新后重试");
    }
    @Override @Transactional(rollbackFor = Exception.class)
    public void cancel(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.cancelWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("取消失败：订单不存在或状态已变更，请刷新后重试");
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-销售订单-----------

    private void validateOrder(MesSalesOrder entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("订单编码不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("订单编码长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getCustomerId())) throw new JeecgBootException("客户不能为空");
        //update-begin---author:ruiwancheng---date:2026-07-18---for: P1-01 订单日期+交货日期必填校验-----------
        if (entity.getOrderDate() == null) throw new JeecgBootException("订单日期不能为空");
        if (entity.getDeliveryDate() == null) throw new JeecgBootException("交货日期不能为空");
        //update-end---author:ruiwancheng---date:2026-07-18---for: P1-01 订单日期+交货日期必填校验-----------
        List<MesSalesOrderItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个订单行");
        for (int i = 0; i < items.size(); i++) {
            MesSalesOrderItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getQuantity() == null || item.getQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行数量必须大于0");
            //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 价格自动带出-从价格表查价-----------
            if (item.getUnitPrice() == null || item.getUnitPrice().compareTo(BigDecimal.ZERO) == 0) {
                if (StringUtils.hasText(entity.getCustomerId()) && entity.getOrderDate() != null) {
                    MesPrice price = priceService.findActivePrice(item.getMaterialId(), entity.getCustomerId(), entity.getOrderDate());
                    if (price != null && price.getPrice() != null && price.getPrice().compareTo(BigDecimal.ZERO) > 0) {
                        item.setUnitPrice(price.getPrice());
                    }
                }
            }
            //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 价格自动带出-从价格表查价-----------
            //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.6.0 价格兜底-物料标准售价-----------
            if (item.getUnitPrice() == null || item.getUnitPrice().compareTo(BigDecimal.ZERO) == 0) {
                MesMaterial mat = materialMapper.selectById(item.getMaterialId());
                if (mat != null && mat.getStandardPrice() != null
                        && mat.getStandardPrice().compareTo(BigDecimal.ZERO) > 0) {
                    item.setUnitPrice(mat.getStandardPrice());
                }
            }
            //update-end---author:ruiwancheng---date:2026-07-24---for: V9.6.0 价格兜底-物料标准售价-----------
            if (item.getUnitPrice() == null || item.getUnitPrice().compareTo(BigDecimal.ZERO) < 0)
                throw new JeecgBootException("第" + (i+1) + "行单价不能为负数");
            item.setLineNo(i + 1);
            item.setOrderId(entity.getId());
            // 后端强制重算金额，忽略前端传入的 amount
            item.setAmount(item.getQuantity().multiply(item.getUnitPrice()).setScale(2, java.math.RoundingMode.HALF_UP));
            //update-begin---author:ruiwancheng---date:2026-07-21---for: 明细税额计算（税率默认13%）-----------
            java.math.BigDecimal taxRate = item.getTaxRate() != null ? item.getTaxRate() : new java.math.BigDecimal("0.13");
            item.setTaxRate(taxRate);
            item.setTaxAmount(item.getAmount().multiply(taxRate).setScale(2, java.math.RoundingMode.HALF_UP));
            //update-end---author:ruiwancheng---date:2026-07-21---for: 明细税额计算（税率默认13%）-----------
        }
    }

    private void calcTotal(MesSalesOrder entity) {
        BigDecimal total = BigDecimal.ZERO;
        for (MesSalesOrderItem item : entity.getItems()) {
            if (item.getAmount() != null) total = total.add(item.getAmount());
        }
        entity.setTotalAmount(total.setScale(2, java.math.RoundingMode.HALF_UP));
    }

    /** 非草稿状态禁止编辑/删除 */
    private void checkStatus(MesSalesOrder entity, String action) {
        if (entity.getId() == null) return;
        MesSalesOrder exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态订单禁止" + action);
        }
    }

    private void checkStatus(String id, String action) {
        MesSalesOrder exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态订单禁止" + action);
        }
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
