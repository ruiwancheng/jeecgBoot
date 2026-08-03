//update-begin---author:ruiwancheng---date:2026-07-16---for: P0修复-入库校验超量+关联订单+审计字段-----------
package org.jeecg.modules.mes.purchase.receipt.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrder;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItem;
import org.jeecg.modules.mes.purchase.order.mapper.MesPurchaseOrderItemMapper;
import org.jeecg.modules.mes.purchase.order.mapper.MesPurchaseOrderMapper;
import org.jeecg.modules.mes.basic.service.IMesInventoryService;
import org.jeecg.modules.mes.basic.service.IMesMaterialService;
import org.jeecg.modules.mes.finance.payable.entity.MesPayable;
import org.jeecg.modules.mes.finance.payable.service.IMesPayableService;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceipt;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceiptItem;
import org.jeecg.modules.mes.purchase.receipt.mapper.MesPurchaseReceiptItemMapper;
import org.jeecg.modules.mes.purchase.receipt.mapper.MesPurchaseReceiptMapper;
import org.jeecg.modules.mes.purchase.receipt.service.IMesPurchaseReceiptService;
import org.jeecg.modules.mes.batch.master.service.IMesBatchService;
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.jeecg.modules.mes.basic.entity.MesMaterial;
import org.jeecg.modules.mes.basic.mapper.MesMaterialMapper;import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class MesPurchaseReceiptServiceImpl extends ServiceImpl<MesPurchaseReceiptMapper, MesPurchaseReceipt> implements IMesPurchaseReceiptService {

    @Autowired private MesPurchaseReceiptItemMapper itemMapper;
    @Autowired private MesPurchaseOrderMapper purchaseOrderMapper;
    @Autowired private MesPurchaseOrderItemMapper purchaseOrderItemMapper;
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-采购入库-----------
    @Autowired private IMesInventoryService inventoryService;
    //update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-采购收货集成依赖-----------
    @Autowired private IMesBatchService batchService;
    @Autowired private IMesBatchInventoryService batchInventoryService;
    @Autowired private MesMaterialMapper materialMapper;
    //update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-采购收货集成依赖-----------
    //update-begin---author:ruiwancheng---date:20260801---for:【生产批次总开关】注入总开关 Service-----------
    @Autowired private org.jeecg.modules.mes.system.service.IMesGlobalSwitchService globalSwitchService;
    //update-end---author:ruiwancheng---date:20260801---for:【生产批次总开关】总开关注入-----------
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 库存联动-采购入库-----------
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-生成应付-----------
    @Autowired private IMesPayableService payableService;
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 业财联动-生成应付-----------
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 成本价体系-物料成本更新-----------
    @Autowired private IMesMaterialService materialService;
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 成本价体系-物料成本更新-----------

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
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-saveWithItems补充delFlag防护(与updateWithItems对齐)-----------
        entity.setDelFlag(null);
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-saveWithItems补充delFlag防护-----------
        // 【P0修复-slice-1.3】入库单 supplierId 兜底
        // 测试/历史数据可能不传 supplierId; 从关联的 purchaseOrderId 反查订单的 supplierId。
        // 此兜底是后续 audit() 路径生成 MesPayable 必须 supplier_id NOT NULL 的前置条件。
        if (!org.springframework.util.StringUtils.hasText(entity.getSupplierId())
                && org.springframework.util.StringUtils.hasText(entity.getPurchaseOrderId())) {
            MesPurchaseOrder po = purchaseOrderMapper.selectById(entity.getPurchaseOrderId());
            if (po != null && org.springframework.util.StringUtils.hasText(po.getSupplierId())) {
                entity.setSupplierId(po.getSupplierId());
            }
        }
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
        //update-begin P0-3 编辑改FOR UPDATE行锁防并发击穿
        MesPurchaseReceipt exist = baseMapper.selectByIdForUpdate(entity.getId());
        if (exist == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("当前状态不允许编辑，仅草稿状态可操作");
        //update-end P0-3
        //update-begin P1-8 敏感字段置null
        entity.setDelFlag(null); entity.setCreateBy(null); entity.setCreateTime(null);
        entity.setStatus(null); // 防止客户端注入覆盖status
        //update-end P1-8
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
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-删除改用FOR UPDATE行锁防并发击穿(与编辑路径对齐，照抄采购订单P0-3修复)-----------
        MesPurchaseReceipt exist = baseMapper.selectByIdForUpdate(id);
        if (exist == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态入库单禁止删除");
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-删除FOR UPDATE行锁-----------
        LambdaQueryWrapper<MesPurchaseReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseReceiptItem::getReceiptId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        MesPurchaseReceipt e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("入库单不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核");
        //update-begin---author:ruiwancheng---date:20260801---for:【生产批次总开关】事务内仅查一次总开关状态-----------
        // 全局总开关：关闭时不创建采购批次（避免总开关关闭时还在写入批次库存造成数据漂移）
        final boolean batchSwitchOn = globalSwitchService.isEnabled("mes_batch_enabled");
        //update-end---author:ruiwancheng---date:20260801---for:【生产批次总开关】总开关缓存-----------

        // ← 【P0修复-顺序调换】先改状态（原子守卫），确认成功后再执行副作用（oracle-review①）
        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：入库单不存在或状态已变更，请刷新后重试");

        // 审核成功后：原子扣减 → 计算成本 → 更新物料成本 → 加库存 → 算应付税额
        java.math.BigDecimal totalAmount = java.math.BigDecimal.ZERO;
        java.math.BigDecimal totalTax = java.math.BigDecimal.ZERO;
        for (MesPurchaseReceiptItem item : e.getItems()) {
            // 【P0修复-原子扣减】单SQL防超收（oracle-review④自然消解，替代旧的历史汇总校验）
            int ar = purchaseOrderItemMapper.atomicReceive(e.getPurchaseOrderId(), item.getMaterialId(), item.getReceiptQuantity());
            if (ar == 0) throw new JeecgBootException("物料[" + item.getMaterialId() + "]累计入库量超采购数量，请检查");

            // 从采购订单行取单价+税率（同物料多行取第一行——后续 order_item_id 关联后再优化）
            LambdaQueryWrapper<MesPurchaseOrderItem> piQw = new LambdaQueryWrapper<>();
            piQw.eq(MesPurchaseOrderItem::getOrderId, e.getPurchaseOrderId()).eq(MesPurchaseOrderItem::getMaterialId, item.getMaterialId());
            java.util.List<MesPurchaseOrderItem> orderItems = purchaseOrderItemMapper.selectList(piQw);

            // V10.0.1 方案1：优先用 item 自身字段（前端表单带出），缺省再反查订单行兜底
            //   订单物料路径：onOrderSelected 把 unitPrice/taxRate 写入 item，audit 不必再反查
            //   手动物料路径：onMaterialChange 把物料 standardPrice 写入 unitPrice，taxRate 默认 0.13
            //   兜底路径：item 字段为空时（如历史数据/调用方未填），反查订单行取第一行
            java.math.BigDecimal unitPriceWithTax = item.getUnitPrice();
            java.math.BigDecimal taxRate = item.getTaxRate();
            if (unitPriceWithTax == null || taxRate == null) {
                if (!orderItems.isEmpty() && orderItems.get(0).getUnitPrice() != null) {
                    if (unitPriceWithTax == null) unitPriceWithTax = orderItems.get(0).getUnitPrice();
                    if (taxRate == null) taxRate = orderItems.get(0).getTaxRate();
                }
            }
            if (unitPriceWithTax == null) unitPriceWithTax = java.math.BigDecimal.ZERO;
            if (taxRate == null) taxRate = new java.math.BigDecimal("0.13");

            // V9.7.1 修复: 采购订单 unitPrice 即不含税成本单价，不再除以(1+taxRate)
            java.math.BigDecimal unitCost = unitPriceWithTax;  // unitPrice 本身就是不含税价
            java.math.BigDecimal costAmount = unitCost.multiply(item.getReceiptQuantity()).setScale(2, java.math.RoundingMode.HALF_UP);

            // 【关键顺序】先更新物料移动平均成本（读入库前库存量），再入库
            materialService.updateMovingAvgCostOnStockIn(item.getMaterialId(), item.getReceiptQuantity(), unitCost, e.getWarehouseId(), "采购入库", e.getCode());

            // 入库（带成本参数）
            inventoryService.stockIn(item.getMaterialId(), e.getWarehouseId(), item.getReceiptQuantity(), unitCost, costAmount, "采购入库", e.getCode());
            //update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-采购收货集成（可选创建批次）-----------
            // 降级：总开关开启 + 物料 batch_enabled=1 时可选创建批次（采购收货可创建采购批次）
            if (batchSwitchOn) {
                MesMaterial mat = materialMapper.selectById(item.getMaterialId());
                if (mat != null && Integer.valueOf(1).equals(mat.getBatchEnabled())) {
                    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-采购入库审核透传明细 shelfLife/expiryDate 到批次主档-----------
                    // V10.0.0 保质期+有效期至：透传明细行数据到批次主档
                    String batchId = batchService.createBatchWithManualNo(
                        item.getMaterialId(),
                        item.getBatchNo(),     // 从明细行取（为 null/空时报错）
                        "1",                    // origin_type=1 采购入库
                        e.getId(), e.getCode(),
                        item.getReceiptQuantity(), unitCost,
                        item.getProductionDate(),  // 从明细行取（可空）
                        item.getExpiryDate(),      // V10.0.0 透传明细行"有效期至"（可空）
                        item.getShelfLife());      // V10.0.0 透传明细行"保质期(天)"（可空）
                    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-采购入库审核透传明细 shelfLife/expiryDate 到批次主档-----------
                    batchInventoryService.stockIn(batchId, e.getWarehouseId(),
                        item.getReceiptQuantity(), "1", e.getId(), e.getCode());
                }
            }
            //update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-采购收货集成-----------

            // 应付: 不含税金额 + 税额
            item.setUnitPrice(unitPriceWithTax);
            java.math.BigDecimal lineAmount = unitPriceWithTax.multiply(item.getReceiptQuantity()).setScale(2, java.math.RoundingMode.HALF_UP);
            item.setAmount(lineAmount);
            totalAmount = totalAmount.add(lineAmount);
            totalTax = totalTax.add(lineAmount.multiply(taxRate).setScale(2, java.math.RoundingMode.HALF_UP));
            //update-begin---author:ruiwancheng---date:20260802---for: V10.0.1 采购入库-明细行 unitPrice/amount 回写 DB（修复工人自报范围外 bug）-----------
            itemMapper.updateById(item);
            //update-end---author:ruiwancheng---date:20260802---for: V10.0.1 采购入库-明细行 unitPrice/amount 回写 DB-----------
        }

        // 【P1修复-订单状态回写】按累计入库量推进状态（oracle-review P1-1）
        purchaseOrderMapper.markPartiallyReceived(e.getPurchaseOrderId(), username, now);
        purchaseOrderMapper.markFullyReceived(e.getPurchaseOrderId(), username, now);

        // 应付（税额取订单行税率，不再硬编码）
        MesPayable ap = new MesPayable();
        ap.setCode("AP-" + e.getCode());
        // 【P0修复-slice-1.3】应付单 supplier_id NOT NULL 兜底
        // 测试或历史数据可能让 receipt.getSupplierId() 为 null;
        // 从关联的 purchaseOrderId 反查 c_mes_purchase_order.supplier_id。
        if (!org.springframework.util.StringUtils.hasText(e.getSupplierId())
                && org.springframework.util.StringUtils.hasText(e.getPurchaseOrderId())) {
            MesPurchaseOrder po = purchaseOrderMapper.selectById(e.getPurchaseOrderId());
            if (po != null && org.springframework.util.StringUtils.hasText(po.getSupplierId())) {
                e.setSupplierId(po.getSupplierId());
            }
        }
        ap.setSupplierId(e.getSupplierId());
        if (!org.springframework.util.StringUtils.hasText(ap.getSupplierId())) {
            throw new JeecgBootException("入库单缺少供应商，请检查上游采购订单是否已保存");
        }
        ap.setSourceType("采购入库");
        ap.setSourceBillId(e.getId());
        ap.setSourceBillNo(e.getCode());
        ap.setAmount(totalAmount);
        ap.setPaidAmount(java.math.BigDecimal.ZERO);
        ap.setUnsettledAmount(totalAmount);
        ap.setTaxAmount(totalTax.setScale(2, java.math.RoundingMode.HALF_UP));
        ap.setCreditPeriod(30);
        ap.setDueDate(new Date(now.getTime() + 30L * 86400000));
        ap.setStatus("1");
        try { payableService.save(ap); } catch (org.springframework.dao.DuplicateKeyException ex) { /* 已生成 */ }
    }
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------

    //update-begin---author:ruisuyun---date:2026-07-22---for: 链路P1-入库反审核(已审核→草稿)-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unaudit(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.unauditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("反审核失败：入库单不存在或状态不是已审核，请刷新后重试");
    }
    //update-end---author:ruisuyun---date:2026-07-22---for: 链路P1-入库反审核-----------

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-批量删除改用逐行FOR UPDATE锁防并发击穿(与removeWithItems对齐)-----------
        for (Object id : list) {
            MesPurchaseReceipt exist = baseMapper.selectByIdForUpdate((String) id);
            if (exist == null) throw new JeecgBootException("入库单[" + id + "]不存在");
            if (!"1".equals(exist.getStatus()))
                throw new JeecgBootException("非草稿状态入库单[" + exist.getCode() + "]禁止删除");
        }
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-批量删除FOR UPDATE行锁-----------
        // 批量删明细行
        LambdaQueryWrapper<MesPurchaseReceiptItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesPurchaseReceiptItem::getReceiptId, list);
        itemMapper.delete(delQw);
        // 批量删主表
        return super.removeByIds(list);
    }

    private void validateReceipt(MesPurchaseReceipt entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("入库单号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("入库单号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getPurchaseOrderId())) throw new JeecgBootException("关联采购订单不能为空");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("仓库不能为空");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
        // P0修复：校验关联采购订单存在且状态可入库
        MesPurchaseOrder order = purchaseOrderMapper.selectById(entity.getPurchaseOrderId());
        if (order == null) throw new JeecgBootException("关联采购订单不存在");
        if (!"3".equals(order.getStatus()) && !"4".equals(order.getStatus()))
            throw new JeecgBootException("采购订单状态不允许入库，仅已确认或部分到货状态可入库");
        // 加载订单物料行用于超量校验
        LambdaQueryWrapper<MesPurchaseOrderItem> oqw = new LambdaQueryWrapper<>();
        oqw.eq(MesPurchaseOrderItem::getOrderId, order.getId());
        List<MesPurchaseOrderItem> orderItems = purchaseOrderItemMapper.selectList(oqw);
        Map<String, BigDecimal> orderQtyMap = orderItems.stream()
                .collect(Collectors.toMap(MesPurchaseOrderItem::getMaterialId, MesPurchaseOrderItem::getQuantity, (a, b) -> a));
        // P0-004修复：累计历史入库量，防止同一订单多次入库累计超量
        Map<String, BigDecimal> historyQtyMap = new HashMap<>();
        LambdaQueryWrapper<MesPurchaseReceipt> rqw = new LambdaQueryWrapper<>();
        rqw.eq(MesPurchaseReceipt::getPurchaseOrderId, entity.getPurchaseOrderId());
        if (StringUtils.hasText(entity.getId())) {
            rqw.ne(MesPurchaseReceipt::getId, entity.getId()); // 编辑时排除自身
        }
        List<MesPurchaseReceipt> existingReceipts = baseMapper.selectList(rqw);
        if (!existingReceipts.isEmpty()) {
            List<String> existingIds = existingReceipts.stream().map(MesPurchaseReceipt::getId).collect(Collectors.toList());
            LambdaQueryWrapper<MesPurchaseReceiptItem> hiqw = new LambdaQueryWrapper<>();
            hiqw.in(MesPurchaseReceiptItem::getReceiptId, existingIds);
            List<MesPurchaseReceiptItem> historyItems = itemMapper.selectList(hiqw);
            for (MesPurchaseReceiptItem hi : historyItems) {
                historyQtyMap.merge(hi.getMaterialId(), hi.getReceiptQuantity() != null ? hi.getReceiptQuantity() : BigDecimal.ZERO, BigDecimal::add);
            }
        }
        // 逐行校验
        List<MesPurchaseReceiptItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个入库行");
        for (int i = 0; i < items.size(); i++) {
            MesPurchaseReceiptItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getReceiptQuantity() == null || item.getReceiptQuantity().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行入库数量必须大于0");
            // P0-b 修复：订单外物料拦截（orderQtyMap中不存在的物料报错，不再静默跳过）
            BigDecimal orderQty = orderQtyMap.get(item.getMaterialId());
            if (orderQty == null)
                throw new JeecgBootException("第" + (i+1) + "行物料不在采购订单中");
            // 累计校验（历史已入库 + 本次入库）<= 采购数量
            BigDecimal historyQty = historyQtyMap.getOrDefault(item.getMaterialId(), BigDecimal.ZERO);
            BigDecimal totalAfter = historyQty.add(item.getReceiptQuantity());
            if (totalAfter.compareTo(orderQty) > 0) {
                    throw new JeecgBootException("第" + (i+1) + "行累计入库量(" + totalAfter + ")超过采购数量(" + orderQty
                            + ")，历史已入库" + historyQty + "，本次入库" + item.getReceiptQuantity());
                }
            // P0修复：白名单校验质检结果
            if (StringUtils.hasText(item.getQcResult())) {
                Set<String> validQc = new HashSet<>(Arrays.asList("1", "2", "3"));
                if (!validQc.contains(item.getQcResult()))
                    throw new JeecgBootException("第" + (i+1) + "行质检结果值无效");
            }
            item.setLineNo(i + 1);
            item.setReceiptId(entity.getId());
        }
    }

    //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-checkStatus已删除-所有调用点已改为内联FOR UPDATE(与采购订单模式对齐)-----------
    // checkStatus 辅助方法已删除——普通SELECT无锁容易让人误以为"状态校验已经安全"
    // 编辑(L.86)、删除单(L.108)、批量删除(L.178) 均直接使用 selectByIdForUpdate + 内联状态判断
    //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-checkStatus已删除-----------

    private void saveItems(MesPurchaseReceipt entity) {
        String username = getCurrentUsername();
        Date now = new Date();
        for (MesPurchaseReceiptItem item : entity.getItems()) {
            item.setReceiptId(entity.getId());
            // P0修复：明细行补审计字段
            if (item.getCreateBy() == null) item.setCreateBy(username);
            if (item.getCreateTime() == null) item.setCreateTime(now);
            item.setUpdateBy(username);
            item.setUpdateTime(now);
            itemMapper.insert(item);
        }
    }

    //update-begin---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------
    @Override
    public java.util.List<org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItemForReceipt> loadOrderItemsForReceipt(String orderId) {
        LambdaQueryWrapper<MesPurchaseOrderItem> qw = new LambdaQueryWrapper<>();
        qw.eq(MesPurchaseOrderItem::getOrderId, orderId).orderByAsc(MesPurchaseOrderItem::getLineNo);
        java.util.List<MesPurchaseOrderItem> orderItems = purchaseOrderItemMapper.selectList(qw);
        java.util.List<org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItemForReceipt> result = new java.util.ArrayList<>();
        for (MesPurchaseOrderItem item : orderItems) {
            org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItemForReceipt dto =
                new org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItemForReceipt()
                    .setItemId(item.getId())
                    .setMaterialId(item.getMaterialId())
                    .setOrderQty(item.getQuantity())
                    .setReceivedQty(item.getReceivedQty() != null ? item.getReceivedQty() : java.math.BigDecimal.ZERO)
                    .setRemainQty(item.getQuantity().subtract(item.getReceivedQty() != null ? item.getReceivedQty() : java.math.BigDecimal.ZERO))
                    .setUnitPrice(item.getUnitPrice())
                    .setTaxRate(item.getTaxRate());
            result.add(dto);
        }
        return result;
    }
    //update-end---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------

    private String getCurrentUsername() {
        try {
            LoginUser user = (LoginUser) SecurityUtils.getSubject().getPrincipal();
            return user != null ? user.getUsername() : "system";
        } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-16---for: P0修复-入库校验超量+关联订单+审计字段-----------
