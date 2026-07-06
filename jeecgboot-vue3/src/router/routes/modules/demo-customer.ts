import type { AppRouteModule } from '/@/router/types';
import { LAYOUT } from '/@/router/constant';
const demoCustomer: AppRouteModule = {
  path: '/customer/demo',
  name: 'CustomerDemo',
  component: LAYOUT,
  redirect: '/customer/demo/warehouse',
  meta: { orderNo: 9000, icon: 'ant-design:experiment-filled', title: 'demo客户' },
  children: [
    {
      path: 'warehouse',
      name: 'DemoWarehouseParent',
      component: LAYOUT,
      redirect: '/customer/demo/warehouse',
      meta: { title: '仓库' },
      children: [
        { path: 'index', name: 'DemoWarehouse', component: () => import('/@/views/customer/demo/warehouse/index.vue'), meta: { title: '仓库管理' } },
        {
          path: 'location',
          name: 'DemoLocation',
          component: () => import('/@/views/customer/demo/warehouse/location.vue'),
          meta: { title: '库位明细管理' },
        },
      ],
    },
  ],
};
export default demoCustomer;
