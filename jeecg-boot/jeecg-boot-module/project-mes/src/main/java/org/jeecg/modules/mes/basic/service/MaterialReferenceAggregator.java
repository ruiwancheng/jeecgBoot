//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】阶段 4 性能优化：MaterialReferenceAggregator UNION ALL 聚合（避免 v2 JdbcTemplate 参数绑定 bug）-----------
package org.jeecg.modules.mes.basic.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * 物料引用计数聚合器（UNION ALL 单次 round-trip）。
 * <p>
 * CRITICAL bug 修复：v2 用 JdbcTemplate.queryForList(sql, materialId) 配合 19 个 ? 占位符，
 * 仅绑定 1 个参数 → "Parameter count mismatch" 运行时崩溃。本实现改用 NamedParameterJdbcTemplate + :materialId 同名复用 19 次。
 */
@Component
public class MaterialReferenceAggregator {
    @Autowired private NamedParameterJdbcTemplate jdbc;

    /** 聚合 19 张表的引用计数（含 status 过滤的 11 张业务单据）。调用方传 openStatuses（未完结状态集）。 */
    public Map<String, Long> aggregate(String materialId, Set<String> openStatuses) {
        String sql = buildUnionSql();
        Map<String, Object> params = new HashMap<>();
        params.put("materialId", materialId);
        params.put("openStatuses", openStatuses);
        List<Map<String, Object>> rows = jdbc.queryForList(sql, params);
        return rows.stream().collect(Collectors.toMap(
            r -> (String) r.get("tbl"),
            r -> ((Number) r.get("cnt")).longValue(),
            (a, b) -> a,
            LinkedHashMap::new));
    }

    private String buildUnionSql() {
        // 8 张直接表 + 11 张 JOIN 父单 + status IN(:openStatuses)
        return Stream.of(
            // 8 张直接表
            "SELECT 'c_mes_inventory' AS tbl, COUNT(*) AS cnt FROM c_mes_inventory WHERE material_id = :materialId",
            "SELECT 'c_mes_inventory_ledger' AS tbl, COUNT(*) AS cnt FROM c_mes_inventory_ledger WHERE material_id = :materialId",
            "SELECT 'c_mes_batch' AS tbl, COUNT(*) AS cnt FROM c_mes_batch WHERE material_id = :materialId AND del_flag = 0",
            "SELECT 'c_mes_batch_inventory' AS tbl, COUNT(*) AS cnt FROM c_mes_batch_inventory WHERE material_id = :materialId",
            "SELECT 'c_mes_batch_ledger' AS tbl, COUNT(*) AS cnt FROM c_mes_batch_ledger WHERE material_id = :materialId",
            "SELECT 'c_mes_bom_item' AS tbl, COUNT(*) AS cnt FROM c_mes_bom_item WHERE material_id = :materialId",
            "SELECT 'c_mes_cost_log' AS tbl, COUNT(*) AS cnt FROM c_mes_cost_log WHERE material_id = :materialId",
            "SELECT 'c_mes_price' AS tbl, COUNT(*) AS cnt FROM c_mes_price WHERE material_id = :materialId AND del_flag = 0",
            // 11 张 JOIN 父单 + status IN(:openStatuses)
            "SELECT 'c_mes_completion_receipt_item' AS tbl, COUNT(*) AS cnt FROM c_mes_completion_receipt_item i JOIN c_mes_completion_receipt p ON i.receipt_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_delivery_note_item' AS tbl, COUNT(*) AS cnt FROM c_mes_delivery_note_item i JOIN c_mes_delivery_note p ON i.delivery_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_other_stock_in_item' AS tbl, COUNT(*) AS cnt FROM c_mes_other_stock_in_item i JOIN c_mes_other_stock_in p ON i.in_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_other_stock_out_item' AS tbl, COUNT(*) AS cnt FROM c_mes_other_stock_out_item i JOIN c_mes_other_stock_out p ON i.out_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_production_picking_item' AS tbl, COUNT(*) AS cnt FROM c_mes_production_picking_item i JOIN c_mes_production_picking p ON i.picking_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_purchase_apply_item' AS tbl, COUNT(*) AS cnt FROM c_mes_purchase_apply_item i JOIN c_mes_purchase_apply p ON i.apply_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_purchase_order_item' AS tbl, COUNT(*) AS cnt FROM c_mes_purchase_order_item i JOIN c_mes_purchase_order p ON i.order_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_purchase_receipt_item' AS tbl, COUNT(*) AS cnt FROM c_mes_purchase_receipt_item i JOIN c_mes_purchase_receipt p ON i.receipt_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_sales_order_item' AS tbl, COUNT(*) AS cnt FROM c_mes_sales_order_item i JOIN c_mes_sales_order p ON i.order_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_sales_outbound_item' AS tbl, COUNT(*) AS cnt FROM c_mes_sales_outbound_item i JOIN c_mes_sales_outbound p ON i.outbound_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)",
            "SELECT 'c_mes_stocktake_item' AS tbl, COUNT(*) AS cnt FROM c_mes_stocktake_item i JOIN c_mes_stocktake p ON i.take_id = p.id WHERE i.material_id = :materialId AND p.status IN (:openStatuses)"
        ).collect(Collectors.joining(" UNION ALL "));
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】MaterialReferenceAggregator-----------
