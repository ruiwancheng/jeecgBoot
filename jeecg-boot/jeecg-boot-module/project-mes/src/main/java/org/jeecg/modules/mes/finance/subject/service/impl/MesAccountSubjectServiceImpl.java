//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目Service实现-----------
package org.jeecg.modules.mes.finance.subject.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.finance.subject.entity.MesAccountSubject;
import org.jeecg.modules.mes.finance.subject.mapper.MesAccountSubjectMapper;
import org.jeecg.modules.mes.finance.subject.service.IMesAccountSubjectService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class MesAccountSubjectServiceImpl extends ServiceImpl<MesAccountSubjectMapper, MesAccountSubject> implements IMesAccountSubjectService {

    @Override
    public List<MesAccountSubject> queryTree() {
        List<MesAccountSubject> all = list();
        Map<String, List<MesAccountSubject>> byParent = all.stream().collect(Collectors.groupingBy(s -> s.getParentId() == null ? "" : s.getParentId()));
        List<MesAccountSubject> roots = byParent.getOrDefault("", Collections.emptyList());
        for (MesAccountSubject root : roots) buildTree(root, byParent);
        return roots;
    }

    private void buildTree(MesAccountSubject parent, Map<String, List<MesAccountSubject>> byParent) {
        List<MesAccountSubject> children = byParent.get(parent.getId());
        if (children != null) { parent.setChildren(children); for (MesAccountSubject c : children) buildTree(c, byParent); }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean save(MesAccountSubject entity) {
        validate(entity);
        checkCodeDuplicate(entity.getCode(), null);
        // 更新父节点为非叶子
        if (StringUtils.hasText(entity.getParentId())) {
            MesAccountSubject parent = baseMapper.selectById(entity.getParentId());
            if (parent != null && parent.getIsLeaf() == 1) {
                parent.setIsLeaf(0); super.updateById(parent);
            }
        }
        entity.setIsLeaf(1);
        if (entity.getLevel() == null) entity.setLevel(1);
        MesAccountSubject old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId()); entity.setCreateBy(old.getCreateBy()); entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getUsername()); entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
            return true;
        }
        try { return super.save(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("科目编码已存在"); }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateById(MesAccountSubject entity) {
        validate(entity);
        checkCodeDuplicate(entity.getCode(), entity.getId());
        try { return super.updateById(entity); } catch (DuplicateKeyException e) { throw new JeecgBootException("科目编码已存在"); }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeById(java.io.Serializable id) {
        // 检查是否有子科目
        LambdaQueryWrapper<MesAccountSubject> qw = new LambdaQueryWrapper<>();
        qw.eq(MesAccountSubject::getParentId, id);
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("该科目下存在子科目，无法删除");
        return super.removeById(id);
    }

    private void validate(MesAccountSubject entity) {
        if (!StringUtils.hasText(entity.getCode())) throw new JeecgBootException("科目编码不能为空");
        if (entity.getCode().length() > 50) throw new JeecgBootException("科目编码不超过50字符");
        if (!StringUtils.hasText(entity.getName())) throw new JeecgBootException("科目名称不能为空");
        if (!StringUtils.hasText(entity.getCategory())) throw new JeecgBootException("科目类别不能为空");
    }

    private void checkCodeDuplicate(String code, String excludeId) {
        QueryWrapper<MesAccountSubject> qw = new QueryWrapper<>();
        qw.eq("code", code);
        if (excludeId != null) qw.ne("id", excludeId);
        if (baseMapper.selectCount(qw) > 0) throw new JeecgBootException("科目编码已存在");
    }

    private String getUsername() {
        try { LoginUser u = (LoginUser) SecurityUtils.getSubject().getPrincipal(); return u != null ? u.getUsername() : "system"; } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目Service实现-----------
