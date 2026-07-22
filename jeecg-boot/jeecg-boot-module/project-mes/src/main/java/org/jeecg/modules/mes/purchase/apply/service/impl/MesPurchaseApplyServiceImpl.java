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
import java.util.Collection;
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
        //update-begin---author:ruisuyun---date:2026-07-22---for: P0修复-敏感字段置null防客户端注入(照抄采购订单+入库修复)-----------
        entity.setDelFlag(null);
        entity.setCreateBy(null);
        entity.setCreateTime(null);
        //update-end---author:ruisuyun---date:2026-07-22---for: P0修复-敏感字段置null防客户端注入-----------
        validateApply(entity);
        entity.setStatus("1"); // 强制草稿状态，防止API绕过状态机
        // apply items无定价，totalAmount由用户手动填写，不自动计算
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
        // apply items无定价，totalAmount由用户手动填写，不自动计算
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

    //update-begin---author:ruisuyun---date:2026-07-22---for: 链路P0-申请审核端点(照抄采购订单audit模式)-----------
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        String username = getCurrentUsername();
        Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：申请不存在或状态已变更，请刷新后重试");
    }
    //update-end---author:ruisuyun---date:2026-07-22---for: 链路P0-申请审核端点-----------

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

    //update-begin---author:ruisuyun---date:2026-07-22---for: P1修复-删除死代码calcTotal(如果有定价需求再实现)-----------
    // calcTotal 已删除——方法体为 setTotalAmount(BigDecimal.ZERO)，与注释"用户手动填写"矛盾，且从未被调用
    //update-end---author:ruisuyun---date:2026-07-22---for: P1修复-删除死代码-----------

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
