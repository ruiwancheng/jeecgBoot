//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证Service实现-----------
package org.jeecg.modules.mes.finance.voucher.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.finance.voucher.entity.MesVoucher;
import org.jeecg.modules.mes.finance.voucher.entity.MesVoucherItem;
import org.jeecg.modules.mes.finance.voucher.mapper.MesVoucherItemMapper;
import org.jeecg.modules.mes.finance.voucher.mapper.MesVoucherMapper;
import org.jeecg.modules.mes.finance.voucher.service.IMesVoucherService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Service
public class MesVoucherServiceImpl extends ServiceImpl<MesVoucherMapper, MesVoucher> implements IMesVoucherService {

    @Autowired private MesVoucherItemMapper itemMapper;

    @Override public MesVoucher queryWithItems(String id) {
        MesVoucher v = baseMapper.selectById(id);
        if (v != null) { LambdaQueryWrapper<MesVoucherItem> qw = new LambdaQueryWrapper<>(); qw.eq(MesVoucherItem::getVoucherId, id).orderByAsc(MesVoucherItem::getLineNo); v.setItems(itemMapper.selectList(qw)); }
        return v;
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void saveWithItems(MesVoucher entity) {
        validate(entity); entity.setStatus("1");
        calcTotal(entity);
        QueryWrapper<MesVoucher> qw = new QueryWrapper<>(); qw.eq("voucher_no", entity.getVoucherNo());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("凭证号已存在");
        super.save(entity); saveItems(entity);
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void updateWithItems(MesVoucher entity) {
        if (entity.getId() == null) throw new JeecgBootException("凭证ID不能为空");
        MesVoucher exist = baseMapper.selectById(entity.getId());
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态禁止编辑");
        validate(entity); entity.setStatus("1");
        calcTotal(entity);
        QueryWrapper<MesVoucher> qw = new QueryWrapper<>(); qw.eq("voucher_no", entity.getVoucherNo()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("凭证号已存在");
        super.updateById(entity);
        LambdaQueryWrapper<MesVoucherItem> delQw = new LambdaQueryWrapper<>(); delQw.eq(MesVoucherItem::getVoucherId, entity.getId()); itemMapper.delete(delQw);
        saveItems(entity);
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void removeWithItems(String id) {
        MesVoucher exist = baseMapper.selectById(id);
        if (exist != null && !"1".equals(exist.getStatus())) throw new JeecgBootException("非草稿状态禁止删除");
        LambdaQueryWrapper<MesVoucherItem> delQw = new LambdaQueryWrapper<>(); delQw.eq(MesVoucherItem::getVoucherId, id); itemMapper.delete(delQw);
        super.removeById(id);
    }

    @Override @Transactional(rollbackFor = Exception.class)
    public void audit(String id) {
        MesVoucher e = queryWithItems(id);
        if (e == null) throw new JeecgBootException("凭证不存在");
        if (!"1".equals(e.getStatus())) throw new JeecgBootException("只有草稿可审核");
        // 审核前再次校验借贷平衡
        BigDecimal dr = BigDecimal.ZERO, cr = BigDecimal.ZERO;
        for (MesVoucherItem item : e.getItems()) {
            if (item.getDebitAmount() != null) dr = dr.add(item.getDebitAmount());
            if (item.getCreditAmount() != null) cr = cr.add(item.getCreditAmount());
        }
        if (dr.compareTo(cr) != 0) throw new JeecgBootException("借贷不平衡，借方" + dr + " ≠ 贷方" + cr);
        String username = getUsername(); Date now = new Date();
        int rows = baseMapper.auditWithGuard(id, username, now);
        if (rows == 0) throw new JeecgBootException("审核失败：凭证不存在或状态已变更");
    }

    private void validate(MesVoucher entity) {
        if (!StringUtils.hasText(entity.getVoucherNo())) throw new JeecgBootException("凭证号不能为空");
        if (entity.getVoucherDate() == null) throw new JeecgBootException("凭证日期不能为空");
        List<MesVoucherItem> items = entity.getItems();
        if (items == null || items.isEmpty()) throw new JeecgBootException("至少需要一行为明细");
        BigDecimal dr = BigDecimal.ZERO, cr = BigDecimal.ZERO;
        for (int i = 0; i < items.size(); i++) {
            MesVoucherItem item = items.get(i);
            if (!StringUtils.hasText(item.getSubjectId())) throw new JeecgBootException("第" + (i+1) + "行科目不能为空");
            if (item.getDebitAmount() == null) item.setDebitAmount(BigDecimal.ZERO);
            if (item.getCreditAmount() == null) item.setCreditAmount(BigDecimal.ZERO);
            if (item.getDebitAmount().compareTo(BigDecimal.ZERO) == 0 && item.getCreditAmount().compareTo(BigDecimal.ZERO) == 0)
                throw new JeecgBootException("第" + (i+1) + "行借贷金额不能同时为0");
            dr = dr.add(item.getDebitAmount()); cr = cr.add(item.getCreditAmount());
            item.setLineNo(i + 1); item.setVoucherId(entity.getId());
        }
        if (dr.compareTo(cr) != 0) throw new JeecgBootException("借贷不平衡：借方合计" + dr + "，贷方合计" + cr);
    }

    private void calcTotal(MesVoucher entity) {
        BigDecimal dr = BigDecimal.ZERO, cr = BigDecimal.ZERO;
        for (MesVoucherItem item : entity.getItems()) {
            if (item.getDebitAmount() != null) dr = dr.add(item.getDebitAmount());
            if (item.getCreditAmount() != null) cr = cr.add(item.getCreditAmount());
        }
        entity.setTotalDebit(dr); entity.setTotalCredit(cr);
    }

    private void saveItems(MesVoucher entity) { for (MesVoucherItem item : entity.getItems()) { item.setVoucherId(entity.getId()); itemMapper.insert(item); } }
    private String getUsername() { try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception e) { return "system"; } }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证Service实现-----------
