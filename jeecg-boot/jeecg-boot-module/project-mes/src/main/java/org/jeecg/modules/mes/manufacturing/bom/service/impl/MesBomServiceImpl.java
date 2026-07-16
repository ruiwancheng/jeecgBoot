//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Service实现-----------
package org.jeecg.modules.mes.manufacturing.bom.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBom;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBomItem;
import org.jeecg.modules.mes.manufacturing.bom.mapper.MesBomItemMapper;
import org.jeecg.modules.mes.manufacturing.bom.mapper.MesBomMapper;
import org.jeecg.modules.mes.manufacturing.bom.service.IMesBomService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.*;

@Service
public class MesBomServiceImpl extends ServiceImpl<MesBomMapper, MesBom> implements IMesBomService {

    @Autowired
    private MesBomItemMapper itemMapper;

    @Override
    public MesBom queryWithItems(String id) {
        MesBom bom = baseMapper.selectById(id);
        if (bom != null) {
            LambdaQueryWrapper<MesBomItem> qw = new LambdaQueryWrapper<>();
            qw.eq(MesBomItem::getBomId, id).orderByAsc(MesBomItem::getLineNo);
            bom.setItems(itemMapper.selectList(qw));
        }
        return bom;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesBom entity) {
        validateBom(entity);
        entity.setStatus("1");
        QueryWrapper<MesBom> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("BOM编号已存在");
        MesBom old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            LambdaQueryWrapper<MesBomItem> delQw = new LambdaQueryWrapper<>();
            delQw.eq(MesBomItem::getBomId, old.getId());
            itemMapper.delete(delQw);
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("BOM编号已存在"); }
        }
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesBom entity) {
        if (entity.getId() == null) throw new JeecgBootException("BOM ID不能为空");
        checkStatus(entity, "edit");
        validateBom(entity);
        entity.setStatus("1");
        QueryWrapper<MesBom> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("BOM编号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesBomItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesBomItem::getBomId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        checkStatus(id, "delete");
        LambdaQueryWrapper<MesBomItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesBomItem::getBomId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        List<MesBom> existing = baseMapper.selectBatchIds((Collection<String>) (Collection<?>) list);
        for (MesBom e : existing) {
            if (!"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态BOM[" + e.getCode() + "]禁止删除");
        }
        LambdaQueryWrapper<MesBomItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesBomItem::getBomId, list);
        itemMapper.delete(delQw);
        return super.removeByIds(list);
    }

    private void validateBom(MesBom entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("BOM编号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("BOM编号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getProductId())) throw new JeecgBootException("父项物料不能为空");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
        List<MesBomItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个BOM子项");
        for (int i = 0; i < items.size(); i++) {
            MesBomItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getQuantity() == null || item.getQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行用量必须大于0");
            if (item.getMaterialId().equals(entity.getProductId()))
                throw new JeecgBootException("第" + (i+1) + "行子项物料不能与父项物料相同");
            item.setLineNo(i + 1);
            item.setBomId(entity.getId());
        }
    }

    private void checkStatus(MesBom entity, String action) {
        if (entity.getId() == null) return;
        MesBom exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void checkStatus(String id, String action) {
        MesBom exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus()))
            throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void saveItems(MesBom entity) {
        String username = getCurrentUsername();
        Date now = new Date();
        for (MesBomItem item : entity.getItems()) {
            item.setBomId(entity.getId());
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
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Service实现-----------
