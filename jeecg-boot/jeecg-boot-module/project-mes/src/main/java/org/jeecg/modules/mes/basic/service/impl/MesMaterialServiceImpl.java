//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.entity.MesMaterial;
import org.jeecg.modules.mes.basic.mapper.MesMaterialMapper;
import org.jeecg.modules.mes.basic.service.IMesMaterialService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.Serializable;
import java.util.*;

@Service
public class MesMaterialServiceImpl extends ServiceImpl<MesMaterialMapper, MesMaterial> implements IMesMaterialService {

    private static final Set<String> VALID_TYPES = new HashSet<>(Arrays.asList("1", "2", "3", "4"));
    private static final Set<String> VALID_UNITS = new HashSet<>(Arrays.asList("1", "2", "3", "4", "5", "6", "7", "8"));

    @Override
    @Transactional
    public boolean save(MesMaterial entity) {
        validateEntity(entity);
        QueryWrapper<MesMaterial> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("物料编码已存在，请使用其他编码");
        }
        MesMaterial old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
            return true;
        }
        try {
            return super.save(entity);
        } catch (DuplicateKeyException e) {
            throw new JeecgBootException("物料编码已存在，请使用其他编码");
        }
    }

    @Override
    @Transactional
    public boolean updateById(MesMaterial entity) {
        validateEntity(entity);
        QueryWrapper<MesMaterial> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("物料编码已存在，请使用其他编码");
        }
        try {
            return super.updateById(entity);
        } catch (DuplicateKeyException e) {
            throw new JeecgBootException("物料编码已存在，请使用其他编码");
        }
    }

    @Override
    @Transactional
    public boolean removeById(Serializable id) {
        return super.removeById(id);
    }

    @Override
    @Transactional
    public boolean removeByIds(Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        return super.removeByIds(list);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void importFromExcel(List<MesMaterial> list) {
        for (MesMaterial entity : list) {
            save(entity);
        }
    }

    private void validateEntity(MesMaterial entity) {
        if (!StringUtils.hasText(entity.getCode())) {
            throw new JeecgBootException("物料编码不能为空");
        }
        if (entity.getCode().length() > 50) {
            throw new JeecgBootException("物料编码长度不能超过50个字符");
        }
        if (!StringUtils.hasText(entity.getName())) {
            throw new JeecgBootException("物料名称不能为空");
        }
        if (entity.getName().length() > 100) {
            throw new JeecgBootException("物料名称长度不能超过100个字符");
        }
        if (entity.getType() != null && !VALID_TYPES.contains(entity.getType())) {
            throw new JeecgBootException("物料类型值无效");
        }
        if (entity.getUnit() != null && !VALID_UNITS.contains(entity.getUnit())) {
            throw new JeecgBootException("物料单位值无效");
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
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Service实现-----------
