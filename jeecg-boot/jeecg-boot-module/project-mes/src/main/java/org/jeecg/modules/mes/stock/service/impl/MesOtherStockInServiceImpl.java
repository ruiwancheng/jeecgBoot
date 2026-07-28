//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它入库Service实现-----------
package org.jeecg.modules.mes.stock.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.service.IMesInventoryService;
import org.jeecg.modules.mes.stock.entity.MesOtherStockIn;
import org.jeecg.modules.mes.stock.entity.MesOtherStockInItem;
import org.jeecg.modules.mes.stock.mapper.MesOtherStockInItemMapper;
import org.jeecg.modules.mes.stock.mapper.MesOtherStockInMapper;
import org.jeecg.modules.mes.stock.service.IMesOtherStockInService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Date;
import java.util.List;

@Service
public class MesOtherStockInServiceImpl extends ServiceImpl<MesOtherStockInMapper, MesOtherStockIn> implements IMesOtherStockInService {

    @Autowired private MesOtherStockInItemMapper itemMapper;
    @Autowired private IMesInventoryService inventoryService;
    //update-begin---author:ruiwancheng---date:2026-07-28---for: 方案B 手工成本进入移动平均体系-----------
    @Autowired private org.jeecg.modules.mes.basic.service.IMesMaterialService materialService;
    //update-end---author:ruiwancheng---date:2026-07-28---for: 方案B 成本联动-----------

    @Override
    public MesOtherStockIn queryWithItems(String id) {
        MesOtherStockIn e = baseMapper.selectById(id);
        if (e != null) {
            LambdaQueryWrapper<MesOtherStockInItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesOtherStockInItem::getInId, id).orderByAsc(MesOtherStockInItem::getLineNo);
            e.setItems(itemMapper.selectList(qw));
        }
        return e;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesOtherStockIn entity) {
        entity.setDelFlag(null);
        validate(entity);
        if (entity.getStatus() == null) entity.setStatus("1");
        QueryWrapper<MesOtherStockIn> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("入库单号已存在");
        MesOtherStockIn old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesOtherStockInItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesOtherStockInItem::getInId, old.getId());
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
    public void updateWithItems(MesOtherStockIn entity) {
        if (entity.getId() == null) throw new JeecgBootException("入库单ID不能为空");
        // FOR UPDATE 行锁防并发击穿（镜像 purchase/receipt P0-3 修复模式）
        MesOtherStockIn exist = baseMapper.selectByIdForUpdate(entity.getId());
        if (exist == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("当前状态不允许编辑，仅草稿状态可操作");
        // 敏感字段置null防注入覆盖
        entity.setDelFlag(null); entity.setCreateBy(null); entity.setCreateTime(null);
        entity.setStatus(null);
        validate(entity);
        QueryWrapper<MesOtherStockIn> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("入库单号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesOtherStockInItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesOtherStockInItem::getInId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        MesOtherStockIn exist = baseMapper.selectByIdForUpdate(id);
        if (exist == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态入库单禁止删除");
        LambdaQueryWrapper<MesOtherStockInItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesOtherStockInItem::getInId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        // 铁拳团 P0-4 修复：先 FOR UPDATE 锁主表（与 updateWithItems 同锁互斥），再读明细——消除审核使用过期明细的 TOCTOU
        MesOtherStockIn locked = baseMapper.selectByIdForUpdate(id);
        if (locked == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(locked.getStatus())) throw new JeecgBootException("只有草稿可审核");

        // 先改状态（原子守卫），成功后再执行副作用——以 purchase/receipt 顺序为准，禁止参考 completion 的反序bug
        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：入库单不存在或状态已变更，请刷新后重试");

        // 锁内读明细（主表行锁阻断 updateWithItems，明细稳定）
        MesOtherStockIn e = queryWithItems(id);
        // 审核成功后逐行加库存（按明细快照成本改库存金额）
        for (MesOtherStockInItem item : e.getItems()) {
            //update-begin---author:ruiwancheng---date:2026-07-28---for: 方案B 手工成本进入移动平均（先成本后库存，镜像采购入库；0/空成本跳过不污染）-----------
            if (item.getUnitCost() != null && item.getUnitCost().compareTo(BigDecimal.ZERO) > 0) {
                materialService.updateMovingAvgCostOnStockIn(item.getMaterialId(), item.getQty(), item.getUnitCost(), e.getWarehouseId(), "其它入库", e.getCode());
            }
            //update-end---author:ruiwancheng---date:2026-07-28---for: 方案B 成本联动-----------
            inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getQty(), item.getUnitCost(), item.getAmount(), "其它入库", e.getCode());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unaudit(String id) {
        // 铁拳团 P1-2 修复：unaudit 同样先锁主表再读明细（与 audit 同一 TOCTOU 加固）
        String username = getCurrentUsername();
        Date now = new Date();
        MesOtherStockIn locked = baseMapper.selectByIdForUpdate(id);
        if (locked == null) throw new JeecgBootException("入库单不存在");
        int rows = baseMapper.unauditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("反审核失败：入库单不存在或状态不是已审核，请刷新后重试");
        MesOtherStockIn e = queryWithItems(id);
        for (MesOtherStockInItem item : e.getItems()) {
            // 铁拳团 P1-1：库存已被消耗时回冲失败，补充业务指引（保持拦截，不碰平台 stockOut）
            try {
                inventoryService.stockOut(item.getMaterialId(), e.getWarehouseId(), item.getQty(), item.getUnitCost(), item.getAmount(), "其它入库红冲", e.getCode());
            } catch (JeecgBootException ex) {
                throw new JeecgBootException("反审核回冲失败：" + ex.getMessage() + "。该入库的库存已被后续出库消耗，请先补足库存再反审核，或联系管理员处理。");
            }
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        for (Object id : list) {
            MesOtherStockIn exist = baseMapper.selectByIdForUpdate((String) id);
            if (exist == null) throw new JeecgBootException("入库单[" + id + "]不存在");
            if (!"1".equals(exist.getStatus()))
                throw new JeecgBootException("非草稿状态入库单[" + exist.getCode() + "]禁止删除");
        }
        LambdaQueryWrapper<MesOtherStockInItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesOtherStockInItem::getInId, list);
        itemMapper.delete(delQw);
        return super.removeByIds(list);
    }

    private void validate(MesOtherStockIn entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("入库单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("入库单号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getInType())) throw new JeecgBootException("入库类型不能为空");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("仓库不能为空");
        if (entity.getReason() != null && entity.getReason().length() > 500) throw new JeecgBootException("原因长度不能超过500个字符");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
        List<MesOtherStockInItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个入库行");
        BigDecimal totalAmount = BigDecimal.ZERO;
        for (int i = 0; i < items.size(); i++) {
            MesOtherStockInItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i + 1) + "行物料不能为空");
            if (item.getQty() == null || item.getQty().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i + 1) + "行数量必须大于0");
            if (item.getUnitCost() != null && item.getUnitCost().compareTo(BigDecimal.ZERO) < 0)
                throw new JeecgBootException("第" + (i + 1) + "行成本单价不能为负数");
            // 服务端权威计算金额快照（无条件覆盖，前端只读只是 UI 防线）
            BigDecimal cost = item.getUnitCost() != null ? item.getUnitCost() : BigDecimal.ZERO;
            item.setAmount(item.getQty().multiply(cost).setScale(2, java.math.RoundingMode.HALF_UP));
            totalAmount = totalAmount.add(item.getAmount());
            item.setLineNo(i + 1);
            item.setInId(entity.getId());
        }
        entity.setTotalAmount(totalAmount);
    }

    private void saveItems(MesOtherStockIn entity) {
        String username = getCurrentUsername();
        Date now = new Date();
        for (MesOtherStockInItem item : entity.getItems()) {
            item.setInId(entity.getId());
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
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它入库Service实现-----------
