//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请实体-----------
package org.jeecg.modules.mes.purchase.apply.entity;

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
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_purchase_apply")
@Schema(description = "MES-采购申请")
public class MesPurchaseApply implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "申请单号", width = 15)
    @Schema(description = "申请单号")
    private String code;
    @Excel(name = "申请部门", width = 15)
    @Schema(description = "申请部门")
    private String deptId;
    @Excel(name = "申请人", width = 12)
    @Schema(description = "申请人")
    private String applicantId;
    @Excel(name = "申请日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "申请日期")
    private Date applyDate;
    @Excel(name = "需求日期", width = 15, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "需求日期")
    private Date requiredDate;
    @Excel(name = "预算科目", width = 15)
    @Schema(description = "预算科目")
    private String budgetSubject;
    @Excel(name = "申请金额", width = 15)
    @Schema(description = "申请金额合计")
    private BigDecimal totalAmount;
    @Excel(name = "状态", width = 12, dicCode = "mes_purchase_apply_status")
    @Dict(dicCode = "mes_purchase_apply_status")
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

    @Schema(description = "申请行列表")
    private transient List<MesPurchaseApplyItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请实体-----------
