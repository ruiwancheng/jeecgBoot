//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商管理实体-----------
package org.jeecg.modules.mes.basic.entity;

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

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_supplier")
@Schema(description = "MES-供应商")
public class MesSupplier implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Excel(name = "供应商编码", width = 15)
    @Schema(description = "供应商编码")
    private String code;
    @Excel(name = "供应商名称", width = 20)
    @Schema(description = "供应商名称")
    private String name;
    @Excel(name = "供应商类型", width = 15, dicCode = "mes_supplier_type")
    @Dict(dicCode = "mes_supplier_type")
    @Schema(description = "供应商类型")
    private String type;
    @Excel(name = "供应商状态", width = 12, dicCode = "mes_supplier_status")
    @Dict(dicCode = "mes_supplier_status")
    @Schema(description = "供应商状态")
    private String status;
    @Excel(name = "供应商等级", width = 12, dicCode = "mes_supplier_grade")
    @Dict(dicCode = "mes_supplier_grade")
    @Schema(description = "供应商等级")
    private String grade;
    @Excel(name = "黑名单", width = 10, dicCode = "yn")
    @Dict(dicCode = "yn")
    @Schema(description = "黑名单标记")
    private Integer blacklistFlag;
    @Excel(name = "联系人", width = 15)
    @Schema(description = "联系人")
    private String contact;
    @Excel(name = "联系电话", width = 15)
    @Schema(description = "联系电话")
    private String phone;
    @Excel(name = "地址", width = 30)
    @Schema(description = "地址")
    private String address;
    @Excel(name = "发票抬头", width = 20)
    @Schema(description = "发票抬头")
    private String invoiceTitle;
    //update-begin---author:ruiwancheng---date:2026-07-14---for: 审计修复#9-敏感字段移除@Excel防导出泄露-----------
    @Schema(description = "税号")
    private String taxNo;
    @Excel(name = "开户银行", width = 20)
    @Schema(description = "开户银行")
    private String bankName;
    @Schema(description = "银行账号")
    private String bankAccount;
    //update-end---author:ruiwancheng---date:2026-07-14---for: 审计修复#9-敏感字段移除@Excel防导出泄露-----------
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
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商管理实体-----------
