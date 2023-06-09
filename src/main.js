import * as VueRouter from 'vue-router'
import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import App from './App.vue'

const routes = [
  { path: '/sdf', component:  () => import('./components/glyph/sdf.vue') },
  { path: '/CubeShadow', component: () => import('./components/shadow/CubeShadow.vue') },
  { path: '/LineJoinCap', component: () => import('./components/line/antialise/LineJoinCap.vue') },
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
