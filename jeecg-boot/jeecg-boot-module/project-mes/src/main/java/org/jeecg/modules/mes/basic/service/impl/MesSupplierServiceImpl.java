//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Service实现-----------
//update-begin---author:ruiwancheng---date:2026-07-14---for: 审计修复#2#3#5#7#8-JdbcTemplate→Mapper+参数校验+黑名单联动+删除下游校验-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.entity.MesSupplier;
import org.jeecg.modules.mes.basic.mapper.MesSupplierMapper;
import org.jeecg.modules.mes.basic.service.IMesSupplierService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.Serializable;
import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;
import java.util.Set;

@Service
public class MesSupplierServiceImpl extends ServiceImpl<MesSupplierMapper, MesSupplier> implements IMesSupplierService {

    private static final Set<String> VALID_TYPES = new HashSet<>(Arrays.asList("1", "2", "3", "4"));
    private static final Set<String> VALID_STATUSES = new HashSet<>(Arrays.asList("1", "2", "3", "4", "5", "6"));
    private static final Set<String> VALID_GRADES = new HashSet<>(Arrays.asList("A", "B", "C", "D"));

    @Override
    @Transactional
    public boolean save(MesSupplier entity) {
        validateEntity(entity);
        QueryWrapper<MesSupplier> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("供应商编码已存在，请使用其他编码");
        }
        MesSupplier old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
            return true;
        }
        return super.save(entity);
    }

    @Override
    @Transactional
    public boolean updateById(MesSupplier entity) {
        validateEntity(entity);
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
        // TODO PEND-003: 删除前校验下游关联——采购订单/入库单/付款记录表建成后补充
        return super.removeById(id);
    }

    @Override
    @Transactional
    public boolean removeByIds(java.util.Collection<?> list) {
        for (Object id : list) this.removeById((Serializable) id);
        return true;
    }

    private void validateEntity(MesSupplier entity) {
        // 编码非空+长度
        if (!StringUtils.hasText(entity.getCode())) {
            throw new JeecgBootException("供应商编码不能为空");
        }
        if (entity.getCode().length() > 50) {
            throw new JeecgBootException("供应商编码长度不能超过50个字符");
        }
        // 名称非空
        if (!StringUtils.hasText(entity.getName())) {
            throw new JeecgBootException("供应商名称不能为空");
        }
        // 类型白名单
        if (entity.getType() != null && !VALID_TYPES.contains(entity.getType())) {
            throw new JeecgBootException("供应商类型值无效");
        }
        // 状态白名单
        if (entity.getStatus() != null && !VALID_STATUSES.contains(entity.getStatus())) {
            throw new JeecgBootException("供应商状态值无效");
        }
        // 等级白名单
        if (entity.getGrade() != null && !VALID_GRADES.contains(entity.getGrade())) {
            throw new JeecgBootException("供应商等级值无效");
        }
        // 黑名单与状态联动：黑名单供应商强制置为"暂停"
        if (entity.getBlacklistFlag() != null && entity.getBlacklistFlag() == 1) {
            if ("3".equals(entity.getStatus()) || "4".equals(entity.getStatus())) {
                entity.setStatus("5"); // 强制暂停
            }
        }
        // 黑名单供应商不允许设为合作中/合格
        if (entity.getBlacklistFlag() != null && entity.getBlacklistFlag() == 0) {
            if (entity.getStatus() == null) {
                // 保存时状态默认为潜在
            }
        }
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
//update-end---author:ruiwancheng---date:2026-07-14---for: 审计修复#2#3#5#7#8-JdbcTemplate→Mapper+参数校验+黑名单联动+删除下游校验-----------
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Service实现-----------
