//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库Service实现-----------
package org.jeecg.modules.mes.manufacturing.completion.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
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

    @Autowired
    private MesCompletionReceiptItemMapper itemMapper;

    @Autowired
    private MesProductionOrderMapper orderMapper;

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

    private void validate(MesCompletionReceipt entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("入库单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("入库单号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getProductionOrderId())) throw new JeecgBootException("生产订单不能为空");
        MesProductionOrder order = orderMapper.selectById(entity.getProductionOrderId());
        if (order == null) throw new JeecgBootException("生产订单不存在");
        if (!"1".equals(order.getStatus())) throw new JeecgBootException("仅草稿状态的生产订单可入库");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("入库仓库不能为空");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
        List<MesCompletionReceiptItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个入库明细");
        for (int i = 0; i < items.size(); i++) {
            MesCompletionReceiptItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getReceiptQty() == null || item.getReceiptQty().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行入库数量必须大于0");
            if (order.getPlanQty() != null && item.getReceiptQty().compareTo(order.getPlanQty()) > 0)
                throw new JeecgBootException("第" + (i+1) + "行入库数量不能超过计划数量(" + order.getPlanQty() + ")");
            item.setLineNo(i + 1);
            item.setReceiptId(entity.getId());
        }
    }

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
