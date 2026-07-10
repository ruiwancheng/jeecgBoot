//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-价格表实体-----------
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
import org.jeecgframework.poi.excel.annotation.Excel;
import org.springframework.format.annotation.DateTimeFormat;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_customer_price")
@Schema(description = "MES-客户价格表")
public class MesCustomerPrice implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "产品ID", width = 15)
    @Schema(description = "产品ID")
    private String productId;
    @Excel(name = "协议单价", width = 15)
    @Schema(description = "协议单价")
    private BigDecimal price;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "生效日期") private Date beginDate;
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "失效日期") private Date endDate;
    @Schema(description = "起订数量") private BigDecimal minQty;
    @Schema(description = "截止数量") private BigDecimal maxQty;
    @Excel(name = "备注", width = 20)
    @Schema(description = "备注")
    private String remark;
    @Schema(description = "创建人") private String createBy;
    @Schema(description = "创建时间") private Date createTime;
    @Schema(description = "更新人") private String updateBy;
    @Schema(description = "更新时间") private Date updateTime;
    @TableLogic
    @Schema(description = "删除状态") private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-价格表实体-----------
