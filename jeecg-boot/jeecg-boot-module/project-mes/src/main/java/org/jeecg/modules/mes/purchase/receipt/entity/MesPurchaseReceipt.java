//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库实体-----------
package org.jeecg.modules.mes.purchase.receipt.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
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
@TableName("c_mes_purchase_receipt")
@Schema(description = "MES-采购入库")
public class MesPurchaseReceipt implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "入库单号", width = 15)
    @Schema(description = "入库单号")
    private String code;
    @Excel(name = "采购订单", width = 15)
    @Schema(description = "关联采购订单ID")
    private String purchaseOrderId;
    @Excel(name = "供应商", width = 20, dictTable = "c_mes_supplier", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_supplier", dicText = "name", dicCode = "id")
    @Schema(description = "供应商ID")
    private String supplierId;
    @Excel(name = "仓库", width = 15, dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Schema(description = "仓库ID")
    private String warehouseId;
    @Excel(name = "入库日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "入库日期")
    private Date receiptDate;
    @Excel(name = "状态", width = 12, dicCode = "mes_purchase_receipt_status")
    @Dict(dicCode = "mes_purchase_receipt_status")
    @Schema(description = "状态")
    private String status;
    @Excel(name = "备注", width = 30)
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新时间") private Date updateTime;
    @TableLogic
    @Schema(description = "删除状态") private Integer delFlag;

    @Schema(description = "入库行列表")
    private transient List<MesPurchaseReceiptItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库实体-----------
