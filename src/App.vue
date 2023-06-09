<script setup>
// This starter template is using Vue 3 <script setup> SFCs
// Check out https://vuejs.org/api/sfc-script-setup.html#script-setup
import { ref, reactive } from 'vue'
const activeTab = ref('1-1');
const isCollapse = ref(false);
import {
  Document,
  Menu as IconMenu,
  Location,
  Setting,
} from '@element-plus/icons-vue'
</script>
<script>
  export default {
    mounted() {
      this.activeTab = location.href.split('/').at(-1) || '1-1';
    }
  }

</script>

<template>
  <div class="common-layout">
    <el-switch
      v-model="isCollapse"
      size="large"
      active-text="折叠"
      inactive-text="打开"
    />
    <el-container>
      <el-aside :width="isCollapse ? '70px' : '200px'">
        <h5 class="mb-2">Examples</h5>
        <el-menu
          :collapse="isCollapse"
          :default-active="activeTab"
        >
          <el-sub-menu index="1">
            <template #title>
              <el-icon><location /></el-icon>
              <span>文字渲染</span>
            </template>
            <el-menu-item-group title="SDF渲染">
              <el-menu-item index="1-1">
                <router-link to="/sdf">单文字渲染</router-link>
              </el-menu-item>
              <el-menu-item index="1-2">item two</el-menu-item>
            </el-menu-item-group>
            <el-menu-item-group title="Group Two">
              <el-menu-item index="1-3">item three</el-menu-item>
            </el-menu-item-group>
            <el-sub-menu index="1-4">
              <template #title>item four</template>
              <el-menu-item index="1-4-1">item one</el-menu-item>
            </el-sub-menu>
          </el-sub-menu>
        </el-menu>
      </el-aside>
      <el-main> <router-view></router-view> </el-main>
    </el-container>
  </div>
</template>


<style>
html, body { width: 100%; height: 100% }
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  width: 100%;
  height: 100%;
}
</style>
