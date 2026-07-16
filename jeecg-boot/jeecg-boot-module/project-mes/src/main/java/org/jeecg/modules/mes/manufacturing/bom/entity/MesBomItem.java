//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM子项实体-----------
package org.jeecg.modules.mes.manufacturing.bom.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_bom_item")
@Schema(description = "MES-BOM子项")
public class MesBomItem implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID) private String id;
    private String bomId;
    private Integer lineNo;
    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id") private String materialId;
    private BigDecimal quantity;
    private BigDecimal lossRate;
    private String isSubstitute;
    private String createBy; private Date createTime;
    private String updateBy; private Date updateTime;
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM子项实体-----------
