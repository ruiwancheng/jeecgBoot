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
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrder;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItem;
import org.jeecg.modules.mes.purchase.order.service.IMesPurchaseOrderService;
import org.jeecg.modules.mes.basic.service.IMesCodeRuleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Date;
import java.util.List;

@Service
public class MesPurchaseApplyServiceImpl extends ServiceImpl<MesPurchaseApplyMapper, MesPurchaseApply> implements IMesPurchaseApplyService {

    @Autowired
    private MesPurchaseApplyItemMapper itemMapper;
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-自动生成订单+反审核-----------
    @Autowired
    private IMesPurchaseOrderService purchaseOrderService;
    @Autowired
    private IMesCodeRuleService codeRuleService;
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-自动生成订单+反审核-----------

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
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-敏感字段置null防客户端注入(照抄采购订单+入库修复)-----------
        entity.setDelFlag(null);
        entity.setCreateBy(null);
        entity.setCreateTime(null);
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-敏感字段置null防客户端注入-----------
        validateApply(entity);
        entity.setStatus("1"); // 强制草稿状态，防止API绕过状态机
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
            //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-resurrect校验影响行数防并发复活(照抄采购订单修复)-----------
            if (baseMapper.resurrect(entity) == 0) throw new JeecgBootException("申请单号已存在");
            //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-resurrect校验影响行数-----------
        } else {
            try { super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("申请单号已存在"); }
        }
        saveItems(entity);
        //update-begin---author:ruisuyun---date:2026-07-23---for: 自动计算totalAmount=sum(quantity×unitPrice)-----------
        calcTotal(entity);
        //update-end---author:ruisuyun---date:2026-07-23---for: 自动计算totalAmount-----------
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesPurchaseApply entity) {
        if (entity.getId() == null) throw new JeecgBootException("申请ID不能为空");
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-编辑改用FOR UPDATE行锁+不回写status防并发击穿(照抄采购订单P0-3修复)-----------
        MesPurchaseApply exist = baseMapper.selectByIdForUpdate(entity.getId());
        if (exist == null) throw new JeecgBootException("申请不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态申请禁止编辑");
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-编辑FOR UPDATE行锁-----------
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-敏感字段置null防客户端注入-----------
        entity.setDelFlag(null);
        entity.setCreateBy(null);
        entity.setCreateTime(null);
        entity.setStatus(null); // 防止客户端注入覆盖status
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-敏感字段置null-----------
        validateApply(entity);
        QueryWrapper<MesPurchaseApply> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("申请单号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesPurchaseApplyItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseApplyItem::getApplyId, entity.getId());
        itemMapper.delete(delQw);
        saveItems(entity);
        //update-begin---author:ruisuyun---date:2026-07-23---for: 自动计算totalAmount=sum(quantity×unitPrice)-----------
        calcTotal(entity);
        //update-end---author:ruisuyun---date:2026-07-23---for: 自动计算totalAmount-----------
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-删除改用FOR UPDATE行锁防并发击穿(照抄采购订单P0-3修复)-----------
        MesPurchaseApply exist = baseMapper.selectByIdForUpdate(id);
        if (exist == null) throw new JeecgBootException("申请不存在");
        if (!"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态申请禁止删除");
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-删除FOR UPDATE行锁-----------
        LambdaQueryWrapper<MesPurchaseApplyItem> delQw = new LambdaQueryWrapper<>();
        delQw.eq(MesPurchaseApplyItem::getApplyId, id);
        itemMapper.delete(delQw);
        super.removeById(id);
    }

    //update-begin---author:ruiwancheng---date:2026-07-16---for: P0修复-批量删除改为批量SQL避免自调用-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-批量删除改用逐行FOR UPDATE锁防并发击穿(与removeWithItems对齐)-----------
        for (Object id : list) {
            MesPurchaseApply exist = baseMapper.selectByIdForUpdate((String) id);
            if (exist == null) throw new JeecgBootException("申请[" + id + "]不存在");
            if (!"1".equals(exist.getStatus()))
                throw new JeecgBootException("非草稿状态申请[" + exist.getCode() + "]禁止删除");
        }
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-批量删除FOR UPDATE行锁-----------
        // 批量删明细行
        LambdaQueryWrapper<MesPurchaseApplyItem> delQw = new LambdaQueryWrapper<>();
        delQw.in(MesPurchaseApplyItem::getApplyId, list);
        itemMapper.delete(delQw);
        // 批量删主表
        return super.removeByIds(list);
    }
    //update-end---author:ruiwancheng---date:2026-07-16---for: P0修复-批量删除改为批量SQL避免自调用-----------

    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-审核自动生成订单+驳回+反审核-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        String username = getCurrentUsername();
        Date now = new Date();
        // 状态机: 1草稿 → 3已审核（对齐采购订单的1→3模式，跳过2已提交）
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：申请不存在或状态已变更，请刷新后重试");
        // 审核成功后自动生成草稿采购订单
        generateDraftPurchaseOrder(id, username, now);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void reject(String id) {
        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.rejectWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("驳回失败：申请不存在或状态已变更（仅草稿可驳回），请刷新后重试");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unaudit(String id) {
        String username = getCurrentUsername();
        Date now = new Date();
        // 反审核前检查：如已生成订单且订单非草稿，禁止反审核
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesPurchaseOrder> poQw =
            new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        poQw.eq(MesPurchaseOrder::getPurchaseApplyId, id).ne(MesPurchaseOrder::getStatus, "1");
        long nonDraftCount = purchaseOrderService.count(poQw);
        if (nonDraftCount > 0) throw new JeecgBootException("已生成非草稿状态的采购订单，禁止反审核");
        int rows = baseMapper.unauditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("反审核失败：申请不存在或状态已变更（仅已审核可反审核），请刷新后重试");
        // 同步作废关联的草稿订单
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesPurchaseOrder> draftQw =
            new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        draftQw.eq(MesPurchaseOrder::getPurchaseApplyId, id).eq(MesPurchaseOrder::getStatus, "1");
        java.util.List<MesPurchaseOrder> draftOrders = purchaseOrderService.list(draftQw);
        for (MesPurchaseOrder po : draftOrders) {
            purchaseOrderService.removeWithItems(po.getId());
        }
    }

    /**
     * 审核后自动生成草稿采购订单（幂等：purchaseApplyId 已存在则跳过）
     */
    private void generateDraftPurchaseOrder(String applyId, String username, Date now) {
        // 幂等检查：是否已有订单关联此申请
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesPurchaseOrder> existQw =
            new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        existQw.eq(MesPurchaseOrder::getPurchaseApplyId, applyId);
        if (purchaseOrderService.count(existQw) > 0) return;

        MesPurchaseApply apply = baseMapper.selectById(applyId);
        if (apply == null) return;

        MesPurchaseOrder order = new MesPurchaseOrder();
        // 自动获取编码（复用已注册的 PO 编码规则）
        try {
            order.setCode(codeRuleService.nextCode("PO"));
        } catch (Exception e) {
            // 编码生成失败不阻塞审核，订单保存时 validateOrder 会报错提示
            order.setCode("PO-" + apply.getCode().replace("SQ-", ""));
        }
        order.setPurchaseApplyId(applyId);
        order.setSupplierId(apply.getSupplierId());
        order.setPurchaseType(apply.getPurchaseType());
        order.setOrderDate(new Date());
        order.setDeliveryDate(apply.getRequiredDate());
        order.setStatus("1"); // 草稿

        // 从申请行复制到订单行
        java.util.List<MesPurchaseApplyItem> applyItems =
            itemMapper.selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesPurchaseApplyItem>()
                .eq(MesPurchaseApplyItem::getApplyId, applyId).orderByAsc(MesPurchaseApplyItem::getLineNo));

        java.util.List<MesPurchaseOrderItem> orderItems = new java.util.ArrayList<>();
        for (int i = 0; i < applyItems.size(); i++) {
            MesPurchaseApplyItem ai = applyItems.get(i);
            MesPurchaseOrderItem oi = new MesPurchaseOrderItem();
            oi.setLineNo(i + 1);
            oi.setMaterialId(ai.getMaterialId());
            oi.setQuantity(ai.getQuantity());
            oi.setUnitPrice(ai.getUnitPrice());
            oi.setAmount(ai.getAmount());
            oi.setTaxRate(ai.getTaxRate() != null ? ai.getTaxRate() : new BigDecimal("0.13"));
            // ⚠️ 必须显式设 ZERO，否则 atomicReceive 的 SQL 条件永远不成立
            oi.setReceivedQty(BigDecimal.ZERO);
            orderItems.add(oi);
        }
        order.setItems(orderItems);

        // 复用现有 saveWithItems（含 validateOrder + resurrect + DuplicateKey 兜底）
        purchaseOrderService.saveWithItems(order);
    }
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-审核自动生成订单-----------

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

    //update-begin---author:ruisuyun---date:2026-07-23---for: 自动计算totalAmount=sum(quantity×unitPrice)-----------
    private void calcTotal(MesPurchaseApply entity) {
        BigDecimal total = BigDecimal.ZERO;
        List<MesPurchaseApplyItem> items = entity.getItems();
        if (items != null) {
            for (MesPurchaseApplyItem item : items) {
                BigDecimal qty = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
                BigDecimal price = item.getUnitPrice() != null ? item.getUnitPrice() : BigDecimal.ZERO;
                item.setAmount(qty.multiply(price));
                total = total.add(item.getAmount());
                // 回写明细行的金额到数据库
                itemMapper.updateById(item);
            }
        }
        entity.setTotalAmount(total);
        super.updateById(entity);
    }
    //update-end---author:ruisuyun---date:2026-07-23---for: 自动计算totalAmount-----------

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
