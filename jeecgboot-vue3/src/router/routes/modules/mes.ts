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
      ],
    },
  ],
};
export default mes;
