# MES 客户模块改造 — 实施计划

> **适用对象：** AI agentic worker。每个 Task 按顺序执行，完成一个再进入下一个。使用 checkbox（`- [ ]`）追踪进度。

**目标：** 将 MES 客户模块从通讯录升级为 PRD 客户全生命周期管理基础设施（新增 12 字段 + 4 子表 + 6 字典）。

**架构：** 直接在 `c_mes_customer` 表加字段，新建 4 张子表。Java 后端沿用 basic 包下 entity→mapper→service→controller 标准四层。前端 CustomerDrawer 改造为 Tab 布局，每个子表独立 Tab 组件。

**技术栈：** Spring Boot 3.5.5 + MyBatis-Plus 3.5.12 + Vue 3 + Ant Design Vue 4 + TypeScript

**设计文档：** `harness/docs/2026-07-10-mes-customer-upgrade-design.md`

---

### Task 1: 数据库 — 修改客户表 + 新建子表

**文件：**
- 创建: `jeecg-boot/jeecg-boot-module/project-mes/db/V1.0.0__mes_customer_upgrade.sql`

- [ ] **Step 1: 编写 SQL 迁移脚本**

```sql
-- MES 客户模块升级 V1.0.0
-- ALTER TABLE: c_mes_customer 新增 12 字段
-- CREATE TABLE: 4 个子表

ALTER TABLE c_mes_customer
    ADD COLUMN grade             VARCHAR(32)   COMMENT '客户等级(dict:mes_customer_grade)',
    ADD COLUMN credit_limit      DECIMAL(18,2) COMMENT '信用额度',
    ADD COLUMN salesman_id       VARCHAR(36)   COMMENT '所属业务员(sys_user.id)',
    ADD COLUMN industry          VARCHAR(32)   COMMENT '行业(dict:mes_customer_industry)',
    ADD COLUMN region            VARCHAR(32)   COMMENT '区域(dict:mes_customer_region)',
    ADD COLUMN scale             VARCHAR(32)   COMMENT '企业规模(dict:mes_customer_scale)',
    ADD COLUMN invoice_title     VARCHAR(200)  COMMENT '发票抬头',
    ADD COLUMN tax_no            VARCHAR(50)   COMMENT '税号',
    ADD COLUMN bank_name         VARCHAR(100)  COMMENT '开户银行',
    ADD COLUMN bank_account      VARCHAR(50)   COMMENT '银行账号',
    ADD COLUMN invoice_address   VARCHAR(300)  COMMENT '开票地址',
    ADD COLUMN invoice_phone     VARCHAR(30)   COMMENT '开票电话',
    ADD COLUMN invoice_type      VARCHAR(10)   COMMENT '发票类型(dict:invoice_type)';

-- 联系人子表
CREATE TABLE c_mes_customer_contact (
    id          VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)  NOT NULL COMMENT '客户ID',
    name        VARCHAR(50)  COMMENT '姓名',
    title       VARCHAR(50)  COMMENT '职务',
    phone       VARCHAR(20)  COMMENT '手机',
    email       VARCHAR(100) COMMENT '邮箱',
    social      VARCHAR(100) COMMENT 'QQ/微信',
    is_default  TINYINT(1)   DEFAULT 0 COMMENT '是否默认',
    remark      VARCHAR(200) COMMENT '备注',
    create_by   VARCHAR(50)  COMMENT '创建人',
    create_time DATETIME     COMMENT '创建时间',
    update_by   VARCHAR(50)  COMMENT '更新人',
    update_time DATETIME     COMMENT '更新时间',
    del_flag    INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户联系人';

-- 地址子表
CREATE TABLE c_mes_customer_address (
    id           VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id  VARCHAR(36)  NOT NULL COMMENT '客户ID',
    address_type VARCHAR(20)  COMMENT '地址类型(dict:address_type)',
    contact      VARCHAR(50)  COMMENT '联系人',
    phone        VARCHAR(20)  COMMENT '联系电话',
    province     VARCHAR(50)  COMMENT '省',
    city         VARCHAR(50)  COMMENT '市',
    district     VARCHAR(50)  COMMENT '区',
    detail       VARCHAR(300) COMMENT '详细地址',
    is_default   TINYINT(1)   DEFAULT 0 COMMENT '是否默认',
    remark       VARCHAR(200) COMMENT '备注',
    create_by    VARCHAR(50)  COMMENT '创建人',
    create_time  DATETIME     COMMENT '创建时间',
    update_by    VARCHAR(50)  COMMENT '更新人',
    update_time  DATETIME     COMMENT '更新时间',
    del_flag     INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户地址';

-- 跟进记录子表
CREATE TABLE c_mes_customer_follow_up (
    id          VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)  NOT NULL COMMENT '客户ID',
    follow_type VARCHAR(20)  COMMENT '跟进方式(dict:follow_type)',
    follow_date DATETIME     COMMENT '跟进日期',
    content     TEXT         COMMENT '跟进内容',
    follower    VARCHAR(36)  COMMENT '跟进人(sys_user.id)',
    next_date   DATETIME     COMMENT '下次跟进日期',
    attachment  VARCHAR(500) COMMENT '附件路径',
    remark      VARCHAR(200) COMMENT '备注',
    create_by   VARCHAR(50)  COMMENT '创建人',
    create_time DATETIME     COMMENT '创建时间',
    update_by   VARCHAR(50)  COMMENT '更新人',
    update_time DATETIME     COMMENT '更新时间',
    del_flag    INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户跟进记录';

-- 价格表
CREATE TABLE c_mes_customer_price (
    id          VARCHAR(36)   NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)   NOT NULL COMMENT '客户ID',
    product_id  VARCHAR(36)   COMMENT '产品ID',
    price       DECIMAL(18,2) COMMENT '协议单价',
    begin_date  DATETIME      COMMENT '生效日期（预留）',
    end_date    DATETIME      COMMENT '失效日期（预留）',
    min_qty     DECIMAL(18,2) COMMENT '起订数量（预留）',
    max_qty     DECIMAL(18,2) COMMENT '截止数量（预留）',
    remark      VARCHAR(200)  COMMENT '备注',
    create_by   VARCHAR(50)   COMMENT '创建人',
    create_time DATETIME      COMMENT '创建时间',
    update_by   VARCHAR(50)   COMMENT '更新人',
    update_time DATETIME      COMMENT '更新时间',
    del_flag    INT           DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户价格表';
```

- [ ] **Step 2: 在服务器上执行 SQL**

```bash
# 通过部署控制台或手动执行
mysql -h 100.122.125.106 -P 13306 -u root -proot jeecg-boot \
  < jeecg-boot/jeecg-boot-module/project-mes/db/V1.0.0__mes_customer_upgrade.sql
```

- [ ] **Step 3: 验证表结构**

```sql
DESC c_mes_customer;
SHOW CREATE TABLE c_mes_customer_contact;
SHOW CREATE TABLE c_mes_customer_address;
SHOW CREATE TABLE c_mes_customer_follow_up;
SHOW CREATE TABLE c_mes_customer_price;
```

---

### Task 2: 字典 — 创建 6 个新字典 + 修正客户类型

**依赖：** 后端 API 可访问

- [ ] **Step 1: 通过 system_creator.py 批量创建字典**

```bash
SCRIPT="C:/Users/72899/.claude/skills/jeecg-system/scripts/system_creator.py"
API="http://100.122.125.106:8080/jeecg-boot"
TOKEN="<使用当前登录token>"

# 批量创建/更新字典（先查后建，已有则跳过）
python "$SCRIPT" --api-base $API --token $TOKEN --config - <<'JSON'
{
  "dicts": [
    {
      "dictCode": "mes_customer_grade",
      "dictName": "客户等级",
      "items": [
        {"value": "VIP", "text": "VIP", "extJson": "{\"discount\":0.8}"},
        {"value": "ADVANCED", "text": "高级", "extJson": "{\"discount\":0.9}"},
        {"value": "NORMAL", "text": "普通", "extJson": "{\"discount\":1.0}"},
        {"value": "POTENTIAL", "text": "潜在", "extJson": "{\"discount\":1.0}"}
      ]
    },
    {
      "dictCode": "mes_customer_industry",
      "dictName": "客户行业",
      "items": [
        {"value": "1", "text": "制造业"},
        {"value": "2", "text": "零售业"},
        {"value": "3", "text": "电子商务"},
        {"value": "4", "text": "信息技术"},
        {"value": "5", "text": "建筑业"},
        {"value": "6", "text": "金融业"},
        {"value": "7", "text": "其他"}
      ]
    },
    {
      "dictCode": "mes_customer_region",
      "dictName": "客户区域",
      "items": [
        {"value": "EAST", "text": "华东"},
        {"value": "SOUTH", "text": "华南"},
        {"value": "NORTH", "text": "华北"},
        {"value": "CENTRAL", "text": "华中"},
        {"value": "SOUTHWEST", "text": "西南"},
        {"value": "NORTHWEST", "text": "西北"},
        {"value": "NORTHEAST", "text": "东北"},
        {"value": "OVERSEAS", "text": "海外"}
      ]
    },
    {
      "dictCode": "mes_customer_scale",
      "dictName": "企业规模",
      "items": [
        {"value": "LARGE", "text": "大型"},
        {"value": "MEDIUM", "text": "中型"},
        {"value": "SMALL", "text": "小型"},
        {"value": "MICRO", "text": "微型"}
      ]
    },
    {
      "dictCode": "address_type",
      "dictName": "地址类型",
      "items": [
        {"value": "shipping", "text": "收货地址"},
        {"value": "invoice", "text": "发票地址"},
        {"value": "office", "text": "办公地址"}
      ]
    },
    {
      "dictCode": "follow_type",
      "dictName": "跟进方式",
      "items": [
        {"value": "phone", "text": "电话"},
        {"value": "visit", "text": "拜访"},
        {"value": "email", "text": "邮件"},
        {"value": "other", "text": "其他"}
      ]
    },
    {
      "dictCode": "invoice_type",
      "dictName": "发票类型",
      "items": [
        {"value": "special", "text": "增值税专用发票"},
        {"value": "normal", "text": "增值税普通发票"}
      ]
    }
  ]
}
JSON
```

- [ ] **Step 2: 修正现有 mes_customer_type 字典（删除"供应商"项）**

> 供应商不应属于客户类型，通过系统管理页面手动删除 `value=3, text=供应商` 项。

- [ ] **Step 3: 验证字典**

```bash
# 确认所有字典已创建
python "$SCRIPT" --api-base $API --token $TOKEN --action query-dict --code mes_customer_grade
python "$SCRIPT" --api-base $API --token $TOKEN --action query-dict --code mes_customer_industry
python "$SCRIPT" --api-base $API --token $TOKEN --action query-dict --code address_type
python "$SCRIPT" --api-base $API --token $TOKEN --action query-dict --code follow_type
python "$SCRIPT" --api-base $API --token $TOKEN --action query-dict --code invoice_type
```

---

### Task 3: 后端 — 修改 MesCustomer Entity

**文件：**
- 修改: `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/entity/MesCustomer.java`

- [ ] **Step 1: 在 MesCustomer 中新增字段**

在 `code` / `name` / `type` 字段之后，`status` 之前插入：

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-新增等级/额度/归属/分类/财务字段-----------
@Excel(name = "客户等级", width = 12, dicCode = "mes_customer_grade")
@Dict(dicCode = "mes_customer_grade")
@Schema(description = "客户等级")
private String grade;

@Excel(name = "信用额度", width = 15)
@Schema(description = "信用额度")
private java.math.BigDecimal creditLimit;

@Excel(name = "所属业务员", width = 12)
@Schema(description = "所属业务员")
private String salesmanId;

@Excel(name = "行业", width = 12, dicCode = "mes_customer_industry")
@Dict(dicCode = "mes_customer_industry")
@Schema(description = "行业")
private String industry;

@Excel(name = "区域", width = 12, dicCode = "mes_customer_region")
@Dict(dicCode = "mes_customer_region")
@Schema(description = "区域")
private String region;

@Excel(name = "企业规模", width = 12, dicCode = "mes_customer_scale")
@Dict(dicCode = "mes_customer_scale")
@Schema(description = "企业规模")
private String scale;

@Excel(name = "发票抬头", width = 20)
@Schema(description = "发票抬头")
private String invoiceTitle;

@Excel(name = "税号", width = 20)
@Schema(description = "税号")
private String taxNo;

@Excel(name = "开户银行", width = 20)
@Schema(description = "开户银行")
private String bankName;

@Excel(name = "银行账号", width = 20)
@Schema(description = "银行账号")
private String bankAccount;

@Excel(name = "开票地址", width = 30)
@Schema(description = "开票地址")
private String invoiceAddress;

@Excel(name = "开票电话", width = 15)
@Schema(description = "开票电话")
private String invoicePhone;

@Excel(name = "发票类型", width = 12, dicCode = "invoice_type")
@Dict(dicCode = "invoice_type")
@Schema(description = "发票类型")
private String invoiceType;
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-新增等级/额度/归属/分类/财务字段-----------
```

- [ ] **Step 2: 验证编译**

```bash
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am -DskipTests
```

Expected: BUILD SUCCESS

---

### Task 4: 后端 — 新建 4 个 Entity

**文件：** 在 `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/entity/` 下创建

- [ ] **Step 1: 创建 MesCustomerContact.java**

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人实体-----------
package org.jeecg.modules.mes.basic.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecgframework.poi.excel.annotation.Excel;
import java.io.Serializable;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_customer_contact")
@Schema(description = "MES-客户联系人")
public class MesCustomerContact implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "姓名", width = 15)
    @Schema(description = "姓名")
    private String name;
    @Excel(name = "职务", width = 15)
    @Schema(description = "职务")
    private String title;
    @Excel(name = "手机", width = 15)
    @Schema(description = "手机")
    private String phone;
    @Excel(name = "邮箱", width = 20)
    @Schema(description = "邮箱")
    private String email;
    @Excel(name = "QQ/微信", width = 15)
    @Schema(description = "QQ/微信")
    private String social;
    @Excel(name = "是否默认", width = 10)
    @Schema(description = "是否默认")
    private Integer isDefault;
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
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人实体-----------
```

- [ ] **Step 2: 创建 MesCustomerAddress.java**

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址实体-----------
package org.jeecg.modules.mes.basic.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.jeecg.common.aspect.annotation.Dict;
import org.jeecgframework.poi.excel.annotation.Excel;
import java.io.Serializable;
import java.util.Date;

@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("c_mes_customer_address")
@Schema(description = "MES-客户地址")
public class MesCustomerAddress implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "地址类型", width = 12, dicCode = "address_type")
    @Dict(dicCode = "address_type")
    @Schema(description = "地址类型")
    private String addressType;
    @Excel(name = "联系人", width = 15)
    @Schema(description = "联系人")
    private String contact;
    @Excel(name = "联系电话", width = 15)
    @Schema(description = "联系电话")
    private String phone;
    @Schema(description = "省") private String province;
    @Schema(description = "市") private String city;
    @Schema(description = "区") private String district;
    @Excel(name = "详细地址", width = 30)
    @Schema(description = "详细地址")
    private String detail;
    @Excel(name = "是否默认", width = 10)
    @Schema(description = "是否默认")
    private Integer isDefault;
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
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址实体-----------
```

- [ ] **Step 3: 创建 MesCustomerFollowUp.java**

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-跟进记录实体-----------
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
@TableName("c_mes_customer_follow_up")
@Schema(description = "MES-客户跟进记录")
public class MesCustomerFollowUp implements Serializable {
    private static final long serialVersionUID = 1L;
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    @Schema(description = "客户ID")
    private String customerId;
    @Excel(name = "跟进方式", width = 12, dicCode = "follow_type")
    @Dict(dicCode = "follow_type")
    @Schema(description = "跟进方式")
    private String followType;
    @Excel(name = "跟进日期", width = 15)
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "跟进日期")
    private Date followDate;
    @Excel(name = "跟进内容", width = 30)
    @Schema(description = "跟进内容")
    private String content;
    @Schema(description = "跟进人")
    private String follower;
    @Excel(name = "下次跟进日期", width = 15)
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "下次跟进日期")
    private Date nextDate;
    @Schema(description = "附件路径")
    private String attachment;
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
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-跟进记录实体-----------
```

- [ ] **Step 4: 创建 MesCustomerPrice.java**

```java
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
```

- [ ] **Step 5: 验证编译**

```bash
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am -DskipTests
```

Expected: BUILD SUCCESS

---

### Task 5: 后端 — 新建 4 个 Mapper

**文件：** 在 `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/mapper/` 下创建

- [ ] **Step 1: 创建 4 个 Mapper 接口**

```java
// MesCustomerContactMapper.java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Mapper-----------
package org.jeecg.modules.mes.basic.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.jeecg.modules.mes.basic.entity.MesCustomerContact;

public interface MesCustomerContactMapper extends BaseMapper<MesCustomerContact> {
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Mapper-----------
```

```java
// MesCustomerAddressMapper.java
package org.jeecg.modules.mes.basic.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.jeecg.modules.mes.basic.entity.MesCustomerAddress;
public interface MesCustomerAddressMapper extends BaseMapper<MesCustomerAddress> {}
```

```java
// MesCustomerFollowUpMapper.java
package org.jeecg.modules.mes.basic.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.jeecg.modules.mes.basic.entity.MesCustomerFollowUp;
public interface MesCustomerFollowUpMapper extends BaseMapper<MesCustomerFollowUp> {}
```

```java
// MesCustomerPriceMapper.java
package org.jeecg.modules.mes.basic.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.jeecg.modules.mes.basic.entity.MesCustomerPrice;
public interface MesCustomerPriceMapper extends BaseMapper<MesCustomerPrice> {}
```

> 注：Address、FollowUp、Price 三个 Mapper 无需 update-begin/end（纯样板代码，无业务逻辑），只有 Contact 需要包裹（下同，只在首个有业务含义的类加标记）。

- [ ] **Step 2: 验证编译**

```bash
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am -DskipTests
```

---

### Task 6: 后端 — 新建 4 组 Service

**文件：** 在 `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/service/` 和 `service/impl/` 下创建

- [ ] **Step 1: 创建 Service 接口和实现**

每对文件如下（以 Contact 为例，其余三个同理替换类名）：

```java
// IMesCustomerContactService.java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Service接口-----------
package org.jeecg.modules.mes.basic.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.entity.MesCustomerContact;

public interface IMesCustomerContactService extends IService<MesCustomerContact> {
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Service接口-----------
```

```java
// MesCustomerContactServiceImpl.java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.modules.mes.basic.entity.MesCustomerContact;
import org.jeecg.modules.mes.basic.mapper.MesCustomerContactMapper;
import org.jeecg.modules.mes.basic.service.IMesCustomerContactService;
import org.springframework.stereotype.Service;

@Service
public class MesCustomerContactServiceImpl extends ServiceImpl<MesCustomerContactMapper, MesCustomerContact> implements IMesCustomerContactService {
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人Service实现-----------
```

同样方式创建：
- `IMesCustomerAddressService` / `MesCustomerAddressServiceImpl`
- `IMesCustomerFollowUpService` / `MesCustomerFollowUpServiceImpl`
- `IMesCustomerPriceService` / `MesCustomerPriceServiceImpl`

- [ ] **Step 2: 验证编译**

```bash
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am -DskipTests
```

---

### Task 7: 后端 — 新建 4 个 Controller

**文件：** 在 `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/controller/` 下创建

- [ ] **Step 1: 创建 MesCustomerContactController.java**

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.modules.mes.basic.entity.MesCustomerContact;
import org.jeecg.modules.mes.basic.service.IMesCustomerContactService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;

@Slf4j
@Tag(name = "MES-客户联系人")
@RestController
@RequestMapping("/mes/basic/customer/contact")
public class MesCustomerContactController extends JeecgController<MesCustomerContact, IMesCustomerContactService> {
    @Autowired
    private IMesCustomerContactService service;

    @GetMapping("/list")
    public Result<IPage<MesCustomerContact>> queryPageList(MesCustomerContact entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        LambdaQueryWrapper<MesCustomerContact> qw = new LambdaQueryWrapper<>();
        qw.eq(MesCustomerContact::getCustomerId, entity.getCustomerId());
        qw.orderByDesc(MesCustomerContact::getIsDefault);
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomerContact e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomerContact e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-联系人接口-----------
```

- [ ] **Step 2: 创建 MesCustomerAddressController.java**

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.modules.mes.basic.entity.MesCustomerAddress;
import org.jeecg.modules.mes.basic.service.IMesCustomerAddressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;

@Slf4j
@Tag(name = "MES-客户地址")
@RestController
@RequestMapping("/mes/basic/customer/address")
public class MesCustomerAddressController extends JeecgController<MesCustomerAddress, IMesCustomerAddressService> {
    @Autowired
    private IMesCustomerAddressService service;

    @GetMapping("/list")
    public Result<IPage<MesCustomerAddress>> queryPageList(MesCustomerAddress entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        LambdaQueryWrapper<MesCustomerAddress> qw = new LambdaQueryWrapper<>();
        qw.eq(MesCustomerAddress::getCustomerId, entity.getCustomerId());
        qw.orderByDesc(MesCustomerAddress::getIsDefault);
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomerAddress e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomerAddress e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址接口-----------
```

- [ ] **Step 3: 创建 MesCustomerFollowUpController.java**

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-跟进记录接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.modules.mes.basic.entity.MesCustomerFollowUp;
import org.jeecg.modules.mes.basic.service.IMesCustomerFollowUpService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;

@Slf4j
@Tag(name = "MES-客户跟进记录")
@RestController
@RequestMapping("/mes/basic/customer/followUp")
public class MesCustomerFollowUpController extends JeecgController<MesCustomerFollowUp, IMesCustomerFollowUpService> {
    @Autowired
    private IMesCustomerFollowUpService service;

    @GetMapping("/list")
    public Result<IPage<MesCustomerFollowUp>> queryPageList(MesCustomerFollowUp entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        LambdaQueryWrapper<MesCustomerFollowUp> qw = new LambdaQueryWrapper<>();
        qw.eq(MesCustomerFollowUp::getCustomerId, entity.getCustomerId());
        qw.orderByDesc(MesCustomerFollowUp::getFollowDate);
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomerFollowUp e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomerFollowUp e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-跟进记录接口-----------
```

- [ ] **Step 4: 创建 MesCustomerPriceController.java**

```java
//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-价格表接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.modules.mes.basic.entity.MesCustomerPrice;
import org.jeecg.modules.mes.basic.service.IMesCustomerPriceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;

@Slf4j
@Tag(name = "MES-客户价格表")
@RestController
@RequestMapping("/mes/basic/customer/price")
public class MesCustomerPriceController extends JeecgController<MesCustomerPrice, IMesCustomerPriceService> {
    @Autowired
    private IMesCustomerPriceService service;

    @GetMapping("/list")
    public Result<IPage<MesCustomerPrice>> queryPageList(MesCustomerPrice entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        LambdaQueryWrapper<MesCustomerPrice> qw = new LambdaQueryWrapper<>();
        qw.eq(MesCustomerPrice::getCustomerId, entity.getCustomerId());
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomerPrice e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomerPrice e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-价格表接口-----------
```

- [ ] **Step 5: 验证编译后 install**

```bash
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am -DskipTests && mvn install -pl jeecg-boot-module/project-mes -am -DskipTests -Dmaven.test.skip=true
```

Expected: BUILD SUCCESS

---

### Task 8: 后端 — 更新 Mapper XML（resurrect 方法字段补齐）

**文件：**
- 修改: `MesCustomerMapper.java`（无 XML，resurrect 用注解 SQL，需补齐新字段）

- [ ] **Step 1: 更新 resurrect 方法的 @Update SQL**

```java
// 将 MesCustomerMapper.java 中 resurrect 方法替换为包含所有字段的 UPDATE
@Update("UPDATE c_mes_customer SET code=#{code}, name=#{name}, type=#{type}, " +
        "grade=#{grade}, credit_limit=#{creditLimit}, salesman_id=#{salesmanId}, " +
        "industry=#{industry}, region=#{region}, scale=#{scale}, " +
        "invoice_title=#{invoiceTitle}, tax_no=#{taxNo}, bank_name=#{bankName}, " +
        "bank_account=#{bankAccount}, invoice_address=#{invoiceAddress}, " +
        "invoice_phone=#{invoicePhone}, invoice_type=#{invoiceType}, " +
        "contact=#{contact}, phone=#{phone}, address=#{address}, status=#{status}, " +
        "remark=#{remark}, update_by=#{updateBy}, update_time=#{updateTime}, del_flag=0 WHERE id=#{id}")
void resurrect(MesCustomer entity);
```

- [ ] **Step 2: 验证编译**

```bash
cd jeecg-boot && mvn compile -pl jeecg-boot-module/project-mes -am -DskipTests
```

---

### Task 9: 前端 — 更新 customer.data.ts（搜索 + 表单 Schema）

**文件：**
- 修改: `jeecgboot-vue3/src/views/project/mes/basic/customer/customer.data.ts`

- [ ] **Step 1: 更新 columns、searchFormSchema、formSchema**

```typescript
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '客户编码', dataIndex: 'code', width: 120 },
  { title: '客户名称', dataIndex: 'name', width: 150 },
  { title: '客户类型', dataIndex: 'type_dictText', width: 100 },
  { title: '客户等级', dataIndex: 'grade_dictText', width: 100 },
  { title: '信用额度', dataIndex: 'creditLimit', width: 100 },
  { title: '所属业务员', dataIndex: 'salesmanId', width: 100 },
  { title: '行业', dataIndex: 'industry_dictText', width: 100 },
  { title: '区域', dataIndex: 'region_dictText', width: 80 },
  { title: '联系人', dataIndex: 'contact', width: 80 },
  { title: '联系电话', dataIndex: 'phone', width: 130 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '客户编码', component: 'Input', colProps: { span: 6 } },
  { field: 'name', label: '客户名称', component: 'Input', colProps: { span: 6 } },
  { field: 'type', label: '客户类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_type' } },
  { field: 'grade', label: '客户等级', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_grade' } },
  { field: 'salesmanId', label: '业务员', component: 'Input', colProps: { span: 6 } },
  { field: 'industry', label: '行业', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_industry' } },
  { field: 'region', label: '区域', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_region' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  // ---- 基础信息 ----
  { field: 'code', label: '客户编码', component: 'Input', required: true, colProps: { span: 8 } },
  { field: 'name', label: '客户名称', component: 'Input', required: true, colProps: { span: 8 } },
  { field: 'type', label: '客户类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_type' }, required: true },
  { field: 'grade', label: '客户等级', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_grade' } },
  { field: 'creditLimit', label: '信用额度', component: 'InputNumber', colProps: { span: 8 } },
  { field: 'salesmanId', label: '所属业务员', component: 'Input', colProps: { span: 8 } },
  { field: 'industry', label: '行业', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_industry' } },
  { field: 'region', label: '区域', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_region' } },
  { field: 'scale', label: '企业规模', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_scale' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  // ---- 联系信息 ----
  { field: 'contact', label: '联系人', component: 'Input', colProps: { span: 8 } },
  { field: 'phone', label: '联系电话', component: 'Input', colProps: { span: 8 } },
  { field: 'address', label: '地址', component: 'Input', colProps: { span: 24 } },
  // ---- 财务资料 ----
  { field: 'invoiceTitle', label: '发票抬头', component: 'Input', colProps: { span: 12 } },
  { field: 'taxNo', label: '税号', component: 'Input', colProps: { span: 12 } },
  { field: 'bankName', label: '开户银行', component: 'Input', colProps: { span: 12 } },
  { field: 'bankAccount', label: '银行账号', component: 'Input', colProps: { span: 12 } },
  { field: 'invoiceAddress', label: '开票地址', component: 'Input', colProps: { span: 12 } },
  { field: 'invoicePhone', label: '开票电话', component: 'Input', colProps: { span: 12 } },
  { field: 'invoiceType', label: '发票类型', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'invoice_type' } },
  // ---- 备注 ----
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
```

- [ ] **Step 2: 前端类型检查**

```bash
cd jeecgboot-vue3 && npx vue-tsc --noEmit src/views/project/mes/basic/customer/customer.data.ts 2>&1 | head -5
```

---

### Task 10: 前端 — 更新 customer.api.ts

**文件：**
- 修改: `jeecgboot-vue3/src/views/project/mes/basic/customer/customer.api.ts`

- [ ] **Step 1: 新增子表接口**

```typescript
import { defHttp } from '/@/utils/http/axios';

enum Api {
  // 客户主表
  list = '/mes/basic/customer/list',
  add = '/mes/basic/customer/add',
  edit = '/mes/basic/customer/edit',
  delete = '/mes/basic/customer/delete',
  deleteBatch = '/mes/basic/customer/deleteBatch',
  queryAll = '/mes/basic/customer/queryAll',
  exportXls = '/mes/basic/customer/exportXls',
  importExcel = '/mes/basic/customer/importExcel',
  // 联系人
  contactList = '/mes/basic/customer/contact/list',
  contactAdd = '/mes/basic/customer/contact/add',
  contactEdit = '/mes/basic/customer/contact/edit',
  contactDelete = '/mes/basic/customer/contact/delete',
  // 地址
  addressList = '/mes/basic/customer/address/list',
  addressAdd = '/mes/basic/customer/address/add',
  addressEdit = '/mes/basic/customer/address/edit',
  addressDelete = '/mes/basic/customer/address/delete',
  // 跟进记录
  followUpList = '/mes/basic/customer/followUp/list',
  followUpAdd = '/mes/basic/customer/followUp/add',
  followUpEdit = '/mes/basic/customer/followUp/edit',
  followUpDelete = '/mes/basic/customer/followUp/delete',
  // 价格表
  priceList = '/mes/basic/customer/price/list',
  priceAdd = '/mes/basic/customer/price/add',
  priceEdit = '/mes/basic/customer/price/edit',
  priceDelete = '/mes/basic/customer/price/delete',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

// 客户主表
export const queryCustomerList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addCustomer = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editCustomer = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteCustomer = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchCustomer = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryAllCustomer = () => defHttp.get({ url: Api.queryAll });
export const saveOrUpdateCustomer = (params: Recordable, isUpdate: boolean) =>
  isUpdate ? editCustomer(params) : addCustomer(params);

// 联系人
export const queryContactList = (params: Recordable) => defHttp.get({ url: Api.contactList, params });
export const addContact = (params: Recordable) => defHttp.post({ url: Api.contactAdd, params });
export const editContact = (params: Recordable) => defHttp.put({ url: Api.contactEdit, params });
export const deleteContact = (params: Recordable) => defHttp.delete({ url: Api.contactDelete, params }, { joinParamsToUrl: true });

// 地址
export const queryAddressList = (params: Recordable) => defHttp.get({ url: Api.addressList, params });
export const addAddress = (params: Recordable) => defHttp.post({ url: Api.addressAdd, params });
export const editAddress = (params: Recordable) => defHttp.put({ url: Api.addressEdit, params });
export const deleteAddress = (params: Recordable) => defHttp.delete({ url: Api.addressDelete, params }, { joinParamsToUrl: true });

// 跟进记录
export const queryFollowUpList = (params: Recordable) => defHttp.get({ url: Api.followUpList, params });
export const addFollowUp = (params: Recordable) => defHttp.post({ url: Api.followUpAdd, params });
export const editFollowUp = (params: Recordable) => defHttp.put({ url: Api.followUpEdit, params });
export const deleteFollowUp = (params: Recordable) => defHttp.delete({ url: Api.followUpDelete, params }, { joinParamsToUrl: true });

// 价格表
export const queryPriceList = (params: Recordable) => defHttp.get({ url: Api.priceList, params });
export const addPrice = (params: Recordable) => defHttp.post({ url: Api.priceAdd, params });
export const editPrice = (params: Recordable) => defHttp.put({ url: Api.priceEdit, params });
export const deletePrice = (params: Recordable) => defHttp.delete({ url: Api.priceDelete, params }, { joinParamsToUrl: true });
```

---

### Task 11: 前端 — 子表 data 文件

**文件：**
- 创建: `jeecgboot-vue3/src/views/project/mes/basic/customer/contact.data.ts`
- 创建: `jeecgboot-vue3/src/views/project/mes/basic/customer/address.data.ts`
- 创建: `jeecgboot-vue3/src/views/project/mes/basic/customer/followUp.data.ts`
- 创建: `jeecgboot-vue3/src/views/project/mes/basic/customer/price.data.ts`

- [ ] **Step 1: 创建 contact.data.ts**

```typescript
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const contactColumns: BasicColumn[] = [
  { title: '姓名', dataIndex: 'name', width: 100 },
  { title: '职务', dataIndex: 'title', width: 100 },
  { title: '手机', dataIndex: 'phone', width: 130 },
  { title: '邮箱', dataIndex: 'email', width: 180 },
  { title: 'QQ/微信', dataIndex: 'social', width: 120 },
  { title: '默认', dataIndex: 'isDefault', width: 60, customRender: ({ value }) => (value ? '是' : '') },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const contactFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'name', label: '联系人姓名', component: 'Input', required: true, colProps: { span: 24 } },
  { field: 'title', label: '职务', component: 'Input', colProps: { span: 12 } },
  { field: 'phone', label: '手机', component: 'Input', colProps: { span: 12 } },
  { field: 'email', label: '邮箱', component: 'Input', colProps: { span: 12 } },
  { field: 'social', label: 'QQ/微信', component: 'Input', colProps: { span: 12 } },
  { field: 'isDefault', label: '是否默认', component: 'Switch', colProps: { span: 12 }, defaultValue: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
```

- [ ] **Step 2: 创建 address.data.ts**

```typescript
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const addressColumns: BasicColumn[] = [
  { title: '类型', dataIndex: 'addressType_dictText', width: 100 },
  { title: '联系人', dataIndex: 'contact', width: 100 },
  { title: '电话', dataIndex: 'phone', width: 130 },
  { title: '省/市/区', dataIndex: 'province', width: 200, customRender: ({ record }) => [record.province, record.city, record.district].filter(Boolean).join('/') },
  { title: '详细地址', dataIndex: 'detail', width: 250 },
  { title: '默认', dataIndex: 'isDefault', width: 60, customRender: ({ value }) => (value ? '是' : '') },
];

export const addressFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'addressType', label: '地址类型', component: 'JDictSelectTag', required: true, colProps: { span: 12 }, componentProps: { dictCode: 'address_type' } },
  { field: 'contact', label: '联系人', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'phone', label: '联系电话', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'province', label: '省', component: 'Input', colProps: { span: 8 } },
  { field: 'city', label: '市', component: 'Input', colProps: { span: 8 } },
  { field: 'district', label: '区', component: 'Input', colProps: { span: 8 } },
  { field: 'detail', label: '详细地址', component: 'InputTextArea', required: true, colProps: { span: 24 } },
  { field: 'isDefault', label: '是否默认', component: 'Switch', colProps: { span: 12 }, defaultValue: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
```

- [ ] **Step 3: 创建 followUp.data.ts**

```typescript
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const followUpColumns: BasicColumn[] = [
  { title: '跟进日期', dataIndex: 'followDate', width: 150 },
  { title: '跟进方式', dataIndex: 'followType_dictText', width: 100 },
  { title: '跟进内容', dataIndex: 'content', width: 250 },
  { title: '跟进人', dataIndex: 'follower', width: 100 },
  { title: '下次跟进', dataIndex: 'nextDate', width: 150 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const followUpFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'followType', label: '跟进方式', component: 'JDictSelectTag', required: true, colProps: { span: 12 }, componentProps: { dictCode: 'follow_type' } },
  { field: 'followDate', label: '跟进日期', component: 'DatePicker', required: true, colProps: { span: 12 }, componentProps: { showTime: true } },
  { field: 'content', label: '跟进内容', component: 'InputTextArea', required: true, colProps: { span: 24 }, componentProps: { rows: 4 } },
  { field: 'nextDate', label: '下次跟进日期', component: 'DatePicker', colProps: { span: 12 }, componentProps: { showTime: true } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
```

- [ ] **Step 4: 创建 price.data.ts**

```typescript
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const priceColumns: BasicColumn[] = [
  { title: '产品ID', dataIndex: 'productId', width: 150 },
  { title: '协议单价', dataIndex: 'price', width: 120 },
  { title: '生效日期', dataIndex: 'beginDate', width: 150 },
  { title: '失效日期', dataIndex: 'endDate', width: 150 },
  { title: '起订数量', dataIndex: 'minQty', width: 100 },
  { title: '截止数量', dataIndex: 'maxQty', width: 100 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const priceFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'productId', label: '产品ID', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'price', label: '协议单价', component: 'InputNumber', required: true, colProps: { span: 12 } },
  { field: 'beginDate', label: '生效日期', component: 'DatePicker', colProps: { span: 12 } },
  { field: 'endDate', label: '失效日期', component: 'DatePicker', colProps: { span: 12 } },
  { field: 'minQty', label: '起订数量', component: 'InputNumber', colProps: { span: 12 } },
  { field: 'maxQty', label: '截止数量', component: 'InputNumber', colProps: { span: 12 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
```

---

### Task 12: 前端 — 创建 4 个 Tab 组件

**文件：** 在 `jeecgboot-vue3/src/views/project/mes/basic/customer/` 下创建

- [ ] **Step 1: 创建 ContactTab.vue**

```vue
<template>
  <div>
    <a-button type="primary" size="small" preIcon="ant-design:plus-outlined" @click="handleAdd" style="margin-bottom:8px">新增联系人</a-button>
    <BasicTable @register="registerTable">
      <template #action="{ record }">
        <TableAction :actions="[{ label:'编辑', onClick:()=>handleEdit(record) },{ label:'删除', popConfirm:{ title:'确认删除?', confirm:()=>handleDelete(record) } }]" />
      </template>
    </BasicTable>
    <BasicDrawer v-bind="$attrs" @register="registerInnerDrawer" :title="innerTitle" width="500px" destroyOnClose :showFooter="true" @ok="handleInnerSubmit">
      <BasicForm @register="registerInnerForm" />
    </BasicDrawer>
  </div>
</template>
<script lang="ts" setup>
import { ref, computed, unref } from 'vue';
import { BasicTable, useTable, TableAction } from '/@/components/Table';
import { BasicForm, useForm } from '/@/components/Form';
import { BasicDrawer, useDrawer, useDrawerInner } from '/@/components/Drawer';
import { contactColumns, contactFormSchema } from './contact.data';
import { queryContactList, addContact, editContact, deleteContact } from './customer.api';

const props = defineProps<{ customerId: string }>();
const isUpdate = ref(false);
const [registerInnerForm, { resetFields, setFieldsValue, validate }] = useForm({ schemas: contactFormSchema, showActionButtonGroup: false, labelWidth: 100 });
const [registerInnerDrawer, { setDrawerProps, closeDrawer, openDrawer }] = useDrawer();
const innerTitle = computed(() => unref(isUpdate) ? '编辑联系人' : '新增联系人');

const [registerTable, { reload }] = useTable({
  api: queryContactList,
  columns: contactColumns,
  rowKey: 'id',
  beforeFetch: (params) => { params.customerId = props.customerId; return params; },
  showIndexColumn: false,
  showTableSetting: false,
  pagination: { pageSize: 10 },
  immediate: false,
});

function handleAdd() { isUpdate.value = false; resetFields(); openDrawer(true); }
function handleEdit(record: Recordable) { isUpdate.value = true; resetFields(); setFieldsValue({ ...record }); openDrawer(true); }
async function handleDelete(record: Recordable) { await deleteContact({ id: record.id }); reload(); }
async function handleInnerSubmit() {
  const values = await validate();
  isUpdate.value ? await editContact(values) : await addContact({ ...values, customerId: props.customerId });
  closeDrawer();
  reload();
}
defineExpose({ reload });
</script>
```

- [ ] **Step 2: 创建 AddressTab.vue**

> 同 ContactTab.vue 结构，替换为 addressColumns / addressFormSchema / address API。关键差异：`beforeFetch` 传 `customerId`。

类比 ContactTab 创建，核心差异：
- columns: `addressColumns`
- formSchema: `addressFormSchema`
- api: `queryAddressList / addAddress / editAddress / deleteAddress`
- title: "新增地址" / "编辑地址"

- [ ] **Step 3: 创建 FollowUpTab.vue**

> 同上，替换为 followUp 的 columns/form/api。

- [ ] **Step 4: 创建 PriceTab.vue**

> 同上，替换为 price 的 columns/form/api。

---

### Task 13: 前端 — 改造 CustomerDrawer.vue（Tab 布局）

**文件：**
- 修改: `jeecgboot-vue3/src/views/project/mes/basic/customer/CustomerDrawer.vue`

- [ ] **Step 1: 重写 CustomerDrawer.vue**

```vue
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="900px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <Tabs defaultActiveKey="info">
      <Tabs.TabPane tab="客户信息" key="info">
        <BasicForm @register="registerForm" />
      </Tabs.TabPane>
      <Tabs.TabPane tab="联系人" key="contact" v-if="customerId">
        <ContactTab ref="contactTabRef" :customerId="customerId" />
      </Tabs.TabPane>
      <Tabs.TabPane tab="地址" key="address" v-if="customerId">
        <AddressTab ref="addressTabRef" :customerId="customerId" />
      </Tabs.TabPane>
      <Tabs.TabPane tab="价格表" key="price" v-if="customerId">
        <PriceTab ref="priceTabRef" :customerId="customerId" />
      </Tabs.TabPane>
      <Tabs.TabPane tab="跟进记录" key="followUp" v-if="customerId">
        <FollowUpTab ref="followUpTabRef" :customerId="customerId" />
      </Tabs.TabPane>
    </Tabs>
  </BasicDrawer>
</template>

<script lang="ts" setup>
import { ref, computed, unref, nextTick } from 'vue';
import { Tabs } from 'ant-design-vue';
import { BasicForm, useForm } from '/@/components/Form/index';
import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
import { formSchema } from './customer.data';
import { saveOrUpdateCustomer } from './customer.api';
import ContactTab from './ContactTab.vue';
import AddressTab from './AddressTab.vue';
import FollowUpTab from './FollowUpTab.vue';
import PriceTab from './PriceTab.vue';

const emit = defineEmits(['success', 'register']);
const isUpdate = ref(false);
const customerId = ref('');

const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
  schemas: formSchema,
  showActionButtonGroup: false,
  labelWidth: 100,
  actionColOptions: { span: 24 },
});

const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
  await resetFields();
  isUpdate.value = !!data?.isUpdate;
  setDrawerProps({ confirmLoading: false });
  if (unref(isUpdate) && data.record) {
    customerId.value = data.record.id;
    await nextTick();
    await setFieldsValue({ ...data.record });
  } else {
    customerId.value = '';
  }
});

const getTitle = computed(() => (unref(isUpdate) ? '编辑客户' : '新增客户'));

async function handleSubmit() {
  const values = await validate();
  setDrawerProps({ confirmLoading: true });
  try {
    await saveOrUpdateCustomer(values, unref(isUpdate));
    closeDrawer();
    emit('success');
  } finally {
    setDrawerProps({ confirmLoading: false });
  }
}
</script>
```

- [ ] **Step 2: 类型检查**

```bash
cd jeecgboot-vue3 && npx vue-tsc --noEmit --project tsconfig.json 2>&1 | grep -i "customer" | head -10
```

---

### Task 14: 部署验证

- [ ] **Step 1: 编译后端**

```bash
cd jeecg-boot && mvn install -pl jeecg-boot-module/project-mes -am -DskipTests -Dmaven.test.skip=true
```

- [ ] **Step 2: 部署到服务器**

通过部署控制台 `http://100.122.125.106:3101` 执行"开始部署"。

- [ ] **Step 3: 验证后端 API**

```bash
TOKEN="<登录token>"
API="http://100.122.125.106:8080/jeecg-boot"

# 验证客户主表查询（含新字段）
curl -s "$API/mes/basic/customer/list?pageNo=1&pageSize=5" -H "X-Access-Token: $TOKEN" | python -c "import sys,json; r=json.load(sys.stdin); print('records:', len(r['result']['records']))"

# 验证联系人接口
curl -s "$API/mes/basic/customer/contact/list?customerId=xxx&pageNo=1" -H "X-Access-Token: $TOKEN"

# 验证地址接口
curl -s "$API/mes/basic/customer/address/list?customerId=xxx&pageNo=1" -H "X-Access-Token: $TOKEN"

# 验证跟进记录接口
curl -s "$API/mes/basic/customer/followUp/list?customerId=xxx&pageNo=1" -H "X-Access-Token: $TOKEN"

# 验证价格表接口
curl -s "$API/mes/basic/customer/price/list?customerId=xxx&pageNo=1" -H "X-Access-Token: $TOKEN"
```

- [ ] **Step 4: 前端功能验证**

1. 打开前端，进入 MES → 基础设置 → 客户管理
2. 验证搜索区新增字段（等级、业务员、行业、区域）
3. 新增客户 → 填写新字段 → 保存
4. 编辑客户 → 切换 Tab（联系人/地址/价格表/跟进记录）
5. 每个 Tab 验证：新增、编辑、删除

---

### Task 15: 更新 .manifest.yml

**文件：**
- 修改: `jeecg-boot/jeecg-boot-module/project-mes/.manifest.yml`

- [ ] **Step 1: 追加新增内容记录**

```yaml
  - table: c_mes_customer_contact, c_mes_customer_address, c_mes_customer_follow_up, c_mes_customer_price
  - controller: MesCustomerContactController, MesCustomerAddressController, MesCustomerFollowUpController, MesCustomerPriceController
  - dict: mes_customer_grade, mes_customer_industry, mes_customer_region, mes_customer_scale, address_type, follow_type, invoice_type
```

---

### Task 16: 提交代码

- [ ] **Step 1: 提交所有改动**

```bash
cd D:/vibeCoding/JeecgBoot
git add -A
git commit -m "$(cat <<'EOF'
feat: MES客户模块升级——新增等级/额度/归属/分类/财务+4子表

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

*实施计划 V1.0.0*  
*编制日期：2026-07-10*
