import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import cesium from 'vite-plugin-cesium';
import alias from '@rollup/plugin-alias';
import { resolve } from 'path';
import glsl from 'vite-plugin-glsl';
import { viteCommonjs } from '@originjs/vite-plugin-commonjs';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue(), glsl(), viteCommonjs(), cesium(), alias()],
  resolve: {
    alias: {
      "@": resolve(resolve(__dirname), "src"),
    }
  }
})
