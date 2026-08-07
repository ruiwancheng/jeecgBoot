//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Service实现-----------
package org.jeecg.modules.mes.manufacturing.order.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.mapper.MesMaterialMapper;
import org.jeecg.modules.mes.basic.service.IMesCodeRuleService;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBom;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBomItem;
import org.jeecg.modules.mes.manufacturing.bom.mapper.MesBomItemMapper;
import org.jeecg.modules.mes.manufacturing.bom.service.IMesBomService;
import org.jeecg.modules.mes.manufacturing.order.entity.MesProductionOrder;
import org.jeecg.modules.mes.manufacturing.order.mapper.MesProductionOrderMapper;
import org.jeecg.modules.mes.manufacturing.order.service.IProductionOrderService;
import org.jeecg.modules.mes.manufacturing.picking.entity.MesProductionPicking;
import org.jeecg.modules.mes.manufacturing.picking.entity.MesProductionPickingItem;
import org.jeecg.modules.mes.manufacturing.picking.service.IProductionPickingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ProductionOrderServiceImpl extends ServiceImpl<MesProductionOrderMapper, MesProductionOrder> implements IProductionOrderService {

    //update-begin---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 release 跨服务注入（BOM/物料/编码规则/领料单/BOM子项）-----------
    @Autowired private IMesBomService bomService;
    @Autowired private MesBomItemMapper bomItemMapper;
    @Autowired private MesMaterialMapper materialMapper;
    @Autowired private IMesCodeRuleService codeRuleService;
    @Autowired private IProductionPickingService pickingService;
    //update-end---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 release 跨服务注入-----------

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean save(MesProductionOrder entity) {
        validate(entity);
        entity.setStatus("1");
        if (entity.getCompletedQty() == null) entity.setCompletedQty(BigDecimal.ZERO);
        QueryWrapper<MesProductionOrder> qw = new QueryWrapper<>(); qw.eq("code", entity.getCode());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("订单编号已存在");
        MesProductionOrder old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId()); entity.setCreateBy(old.getCreateBy()); entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername()); entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
        } else {
            try { return super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("订单编号已存在"); }
        }
        return true;
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean updateById(MesProductionOrder entity) {
        if (entity.getId() == null) throw new JeecgBootException("订单ID不能为空");
        checkStatus(entity, "edit");
        validate(entity);
        entity.setStatus("1");
        QueryWrapper<MesProductionOrder> qw = new QueryWrapper<>(); qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("订单编号已存在");
        return super.updateById(entity);
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean removeById(Serializable id) { checkStatus((String) id, "delete"); return super.removeById(id); }

    @Override @Transactional(rollbackFor = Exception.class)
    public boolean removeByIds(Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        List<MesProductionOrder> existing = baseMapper.selectBatchIds((Collection<String>) (Collection<?>) list);
        for (MesProductionOrder e : existing) {
            if (!"1".equals(e.getStatus())) throw new JeecgBootException("非草稿状态订单[" + e.getCode() + "]禁止删除");
        }
        return super.removeByIds(list);
    }

    //update-begin---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 5 端点 + generatePicking（E 复用 edit 权限）-----------
    /** 审核：草稿→已审核，校验 BOM 生效 */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        if (!StringUtils.hasText(id)) throw new JeecgBootException("订单ID不能为空");
        MesProductionOrder e = baseMapper.selectById(id);
        if (e == null) throw new JeecgBootException("订单不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿状态订单可审核");
        if (!StringUtils.hasText(e.getBomId())) throw new JeecgBootException("订单未关联BOM，请先编辑订单选择BOM");
        MesBom bom = bomService.getById(e.getBomId());
        if (bom == null) throw new JeecgBootException("关联BOM不存在");
        if (!"2".equals(bom.getStatus())) throw new JeecgBootException("BOM未生效，不能审核订单");
        e.setStatus("2");
        e.setUpdateBy(getCurrentUsername());
        e.setUpdateTime(new Date());
        super.updateById(e);
    }

    /** 下达：已审核→已下达，同事务内 BOM 子件×planQty 库存校验（C 硬阻止），生成草稿领料单（alpha=B 保留草稿） */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public String release(String id) {
        if (!StringUtils.hasText(id)) throw new JeecgBootException("订单ID不能为空");
        MesProductionOrder e = baseMapper.selectById(id);
        if (e == null) throw new JeecgBootException("订单不存在");
        if (!"2".equals(e.getStatus())) throw new JeecgBootException("只有已审核订单可下达");
        if (!StringUtils.hasText(e.getBomId())) throw new JeecgBootException("订单未关联BOM");
        MesBom bom = bomService.getById(e.getBomId());
        if (bom == null || !"2".equals(bom.getStatus())) throw new JeecgBootException("BOM未生效");
        if (!StringUtils.hasText(e.getWarehouseId())) throw new JeecgBootException("订单未关联仓库");

        // 1) 查 BOM 子件
        List<MesBomItem> items = bomItemMapper.selectByMainId(bom.getId());
        if (items == null || items.isEmpty()) throw new JeecgBootException("BOM未配置子件，无法下达");

        // 2) 库存校验（C 硬阻止）：need = 子件用量 × planQty
        StringBuilder lack = new StringBuilder();
        for (MesBomItem item : items) {
            BigDecimal need = item.getQuantity().multiply(e.getPlanQty());
            BigDecimal avail = materialMapper.selectStockQtyByWarehouse(item.getMaterialId(), e.getWarehouseId());
            if (avail == null) avail = BigDecimal.ZERO;
            if (avail.compareTo(need) < 0) {
                if (lack.length() > 0) lack.append("；");
                lack.append("物料[").append(item.getMaterialId()).append("]需要").append(need)
                    .append("，可用").append(avail);
            }
        }
        if (lack.length() > 0) throw new JeecgBootException("库存不足：" + lack);

        // 3) 生成草稿领料单（alpha=B 保留草稿，不自动 audit）
        String username = getCurrentUsername();
        Date now = new Date();
        MesProductionPicking picking = new MesProductionPicking();
        picking.setCode(codeRuleService.nextCode("PP"));
        picking.setProductionOrderId(e.getId());
        picking.setWarehouseId(e.getWarehouseId());
        picking.setStatus("1");
        picking.setPickingDate(now);
        picking.setCreateBy(username);
        picking.setCreateTime(now);
        picking.setUpdateBy(username);
        picking.setUpdateTime(now);
        List<MesProductionPickingItem> pickingItems = items.stream().map(item -> {
            MesProductionPickingItem pi = new MesProductionPickingItem();
            pi.setMaterialId(item.getMaterialId());
            pi.setQuantity(item.getQuantity().multiply(e.getPlanQty()));
            pi.setLineNo(item.getLineNo());
            return pi;
        }).collect(Collectors.toList());
        picking.setItems(pickingItems);
        pickingService.saveWithItems(picking);

        // 4) 订单 status='3'（决策 G：本期不推 4，订单卡 3 等完工联动）
        e.setStatus("3");
        e.setUpdateBy(username);
        e.setUpdateTime(now);
        super.updateById(e);
        return picking.getId();
    }

    /** 完工：已下达→已完工，要求 completedQty≥planQty（决策 F 允许超量报工） */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void complete(String id) {
        if (!StringUtils.hasText(id)) throw new JeecgBootException("订单ID不能为空");
        MesProductionOrder e = baseMapper.selectById(id);
        if (e == null) throw new JeecgBootException("订单不存在");
        // 决策 G：本期不推 status='4'（执行中），订单卡 3 等完工联动 → 完工守卫不要求 4
        if (!"3".equals(e.getStatus())) throw new JeecgBootException("只有已下达订单可完工");
        BigDecimal completed = e.getCompletedQty() == null ? BigDecimal.ZERO : e.getCompletedQty();
        if (completed.compareTo(e.getPlanQty()) < 0)
            throw new JeecgBootException("已完工数量[" + completed + "]未达计划数量[" + e.getPlanQty() + "]，无法完工");
        e.setStatus("5");
        e.setUpdateBy(getCurrentUsername());
        e.setUpdateTime(new Date());
        super.updateById(e);
    }

    /** 关闭：任意非终态→已关闭（5/6/7 终态抛错） */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void close(String id) {
        if (!StringUtils.hasText(id)) throw new JeecgBootException("订单ID不能为空");
        MesProductionOrder e = baseMapper.selectById(id);
        if (e == null) throw new JeecgBootException("订单不存在");
        String status = e.getStatus();
        if ("5".equals(status) || "6".equals(status) || "7".equals(status))
            throw new JeecgBootException("订单已是终态（已完工/已关闭/已取消），不能再关闭");
        e.setStatus("6");
        e.setUpdateBy(getCurrentUsername());
        e.setUpdateTime(new Date());
        super.updateById(e);
    }

    /** 取消：仅草稿/已审核可取消（1/2），其余抛错 */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancel(String id) {
        if (!StringUtils.hasText(id)) throw new JeecgBootException("订单ID不能为空");
        MesProductionOrder e = baseMapper.selectById(id);
        if (e == null) throw new JeecgBootException("订单不存在");
        String status = e.getStatus();
        if (!"1".equals(status) && !"2".equals(status))
            throw new JeecgBootException("只有草稿/已审核订单可取消");
        e.setStatus("7");
        e.setUpdateBy(getCurrentUsername());
        e.setUpdateTime(new Date());
        super.updateById(e);
    }

    /** 手动生成草稿领料单（订单已下达后补领场景；alpha=B 保留草稿） */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public String generatePicking(String orderId) {
        if (!StringUtils.hasText(orderId)) throw new JeecgBootException("订单ID不能为空");
        MesProductionOrder e = baseMapper.selectById(orderId);
        if (e == null) throw new JeecgBootException("订单不存在");
        if (!"3".equals(e.getStatus())) throw new JeecgBootException("只有已下达订单可生成草稿领料单");
        if (!StringUtils.hasText(e.getBomId())) throw new JeecgBootException("订单未关联BOM");
        MesBom bom = bomService.getById(e.getBomId());
        if (bom == null) throw new JeecgBootException("关联BOM不存在");

        List<MesBomItem> items = bomItemMapper.selectByMainId(bom.getId());
        if (items == null || items.isEmpty()) throw new JeecgBootException("BOM未配置子件");

        String username = getCurrentUsername();
        Date now = new Date();
        MesProductionPicking picking = new MesProductionPicking();
        picking.setCode(codeRuleService.nextCode("PP"));
        picking.setProductionOrderId(e.getId());
        picking.setWarehouseId(e.getWarehouseId());
        picking.setStatus("1");
        picking.setPickingDate(now);
        picking.setCreateBy(username);
        picking.setCreateTime(now);
        picking.setUpdateBy(username);
        picking.setUpdateTime(now);
        List<MesProductionPickingItem> pickingItems = items.stream().map(item -> {
            MesProductionPickingItem pi = new MesProductionPickingItem();
            pi.setMaterialId(item.getMaterialId());
            pi.setQuantity(item.getQuantity().multiply(e.getPlanQty()));
            pi.setLineNo(item.getLineNo());
            return pi;
        }).collect(Collectors.toList());
        picking.setItems(pickingItems);
        pickingService.saveWithItems(picking);
        return picking.getId();
    }
    //update-end---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 5 端点 + generatePicking-----------

    private void validate(MesProductionOrder entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("订单编号不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("订单编号长度不能超过50个字符");
        if (!StringUtils.hasText(entity.getProductId())) throw new JeecgBootException("生产产品不能为空");
        if (entity.getPlanQty() == null || entity.getPlanQty().compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("计划数量必须大于0");
        if (entity.getEndDate() != null && entity.getStartDate() != null && entity.getEndDate().before(entity.getStartDate()))
            throw new JeecgBootException("完工日期不能早于开工日期");
        if (entity.getRemark() != null && entity.getRemark().length() > 500) throw new JeecgBootException("备注长度不能超过500个字符");
    }

    private void checkStatus(MesProductionOrder entity, String action) {
        if (entity.getId() == null) return;
        MesProductionOrder exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private void checkStatus(String id, String action) {
        MesProductionOrder exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("当前状态不允许" + action + "，仅草稿状态可操作");
    }

    private String getCurrentUsername() {
        try { return ((LoginUser) SecurityUtils.getSubject().getPrincipal()).getUsername(); } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Service实现-----------