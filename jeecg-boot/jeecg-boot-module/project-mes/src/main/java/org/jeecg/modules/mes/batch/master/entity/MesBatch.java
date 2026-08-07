//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档实体-----------
package org.jeecg.modules.mes.batch.master.entity;

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
import org.springframework.format.annotation.DateTimeFormat;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_batch")
@Schema(description = "MES-批次主档")
public class MesBatch implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;

    @Schema(description = "批次号(系统生成 BT-{物料编码}-{YYYYMMDD}-{序号})")
    private String batchNo;

    @Dict(dictTable = "c_mes_material", dicText = "code", dicCode = "id")
    @Schema(description = "物料ID")
    private String materialId;

    @Dict(dicCode = "mes_batch_origin_type")
    @Schema(description = "来源类型(dict:mes_batch_origin_type)")
    private String originType;

    @Schema(description = "来源单据ID")
    private String originBillId;

    @Schema(description = "来源单据号")
    private String originBillNo;

    @Schema(description = "初始批次数量")
    private BigDecimal qty;

    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "生产日期")
    private Date productionDate;

    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档保质期字段-----------
    @Schema(description = "保质期(天,可空)")
    private Integer shelfLife;
    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档保质期字段-----------

    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-有效期字段名改为"有效期至"-----------
    @Schema(description = "有效期至(可空)")
    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-有效期字段名改为"有效期至"-----------
    private Date expiryDate;

    @Schema(description = "批次单位成本(采购价/加权平均成本)")
    private BigDecimal unitCost;

    @Dict(dicCode = "mes_batch_status")
    @Schema(description = "状态(dict:mes_batch_status)")
    private String status;

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
    @Schema(description = "删除标记") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档实体-----------
