import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import alias from '@rollup/plugin-alias';
import { resolve } from 'path';
import glsl from 'vite-plugin-glsl';
import { viteCommonjs } from '@originjs/vite-plugin-commonjs';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue(), glsl(), viteCommonjs(), alias()],
  base: '/webgltopic',
  resolve: {
    alias: {
      "@": resolve(resolve(__dirname), "src"),
    }
  }
})
