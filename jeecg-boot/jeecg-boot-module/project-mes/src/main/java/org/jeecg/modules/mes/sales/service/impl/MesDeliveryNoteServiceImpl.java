//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Service实现-----------
package org.jeecg.modules.mes.sales.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNoteItem;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteMapper;
import org.jeecg.modules.mes.sales.service.IMesDeliveryNoteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Service
public class MesDeliveryNoteServiceImpl extends ServiceImpl<MesDeliveryNoteMapper, MesDeliveryNote> implements IMesDeliveryNoteService {

    @Autowired
    private MesDeliveryNoteItemMapper itemMapper;

    @Override
    public MesDeliveryNote queryWithItems(String id) {
        MesDeliveryNote note = baseMapper.selectById(id);
        if (note != null) {
            LambdaQueryWrapper<MesDeliveryNoteItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesDeliveryNoteItem::getDeliveryId, id);
            note.setItems(itemMapper.selectList(qw));
        }
        return note;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesDeliveryNote entity) {
        validate(entity);
        if (entity.getStatus() == null) entity.setStatus("1");
        QueryWrapper<MesDeliveryNote> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("发货单编码已存在");
        MesDeliveryNote old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesDeliveryNoteItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesDeliveryNoteItem::getDeliveryId, old.getId());
            itemMapper.delete(delQw);
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("发货单编码已存在"); }
        }
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesDeliveryNote entity) {
        if (entity.getId() == null) throw new JeecgBootException("发货单ID不能为空");
        checkStatus(entity, "编辑");
        validate(entity);
        QueryWrapper<MesDeliveryNote> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("发货单编码已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesDeliveryNoteItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesDeliveryNoteItem::getDeliveryId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        checkStatus(id, "删除");
        LambdaQueryWrapper<MesDeliveryNoteItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesDeliveryNoteItem::getDeliveryId, id);
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

    private void validate(MesDeliveryNote entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("发货单编码不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("发货单编码长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getSalesOrderId())) throw new JeecgBootException("销售订单不能为空");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("发货仓库不能为空");
        List<MesDeliveryNoteItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个发货明细");
        for (int i = 0; i < items.size(); i++) {
            MesDeliveryNoteItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getDeliveryQty() == null || item.getDeliveryQty().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行发货数量必须大于0");
        }
    }

    private void checkStatus(MesDeliveryNote entity, String action) {
        if (entity.getId() == null) return;
        MesDeliveryNote exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("非草稿状态禁止" + action);
    }

    private void checkStatus(String id, String action) {
        MesDeliveryNote exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("非草稿状态禁止" + action);
    }

    private void saveItems(MesDeliveryNote entity) {
        for (MesDeliveryNoteItem item : entity.getItems()) {
            item.setDeliveryId(entity.getId());
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
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Service实现-----------
