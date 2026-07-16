//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM实体-----------
package org.jeecg.modules.mes.manufacturing.bom.entity;

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
@TableName("c_mes_bom")
@Schema(description = "MES-BOM")
public class MesBom implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    private String id;
    @Excel(name = "BOM编号", width = 15) private String code;
    @Excel(name = "父项物料", width = 20, dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id") private String productId;
    @Excel(name = "版本", width = 10) private String version;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") private Date effectiveDate;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") private Date expiryDate;
    @Excel(name = "状态", width = 10, dicCode = "mes_bom_status") @Dict(dicCode = "mes_bom_status") private String status;
    @Excel(name = "备注", width = 30) private String remark;
    private String createBy; @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") private Date createTime;
    private String updateBy; @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") private Date updateTime;
    @TableLogic private Integer delFlag;
    private transient List<MesBomItem> items;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM实体-----------
