//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】阶段 4 启动自检：MaterialReferenceCoverageAssertor（fail-fast 校验 19 张表覆盖）-----------
package org.jeecg.modules.mes.basic.service;

import com.google.common.collect.Sets;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 启动自检：对比 information_schema 中含 material_id 列的实际表与 19 个 checker 描述的表，
 * 双向差集（schema 中存在但 checker 缺 / checker 描述但 schema 中不存在）发现即启动失败。
 */
@Slf4j
@Component
public class MaterialReferenceCoverageAssertor implements ApplicationRunner {

    @Autowired private DataSource ds;
    @Autowired private List<MaterialReferenceChecker> checkers;

    @Override
    public void run(ApplicationArguments args) {
        Set<String> actualTables = queryActualTables();
        Set<String> checkerTables = checkers.stream()
            .map(c -> c.describe().split("\\.")[0])  // 去掉 schema 前缀
            .collect(Collectors.toSet());

        Set<String> missing = Sets.difference(actualTables, checkerTables);
        Set<String> extra = Sets.difference(checkerTables, actualTables);

        if (!missing.isEmpty() || !extra.isEmpty()) {
            StringBuilder msg = new StringBuilder("【守卫覆盖校验】失败：\n");
            if (!missing.isEmpty()) {
                msg.append("  schema 中含 material_id 但未实现 checker：").append(missing).append("\n");
            }
            if (!extra.isEmpty()) {
                msg.append("  checker 描述但 schema 中无对应表：").append(extra).append("\n");
            }
            msg.append("请补齐 MaterialReferenceChecker 实现，确保守卫覆盖完整。");
            throw new IllegalStateException(msg.toString());
        }

        log.info("【守卫覆盖校验】通过：schema 与 19 个 checker 描述完全对齐（{} 张表）",
            actualTables.size());
    }

    private Set<String> queryActualTables() {
        Set<String> tables = new HashSet<>();
        String sql = "SELECT table_name FROM information_schema.columns "
                   + "WHERE column_name = 'material_id' AND table_schema = DATABASE()";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                tables.add(rs.getString(1));
            }
        } catch (SQLException e) {
            throw new RuntimeException("启动自检：information_schema 查询失败", e);
        }
        return tables;
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】启动自检 CoverageAssertor-----------
