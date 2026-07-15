//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
package org.jeecg.modules.mes.sales.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.sales.entity.MesSalesOutbound;
import org.jeecg.modules.mes.sales.entity.MesSalesOutboundItem;
import org.jeecg.modules.mes.sales.mapper.MesSalesOutboundItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOutboundMapper;
import org.jeecg.modules.mes.sales.service.IMesSalesOutboundService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Service
public class MesSalesOutboundServiceImpl extends ServiceImpl<MesSalesOutboundMapper, MesSalesOutbound> implements IMesSalesOutboundService {

    @Autowired private MesSalesOutboundItemMapper itemMapper;

    @Override public MesSalesOutbound queryWithItems(String id) {
        MesSalesOutbound o = baseMapper.selectById(id);
        if (o != null) { LambdaQueryWrapper<MesSalesOutboundItem> qw = new LambdaQueryWrapper<>(); qw.eq(MesSalesOutboundItem::getOutboundId, id); o.setItems(itemMapper.selectList(qw)); }
        return o;
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesSalesOutbound entity) {
        validate(entity); entity.setStatus("1");
        QueryWrapper<MesSalesOutbound> aqw = new QueryWrapper<>(); aqw.eq("code", entity.getCode());
        if (baseMapper.selectCount(aqw) > 0) throw new JeecgBootException("出库单编码已存在");
        MesSalesOutbound old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) { cleanOldItems(old.getId()); entity.setId(old.getId()); entity.setCreateBy(old.getCreateBy()); entity.setCreateTime(old.getCreateTime()); entity.setUpdateBy(getUser()); entity.setUpdateTime(new Date()); baseMapper.resurrect(entity); }
        else { try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("出库单编码已存在"); } }
        saveItems(entity);
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesSalesOutbound entity) {
        if (entity.getId() == null) throw new JeecgBootException("ID不能为空");
        checkStatus(entity.getId()); validate(entity); entity.setStatus("1");
        QueryWrapper<MesSalesOutbound> qw = new QueryWrapper<>(); qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("出库单编码已存在");
        super.updateById(entity); cleanOldItems(entity.getId()); saveItems(entity);
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) { checkStatus(id); cleanOldItems(id); super.removeById(id); }

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) { if (list == null || list.isEmpty()) return false; for (Object id : list) this.removeWithItems((String) id); return true; }

    @Override @Transactional(rollbackFor = Exception.class)
    public void audit(String id) { MesSalesOutbound e = baseMapper.selectById(id); if (e == null) throw new JeecgBootException("不存在"); if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核"); e.setStatus("3"); e.setUpdateBy(getUser()); e.setUpdateTime(new Date()); baseMapper.updateById(e); }

    @Override @Transactional(rollbackFor = Exception.class)
    public void cancel(String id) { MesSalesOutbound e = baseMapper.selectById(id); if (e == null) throw new JeecgBootException("不存在"); if ("3".equals(e.getStatus())) throw new JeecgBootException("已审核不可取消"); e.setStatus("0"); e.setUpdateBy(getUser()); e.setUpdateTime(new Date()); baseMapper.updateById(e); }

    private void validate(MesSalesOutbound e) {
        if (!StringUtils.hasText(e.getCode())) throw new JeecgBootException("编码不能为空");
        if (e.getCode().length() > 50) throw new JeecgBootException("编码不超过50字符");
        if (!StringUtils.hasText(e.getWarehouseId())) throw new JeecgBootException("仓库不能为空");
        List<MesSalesOutboundItem> items = e.getItems(); if (items == null || items.isEmpty()) throw new JeecgBootException("至少一个明细");
        for (int i = 0; i < items.size(); i++) { MesSalesOutboundItem item = items.get(i); if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第"+(i+1)+"行物料不能为空"); if (item.getActualQty() == null || item.getActualQty().compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("第"+(i+1)+"行数量必须大于0"); }
    }

    private void checkStatus(String id) { MesSalesOutbound e = baseMapper.selectById(id); if (e != null && !"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态禁止操作"); }
    private void cleanOldItems(String outboundId) { QueryWrapper<MesSalesOutboundItem> qw = new QueryWrapper<>(); qw.eq("outbound_id", outboundId); itemMapper.delete(qw); }
    private void saveItems(MesSalesOutbound e) { for (MesSalesOutboundItem i : e.getItems()) { i.setOutboundId(e.getId()); itemMapper.insert(i); } }
    private String getUser() { try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception ex) { return "system"; } }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
