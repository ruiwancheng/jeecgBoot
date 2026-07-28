//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Service实现-----------
package org.jeecg.modules.mes.stock.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.service.IMesCodeRuleService;
import org.jeecg.modules.mes.stock.entity.MesOtherStockIn;
import org.jeecg.modules.mes.stock.entity.MesOtherStockInItem;
import org.jeecg.modules.mes.stock.entity.MesOtherStockOut;
import org.jeecg.modules.mes.stock.entity.MesOtherStockOutItem;
import org.jeecg.modules.mes.stock.entity.MesStocktake;
import org.jeecg.modules.mes.stock.entity.MesStocktakeItem;
import org.jeecg.modules.mes.stock.mapper.MesStocktakeItemMapper;
import org.jeecg.modules.mes.stock.mapper.MesStocktakeMapper;
import org.jeecg.modules.mes.stock.service.IMesOtherStockInService;
import org.jeecg.modules.mes.stock.service.IMesOtherStockOutService;
import org.jeecg.modules.mes.stock.service.IMesStocktakeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

@Service
public class MesStocktakeServiceImpl extends ServiceImpl<MesStocktakeMapper, MesStocktake> implements IMesStocktakeService {

    @Autowired private MesStocktakeItemMapper itemMapper;
    @Autowired private IMesCodeRuleService codeRuleService;
    // 评审 P0：必须通过 Spring 代理调用（@Transactional 传播 REQUIRED 合并为一大事务），禁止 this.xxx() 自调用
    @Autowired private IMesOtherStockInService otherStockInService;
    @Autowired private IMesOtherStockOutService otherStockOutService;

    @Override
    public MesStocktake queryWithItems(String id) {
        MesStocktake e = baseMapper.selectById(id);
        if (e != null) {
            LambdaQueryWrapper<MesStocktakeItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesStocktakeItem::getTakeId, id).orderByAsc(MesStocktakeItem::getLineNo);
            e.setItems(itemMapper.selectList(qw));
        }
        return e;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesStocktake entity) {
        entity.setDelFlag(null);
        if (entity.getWarehouseId() == null) throw new JeecgBootException("仓库不能为空");
        if (entity.getTakeType() == null) entity.setTakeType("1");
        if (entity.getStatus() == null) entity.setStatus("1");
        if (entity.getTakeDate() == null) entity.setTakeDate(new Date());

        // 全盘且未传明细 → 后端快照全仓账面库存（评审：普通SELECT不加锁；actual_qty默认=账面）
        List<MesStocktakeItem> items = entity.getItems();
        if ("1".equals(entity.getTakeType()) && (items == null || items.isEmpty())) {
            items = snapshotItems(entity.getWarehouseId());
            if (items.isEmpty()) throw new JeecgBootException("该仓库无库存物料，无法全盘");
        }
        if (items == null || items.isEmpty()) throw new JeecgBootException("盘点明细不能为空");
        entity.setSnapshotTime(new Date());

        QueryWrapper<MesStocktake> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("盘点单号已存在");
        MesStocktake old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesStocktakeItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesStocktakeItem::getTakeId, old.getId());
            itemMapper.delete(delQw);
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("盘点单号已存在"); }
        }
        calcAndSaveItems(entity, items);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesStocktake entity) {
        if (entity.getId() == null) throw new JeecgBootException("盘点单ID不能为空");
        MesStocktake exist = baseMapper.selectByIdForUpdate(entity.getId());
        if (exist == null) throw new JeecgBootException("盘点单不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("当前状态不允许编辑，仅草稿状态可操作");
        entity.setDelFlag(null); entity.setCreateBy(null); entity.setCreateTime(null);
        entity.setStatus(null); entity.setSnapshotTime(null);
        super.updateById(entity);
        LambdaQueryWrapper<MesStocktakeItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesStocktakeItem::getTakeId, entity.getId());
        itemMapper.delete(delQw);
        if (entity.getItems() == null || entity.getItems().isEmpty()) throw new JeecgBootException("盘点明细不能为空");
        calcAndSaveItems(entity, entity.getItems());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        MesStocktake exist = baseMapper.selectByIdForUpdate(id);
        if (exist == null) throw new JeecgBootException("盘点单不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态盘点单禁止删除");
        LambdaQueryWrapper<MesStocktakeItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesStocktakeItem::getTakeId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String audit(String id) {
        // FOR UPDATE 锁主表（与 updateWithItems 同锁互斥），再读明细——消除 TOCTOU
        MesStocktake locked = baseMapper.selectByIdForUpdate(id);
        if (locked == null) throw new JeecgBootException("盘点单不存在");
        if (!"1".equals(locked.getStatus())) throw new JeecgBootException("只有草稿可审核");

        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：盘点单不存在或状态已变更，请刷新后重试");

        MesStocktake e = queryWithItems(id);
        // 校验实盘数已填
        List<MesStocktakeItem> inLines = new ArrayList<>();
        List<MesStocktakeItem> outLines = new ArrayList<>();
        for (MesStocktakeItem item : e.getItems()) {
            if (item.getActualQty() == null) throw new JeecgBootException("存在未填实盘数量的行（物料ID:" + item.getMaterialId() + "），请补全后再审核");
            BigDecimal diff = item.getActualQty().subtract(item.getBookQty());
            if (diff.compareTo(BigDecimal.ZERO) > 0) inLines.add(item);
            else if (diff.compareTo(BigDecimal.ZERO) < 0) outLines.add(item);
        }

        String inCode = null, outCode = null;
        // 盘盈：同仓合并为一张其它入库单（inType='1'盘盈），创建+审核同事务（用户看不到草稿态调整单）
        if (!inLines.isEmpty()) {
            MesOtherStockIn inDoc = new MesOtherStockIn();
            inDoc.setCode(codeRuleService.nextCode("QI"));
            inDoc.setInType("1");
            inDoc.setWarehouseId(e.getWarehouseId());
            inDoc.setReason("盘点单 " + e.getCode() + " 自动生成（盘盈）");
            inDoc.setStockDate(e.getTakeDate());
            inDoc.setStatus("1");
            List<MesOtherStockInItem> inItems = new ArrayList<>();
            int ln = 1;
            for (MesStocktakeItem item : inLines) {
                MesOtherStockInItem ii = new MesOtherStockInItem();
                ii.setLineNo(ln++);
                ii.setMaterialId(item.getMaterialId());
                ii.setQty(item.getActualQty().subtract(item.getBookQty()));
                ii.setUnitCost(item.getUnitCost());
                ii.setAmount(ii.getQty().multiply(item.getUnitCost() != null ? item.getUnitCost() : BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP));
                inItems.add(ii);
            }
            inDoc.setItems(inItems);
            otherStockInService.saveWithItems(inDoc);
            otherStockInService.audit(inDoc.getId());
            inCode = inDoc.getCode();
            for (MesStocktakeItem item : inLines) { item.setGeneratedInId(inDoc.getId()); itemMapper.updateById(item); }
        }
        // 盘亏：同仓合并为一张其它出库单（outType='1'盘亏）
        if (!outLines.isEmpty()) {
            MesOtherStockOut outDoc = new MesOtherStockOut();
            outDoc.setCode(codeRuleService.nextCode("QO"));
            outDoc.setOutType("1");
            outDoc.setWarehouseId(e.getWarehouseId());
            outDoc.setReason("盘点单 " + e.getCode() + " 自动生成（盘亏）");
            outDoc.setStockDate(e.getTakeDate());
            outDoc.setStatus("1");
            List<MesOtherStockOutItem> outItems = new ArrayList<>();
            int ln = 1;
            for (MesStocktakeItem item : outLines) {
                MesOtherStockOutItem oi = new MesOtherStockOutItem();
                oi.setLineNo(ln++);
                oi.setMaterialId(item.getMaterialId());
                oi.setQty(item.getBookQty().subtract(item.getActualQty()));
                oi.setUnitCost(item.getUnitCost());
                oi.setAmount(oi.getQty().multiply(item.getUnitCost() != null ? item.getUnitCost() : BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP));
                outItems.add(oi);
            }
            outDoc.setItems(outItems);
            otherStockOutService.saveWithItems(outDoc);
            otherStockOutService.audit(outDoc.getId());
            outCode = outDoc.getCode();
            for (MesStocktakeItem item : outLines) { item.setGeneratedOutId(outDoc.getId()); itemMapper.updateById(item); }
        }

        return "审核成功：差异" + (inLines.size() + outLines.size()) + "行"
                + (inCode != null ? "，盘盈入库单 " + inCode : "")
                + (outCode != null ? "，盘亏出库单 " + outCode : "")
                + (inLines.isEmpty() && outLines.isEmpty() ? "（无差异，库存未调整）" : "");
    }

    /** 全盘快照：普通 SELECT 不加锁（评审 P1），actual_qty 默认=账面（用户只改差异行） */
    private List<MesStocktakeItem> snapshotItems(String warehouseId) {
        List<Map<String, Object>> rows = baseMapper.snapshotByWarehouse(warehouseId);
        List<MesStocktakeItem> items = new ArrayList<>();
        int ln = 1;
        for (Map<String, Object> r : rows) {
            MesStocktakeItem item = new MesStocktakeItem();
            item.setLineNo(ln++);
            item.setMaterialId((String) r.get("materialId"));
            BigDecimal bookQty = r.get("bookQty") != null ? new BigDecimal(r.get("bookQty").toString()) : BigDecimal.ZERO;
            item.setBookQty(bookQty);
            item.setActualQty(bookQty);
            item.setUnitCost(r.get("unitCost") != null ? new BigDecimal(r.get("unitCost").toString()) : BigDecimal.ZERO);
            items.add(item);
        }
        return items;
    }

    /** 逐行计算差异并保存明细（行号重新编排） */
    private void calcAndSaveItems(MesStocktake entity, List<MesStocktakeItem> items) {
        BigDecimal totalDiff = BigDecimal.ZERO;
        int ln = 1;
        for (MesStocktakeItem item : items) {
            if (item.getMaterialId() == null) throw new JeecgBootException("明细行物料不能为空");
            if (item.getBookQty() == null) throw new JeecgBootException("明细行账面数量不能为空");
            item.setId(null);
            item.setTakeId(entity.getId());
            item.setLineNo(ln++);
            BigDecimal cost = item.getUnitCost() != null ? item.getUnitCost() : BigDecimal.ZERO;
            item.setUnitCost(cost);
            if (item.getActualQty() != null) {
                BigDecimal diff = item.getActualQty().subtract(item.getBookQty());
                item.setDiffQty(diff);
                item.setDiffAmount(diff.multiply(cost).setScale(2, RoundingMode.HALF_UP));
                totalDiff = totalDiff.add(item.getDiffAmount());
            }
            itemMapper.insert(item);
        }
        entity.setTotalDiffAmount(totalDiff);
        baseMapper.updateById(new MesStocktake().setId(entity.getId()).setTotalDiffAmount(totalDiff));
    }

    private String getCurrentUsername() {
        LoginUser user = (LoginUser) SecurityUtils.getSubject().getPrincipal();
        return user != null ? user.getUsername() : "admin";
    }
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Service实现-----------
