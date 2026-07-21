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
import org.jeecg.modules.mes.sales.entity.MesSalesOrderItem;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesDeliveryNoteMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderItemMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOrderMapper;
import org.jeecg.modules.mes.sales.mapper.MesSalesOutboundMapper;
import org.jeecg.modules.mes.finance.receivable.mapper.MesReceivableMapper;
import org.jeecg.modules.mes.finance.receivable.entity.MesReceivable;
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
    @Autowired
    private MesSalesOrderMapper salesOrderMapper;
    @Autowired
    private MesSalesOrderItemMapper salesOrderItemMapper;
    @Autowired
    private MesSalesOutboundMapper outboundMapper;
    @Autowired
    private MesReceivableMapper receivableMapper;

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
        //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-03 并发超量校验——SELECT FOR UPDATE锁订单行-----------
        if (StringUtils.hasText(entity.getSalesOrderId())) {
            salesOrderMapper.selectByIdForUpdate(entity.getSalesOrderId());
        }
        //update-end---author:ruiwancheng---date:2026-07-18---for: P0-03 并发超量校验——SELECT FOR UPDATE锁订单行-----------
        validate(entity);
        entity.setStatus("1"); // 强制草稿，禁止绕过前端直接设状态
        QueryWrapper<MesDeliveryNote> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) throw new JeecgBootException("发货单编码已存在");
        //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到save之前-----------
        calcTotal(entity);
        //update-end---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到save之前-----------
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
        entity.setStatus("1"); // 编辑时保持草稿
        QueryWrapper<MesDeliveryNote> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("发货单编码已存在");
        //update-begin---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到updateById之前-----------
        calcTotal(entity);
        //update-end---author:ruiwancheng---date:2026-07-19---for: P0-01 calcTotal移到updateById之前-----------
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

    //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-04 批量删除改用super.removeByIds+批量删明细-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(java.util.Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        for (Object id : list) checkStatus((String) id, "删除");
        // 批量删除明细行
        QueryWrapper<MesDeliveryNoteItem> itemQw = new QueryWrapper<>();
        itemQw.in("delivery_id", list);
        itemMapper.delete(itemQw);
        return super.removeByIds(list);
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: P0-04 批量删除改用super.removeByIds+批量删明细-----------

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------
    @Override @Transactional(rollbackFor = Exception.class)
    public void submit(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.submitWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("提交失败：发货单不存在或状态已变更，请刷新后重试");
    }
    @Override @Transactional(rollbackFor = Exception.class)
    public void sign(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.signWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("签收失败：发货单不存在或状态已变更（需为已出库），请刷新后重试");
    }
    @Override @Transactional(rollbackFor = Exception.class)
    public void cancel(String id) {
        String username = getCurrentUsername(); Date now = new Date();
        int rows = baseMapper.cancelWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("取消失败：发货单不存在或状态已变更，请刷新后重试");
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------

    private void validate(MesDeliveryNote entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("发货单编码不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("发货单编码长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getSalesOrderId())) throw new JeecgBootException("销售订单不能为空");
        if (!StringUtils.hasText(entity.getWarehouseId())) throw new JeecgBootException("发货仓库不能为空");
        //update-begin---author:ruiwancheng---date:2026-07-18---for: P1-01 发货日期必填校验-----------
        if (entity.getDeliveryDate() == null) throw new JeecgBootException("发货日期不能为空");
        //update-end---author:ruiwancheng---date:2026-07-18---for: P1-01 发货日期必填校验-----------
        // 校验销售订单存在
        if (salesOrderMapper.selectById(entity.getSalesOrderId()) == null)
            throw new JeecgBootException("销售订单不存在");
        List<MesDeliveryNoteItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一个发货明细");
        for (int i = 0; i < items.size(); i++) {
            MesDeliveryNoteItem item = items.get(i);
            if (!StringUtils.hasText(item.getMaterialId())) throw new JeecgBootException("第" + (i+1) + "行物料不能为空");
            if (item.getDeliveryQty() == null || item.getDeliveryQty().compareTo(BigDecimal.ZERO) <= 0)
                throw new JeecgBootException("第" + (i+1) + "行发货数量必须大于0");
            // P0-01: 校验发货数量不超过订单未发货数量
            checkDeliveryQty(entity, item, i + 1);
            //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-从订单行取单价算金额-----------
            if (item.getUnitPrice() == null || item.getUnitPrice().compareTo(BigDecimal.ZERO) == 0) {
                LambdaQueryWrapper<MesSalesOrderItem> piQw = new LambdaQueryWrapper<>();
                piQw.eq(MesSalesOrderItem::getOrderId, entity.getSalesOrderId())
                   .eq(MesSalesOrderItem::getMaterialId, item.getMaterialId());
                java.util.List<MesSalesOrderItem> ol = salesOrderItemMapper.selectList(piQw);
                if (!ol.isEmpty() && ol.get(0).getUnitPrice() != null) {
                    item.setUnitPrice(ol.get(0).getUnitPrice());
                }
            }
            if (item.getUnitPrice() == null) item.setUnitPrice(BigDecimal.ZERO);
            item.setAmount(item.getDeliveryQty().multiply(item.getUnitPrice()).setScale(2, java.math.RoundingMode.HALF_UP));
            //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-从订单行取单价算金额-----------
        }
    }

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-计算合计-----------
    private void calcTotal(MesDeliveryNote entity) {
        BigDecimal total = BigDecimal.ZERO;
        for (MesDeliveryNoteItem item : entity.getItems()) {
            if (item.getAmount() != null) total = total.add(item.getAmount());
        }
        entity.setTotalAmount(total.setScale(2, java.math.RoundingMode.HALF_UP));
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 金额字段补齐-计算合计-----------

    //update-begin---author:ruiwancheng---date:2026-07-18---for: P0-05 N+1查询优化——批量聚合替代嵌套循环-----------
    private void checkDeliveryQty(MesDeliveryNote entity, MesDeliveryNoteItem item, int lineNo) {
        // 查订单行的订单数量
        LambdaQueryWrapper<MesSalesOrderItem> oqw = new LambdaQueryWrapper<>();
        oqw.eq(MesSalesOrderItem::getOrderId, entity.getSalesOrderId())
          .eq(MesSalesOrderItem::getMaterialId, item.getMaterialId());
        List<MesSalesOrderItem> orderLines = salesOrderItemMapper.selectList(oqw);
        BigDecimal orderedQty = BigDecimal.ZERO;
        for (MesSalesOrderItem ol : orderLines) {
            if (ol.getQuantity() != null) orderedQty = orderedQty.add(ol.getQuantity());
        }
        if (orderedQty.compareTo(BigDecimal.ZERO) == 0)
            throw new JeecgBootException("第" + lineNo + "行物料在销售订单中未找到或数量为0");

        // 一次性查所有已有发货单的明细，内存聚合，避免N+1
        String selfId = entity.getId();
        QueryWrapper<MesDeliveryNote> dnQw = new QueryWrapper<>();
        dnQw.eq("sales_order_id", entity.getSalesOrderId());
        List<MesDeliveryNote> existingNotes = baseMapper.selectList(dnQw);

        BigDecimal shippedQty = BigDecimal.ZERO;
        if (!existingNotes.isEmpty()) {
            List<String> dnIds = new java.util.ArrayList<>();
            for (MesDeliveryNote dn : existingNotes) {
                if (!dn.getId().equals(selfId)) dnIds.add(dn.getId());
            }
            if (!dnIds.isEmpty()) {
                QueryWrapper<MesDeliveryNoteItem> iqw = new QueryWrapper<>();
                iqw.in("delivery_id", dnIds).eq("material_id", item.getMaterialId());
                List<MesDeliveryNoteItem> shipped = itemMapper.selectList(iqw);
                for (MesDeliveryNoteItem si : shipped) {
                    if (si.getDeliveryQty() != null) shippedQty = shippedQty.add(si.getDeliveryQty());
                }
            }
        }

        BigDecimal remaining = orderedQty.subtract(shippedQty);
        if (item.getDeliveryQty().compareTo(remaining) > 0)
            throw new JeecgBootException("第" + lineNo + "行发货数量(" + item.getDeliveryQty()
                + ")超过未发货数量(" + remaining + ")，已订" + orderedQty + "，已发" + shippedQty);
    }
    //update-end---author:ruiwancheng---date:2026-07-18---for: P0-05 N+1查询优化——批量聚合替代嵌套循环-----------

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
