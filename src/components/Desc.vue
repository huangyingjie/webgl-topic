<script setup>
  import { defineProps,toRefs, reactive } from 'vue';
  const props = defineProps({
    desc: String,
    sourceUrl: String
  })
  const { sourceUrl } = toRefs(props);
  const baseUrl = 'https://github.com/huangyingjie/webgl-topic/blob/master/src/components';
</script>
<script>
  export default {
  };
</script>
<template>
  <div id="desc">
    <el-text class="mx-1" type="primary"> <slot></slot> </el-text>
    <p><el-link type="success" :href="baseUrl + sourceUrl" target="_blank">源码地址</el-link></p>
  </div>
</template>
<style scoped>
</style>
