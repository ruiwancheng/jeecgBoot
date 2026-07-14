//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.entity.MesSupplier;
import org.jeecg.modules.mes.basic.mapper.MesSupplierMapper;
import org.jeecg.modules.mes.basic.service.IMesSupplierService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.Serializable;
import java.util.Date;
import java.util.List;

@Service
public class MesSupplierServiceImpl extends ServiceImpl<MesSupplierMapper, MesSupplier> implements IMesSupplierService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    @Transactional
    public boolean save(MesSupplier entity) {
        if (entity.getCode() != null && entity.getCode().length() > 50) {
            throw new JeecgBootException("供应商编码长度不能超过50个字符");
        }
        QueryWrapper<MesSupplier> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("供应商编码已存在，请使用其他编码");
        }
        MesSupplier old = findDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            resurrectByJdbc(entity);
            return true;
        }
        return super.save(entity);
    }

    @Override
    @Transactional
    public boolean updateById(MesSupplier entity) {
        QueryWrapper<MesSupplier> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("供应商编码已存在，请使用其他编码");
        }
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public boolean removeById(Serializable id) {
        return super.removeById(id);
    }

    private MesSupplier findDeletedByCode(String code) {
        try {
            List<MesSupplier> list = jdbcTemplate.query(
                    "SELECT * FROM c_mes_supplier WHERE code = ? AND del_flag = 1 LIMIT 1",
                    new BeanPropertyRowMapper<>(MesSupplier.class), code);
            return list.isEmpty() ? null : list.get(0);
        } catch (Exception e) {
            log.warn("查询已删除供应商失败: " + e.getMessage());
            return null;
        }
    }

    private void resurrectByJdbc(MesSupplier entity) {
        jdbcTemplate.update(
                "UPDATE c_mes_supplier SET code=?, name=?, type=?, status=?, grade=?, blacklist_flag=?, " +
                        "contact=?, phone=?, address=?, invoice_title=?, tax_no=?, bank_name=?, bank_account=?, " +
                        "remark=?, update_by=?, update_time=?, del_flag=0 WHERE id=?",
                entity.getCode(), entity.getName(), entity.getType(), entity.getStatus(), entity.getGrade(),
                entity.getBlacklistFlag(),
                entity.getContact(), entity.getPhone(), entity.getAddress(), entity.getInvoiceTitle(),
                entity.getTaxNo(), entity.getBankName(), entity.getBankAccount(),
                entity.getRemark(), entity.getUpdateBy(), entity.getUpdateTime(), entity.getId());
    }

    private String getCurrentUsername() {
        try {
            LoginUser user = (LoginUser) SecurityUtils.getSubject().getPrincipal();
            return user != null ? user.getUsername() : "system";
        } catch (Exception e) {
            return "system";
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Service实现-----------
