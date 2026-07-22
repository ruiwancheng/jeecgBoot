# [2026-07-20] [后端] JSearchSelect表字典绕过@TableLogic — 下拉与列表数据不一致

## 触发条件
前台下拉选择（JSearchSelect + `dict="c_mes_xxx,text,value"`）显示的选项与对应管理页面列表不一致。

## 根因
`JSearchSelect` 通过 `SysDictController.loadDict()` 加载表字典数据，最终走 `SysDictMapper.xml` 中的**原始SQL拼接**：
```sql
SELECT name as "text", id as "value" FROM c_mes_material WHERE name LIKE '%keyword%'
```

这段SQL通过 `${table}` `${text}` `${code}` 占位符拼接，**完全绕过 MyBatis-Plus 的 `@TableLogic` 拦截器**，不会自动追加 `WHERE del_flag=0`。

而管理页面的 `Controller.list()` 使用 MyBatis-Plus 标准分页，自动获得 `del_flag=0` 过滤。

**结论：** 任何使用 `dict="表名,text字段,value字段"` 的表字典选择器，都会显示已逻辑删除的数据。

## 修复方式

### 方案 A：新增专用端点（推荐，不碰平台代码）
```java
@GetMapping("/selectPage")
public Result<IPage<MesMaterial>> selectPage(...) {
    QueryWrapper<MesMaterial> qw = new QueryWrapper<>();
    qw.eq("status", 1); // 额外过滤停用
    // MyBatis-Plus标准分页自动加 del_flag=0
    return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
}
```
+ 前端弹窗组件替换 JSearchSelect。

### 方案 B：改平台代码（不推荐，违反 file-scope）
修改 `SysDictServiceImpl.queryLittleTableDictItems()` 或 `SysDictMapper.xml` 加 `del_flag=0`。
**违规原因：** `jeecg-system-biz` 在受保护目录。

## 适用范围
所有用到 `@TableLogic` 的实体，如果同时被 JSearchSelect 作为表字典引用（`dict="表名,text,value"`），都有相同问题。包括但不限于：物料、仓库、客户、供应商、库位等。
## 关联
- ✅ 已覆盖: code-style.md JSearchSelect 表字典
