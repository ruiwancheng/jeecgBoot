//update-begin---author:ruiwancheng---date:2026-07-16---for: P0修复-入库校验超量+关联订单+审计字段-----------
package org.jeecg.modules.mes.purchase.receipt.service.impl;

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
import org.jeecg.modules.mes.basic.service.IMesInventoryService;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceipt;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceiptItem;
import org.jeecg.modules.mes.purchase.receipt.mapper.MesPurchaseReceiptItemMapper;
import org.jeecg.modules.mes.purchase.receipt.mapper.MesPurchaseReceiptMapper;
import org.jeecg.modules.mes.purchase.receipt.service.IMesPurchaseReceiptService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class MesPurchaseReceiptServiceImpl extends ServiceImpl<MesPurchaseReceiptMapper, MesPurchaseReceipt> implements IMesPurchaseReceiptService {

    @Autowired private MesPurchaseReceiptItemMapper itemMapper;
    @Autowired private MesPurchaseOrderMapper purchaseOrderMapper;
    @Autowired private MesPurchaseOrderItemMapper purchaseOrderItemMapper;
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-采购入库-----------
    @Autowired private IMesInventoryService inventoryService;
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-采购入库-----------

    @Override
    public MesPurchaseReceipt queryWithItems(String id) {
        MesPurchaseReceipt receipt = baseMapper.selectById(id);
        if (receipt != null) {
            LambdaQueryWrapper<MesPurchaseReceiptItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesPurchaseReceiptItem::getReceiptId, id).orderByAsc(MesPurchaseReceiptItem::getLineNo);
            receipt.setItems(itemMapper.selectList(qw));
        }
        return receipt;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesPurchaseReceipt entity) {
        validateReceipt(entity);
        if (entity.getStatus() == null) entity.setStatus("1");
        QueryWrapper<MesPurchaseReceipt> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("入库单号已存在");
        MesPurchaseReceipt old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesPurchaseReceiptItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesPurchaseReceiptItem::getReceiptId, old.getId());
            itemMapper.delete(delQw);
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("入库单号已存在"); }
        }
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesPurchaseReceipt entity) {
        if (entity.getId() == null) throw new JeecgBootException("入库单ID不能为空");
        checkStatus(entity, "edit");
        validateReceipt(entity);
        // 编辑时强制保持草稿状态，防止前端绕过
        entity.setStatus("1");
        QueryWrapper<MesPurchaseReceipt> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("入库单号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesPurchaseReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseReceiptItem::getReceiptId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        checkStatus(id, "delete");
        LambdaQueryWrapper<MesPurchaseReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseReceiptItem::getReceiptId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        MesPurchaseReceipt e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核");
        // 逐行加库存
        for (MesPurchaseReceiptItem item : e.getItems()) {
            inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQuantity(), "采购入库", e.getCode());
        }
        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：入库单不存在或状态已变更，请刷新后重试");
    }
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        // 批量查状态
        List<MesPurchaseReceipt> existing = baseMapper.selectBatchIds((Collection<String>) (Collection<?>) list);
        for (MesPurchaseReceipt e : existing) {
            if (!"1".equals(e.getStatus()))
                throw new JeecgBootException("非草稿状态入库单[" + e.getCode() + "]禁止删除");
        }
        // 批量删明细行
        LambdaQueryWrapper<MesPurchaseReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesPurchaseReceiptItem::getReceiptId, list);
        itemMapper.delete(delQw);
        // 批量删主表
        return super.removeByIds(list);
    }

    private void validateReceipt(MesPurchaseReceipt entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("入库单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("入库单号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getPurchaseOrderId())) throw new JeecgBootException("关联采购订单不能为空");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("仓库不能为空");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
        // P0修复：校验关联采购订单存在且状态可入库
        MesPurchaseOrder order = purchaseOrderMapper.selectById(entity.getPurchaseOrderId());
        if (order == null) throw new JeecgBootException("关联采购订单不存在");
        if (!"3".equals(order.getStatus()) && !"4".equals(order.getStatus()))
            throw new JeecgBootException("采购订单状态不允许入库，仅已确认或部分到货状态可入库");
        // 加载订单物料行用于超量校验
        LambdaQueryWrapper<MesPurchaseOrderItem> oqw = new LambdaQueryWrapper<>();
        oqw.eq(MesPurchaseOrderItem::getOrderId, order.getId());
        List<MesPurchaseOrderItem> orderItems = purchaseOrderItemMapper.selectList(oqw);
        Map<String, BigDecimal> orderQtyMap = orderItems.stream()
                .collect(Collectors.toMap(MesPurchaseOrderItem::getMaterialId, MesPurchaseOrderItem::getQuantity, (a, b) -> a));
        // P0-004修复：累计历史入库量，防止同一订单多次入库累计超量
        Map<String, BigDecimal> historyQtyMap = new HashMap<>();
        LambdaQueryWrapper<MesPurchaseReceipt> rqw = new LambdaQueryWrapper<>();
        rqw.eq(MesPurchaseReceipt::getPurchaseOrderId, entity.getPurchaseOrderId());
        if (StringUtils.hasText(entity.getId())) {
            rqw.ne(MesPurchaseReceipt::getId, entity.getId()); // 编辑时排除自身
        }
        List<MesPurchaseReceipt> existingReceipts = baseMapper.selectList(rqw);
        if (!existingReceipts.isEmpty()) {
            List<String> existingIds = existingReceipts.stream().map(MesPurchaseReceipt::getId).collect(Collectors.toList());
            LambdaQueryWrapper<MesPurchaseReceiptItem> hiqw = new LambdaQueryWrapper<>();
            hiqw.in(MesPurchaseReceiptItem::getReceiptId, existingIds);
            List<MesPurchaseReceiptItem> historyItems = itemMapper.selectList(hiqw);
            for (MesPurchaseReceiptItem hi : historyItems) {
                historyQtyMap.merge(hi.getMaterialId(), hi.getReceiptQuantity() != null ? hi.getReceiptQuantity() : BigDecimal.ZERO, BigDecimal::add);
            }
        }
        // 逐行校验
        List<MesPurchaseReceiptItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个入库行");
        for (int i = 0; i < items.size(); i++) {
            MesPurchaseReceiptItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getReceiptQuantity() == null || item.getReceiptQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行入库数量必须大于0");
            // P0-004修复：累计校验（历史已入库 + 本次入库）<= 采购数量
            BigDecimal orderQty = orderQtyMap.get(item.getMaterialId());
            if (orderQty != null) {
                BigDecimal historyQty = historyQtyMap.getOrDefault(item.getMaterialId(), BigDecimal.ZERO);
                BigDecimal totalAfter = historyQty.add(item.getReceiptQuantity());
                if (totalAfter.compareTo(orderQty) > 0) {
                    throw new JeecgBootException("第" + (i+1) + "行累计入库量(" + totalAfter + ")超过采购数量(" + orderQty
                            + ")，历史已入库" + historyQty + "，本次入库" + item.getReceiptQuantity());
                }
            }
            // P0修复：白名单校验质检结果
            if (StringUtils.hasText(item.getQcResult())) {
                Set<String> validQc = new HashSet<>(Arrays.asList("1", "2", "3"));
                if (!validQc.contains(item.getQcResult()))
                    throw new JeecgBootException("第" + (i+1) + "行质检结果值无效");
            }
            item.setLineNo(i + 1);
            item.setReceiptId(entity.getId());
        }
    }

    private void checkStatus(MesPurchaseReceipt entity, String action) {
        if (entity.getId() == null) return;
        MesPurchaseReceipt exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
        }
    }

    private void checkStatus(String id, String action) {
        MesPurchaseReceipt exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
        }
    }

    private void saveItems(MesPurchaseReceipt entity) {
        String username = getCurrentUsername();
        Date now = new Date();
        for (MesPurchaseReceiptItem item : entity.getItems()) {
            item.setReceiptId(entity.getId());
            // P0修复：明细行补审计字段
            if (item.getCreateBy() == null) item.setCreateBy(username);
            if (item.getCreateTime() == null) item.setCreateTime(now);
            item.setUpdateBy(username);
            item.setUpdateTime(now);
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
//update-end---author:ruiwancheng---date:2026-07-16---for: P0修复-入库校验超量+关联订单+审计字段-----------
