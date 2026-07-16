//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单实体-----------
package org.jeecg.modules.mes.manufacturing.order.entity;

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

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_production_order")
@Schema(description = "MES-生产订单")
public class MesProductionOrder implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) private String id;
    @Excel(name = "订单编号", width = 15) private String code;
    @Excel(name = "产品", width = 20, dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id") private String productId;
    @Excel(name = "BOM", width = 15) private String bomId;
    @Excel(name = "计划数量", width = 12) private BigDecimal planQty;
    @Excel(name = "已完工数量", width = 12) private BigDecimal completedQty;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") private Date startDate;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd") @DateTimeFormat(pattern = "yyyy-MM-dd") private Date endDate;
    @Excel(name = "仓库", width = 15, dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id")
    @Dict(dictTable = "c_mes_warehouse", dicText = "name", dicCode = "id") private String warehouseId;
    @Excel(name = "状态", width = 10, dicCode = "mes_production_order_status")
    @Dict(dicCode = "mes_production_order_status") private String status;
    @Excel(name = "备注", width = 30) private String remark;
    private String createBy; @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") private Date createTime;
    private String updateBy; @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss") @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") private Date updateTime;
    @TableLogic private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单实体-----------
