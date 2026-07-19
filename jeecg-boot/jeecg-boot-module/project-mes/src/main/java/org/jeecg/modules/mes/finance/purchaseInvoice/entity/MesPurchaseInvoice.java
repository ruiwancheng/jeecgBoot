//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 进项发票实体-----------
package org.jeecg.modules.mes.finance.purchaseInvoice.entity;
import com.baomidou.mybatisplus.annotation.IdType; import com.baomidou.mybatisplus.annotation.TableId; import com.baomidou.mybatisplus.annotation.TableLogic; import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat; import io.swagger.v3.oas.annotations.media.Schema; import lombok.Data; import lombok.EqualsAndHashCode; import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict; import org.jeecgframework.poi.excel.annotation.Excel; import org.springframework.format.annotation.DateTimeFormat;
import java.io.Serializable; import java.math.BigDecimal; import java.util.Date;
@Data @EqualsAndHashCode(callSuper=false) @Accessors(chain=true) @TableName("c_mes_purchase_invoice") @Schema(description="MES-进项发票")
public class MesPurchaseInvoice implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type=IdType.ASSIGN_ID) @Schema(description="id") private String id;
    @Excel(name="发票单号",width=15) private String code; @Excel(name="发票号码",width=15) private String invoiceNo;
    @Excel(name="供应商",width=20,dictTable="c_mes_supplier",dicText="name",dicCode="id") @Dict(dictTable="c_mes_supplier",dicText="name",dicCode="id") private String supplierId;
    private String purchaseOrderId; private String receiptId;
    @Excel(name="收票日期",width=15) @JsonFormat(timezone="GMT+8",pattern="yyyy-MM-dd") @DateTimeFormat(pattern="yyyy-MM-dd") private Date invoiceDate;
    @Excel(name="不含税金额",width=15) private BigDecimal amount; @Excel(name="税率",width=10) private BigDecimal taxRate;
    @Excel(name="税额",width=15) private BigDecimal taxAmount; @Excel(name="价税合计",width=15) private BigDecimal totalWithTax;
    @Excel(name="发票类型",width=10,dicCode="mes_invoice_type") @Dict(dicCode="mes_invoice_type") private String invoiceType;
    @Excel(name="状态",width=10,dicCode="yn") @Dict(dicCode="yn") private String status; @Excel(name="备注",width=30) private String remark;
    private String createBy; private Date createTime; private String updateBy; private Date updateTime; @TableLogic private Integer delFlag;
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 进项发票实体-----------
