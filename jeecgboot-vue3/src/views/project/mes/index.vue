<template>
  <div class="mes-home">
    <a-card :bordered="false">
      <div class="mes-welcome">
        <h2>MES 项目</h2>
        <p>欢迎使用 MES 管理系统</p>
      </div>
    </a-card>
  </div>
</template>

<script setup lang="ts">
defineOptions({ name: 'MesHome' });
</script>

<style scoped>
.mes-home {
  padding: 24px;
}

.mes-welcome {
  text-align: center;
  padding: 60px 0;
}

.mes-welcome h2 {
  font-size: 24px;
  color: #1d2129;
  margin-bottom: 16px;
}

.mes-welcome p {
  font-size: 16px;
  color: #86909c;
}
</style>
