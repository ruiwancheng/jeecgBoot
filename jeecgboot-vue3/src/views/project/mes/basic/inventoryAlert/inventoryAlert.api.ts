import { defHttp } from '/@/utils/http/axios';
export const queryInventoryAlerts = () => defHttp.get({ url: '/mes/basic/inventoryAlert/list' });
