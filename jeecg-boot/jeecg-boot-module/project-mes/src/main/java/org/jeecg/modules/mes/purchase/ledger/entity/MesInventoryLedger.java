//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-库存台账实体-----------
package org.jeecg.modules.mes.purchase.ledger.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;
import org.jeecgframework.poi.excel.annotation.Excel;
import org.springframework.format.annotation.DateTimeFormat;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_inventory_ledger")
@Schema(description = "MES-库存台账")
public class MesInventoryLedger implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "物料", width = 20, dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;
    @Excel(name = "仓库", width = 15, dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Schema(description = "仓库ID")
    private String warehouseId;
    @Excel(name = "期初数量", width = 15)
    @Schema(description = "期初数量")
    private BigDecimal beginningQty;
    @Excel(name = "本期入库", width = 15)
    @Schema(description = "本期入库")
    private BigDecimal inQty;
    @Excel(name = "本期出库", width = 15)
    @Schema(description = "本期出库")
    private BigDecimal outQty;
    @Excel(name = "期末数量", width = 15)
    @Schema(description = "期末数量")
    private BigDecimal endingQty;
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存台账金额字段-----------
    @Excel(name = "单位成本", width = 12)
    @Schema(description = "单位成本")
    private BigDecimal unitCost;

    @Excel(name = "入库金额", width = 12)
    @Schema(description = "入库金额")
    private BigDecimal inAmount;

    @Excel(name = "出库金额", width = 12)
    @Schema(description = "出库金额")
    private BigDecimal outAmount;

    @Excel(name = "期初金额", width = 12)
    @Schema(description = "期初金额")
    private BigDecimal beginningAmount;

    @Excel(name = "期末金额", width = 12)
    @Schema(description = "期末金额")
    private BigDecimal endingAmount;
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 库存台账金额字段-----------
    @Excel(name = "记录日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "记录日期")
    private Date recordDate;
    @Excel(name = "业务类型", width = 15)
    @Schema(description = "业务类型")
    private String bizType;
    @Schema(description = "业务单号")
    private String bizId;
    @Schema(description = "创建人") private String createBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间") private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-库存台账实体-----------
