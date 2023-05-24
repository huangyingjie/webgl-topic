<script setup>
// This starter template is using Vue 3 <script setup> SFCs
// Check out https://vuejs.org/api/sfc-script-setup.html#script-setup
import { ref, reactive } from 'vue'
import LineJoinCap from './components/line/antialise/LineJoinCap.vue'
import CubeShadow from './components/shadow/CubeShadow.vue'
import SDF from './components/glyph/sdf.vue'
</script>
<script>
  export default { }

</script>

<template>
  <CubeShadow />
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
