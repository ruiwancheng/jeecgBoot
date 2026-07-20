import { LAYOUT } from '/@/router/constant';
import type { AppRouteModule } from '/@/router/types';

const mes: AppRouteModule = {
  path: '/project/mes',
  name: 'mes',
  component: LAYOUT,
  redirect: '/project/mes/index',
  meta: { orderNo: 9000, title: 'MES', icon: 'ion:grid-outline' },
  children: [
    {
      path: 'index',
      name: 'MesIndex',
      component: () => import('/@/views/project/mes/index.vue'),
      meta: { title: 'MES首页' },
    },
    {
      path: 'basic',
      name: 'MesBasic',
      component: LAYOUT,
      redirect: '/project/mes/basic/warehouse',
      meta: { title: '基础设置' },
      children: [
        {
          path: 'warehouse',
          name: 'MesBasicWarehouse',
          component: () => import('/@/views/project/mes/basic/warehouse/index.vue'),
          meta: { title: '仓库管理' },
        },
        {
          path: 'location',
          name: 'MesBasicLocation',
          component: () => import('/@/views/project/mes/basic/location/index.vue'),
          meta: { title: '库位管理' },
        },
        {
          path: 'customer',
          name: 'MesBasicCustomer',
          component: () => import('/@/views/project/mes/basic/customer/index.vue'),
          meta: { title: '客户管理' },
        },
        {
          path: 'supplier',
          name: 'MesBasicSupplier',
          component: () => import('/@/views/project/mes/basic/supplier/index.vue'),
          meta: { title: '供应商管理' },
        },
        {
          path: 'material',
          name: 'MesBasicMaterial',
          component: () => import('/@/views/project/mes/basic/material/index.vue'),
          meta: { title: '物料管理' },
        },
        //update-begin---author:ruiwancheng---date:2026-07-21  for：编码规则路由注册-----------
        {
          path: 'codeRule',
          name: 'MesBasicCodeRule',
          component: () => import('/@/views/project/mes/basic/codeRule/index.vue'),
          meta: { title: '编码规则' },
        },
        //update-end---author:ruiwancheng---date:2026-07-21  for：编码规则路由注册-----------
        },
      ],
    },
    {
      path: 'sales',
      name: 'MesSales',
      component: LAYOUT,
      redirect: '/project/mes/sales/price',
      meta: { title: '销售管理' },
      children: [
        {
          path: 'price',
          name: 'MesSalesPrice',
          component: () => import('/@/views/project/mes/sales/price/index.vue'),
          meta: { title: '价格管理' },
        },
      ],
    },
    {
      path: 'purchase',
      name: 'MesPurchase',
      component: LAYOUT,
      redirect: '/project/mes/purchase/apply',
      meta: { title: '采购管理' },
      children: [
        {
          path: 'apply',
          name: 'MesPurchaseApply',
          component: () => import('/@/views/project/mes/purchase/apply/index.vue'),
          meta: { title: '采购申请' },
        },
        {
          path: 'order',
          name: 'MesPurchaseOrder',
          component: () => import('/@/views/project/mes/purchase/order/index.vue'),
          meta: { title: '采购订单' },
        },
        {
          path: 'receipt',
          name: 'MesPurchaseReceipt',
          component: () => import('/@/views/project/mes/purchase/receipt/index.vue'),
          meta: { title: '采购入库' },
        },
      ],
    },
    {
      path: 'manufacturing',
      name: 'MesManufacturing',
      component: LAYOUT,
      redirect: '/project/mes/manufacturing/bom',
      meta: { title: '生产制造' },
      children: [
        { path: 'bom', name: 'MesBom', component: () => import('/@/views/project/mes/manufacturing/bom/index.vue'), meta: { title: 'BOM管理' } },
        { path: 'order', name: 'MesProductionOrder', component: () => import('/@/views/project/mes/manufacturing/order/index.vue'), meta: { title: '生产订单' } },
        { path: 'picking', name: 'MesProductionPicking', component: () => import('/@/views/project/mes/manufacturing/picking/index.vue'), meta: { title: '生产领料' } },
        { path: 'completion', name: 'MesCompletionReceipt', component: () => import('/@/views/project/mes/manufacturing/completion/index.vue'), meta: { title: '完工入库' } },
      ],
    },
    {
      path: 'warehouse',
      name: 'MesWarehouse',
      component: LAYOUT,
      redirect: '/project/mes/warehouse/ledger',
      meta: { title: '仓储管理' },
      children: [
        {
          path: 'ledger',
          name: 'MesInventoryLedger',
          component: () => import('/@/views/project/mes/purchase/ledger/index.vue'),
          meta: { title: '库存台账' },
        },
      ],
    },
  ],
};
export default mes;
