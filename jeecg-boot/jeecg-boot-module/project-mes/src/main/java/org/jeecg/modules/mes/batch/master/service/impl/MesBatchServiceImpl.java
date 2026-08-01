//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档ServiceImpl-----------
package org.jeecg.modules.mes.batch.master.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.jeecg.modules.mes.batch.ledger.service.IMesBatchLedgerService;
import org.jeecg.modules.mes.batch.master.entity.MesBatch;
import org.jeecg.modules.mes.batch.master.mapper.MesBatchMapper;
import org.jeecg.modules.mes.batch.master.service.IMesBatchService;
import org.jeecg.modules.mes.basic.mapper.MesMaterialMapper;
import org.jeecg.modules.mes.basic.entity.MesMaterial;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.Date;

@Service
public class MesBatchServiceImpl extends ServiceImpl<MesBatchMapper, MesBatch> implements IMesBatchService {

    @Autowired private IMesBatchInventoryService inventoryService;
    @Autowired private IMesBatchLedgerService ledgerService;
    //update-begin---author:ruiwancheng---date:2026-07-31---for: P0-1 铁拳团-并发取号用物料主档行锁（替代count+1）-----------
    @Autowired private MesMaterialMapper materialMapper;
    //update-end---author:ruiwancheng---date:2026-07-31---for: P0-1 铁拳团-并发取号用物料主档行锁-----------

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String createBatch(String materialId, String originType, String originBillId, String originBillNo,
                              BigDecimal qty, BigDecimal unitCost, Date productionDate, Date expiryDate,
                              Integer shelfLife) {
        //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——老 createBatch 委托 createBatchWithManualNo（自动生成 batchNo）-----------
        // 0. 参数校验
        if (!StringUtils.hasText(materialId)) throw new JeecgBootException("物料不能为空");
        if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("批次数量必须大于0");

        // 1. 物料主档行锁 — 串行化同物料的批次创建
        MesMaterial mat = materialMapper.selectByIdForUpdate(materialId);
        if (mat == null) throw new JeecgBootException("物料不存在");

        // 2. 取当日最大序号 + 1
        String prefix = "BT-" + mat.getCode() + "-";
        String date = new SimpleDateFormat("yyyyMMdd").format(new Date());
        QueryWrapper<MesBatch> maxQw = new QueryWrapper<>();
        maxQw.likeRight("batch_no", prefix + date).orderByDesc("batch_no").last("LIMIT 1");
        MesBatch latest = this.getOne(maxQw);
        long seq = 1;
        if (latest != null && latest.getBatchNo() != null) {
            String latestNo = latest.getBatchNo();
            String seqPart = latestNo.substring(latestNo.lastIndexOf("-") + 1);
            try { seq = Long.parseLong(seqPart) + 1; } catch (NumberFormatException e) { seq = 1; }
        }
        String autoBatchNo = prefix + date + String.format("%04d", seq);
        //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 委托 createBatchWithManualNo-----------

        // 委托给新方法（统一走手工入库主逻辑）
        return createBatchWithManualNo(materialId, autoBatchNo, originType, originBillId, originBillNo,
            qty, unitCost, productionDate, expiryDate, shelfLife);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String createBatchWithManualNo(String materialId, String batchNo, String originType,
                                          String originBillId, String originBillNo,
                                          BigDecimal qty, BigDecimal unitCost,
                                          Date productionDate, Date expiryDate,
                                          Integer shelfLife) {
        //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——参数校验+查重+写入-----------
        // 0. 参数校验
        if (!StringUtils.hasText(materialId)) throw new JeecgBootException("物料不能为空");
        if (!StringUtils.hasText(batchNo)) throw new JeecgBootException("生产批次号不能为空");
        if (batchNo.length() > 50) throw new JeecgBootException("生产批次号长度不能超过50个字符");
        if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("批次数量必须大于0");

        // 1. 物料主档行锁 — 串行化同物料的批次创建
        MesMaterial mat = materialMapper.selectByIdForUpdate(materialId);
        if (mat == null) throw new JeecgBootException("物料不存在");

        // 2. 业务层查重（DB uk_batch_material_no_del 兑底）—— 同物料同 batchNo 不可重复
        QueryWrapper<MesBatch> dupCheck = new QueryWrapper<>();
        dupCheck.eq("material_id", materialId)
                .eq("batch_no", batchNo)
                .eq("del_flag", 0);
        long dupCnt = this.count(dupCheck);
        if (dupCnt > 0) {
            throw new JeecgBootException("批次号 " + batchNo + " 在物料 " + mat.getCode() + " 下已存在，请更换批次号");
        }
        //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------

        // 3. 写主档
        MesBatch batch = new MesBatch();
        batch.setBatchNo(batchNo)
             .setMaterialId(materialId)
             .setOriginType(originType)
             .setOriginBillId(originBillId)
             .setOriginBillNo(originBillNo)
             .setQty(qty)
             .setUnitCost(unitCost)
             .setProductionDate(productionDate)
             .setExpiryDate(expiryDate)
             //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-保质期透传到批次主档-----------
             .setShelfLife(shelfLife)
             //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-保质期透传到批次主档-----------
             .setStatus("1");
        this.save(batch);

        //update-begin---author:ruiwancheng---date:20260801---for:/debug 修复重复 ledger——createBatchWithManualNo 不再写 ledger
        // 原因：createBatch 仅创建批次档案（无仓库、无实际入库动作）；
        //       MesBatchInventoryServiceImpl.stockIn() 会写"批次入库"流水（含仓库、来源单据等完整信息）。
        //       之前在 createBatch 也写一条 warehouseId='' 的"批次创建"流水，导致同一笔入库业务在流水表里出现 2 条。
        //       ledger 表达的是"库存变动"（in_qty/out_qty/warehouse_id），批次档案创建不属于库存变动。
        //update-end---author:ruiwancheng---date:20260801---for:/debug 修复重复 ledger-----------
        return batch.getId();
    }

    @Override
    public void freeze(String id, String operator) {
        MesBatch b = this.getById(id);
        if (b == null) throw new JeecgBootException("批次不存在");
        if ("3".equals(b.getStatus())) throw new JeecgBootException("已耗尽的批次不能冻结");
        b.setStatus("2");
        this.updateById(b);
    }

    @Override
    public void unfreeze(String id, String operator) {
        MesBatch b = this.getById(id);
        if (b == null) throw new JeecgBootException("批次不存在");
        b.setStatus("1");
        this.updateById(b);
    }
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档ServiceImpl-----------
