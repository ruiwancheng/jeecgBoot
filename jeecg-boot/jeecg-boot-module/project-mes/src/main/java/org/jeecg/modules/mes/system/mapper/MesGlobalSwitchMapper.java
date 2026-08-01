//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Mapper（注解式）-----------
package org.jeecg.modules.mes.system.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.jeecg.modules.mes.system.entity.MesGlobalSwitch;

public interface MesGlobalSwitchMapper extends BaseMapper<MesGlobalSwitch> {

    /**
     * L1 检查：批次库存表有余额的记录数
     */
    @Select("SELECT COUNT(*) FROM c_mes_batch_inventory WHERE qty > 0")
    Long countBatchInventoryWithQty();

    /**
     * L3 检查：关联了未完结业务单据的批次记录数（通过 origin_bill_id 反向查）
     * 关联的 4 个业务表：完工入库/领料/采购入库/销售出库
     * 完结状态：完工入库=2(已入库) / 领料=2(已审核) / 采购入库=2(已入库) / 销售出库=3(已审核)
     * 任一业务表存在"非完结"状态的单据且被批次引用 → 阻塞
     */
    @Select("SELECT COUNT(*) FROM c_mes_batch b " +
            "WHERE (b.origin_type = '2' AND EXISTS (SELECT 1 FROM c_mes_completion_receipt r WHERE r.id = b.origin_bill_id AND r.status != '2')) " +
            "   OR (b.origin_type = '3' AND EXISTS (SELECT 1 FROM c_mes_production_picking p WHERE p.id = b.origin_bill_id AND p.status != '2')) " +
            "   OR (b.origin_type = '1' AND EXISTS (SELECT 1 FROM c_mes_purchase_receipt pr WHERE pr.id = b.origin_bill_id AND pr.status != '2')) " +
            "   OR (b.origin_type = '4' AND EXISTS (SELECT 1 FROM c_mes_sales_outbound so WHERE so.id = b.origin_bill_id AND so.status != '3'))")
    Long countOpenBatchRelatedDocs();

    /**
     * 关闭总开关时原子操作：批量将所有物料的 batch_enabled 置 0
     * 解决并发场景下用户勾选物料 vs 关闭总开关的竞态
     */
    @Update("UPDATE c_mes_material SET batch_enabled = 0 WHERE batch_enabled = 1")
    int turnOffAllBatchEnabled();
}
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Mapper（注解式）-----------