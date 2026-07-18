//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
package org.jeecg.modules.mes.sales.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNoteItem;
import org.jeecg.modules.mes.sales.entity.MesSalesOutbound;
import org.jeecg.modules.mes.sales.entity.MesSalesOutboundItem;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteMapper;
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
    @Autowired private MesDeliveryNoteMapper deliveryNoteMapper;
    @Autowired private MesDeliveryNoteItemMapper deliveryNoteItemMapper;

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

    //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-04 批量删除改用super.removeByIds+批量删明细-----------
    @Override @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        for (Object id : list) checkStatus((String) id);
        QueryWrapper<MesSalesOutboundItem> itemQw = new QueryWrapper<>();
        itemQw.in("outbound_id", list);
        itemMapper.delete(itemQw);
        return super.removeByIds(list);
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: P0-04 批量删除改用super.removeByIds+批量删明细-----------

    //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-08 audit/cancel原子UPDATE+日期校验+salesOrderId继承-----------
    @Override @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        String username = getUser();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：出库单不存在或状态已变更，请刷新后重试");
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void cancel(String id) {
        String username = getUser();
        Date now = new Date();
        int rows = baseMapper.cancelWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("取消失败：出库单不存在或状态已变更（已审核/已取消），请刷新后重试");
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: P0-08 audit/cancel原子UPDATE+日期校验+salesOrderId继承-----------

    //update-begin---author:ruiwancheng---date:2026-07-16---for: P0-02/03/10来源+数量校验-----------
    private void validate(MesSalesOutbound e) {
        if (!StringUtils.hasText(e.getCode())) throw new JeecgBootException("编码不能为空");
        if (e.getCode().length() > 50) throw new JeecgBootException("编码不超过50字符");
        if (!StringUtils.hasText(e.getWarehouseId())) throw new JeecgBootException("仓库不能为空");

        // P0-03: 来源校验——强制关联发货单并校验存在性
        if (!StringUtils.hasText(e.getDeliveryNoteId())) throw new JeecgBootException("发货单不能为空");
        MesDeliveryNote dn = deliveryNoteMapper.selectById(e.getDeliveryNoteId());
        if (dn == null) throw new JeecgBootException("发货单不存在");

        // P1-04: 自动从发货单继承销售订单ID和客户ID
        e.setSalesOrderId(dn.getSalesOrderId());
        if (dn.getCustomerId() != null) e.setCustomerId(dn.getCustomerId());

        // P0-03: 如果填了销售订单，校验存在性
        if (StringUtils.hasText(e.getSalesOrderId()) && !e.getSalesOrderId().equals(dn.getSalesOrderId()))
            throw new JeecgBootException("销售订单与发货单不匹配");

        // P1-01: 出库日期必填校验
        if (e.getOutboundDate() == null) throw new JeecgBootException("出库日期不能为空");

        List<MesSalesOutboundItem> items = e.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少一个明细");

        // 查发货单明细作为基准
        LambdaQueryWrapper<MesDeliveryNoteItem> dnQw = new LambdaQueryWrapper<>();
        dnQw.eq(MesDeliveryNoteItem::getDeliveryId, e.getDeliveryNoteId());
        List<MesDeliveryNoteItem> dnItems = deliveryNoteItemMapper.selectList(dnQw);

        for (int i = 0; i < items.size(); i++) {
            MesSalesOutboundItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第"+(i+1)+"行物料不能为空");

            // P0-10: deliveryQty 从发货单来源强制覆盖，禁止前端任意写入
            MesDeliveryNoteItem src = null;
            for (MesDeliveryNoteItem di : dnItems) {
                if (item.getMaterialId().equals(di.getMaterialId())) { src = di; break; }
            }
            if (src == null) throw new JeecgBootException("第"+(i+1)+"行物料不在发货单明细中");
            item.setDeliveryQty(src.getDeliveryQty() != null ? src.getDeliveryQty() : BigDecimal.ZERO);

            // P0-02: 实出数量 ≤ 发货数量
            BigDecimal maxQty = item.getDeliveryQty();
            if (item.getActualQty() == null || item.getActualQty().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第"+(i+1)+"行数量必须大于0");
            if (item.getActualQty().compareTo(maxQty) > 0)
                throw new JeecgBootException("第"+(i+1)+"行实出数量("+item.getActualQty()+")超过发货数量("+maxQty+")");
        }
    }
    //update-end---author:ruiwancheng---date:2026-07-16---for: P0-02/03/10来源+数量校验-----------

    private void checkStatus(String id) { MesSalesOutbound e = baseMapper.selectById(id); if (e != null && !"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态禁止操作"); }
    private void cleanOldItems(String outboundId) { QueryWrapper<MesSalesOutboundItem> qw = new QueryWrapper<>(); qw.eq("outbound_id", outboundId); itemMapper.delete(qw); }
    private void saveItems(MesSalesOutbound e) { for (MesSalesOutboundItem i : e.getItems()) { i.setOutboundId(e.getId()); itemMapper.insert(i); } }
    private String getUser() { try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception ex) { return "system"; } }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
