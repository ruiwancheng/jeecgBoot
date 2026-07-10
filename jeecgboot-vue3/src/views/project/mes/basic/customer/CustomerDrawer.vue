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
