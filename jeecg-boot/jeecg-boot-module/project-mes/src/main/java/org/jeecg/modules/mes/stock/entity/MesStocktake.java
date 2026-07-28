//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-主表实体-----------
package org.jeecg.modules.mes.stock.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
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
import java.util.Date;
import java.util.List;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_stocktake")
@Schema(description = "MES-盘点单")
public class MesStocktake implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "盘点单号", width = 15)
    @Schema(description = "盘点单号")
    private String code;
    @Excel(name = "仓库", width = 15, dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Schema(description = "仓库ID(单仓盘点)")
    private String warehouseId;
    @Excel(name = "盘点类型", width = 12, dicCode = "mes_stocktake_type")
    @Dict(dicCode = "mes_stocktake_type")
    @Schema(description = "盘点类型(1全盘2抽盘)")
    private String takeType;
    @Excel(name = "状态", width = 12, dicCode = "mes_other_stock_status")
    @Dict(dicCode = "mes_other_stock_status")
    @Schema(description = "状态")
    private String status;
    @Excel(name = "盘点日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "盘点日期")
    private Date takeDate;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "账面快照时间(book_qty取数时点,差异以此为准)")
    private Date snapshotTime;
    @Excel(name = "差异金额合计", width = 15)
    @Schema(description = "差异金额合计")
    private java.math.BigDecimal totalDiffAmount;
    @Excel(name = "备注", width = 30)
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间") private Date updateTime;
    @Schema(description = "删除标记") private Integer delFlag;

    @TableField(exist = false)
    @Schema(description = "盘点明细")
    private List<MesStocktakeItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-主表实体-----------
