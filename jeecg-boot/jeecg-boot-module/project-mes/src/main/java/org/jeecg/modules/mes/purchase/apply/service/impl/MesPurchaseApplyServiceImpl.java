//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service实现-----------
package org.jeecg.modules.mes.purchase.apply.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApply;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApplyItem;
import org.jeecg.modules.mes.purchase.apply.mapper.MesPurchaseApplyItemMapper;
import org.jeecg.modules.mes.purchase.apply.mapper.MesPurchaseApplyMapper;
import org.jeecg.modules.mes.purchase.apply.service.IMesPurchaseApplyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Service
public class MesPurchaseApplyServiceImpl extends ServiceImpl<MesPurchaseApplyMapper, MesPurchaseApply> implements IMesPurchaseApplyService {

    @Autowired
    private MesPurchaseApplyItemMapper itemMapper;

    @Override
    public MesPurchaseApply queryWithItems(String id) {
        MesPurchaseApply apply = baseMapper.selectById(id);
        if (apply != null) {
            LambdaQueryWrapper<MesPurchaseApplyItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesPurchaseApplyItem::getApplyId, id).orderByAsc(MesPurchaseApplyItem::getLineNo);
            apply.setItems(itemMapper.selectList(qw));
        }
        return apply;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesPurchaseApply entity) {
        validateApply(entity);
        if (entity.getStatus() == null) entity.setStatus("1");
        calcTotal(entity);
        QueryWrapper<MesPurchaseApply> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("申请单号已存在");
        MesPurchaseApply old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesPurchaseApplyItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesPurchaseApplyItem::getApplyId, old.getId());
            itemMapper.delete(delQw);
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("申请单号已存在"); }
        }
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesPurchaseApply entity) {
        if (entity.getId() == null) throw new JeecgBootException("申请ID不能为空");
        checkStatus(entity, "edit");
        validateApply(entity);
        calcTotal(entity);
        QueryWrapper<MesPurchaseApply> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("申请单号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesPurchaseApplyItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseApplyItem::getApplyId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        checkStatus(id, "delete");
        LambdaQueryWrapper<MesPurchaseApplyItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseApplyItem::getApplyId, id);
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

    private void validateApply(MesPurchaseApply entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("申请单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("申请单号长度不能超过50个字符");
        if (entity.getRequiredDate() != null && entity.getApplyDate() != null
                && entity.getRequiredDate().before(entity.getApplyDate()))
            throw new JeecgBootException("需求日期不能早于申请日期");
        List<MesPurchaseApplyItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个申请行");
        for (int i = 0; i < items.size(); i++) {
            MesPurchaseApplyItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getQuantity() == null || item.getQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行数量必须大于0");
            item.setLineNo(i + 1);
            item.setApplyId(entity.getId());
        }
    }

    private void calcTotal(MesPurchaseApply entity) {
        entity.setTotalAmount(BigDecimal.ZERO);
    }

    private void checkStatus(MesPurchaseApply entity, String action) {
        if (entity.getId() == null) return;
        MesPurchaseApply exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态申请禁止" + action);
        }
    }

    private void checkStatus(String id, String action) {
        MesPurchaseApply exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) {
            throw new JeecgBootException("非草稿状态申请禁止" + action);
        }
    }

    private void saveItems(MesPurchaseApply entity) {
        for (MesPurchaseApplyItem item : entity.getItems()) {
            item.setApplyId(entity.getId());
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
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service实现-----------
