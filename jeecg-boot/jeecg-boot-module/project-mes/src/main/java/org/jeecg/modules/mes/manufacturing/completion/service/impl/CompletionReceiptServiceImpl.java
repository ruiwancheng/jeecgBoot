//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库Service实现-----------
package org.jeecg.modules.mes.manufacturing.completion.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.service.IMesInventoryService;
import org.jeecg.modules.mes.manufacturing.completion.entity.MesCompletionReceipt;
import org.jeecg.modules.mes.manufacturing.completion.entity.MesCompletionReceiptItem;
import org.jeecg.modules.mes.manufacturing.completion.mapper.MesCompletionReceiptItemMapper;
import org.jeecg.modules.mes.manufacturing.completion.mapper.MesCompletionReceiptMapper;
import org.jeecg.modules.mes.manufacturing.completion.service.ICompletionReceiptService;
import org.jeecg.modules.mes.manufacturing.order.entity.MesProductionOrder;
import org.jeecg.modules.mes.manufacturing.order.mapper.MesProductionOrderMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.*;

@Service
public class CompletionReceiptServiceImpl extends ServiceImpl<MesCompletionReceiptMapper, MesCompletionReceipt> implements ICompletionReceiptService {

    @Autowired private MesCompletionReceiptItemMapper itemMapper;
    @Autowired private MesProductionOrderMapper orderMapper;
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-完工入库-----------
    @Autowired private IMesInventoryService inventoryService;
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-完工入库-----------

    @Override
    public MesCompletionReceipt queryWithItems(String id) {
        MesCompletionReceipt receipt = baseMapper.selectById(id);
        if (receipt != null) {
            LambdaQueryWrapper<MesCompletionReceiptItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesCompletionReceiptItem::getReceiptId, id).orderByAsc(MesCompletionReceiptItem::getLineNo);
            receipt.setItems(itemMapper.selectList(qw));
        }
        return receipt;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesCompletionReceipt entity) {
        validate(entity);
        entity.setStatus("1");
        QueryWrapper<MesCompletionReceipt> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("入库单号已存在");
        MesCompletionReceipt old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesCompletionReceiptItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesCompletionReceiptItem::getReceiptId, old.getId());
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
    public void updateWithItems(MesCompletionReceipt entity) {
        if (entity.getId() == null) throw new JeecgBootException("入库单ID不能为空");
        checkStatus(entity, "edit");
        validate(entity);
        entity.setStatus("1");
        QueryWrapper<MesCompletionReceipt> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("入库单号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesCompletionReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesCompletionReceiptItem::getReceiptId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        checkStatus(id, "delete");
        LambdaQueryWrapper<MesCompletionReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesCompletionReceiptItem::getReceiptId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        List<MesCompletionReceipt> existing = baseMapper.selectBatchIds((Collection<String>) (Collection<?>) list);
        for (MesCompletionReceipt e : existing) {
            if (!"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态入库单[" + e.getCode() + "]禁止删除");
        }
        LambdaQueryWrapper<MesCompletionReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesCompletionReceiptItem::getReceiptId, list);
        itemMapper.delete(delQw);
        return super.removeByIds(list);
    }

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-加库存-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        MesCompletionReceipt e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核");
        for (MesCompletionReceiptItem item : e.getItems()) {
            inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQty(), null, null, "完工入库", e.getCode());
        }
        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：入库单不存在或状态已变更，请刷新后重试");
    }
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-加库存-----------

    //update-begin---author:ruiwancheng---date:2026-07-16---for: P0-2修复-累计入库校验+表名修正-----------
    private void validate(MesCompletionReceipt entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("入库单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("入库单号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getProductionOrderId())) throw new JeecgBootException("生产订单不能为空");
        MesProductionOrder order = orderMapper.selectById(entity.getProductionOrderId());
        if (order == null) throw new JeecgBootException("生产订单不存在");
        // MVP: 状态机未实现，暂时允许所有状态可入库
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("入库仓库不能为空");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
        List<MesCompletionReceiptItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个入库明细");
        // P0-2修复：累计历史入库量，防止同一订单多次入库累计超量（照抄purchase e84c96d模式）
        Map<String, BigDecimal> historyQtyMap = new HashMap<>();
        LambdaQueryWrapper<MesCompletionReceipt> rqw = new LambdaQueryWrapper<>();
        rqw.eq(MesCompletionReceipt::getProductionOrderId, entity.getProductionOrderId());
        if (StringUtils.hasText(entity.getId())) {
            rqw.ne(MesCompletionReceipt::getId, entity.getId()); // 编辑时排除自身
        }
        List<MesCompletionReceipt> existingReceipts = baseMapper.selectList(rqw);
        if (!existingReceipts.isEmpty()) {
            List<String> existingIds = new ArrayList<>();
            for (MesCompletionReceipt r : existingReceipts) existingIds.add(r.getId());
            LambdaQueryWrapper<MesCompletionReceiptItem> hiqw = new LambdaQueryWrapper<>();
            hiqw.in(MesCompletionReceiptItem::getReceiptId, existingIds);
            List<MesCompletionReceiptItem> historyItems = itemMapper.selectList(hiqw);
            for (MesCompletionReceiptItem hi : historyItems) {
                historyQtyMap.merge(hi.getMaterialId(), hi.getReceiptQty() != null ? hi.getReceiptQty() : BigDecimal.ZERO, BigDecimal::add);
            }
        }
        for (int i = 0; i < items.size(); i++) {
            MesCompletionReceiptItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getReceiptQty() == null || item.getReceiptQty().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行入库数量必须大于0");
            // 累计校验：（历史已入库 + 本次入库）<= 计划数量
            BigDecimal planQty = item.getPlanQty() != null ? item.getPlanQty() : order.getPlanQty();
            if (planQty != null) {
                BigDecimal historyQty = historyQtyMap.getOrDefault(item.getMaterialId(), BigDecimal.ZERO);
                BigDecimal totalAfter = historyQty.add(item.getReceiptQty());
                if (totalAfter.compareTo(planQty) > 0) {
                    throw new JeecgBootException("第" + (i+1) + "行累计入库量(" + totalAfter + ")超过计划数量(" + planQty
                            + ")，历史已入库" + historyQty + "，本次入库" + item.getReceiptQty());
                }
            }
            item.setLineNo(i + 1);
            item.setReceiptId(entity.getId());
        }
    }
    //update-end---author:ruiwancheng---date:2026-07-16---for: P0-2修复-累计入库校验+表名修正-----------

    private void checkStatus(MesCompletionReceipt entity, String action) {
        if (entity.getId() == null) return;
        MesCompletionReceipt exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void checkStatus(String id, String action) {
        MesCompletionReceipt exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void saveItems(MesCompletionReceipt entity) {
        String username = getCurrentUsername();
        Date now = new Date();
        for (MesCompletionReceiptItem item : entity.getItems()) {
            item.setReceiptId(entity.getId());
            if (item.getCreateBy() == null) item.setCreateBy(username);
            if (item.getCreateTime() == null) item.setCreateTime(now);
            item.setUpdateBy(username);
            item.setUpdateTime(now);
            itemMapper.insert(item);
        }
    }

    private String getCurrentUsername() {
        try { return ((LoginUser) SecurityUtils.getSubject().getPrincipal()).getUsername(); }
        catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库Service实现-----------
