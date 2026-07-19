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
import org.jeecg.modules.mes.basic.service.IMesInventoryService;
import org.jeecg.modules.mes.finance.receivable.entity.MesReceivable;
import org.jeecg.modules.mes.finance.receivable.service.IMesReceivableService;
import org.jeecg.modules.mes.sales.entity.MesSalesOrder;
import org.jeecg.modules.mes.sales.entity.MesSalesOrderItem;
import org.jeecg.modules.mes.sales.entity.MesSalesOutboundItem;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderMapper;
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
    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-查订单行单价-----------
    @Autowired private MesSalesOrderItemMapper salesOrderItemMapper;
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-查订单行单价-----------
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 已发货状态-----------
    @Autowired private MesSalesOrderMapper salesOrderMapper;
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 已发货状态-----------
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-出库扣库存-----------
    @Autowired private IMesInventoryService inventoryService;
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-出库扣库存-----------
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-生成应收-----------
    @Autowired private IMesReceivableService receivableService;
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-生成应收-----------

    @Override public MesSalesOutbound queryWithItems(String id) {
        MesSalesOutbound o = baseMapper.selectById(id);
        if (o != null) { LambdaQueryWrapper<MesSalesOutboundItem> qw = new LambdaQueryWrapper<>(); qw.eq(MesSalesOutboundItem::getOutboundId, id); o.setItems(itemMapper.selectList(qw)); }
        return o;
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesSalesOutbound entity) {
        //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-14 累计出库校验FOR UPDATE-----------
        if (StringUtils.hasText(entity.getDeliveryNoteId())) {
            deliveryNoteMapper.selectByIdForUpdate(entity.getDeliveryNoteId());
        }
        //update-end---author:ruiwancheng---date:2026-07-19---for: P0-14 累计出库校验FOR UPDATE-----------
        validate(entity); entity.setStatus("1");
        QueryWrapper<MesSalesOutbound> aqw = new QueryWrapper<>(); aqw.eq("code", entity.getCode());
        if (baseMapper.selectCount(aqw) > 0) throw new JeecgBootException("出库单编码已存在");
        //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到save之前-----------
        calcTotal(entity);
        //update-end---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到save之前-----------
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
        //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到updateById之前-----------
        calcTotal(entity);
        //update-end---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到updateById之前-----------
        super.updateById(entity); cleanOldItems(entity.getId());
        saveItems(entity);
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

    //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-02/P1-01 先改状态再扣库存+联动发货单-----------
    @Override @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        MesSalesOutbound e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("出库单不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核");
        // 1. 先原子改状态（如果失败，后续都不执行）
        String username = getUser();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：出库单不存在或状态已变更，请刷新后重试");
        // 2. 扣库存（状态已确认，事务内回滚安全）
        for (MesSalesOutboundItem item : e.getItems()) {
            inventoryService.stockOut(item.getMaterialId(), e.getWarehouseId(), item.getActualQty(), "销售出库", e.getCode());
        }
        // 3. 联动更新发货单状态 待出库(2)→已出库(3)
        if (e.getDeliveryNoteId() != null) {
            deliveryNoteMapper.updateStatus(e.getDeliveryNoteId(), "3", "2", username, now);
        }
        //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-自动生成应收-----------
        // 4. 自动生成应收单（唯一索引 uk_rec_source_bill 防重复）
        BigDecimal arAmount = e.getTotalAmount() != null ? e.getTotalAmount() : java.math.BigDecimal.ZERO;
        MesReceivable ar = new MesReceivable();
        ar.setCode("AR-" + e.getCode());
        ar.setCustomerId(e.getCustomerId());
        ar.setSourceType("销售出库");
        ar.setSourceBillId(e.getId());
        ar.setSourceBillNo(e.getCode());
        ar.setAmount(arAmount);
        ar.setReceivedAmount(java.math.BigDecimal.ZERO);
        ar.setUnsettledAmount(arAmount);
        ar.setTaxAmount(arAmount.multiply(new java.math.BigDecimal("0.13")).setScale(2, java.math.RoundingMode.HALF_UP));
        ar.setCreditPeriod(30);
        ar.setDueDate(new Date(now.getTime() + 30L * 86400000));
        ar.setStatus("1");
        try { receivableService.save(ar); } catch (org.springframework.dao.DuplicateKeyException ex) { /* 已生成 */ }
        //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-自动生成应收-----------
        //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 已发货状态自动流转-----------
        // 5. 检查销售订单是否全部出库完成→自动置已发货(4)
        if (StringUtils.hasText(e.getSalesOrderId())) {
            MesSalesOrder order = salesOrderMapper.selectById(e.getSalesOrderId());
            if (order != null && "3".equals(order.getStatus())) {
                // 汇总该订单所有已审核出库的实出数量
                java.util.List<MesSalesOutbound> allObs = baseMapper.selectList(
                    new QueryWrapper<MesSalesOutbound>().eq("sales_order_id", e.getSalesOrderId()).eq("status", "3"));
                java.util.Map<String, java.math.BigDecimal> shippedMap = new java.util.HashMap<>();
                for (MesSalesOutbound ob : allObs) {
                    java.util.List<MesSalesOutboundItem> obItems = itemMapper.selectList(
                        new LambdaQueryWrapper<MesSalesOutboundItem>().eq(MesSalesOutboundItem::getOutboundId, ob.getId()));
                    for (MesSalesOutboundItem oi : obItems) {
                        shippedMap.merge(oi.getMaterialId(), oi.getActualQty() != null ? oi.getActualQty() : java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
                    }
                }
                // 检查是否所有订单行都已足量出库
                java.util.List<MesSalesOrderItem> orderItems = salesOrderItemMapper.selectList(
                    new LambdaQueryWrapper<MesSalesOrderItem>().eq(MesSalesOrderItem::getOrderId, e.getSalesOrderId()));
                boolean allShipped = !orderItems.isEmpty();
                for (MesSalesOrderItem oi : orderItems) {
                    java.math.BigDecimal shipped = shippedMap.getOrDefault(oi.getMaterialId(), java.math.BigDecimal.ZERO);
                    if (shipped.compareTo(oi.getQuantity() != null ? oi.getQuantity() : java.math.BigDecimal.ZERO) < 0) {
                        allShipped = false; break;
                    }
                }
                if (allShipped) salesOrderMapper.shipWithGuard(order.getId(), username, now);
            }
        }
        //update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 已发货状态自动流转-----------
    }

    //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-05 取消审核红冲-恢复库存+应收作废-----------
    @Override @Transactional(rollbackFor = Exception.class)
    public void cancel(String id) {
        MesSalesOutbound e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("出库单不存在");
        // 如果已审核(status=3)，需要回冲库存和应收
        if ("3".equals(e.getStatus())) {
            // 恢复库存
            for (MesSalesOutboundItem item : e.getItems()) {
                inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getActualQty(), "销售出库红冲", e.getCode());
            }
            // 应收作废（查对应应收单标记为已结清）
            try {
                com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesReceivable> arQw =
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
                arQw.eq(MesReceivable::getSourceBillId, e.getId());
                java.util.List<MesReceivable> ars = receivableService.list(arQw);
                for (MesReceivable ar : ars) {
                    ar.setStatus("3"); // 已结清
                    receivableService.updateById(ar);
                }
            } catch (Exception ex) { /* 应收不存在则忽略 */ }
        }
        String username = getUser();
        Date now = new Date();
        int rows = baseMapper.cancelWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("取消失败：出库单不存在或状态已变更，请刷新后重试");
    }
    //update-end---author:ruiwancheng---date:2026-07-19---for: P0-05 取消审核红冲-恢复库存+应收作废-----------

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

            // P0-03: 累计出库量校验——同一发货单+物料不能超过发货数量
            BigDecimal maxQty = item.getDeliveryQty();
            //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-03 累计出库量校验-----------
            LambdaQueryWrapper<MesSalesOutboundItem> cumQw = new LambdaQueryWrapper<>();
            cumQw.eq(MesSalesOutboundItem::getMaterialId, item.getMaterialId());
            if (StringUtils.hasText(e.getDeliveryNoteId())) {
                // 查同一发货单下其他出库单的明细
                QueryWrapper<MesSalesOutbound> obQw = new QueryWrapper<>();
                obQw.eq("delivery_note_id", e.getDeliveryNoteId());
                if (StringUtils.hasText(e.getId())) obQw.ne("id", e.getId());
                java.util.List<MesSalesOutbound> otherObs = baseMapper.selectList(obQw);
                if (!otherObs.isEmpty()) {
                    java.util.List<String> obIds = new java.util.ArrayList<>();
                    for (MesSalesOutbound ob : otherObs) obIds.add(ob.getId());
                    cumQw.in(MesSalesOutboundItem::getOutboundId, obIds);
                    java.util.List<MesSalesOutboundItem> cumItems = itemMapper.selectList(cumQw);
                    BigDecimal cumQty = BigDecimal.ZERO;
                    for (MesSalesOutboundItem ci : cumItems) {
                        if (ci.getActualQty() != null) cumQty = cumQty.add(ci.getActualQty());
                    }
                    BigDecimal totalAfter = cumQty.add(item.getActualQty() != null ? item.getActualQty() : BigDecimal.ZERO);
                    if (totalAfter.compareTo(maxQty) > 0)
                        throw new JeecgBootException("第"+(i+1)+"行累计出库量("+totalAfter+")超过发货数量("+maxQty+")，已有出库"+cumQty);
                }
            }
            //update-end---author:ruiwancheng---date:2026-07-19---for: P0-03 累计出库量校验-----------
            if (item.getActualQty() == null || item.getActualQty().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第"+(i+1)+"行数量必须大于0");
            if (item.getActualQty().compareTo(maxQty) > 0)
                throw new JeecgBootException("第"+(i+1)+"行实出数量("+item.getActualQty()+")超过发货数量("+maxQty+")");

            //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-02 按行号匹配订单行取单价-----------
            if (item.getUnitPrice() == null || item.getUnitPrice().compareTo(BigDecimal.ZERO) == 0) {
                if (StringUtils.hasText(e.getSalesOrderId())) {
                    LambdaQueryWrapper<MesSalesOrderItem> oiQw = new LambdaQueryWrapper<>();
                    oiQw.eq(MesSalesOrderItem::getOrderId, e.getSalesOrderId())
                       .eq(MesSalesOrderItem::getMaterialId, item.getMaterialId());
                    // 有同物料多行时按行号匹配（避免取错价）
                    if (src != null && src.getSalesOrderItemId() != null) {
                        oiQw.eq(MesSalesOrderItem::getId, src.getSalesOrderItemId());
                    }
                    java.util.List<MesSalesOrderItem> orderItems = salesOrderItemMapper.selectList(oiQw);
                    if (!orderItems.isEmpty() && orderItems.get(0).getUnitPrice() != null) {
                        item.setUnitPrice(orderItems.get(0).getUnitPrice());
                    }
                }
            }
            if (item.getUnitPrice() == null) item.setUnitPrice(BigDecimal.ZERO);
            item.setAmount(item.getActualQty().multiply(item.getUnitPrice()).setScale(2, java.math.RoundingMode.HALF_UP));
            //update-end---author:ruiwancheng---date:2026-07-19---for: P0-02 按行号匹配订单行取单价-----------
        }
    }
    //update-end---author:ruiwancheng---date:2026-07-16---for: P0-02/03/10来源+数量校验-----------

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-计算合计方法-----------
    private void calcTotal(MesSalesOutbound entity) {
        BigDecimal total = BigDecimal.ZERO;
        for (MesSalesOutboundItem item : entity.getItems()) {
            if (item.getAmount() != null) total = total.add(item.getAmount());
        }
        entity.setTotalAmount(total.setScale(2, java.math.RoundingMode.HALF_UP));
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-计算合计方法-----------

    private void checkStatus(String id) { MesSalesOutbound e = baseMapper.selectById(id); if (e != null && !"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态禁止操作"); }
    private void cleanOldItems(String outboundId) { QueryWrapper<MesSalesOutboundItem> qw = new QueryWrapper<>(); qw.eq("outbound_id", outboundId); itemMapper.delete(qw); }
    private void saveItems(MesSalesOutbound e) { for (MesSalesOutboundItem i : e.getItems()) { i.setOutboundId(e.getId()); itemMapper.insert(i); } }
    private String getUser() { try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception ex) { return "system"; } }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
