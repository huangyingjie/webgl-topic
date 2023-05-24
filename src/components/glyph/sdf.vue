<script setup>
  function loadTexture(gl, texture, image, u_Sampler, canvas) {
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1); // 翻转Y轴
    // 纹理序号，mac上达到了31号
    // 默认绑定0号，所以可以不写
    gl.activeTexture(gl.TEXTURE31);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    // 配置纹理参数
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    // 配置纹理对象
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, canvas.width, canvas.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image);
    // 将0号纹理传给取样器变量
    gl.uniform1i(u_Sampler, 31);
  }
</script>
<script>
  import Pbf from "pbf";
  import * as Glyphs from "./glyphs.js";
  import * as twgl from 'twgl.js'
  import vertexShaderSource from './sdf.vert.glsl';
  import fragmentShaderSource from './sdf.frag.glsl';
  import { mat4, mat3, vec3 } from 'gl-matrix';
  import { mul } from '@/util/matrix.js'
  import calcSdf from 'bitmap-sdf';

  export default {
    methods: {
      drawSDF() {
        //draw image
        let canvas = this.$refs.container2;
        let w = canvas.width = 30, h = canvas.height = 30
        let ctx = canvas.getContext('2d')
        ctx.fillStyle = 'white'
        ctx.font = 'bold 30px sans-serif'
        ctx.fillText('中', 0, 30)

        //calculate distances
        let arr = calcSdf(canvas)

        //show distances
        let imgArr = new Uint8ClampedArray(w*h*4)
        for (let i = 0; i < w; i++) {
          for (let j = 0; j < h; j++) {
            imgArr[j*w*4 + i*4 + 0] = arr[j*w+i]*255
            imgArr[j*w*4 + i*4 + 1] = arr[j*w+i]*255
            imgArr[j*w*4 + i*4 + 2] = arr[j*w+i]*255
            imgArr[j*w*4 + i*4 + 3] = 255
          }
        }
        var data = new ImageData(imgArr, w, h)
        ctx.putImageData(data, 0, 0)
        ctx.width = w;
        ctx.height = h;
        //console.log(imgArr, '------');
        this.toBlobUrl(imgArr);
        return { ctx, img: imgArr };
      },
      toBlobUrl(array) {
        let blob = new Blob([array], { type: 'image/jpeg' })
        array = null;
        let url = URL.createObjectURL(blob);
        console.log(url);
      },
      async getGlyph(letter) {
        const url = 'https://api-map04.meituan.com/tile/font?key=god&id=Source%20Han%20Sans%20CN%20Normal&glyphs=' + letter.charCodeAt(0);
        const buffer = await fetch(url, { responseType: 'arraybuffer' }).then(res => res.arrayBuffer());
        var pbf = new Pbf(buffer);
        var obj = Glyphs.glyphs.read(pbf);
        return obj.stacks[0].glyphs;
      },
      createImage(glyph) {
        let { width, height, bitmap } = glyph;
        const padding= 6; // 边距
        width += padding;
        height += padding;
        const nPix = width * height;
        const arr = new Uint8ClampedArray(nPix * 4);
        for (var i = 0; i < nPix; i++) {
          arr[4 * i + 0] = bitmap[i];
        }
        return {
          ctx: {
            width,
            height
          },
          img: arr
        };
      }
    },
    async mounted() {
      const { container } = this.$refs;
      const gl = container.getContext('webgl2');
      if (!gl) {
        return;
      }
      const letter = '中';
      const glyphs = await this.getGlyph(letter);
      const glyph = glyphs[0];
      console.log('glyph:', glyph);
      const rs = this.createImage(glyph);
      //const rs = this.drawSDF();

      //this.resize(container);
      twgl.resizeCanvasToDisplaySize(gl.canvas, window.devicePixelRatio)
      gl.viewport(0, 0, container.width, container.height);
      gl.clearColor(0.1, 0.1, 0.1, 1);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      const program = twgl.createProgramInfo(gl, [vertexShaderSource, fragmentShaderSource]).program;
      gl.useProgram(program);

      const u_Sampler = gl.getUniformLocation(program, 'u_sampler2D');
      const texture = gl.createTexture();
      this.loadTexture(gl, texture, rs.img, u_Sampler, rs.ctx);

      const fontSize = 512.0;
      const factor = 2; // 将平面坐标转为顶点坐标
      const offset = 200.;
      const verticesTexture = new Float32Array([
        -offset * factor / container.width, offset * factor / container.height, 0, 1.0,
        (-offset + fontSize)  * factor / container.width, offset * factor / container.height, 1.0, 1.0,
        -offset * factor / container.width, (offset - fontSize) * factor / container.height, 0.0, 0.0,
        (-offset + fontSize) * factor / container.width, (offset - fontSize) * factor / container.height, 1.0, 0.0
      ]);
      const buffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.bufferData(gl.ARRAY_BUFFER, verticesTexture, gl.STATIC_DRAW);

      gl.uniform1f(gl.getUniformLocation(program, 'u_gamma'), 0.05); // 增加抗锯齿效果
      gl.uniform1f(gl.getUniformLocation(program, 'u_buffer'), 192/256);
      gl.uniform4fv(gl.getUniformLocation(program, 'u_color'), [0, 0, 1, 1]);

      const FILE_SIZE = verticesTexture.BYTES_PER_ELEMENT;

      const positionLoaction = gl.getAttribLocation(program, 'a_position');
      gl.enableVertexAttribArray(positionLoaction);
      gl.vertexAttribPointer(positionLoaction, 2, gl.FLOAT, false, 4 * FILE_SIZE, 0); 

      const texCoordLoaction = gl.getAttribLocation(program, 'a_textCoord');
      gl.enableVertexAttribArray(texCoordLoaction);
      gl.vertexAttribPointer(texCoordLoaction, 2, gl.FLOAT, false, 4 * FILE_SIZE, 2 * FILE_SIZE); 
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    },
    unmounted() {
    }
  };
</script>
<template>
  <canvas class="gl" width='400' height='300' ref="container"></canvas>
  <canvas ref="container2" style="display: none"></canvas>

</template>
<style scoped>
canvas.gl {
  width: 800px;
  height: 400px;
}
</style>
