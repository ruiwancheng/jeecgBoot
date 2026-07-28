<template>
  <a-layout style="background:#fff; min-height: calc(100vh - 120px)">
    <a-layout-sider width="240" style="background:#fff; border-right:1px solid #f0f0f0">
      <div style="padding:16px; font-weight:600">单据页黄金模板 · 10 模式</div>
      <a-menu v-model:selectedKeys="selected" mode="inline">
        <a-menu-item v-for="m in modes" :key="m.id">{{ m.id }}. {{ m.title }}</a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout-content style="padding:16px">
      <a-alert
        type="success"
        show-icon
        style="margin-bottom:12px"
        message="本页所有组件均为生产真实组件（BasicTable/BasicForm/JMaterialSelect/MaterialSelectModal），数据为演示假数据；物料弹窗调真实接口。"
      />
      <component :is="currentDemo" />
    </a-layout-content>
  </a-layout>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import DemoListPage from './DemoListPage.vue';
  import DemoDrawerPatterns from './DemoDrawerPatterns.vue';
  import DemoSubTable from './DemoSubTable.vue';

  defineOptions({ name: 'MesTemplateGallery' });

  const modes = [
    { id: 1, title: '搜索区下拉（字典+仓库）', demo: 'list' },
    { id: 2, title: '复选框+批量审核（状态守卫）', demo: 'list' },
    { id: 3, title: '明细子表展开行', demo: 'sub' },
    { id: 4, title: '抽屉+自动编码接线', demo: 'drawer' },
    { id: 5, title: '明细行编辑（数量单价金额）', demo: 'drawer' },
    { id: 6, title: '批量添加物料+成本预填', demo: 'drawer' },
    { id: 7, title: '审核状态机按钮', demo: 'list' },
    { id: 8, title: '快照/口径 Alert 提示', demo: 'drawer' },
    { id: 9, title: '差异红标高亮', demo: 'drawer' },
    { id: 10, title: '删除 popConfirm+操作列守卫', demo: 'list' },
  ];
  const selected = ref([1]);
  const currentDemo = computed(() => {
    const d = modes.find((m) => m.id === selected.value[0])?.demo;
    return d === 'sub' ? DemoSubTable : d === 'drawer' ? DemoDrawerPatterns : DemoListPage;
  });
</script>
