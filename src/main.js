import * as VueRouter from 'vue-router'
import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import LineJoinCap from './components/line/antialise/LineJoinCap.vue'
import CubeShadow from './components/shadow/CubeShadow.vue'
import SDF from './components/glyph/sdf.vue'

import App from './App.vue'

const routes = [
  { path: '/sdf', component:  SDF },
  { path: '/CubeShadow', component: CubeShadow },
  { path: '/LineJoinCap', component: LineJoinCap },
];
const router = VueRouter.createRouter({
  // 4. 内部提供了 history 模式的实现。为了简单起见，我们在这里使用 hash 模式。
  history: VueRouter.createWebHashHistory(),
  routes, // `routes: routes` 的缩写
})

const app = createApp(App);
app.use(router);
app.use(ElementPlus);
app.mount('#app')
