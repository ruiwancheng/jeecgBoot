//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料Service实现-----------
package org.jeecg.modules.mes.manufacturing.picking.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.service.IMesInventoryService;
import org.jeecg.modules.mes.manufacturing.order.entity.MesProductionOrder;
import org.jeecg.modules.mes.manufacturing.order.mapper.MesProductionOrderMapper;
import org.jeecg.modules.mes.manufacturing.picking.entity.MesProductionPicking;
import org.jeecg.modules.mes.manufacturing.picking.entity.MesProductionPickingItem;
import org.jeecg.modules.mes.manufacturing.picking.mapper.MesProductionPickingItemMapper;
import org.jeecg.modules.mes.manufacturing.picking.mapper.MesProductionPickingMapper;
import org.jeecg.modules.mes.manufacturing.picking.service.IProductionPickingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.*;

@Service
public class ProductionPickingServiceImpl extends ServiceImpl<MesProductionPickingMapper, MesProductionPicking> implements IProductionPickingService {

    @Autowired private MesProductionPickingItemMapper itemMapper;
    @Autowired private MesProductionOrderMapper orderMapper;
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-生产领料-----------
    @Autowired private IMesInventoryService inventoryService;
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-生产领料-----------

    @Override
    public MesProductionPicking queryWithItems(String id) {
        MesProductionPicking picking = baseMapper.selectById(id);
        if (picking != null) {
            LambdaQueryWrapper<MesProductionPickingItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesProductionPickingItem::getPickingId, id).orderByAsc(MesProductionPickingItem::getLineNo);
            picking.setItems(itemMapper.selectList(qw));
        }
        return picking;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesProductionPicking entity) {
        validate(entity);
        entity.setStatus("1");
        QueryWrapper<MesProductionPicking> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("领料单号已存在");
        MesProductionPicking old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesProductionPickingItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesProductionPickingItem::getPickingId, old.getId());
            itemMapper.delete(delQw);
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("领料单号已存在"); }
        }
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesProductionPicking entity) {
        if (entity.getId() == null) throw new JeecgBootException("领料单ID不能为空");
        checkStatus(entity, "edit");
        validate(entity);
        entity.setStatus("1");
        QueryWrapper<MesProductionPicking> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("领料单号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesProductionPickingItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesProductionPickingItem::getPickingId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        checkStatus(id, "delete");
        LambdaQueryWrapper<MesProductionPickingItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesProductionPickingItem::getPickingId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        List<MesProductionPicking> existing = baseMapper.selectBatchIds((Collection<String>) (Collection<?>) list);
        for (MesProductionPicking e : existing) {
            if (!"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态领料单[" + e.getCode() + "]禁止删除");
        }
        LambdaQueryWrapper<MesProductionPickingItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesProductionPickingItem::getPickingId, list);
        itemMapper.delete(delQw);
        return super.removeByIds(list);
    }

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 领料审核-扣库存-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        MesProductionPicking e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("领料单不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核");
        for (MesProductionPickingItem item : e.getItems()) {
            inventoryService.stockOut(item.getMaterialId(), e.getWarehouseId(), item.getQuantity(), null, null, "生产领料", e.getCode());
        }
        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：领料单不存在或状态已变更，请刷新后重试");
    }
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 领料审核-扣库存-----------

    private void validate(MesProductionPicking entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("领料单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("领料单号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getProductionOrderId())) throw new JeecgBootException("生产订单不能为空");
        MesProductionOrder order = orderMapper.selectById(entity.getProductionOrderId());
        if (order == null) throw new JeecgBootException("生产订单不存在");
        if (!"1".equals(order.getStatus())) throw new JeecgBootException("仅草稿状态的生产订单可领料");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("领料仓库不能为空");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
        List<MesProductionPickingItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个领料明细");
        for (int i = 0; i < items.size(); i++) {
            MesProductionPickingItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getQuantity() == null || item.getQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行领料数量必须大于0");
            item.setLineNo(i + 1);
            item.setPickingId(entity.getId());
        }
    }

    private void checkStatus(MesProductionPicking entity, String action) {
        if (entity.getId() == null) return;
        MesProductionPicking exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void checkStatus(String id, String action) {
        MesProductionPicking exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void saveItems(MesProductionPicking entity) {
        String username = getCurrentUsername();
        Date now = new Date();
        for (MesProductionPickingItem item : entity.getItems()) {
            item.setPickingId(entity.getId());
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
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料Service实现-----------
