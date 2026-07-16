//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Service实现-----------
package org.jeecg.modules.mes.purchase.receipt.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
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
import java.util.Date;
import java.util.List;

@Service
public class MesPurchaseReceiptServiceImpl extends ServiceImpl<MesPurchaseReceiptMapper, MesPurchaseReceipt> implements IMesPurchaseReceiptService {

    @Autowired
    private MesPurchaseReceiptItemMapper itemMapper;

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

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        for (Object id : list) this.removeWithItems((String) id);
        return true;
    }

    private void validateReceipt(MesPurchaseReceipt entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("入库单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("入库单号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("仓库不能为空");
        List<MesPurchaseReceiptItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个入库行");
        for (int i = 0; i < items.size(); i++) {
            MesPurchaseReceiptItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getReceiptQuantity() == null || item.getReceiptQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行入库数量必须大于0");
            item.setLineNo(i + 1);
            item.setReceiptId(entity.getId());
        }
    }

    private void checkStatus(MesPurchaseReceipt entity, String action) {
        if (entity.getId() == null) return;
        MesPurchaseReceipt exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态入库单禁止" + action);
        }
    }

    private void checkStatus(String id, String action) {
        MesPurchaseReceipt exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态入库单禁止" + action);
        }
    }

    private void saveItems(MesPurchaseReceipt entity) {
        for (MesPurchaseReceiptItem item : entity.getItems()) {
            item.setReceiptId(entity.getId());
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
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Service实现-----------
