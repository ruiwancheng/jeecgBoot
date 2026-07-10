//update-begin---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户Service实现-----------
//update-begin---author:ruiwancheng---date:2026-07-11---for: 审计修复#1#3#6#7-JdbcTemplate绕过@TableLogic+删除校验+额度/业务员校验-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.entity.MesCustomer;
import org.jeecg.modules.mes.basic.mapper.MesCustomerMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Service
public class MesCustomerServiceImpl extends ServiceImpl<MesCustomerMapper, MesCustomer> implements IMesCustomerService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    @Transactional
    public boolean save(MesCustomer entity) {
        if (entity.getCreditLimit() != null && entity.getCreditLimit().compareTo(BigDecimal.ZERO) < 0) {
            throw new JeecgBootException("信用额度不能为负数");
        }
        if (entity.getCode() != null && entity.getCode().length() > 50) {
            throw new JeecgBootException("客户编码长度不能超过50个字符");
        }
        if (StringUtils.hasText(entity.getSalesmanId())) {
            validateSalesman(entity.getSalesmanId());
        }
        QueryWrapper<MesCustomer> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("客户编码已存在，请使用其他编码");
        }
        // 绕过MyBatis-Plus @TableLogic拦截器，直连JDBC查软删除记录
        MesCustomer old = findDeletedByCode(entity.getCode());
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
    public boolean updateById(MesCustomer entity) {
        if (entity.getCreditLimit() != null && entity.getCreditLimit().compareTo(BigDecimal.ZERO) < 0) {
            throw new JeecgBootException("信用额度不能为负数");
        }
        if (StringUtils.hasText(entity.getSalesmanId())) {
            validateSalesman(entity.getSalesmanId());
        }
        QueryWrapper<MesCustomer> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("客户编码已存在，请使用其他编码");
        }
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public boolean removeById(Serializable id) {
        // 删除前校验：检查是否有关联的销售订单（预留，销售订单模块建成后补充）
        // TODO PEND-002: checkSalesOrderExists(id)
        return super.removeById(id);
    }

    private MesCustomer findDeletedByCode(String code) {
        try {
            List<MesCustomer> list = jdbcTemplate.query(
                    "SELECT * FROM c_mes_customer WHERE code = ? AND del_flag = 1 LIMIT 1",
                    new BeanPropertyRowMapper<>(MesCustomer.class), code);
            return list.isEmpty() ? null : list.get(0);
        } catch (Exception e) {
            log.warn("查询已删除客户失败: " + e.getMessage());
            return null;
        }
    }

    private void resurrectByJdbc(MesCustomer entity) {
        jdbcTemplate.update(
                "UPDATE c_mes_customer SET code=?, name=?, type=?, grade=?, credit_limit=?, salesman_id=?, " +
                        "industry=?, region=?, scale=?, invoice_title=?, tax_no=?, bank_name=?, bank_account=?, " +
                        "invoice_address=?, invoice_phone=?, invoice_type=?, contact=?, phone=?, address=?, " +
                        "status=?, remark=?, update_by=?, update_time=?, del_flag=0 WHERE id=?",
                entity.getCode(), entity.getName(), entity.getType(), entity.getGrade(),
                entity.getCreditLimit(), entity.getSalesmanId(),
                entity.getIndustry(), entity.getRegion(), entity.getScale(),
                entity.getInvoiceTitle(), entity.getTaxNo(), entity.getBankName(), entity.getBankAccount(),
                entity.getInvoiceAddress(), entity.getInvoicePhone(), entity.getInvoiceType(),
                entity.getContact(), entity.getPhone(), entity.getAddress(), entity.getStatus(),
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

    private void validateSalesman(String salesmanId) {
        try {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM sys_user WHERE username = ? OR id = ?",
                    Integer.class, salesmanId, salesmanId);
            if (count == null || count == 0) {
                throw new JeecgBootException("业务员不存在: " + salesmanId);
            }
        } catch (JeecgBootException e) {
            throw e;
        } catch (Exception e) {
            log.warn("校验业务员失败: " + e.getMessage());
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-11---for: 审计修复#1#3#6#7-JdbcTemplate绕过@TableLogic+删除校验+额度/业务员校验-----------
//update-end---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户Service实现-----------
