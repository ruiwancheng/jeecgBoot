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
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.jeecg.modules.mes.basic.entity.MesMaterial;
import org.jeecg.modules.mes.basic.mapper.MesMaterialMapper;import org.springframework.beans.factory.annotation.Autowired;
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
    //update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-销售出库集成依赖-----------
    @Autowired private IMesBatchInventoryService batchInventoryService;
    @Autowired private MesMaterialMapper materialMapper;
    //update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-销售出库集成依赖-----------
    //update-begin---author:ruiwancheng---date:20260801---for:【生产批次总开关】注入总开关 Service-----------
    @Autowired private org.jeecg.modules.mes.system.service.IMesGlobalSwitchService globalSwitchService;
    //update-end---author:ruiwancheng---date:20260801---for:【生产批次总开关】总开关注入-----------
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
        validateAuditPreconditions(e);
        //update-begin---author:ruiwancheng---date:20260801---for:【生产批次总开关】事务内仅查一次总开关状态-----------
        // 全局总开关：关闭时跳过批次 FIFO 出库（不影响主库存扣减与业财联动）
        final boolean batchSwitchOn = globalSwitchService.isEnabled("mes_batch_enabled");
        //update-end---author:ruiwancheng---date:20260801---for:【生产批次总开关】总开关缓存-----------
        // 1. 先原子改状态（如果失败，后续都不执行）
        String username = getUser();
        Date now = new Date();
        executeStatusGuard(id, username, now);
        // 2-5. 应用审核副作用（库存扣减 + 跨单据状态联动 + 应收生成）
        applyAuditSideEffects(e, username, now, batchSwitchOn);
    }

    /** 校验：仅草稿状态可审核 + 实体存在 */
    private void validateAuditPreconditions(MesSalesOutbound e) {
        if (e == null) throw new JeecgBootException("出库单不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核");
    }

    /** 状态守卫：调用 baseMapper.auditWithGuard 原子化 status 1→3（如果失败，后续都不执行） */
    private void executeStatusGuard(String id, String username, Date now) {
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：出库单不存在或状态已变更，请刷新后重试");
    }

    /** 审核副作用调度：分发到 4 个子方法 */
    private void applyAuditSideEffects(MesSalesOutbound e, String username, Date now, boolean batchSwitchOn) {
        applyItemInventoryEffects(e, batchSwitchOn);
        updateDeliveryNoteStatus(e, username, now);
        generateReceivable(e, now);
        updateSalesOrderStatus(e, username, now);
    }

    /** 2. 扣库存 + 批次 FIFO（状态已确认，事务内回滚安全） */
    private void applyItemInventoryEffects(MesSalesOutbound e, boolean batchSwitchOn) {
        for (MesSalesOutboundItem item : e.getItems()) {
            inventoryService.stockOut(item.getMaterialId(), e.getWarehouseId(), item.getActualQty(), null, null, "销售出库", e.getCode());
            //update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-销售出库集成（FIFO选批次）-----------
            // 降级：总开关开启 + 物料 batch_enabled=1 时按 FIFO 选批次出库（不影响 ADR 0001 锁定成本逻辑）
            // 销售出库物料移动平均成本仍按"出库时锁定"，但批次选择走 FIFO 单独链路
            if (batchSwitchOn) {
                MesMaterial mat = materialMapper.selectById(item.getMaterialId());
                if (mat != null && Integer.valueOf(1).equals(mat.getBatchEnabled())) {
                    //update-begin---author:ruiwancheng---date:2026-08-01---for: P0-5 铁拳团-批次成本落点决议：保持现状（落 c_mes_batch_ledger.unitCost 不写业务明细表）-----------
                    // 决议：stockOutFifo() 内部已按 FIFO 顺序为每个扣减批次生成一条 ledger 流水（in/out_qty + unitCost），
                    //       业务查询成本走 c_mes_batch_ledger 即可。c_mes_sales_outbound_item 当前仅有 unitPrice（销售价）字段，
                    //       没有 unitCost 字段。ADR 0002 拍板前不动表结构，避免与 ADR 0001（销售出库走物料移动平均成本不重算）冲突。
                    java.util.List<org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService.BatchOutDetail> batchCosts = batchInventoryService.stockOutFifo(
                        item.getMaterialId(), e.getWarehouseId(), item.getActualQty(),
                        "4", e.getId(), e.getCode()); // bizType=4 销售出库
                    // P0-5 终态：返回值仍接收（防止 IDE 告警 + 调试可见），batchCosts 后续如需二次加工可在此处追加。
                    //update-end---author:ruiwancheng---date:2026-08-01---for: P0-5 铁拳团-批次成本落点决议-----------
                }
            }
            //update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-销售出库集成-----------
        }
    }

    /** 3. 联动更新发货单状态：全部物料足量出库才置已出库(3)，部分出库保持2（oracle-review 前置缺陷修复） */
    private void updateDeliveryNoteStatus(MesSalesOutbound e, String username, Date now) {
        if (e.getDeliveryNoteId() != null) {
            boolean allOutbounded = checkDeliveryAllOutbounded(e.getDeliveryNoteId());
            if (allOutbounded) {
                deliveryNoteMapper.updateStatus(e.getDeliveryNoteId(), "3", "2", username, now);
            }
        }
    }

    /** 4. 自动生成应收单（唯一索引 uk_rec_source_bill 防重复） */
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-自动生成应收-----------
    private void generateReceivable(MesSalesOutbound e, Date now) {
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
        //update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-应收报错保护（不阻塞出库主流程）-----------
        try { receivableService.save(ar); } catch (org.springframework.dao.DuplicateKeyException ex) { /* 已生成 */ } catch (Exception ex) { /* 不阻塞出库 */ }
        //update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-应收报错保护-----------
    }
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-自动生成应收-----------

    /** 5. 检查销售订单是否全部出库完成→自动置已发货(4) */
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 已发货状态自动流转-----------
    private void updateSalesOrderStatus(MesSalesOutbound e, String username, Date now) {
        if (StringUtils.hasText(e.getSalesOrderId())) {
            MesSalesOrder order = salesOrderMapper.selectById(e.getSalesOrderId());
            if (order != null && "3".equals(order.getStatus())) {
                java.util.Map<String, java.math.BigDecimal> shippedMap = new java.util.HashMap<>();
                for (MesSalesOutbound ob : baseMapper.selectList(
                    new QueryWrapper<MesSalesOutbound>().eq("sales_order_id", e.getSalesOrderId()).eq("status", "3"))) {
                    for (MesSalesOutboundItem oi : itemMapper.selectList(
                        new LambdaQueryWrapper<MesSalesOutboundItem>().eq(MesSalesOutboundItem::getOutboundId, ob.getId()))) {
                        shippedMap.merge(oi.getMaterialId(), oi.getActualQty() != null ? oi.getActualQty() : java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
                    }
                }
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
    }
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 已发货状态自动流转-----------

    //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-05 取消审核红冲-恢复库存+应收作废-----------
    @Override @Transactional(rollbackFor = Exception.class)
    public void cancel(String id) {
        MesSalesOutbound e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("出库单不存在");
        // 如果已审核(status=3)，需要回冲库存和应收
        if ("3".equals(e.getStatus())) {
            // 恢复库存
            for (MesSalesOutboundItem item : e.getItems()) {
                inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getActualQty(), null, null, "销售出库红冲", e.getCode());
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
        validateHeader(e);
        List<MesDeliveryNoteItem> dnItems = loadDeliveryNoteItems(e.getDeliveryNoteId());
        List<MesSalesOutboundItem> items = e.getItems();
        for (int i = 0; i < items.size(); i++) {
            validateItem(i, items.get(i), e, dnItems);
        }
    }

    /** 头信息校验：编码/仓库/发货单/销售订单/出库日期/明细非空（P0-02/03/10 + P1-01/04） */
    private void validateHeader(MesSalesOutbound e) {
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
    }

    /** 查发货单明细作为校验基准 */
    private List<MesDeliveryNoteItem> loadDeliveryNoteItems(String deliveryNoteId) {
        LambdaQueryWrapper<MesDeliveryNoteItem> dnQw = new LambdaQueryWrapper<>();
        dnQw.eq(MesDeliveryNoteItem::getDeliveryId, deliveryNoteId);
        return deliveryNoteItemMapper.selectList(dnQw);
    }

    /** 单行明细校验 + 累计出库量 + 实出数量上限（P0-03/10） */
    private void validateItem(int i, MesSalesOutboundItem item, MesSalesOutbound e, List<MesDeliveryNoteItem> dnItems) {
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
    }
    //update-end---author:ruiwancheng---date:2026-07-16---for: P0-02/03/10来源+数量校验-----------

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

    // P0修复: 检查发货单是否全部出库完成（汇总所有关联出库的实出量 vs 发货量，防部分出库就置3）
    private boolean checkDeliveryAllOutbounded(String deliveryNoteId) {
        // 查发货单明细
        LambdaQueryWrapper<MesDeliveryNoteItem> dqw = new LambdaQueryWrapper<>();
        dqw.eq(MesDeliveryNoteItem::getDeliveryId, deliveryNoteId);
        java.util.List<MesDeliveryNoteItem> dnItems = deliveryNoteItemMapper.selectList(dqw);
        // 查该发货单下所有已审核出库
        QueryWrapper<MesSalesOutbound> oqw = new QueryWrapper<>();
        oqw.eq("delivery_note_id", deliveryNoteId).eq("status", "3");
        java.util.List<MesSalesOutbound> obs = baseMapper.selectList(oqw);
        // 汇总实际出库量
        java.util.Map<String, java.math.BigDecimal> outQtyMap = new java.util.HashMap<>();
        for (MesSalesOutbound ob : obs) {
            LambdaQueryWrapper<MesSalesOutboundItem> iqw = new LambdaQueryWrapper<>();
            iqw.eq(MesSalesOutboundItem::getOutboundId, ob.getId());
            for (MesSalesOutboundItem oi : itemMapper.selectList(iqw)) {
                outQtyMap.merge(oi.getMaterialId(), oi.getActualQty() != null ? oi.getActualQty() : java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
            }
        }
        // 逐行比对
        for (MesDeliveryNoteItem dnItem : dnItems) {
            java.math.BigDecimal outQty = outQtyMap.getOrDefault(dnItem.getMaterialId(), java.math.BigDecimal.ZERO);
            if (outQty.compareTo(dnItem.getDeliveryQty()) < 0) return false;
        }
        return !dnItems.isEmpty();
    }
    private String getUser() { try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception ex) { return "system"; } }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service实现-----------
