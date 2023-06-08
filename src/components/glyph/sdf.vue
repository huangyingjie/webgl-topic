<script setup>
  function loadTexture(gl, texture, image, u_Sampler, canvas) {
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1); // 翻转Y轴
    // 默认绑定0号，所以可以不写
    gl.bindTexture(gl.TEXTURE_2D, texture);
    // 配置纹理参数
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    // 配置纹理对象
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, canvas.width, canvas.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image);
    // 将0号纹理传给取样器变量
    gl.uniform1i(u_Sampler, 0);
  }
  const gl = null;
</script>
<script>
  import Pbf from "pbf";
  import TinySDF from '@mapbox/tiny-sdf';
  import * as Glyphs from "./glyphs.js";
  import * as twgl from 'twgl.js'
  import vertexShaderSource from './sdf.vert.glsl';
  import fragmentShaderSource from './sdf.frag.glsl';
  import { mat4, mat3, vec3 } from 'gl-matrix';
  import { mul } from '@/util/matrix.js'
  import calcSdf from 'bitmap-sdf';

  export default {
    data: function() {
      return {
        showDomText: 1,
        domFontTop: 113,
        domFontLeft: 411,
        fontSize: 96,
        fontFamily: 'Source Han Sans CN Normal',
        baselineAdjustment: 28.5,
        glyphType: 1,
        letter: '家',
        u_buffer: 0.75
      };
    },
    watch: {
      async baselineAdjustment() {
        if (!this.letter) {
          return;
        }
        this.localGlyphs = await this.getGlyphByTinyGlyph(this.letter, 2);
        this.drawScene();
      },
      async letter() {
        if (!this.letter) {
          return;
        }
        this.localGlyphs = await this.getGlyphByTinyGlyph(this.letter, 2);
        this.remoteGlyphs = await this.getGlyph(this.letter);
        this.drawScene();
      },
      async fontFamily() {
        if (this.fontFamily != 'Source Han Sans CN Normal') {
          this.glyphType = 1;
        }
        this.localGlyphs = await this.getGlyphByTinyGlyph(this.letter, 2);
        this.remoteGlyphs = await this.getGlyph(this.letter);
        this.drawScene();
      }
    },
    methods: {
      getGlyphByTinyGlyph(letter, SDF_SCALE) {
        const fontFamily = this.fontFamily;
        const fontSize = 24 * SDF_SCALE; // 放大fontSize，提高文字顶点数量
        const radius = 8 * SDF_SCALE; // 文字边缘圆润程度
        const buffer = 3 * SDF_SCALE;

        const tinySDF = new TinySDF({fontFamily, fontSize, buffer, radius});
        const { baselineAdjustment } = this;
        const glyphs = letter.split('').map(char => ({ id: char.charCodeAt(0), glyph: tinySDF.draw(char) })).map(({id, glyph}) => {
          const {
            data, width, height, glyphWidth, glyphHeight, glyphLeft, glyphTop, glyphAdvance
          } = glyph;
          // 以24像素字号为基准，返回其规格
          return {
            id,
            bitmap: data,
            width: glyphWidth / SDF_SCALE, // 文字实际宽度，不含border
            height: glyphHeight / SDF_SCALE,// 文字实际高度，不含border
            left: glyphLeft / SDF_SCALE,// 文字位移
            top: glyphTop / SDF_SCALE - baselineAdjustment,// 文字位移
            advance: glyphAdvance / SDF_SCALE, // 文字排版间距
          };
        });
        return glyphs;
      },

      async getGlyph(letter) {
        const url = 'https://api-map04.meituan.com/tile/font?key=god&id=Source%20Han%20Sans%20CN%20Normal&glyphs=' + letter.charCodeAt(0);
        const buffer = await fetch(url, { responseType: 'arraybuffer' }).then(res => res.arrayBuffer());
        var pbf = new Pbf(buffer);
        var obj = Glyphs.glyphs.read(pbf);
        return obj.stacks[0].glyphs;
      },
      createImage(glyph, SDF_SCALE = 1) {
        let { width, height, bitmap } = glyph;
        const border = 3; // 边距
        const imgWidth = width * SDF_SCALE + border * SDF_SCALE * 2;
        const imgHeight = height * SDF_SCALE + border * SDF_SCALE * 2;

        const nPix = imgWidth * imgHeight;
        const arr = new Uint8ClampedArray(nPix * 4);
        for (var i = 0; i < nPix; i++) {
          arr[4 * i + 0] = bitmap[i];
        }
        return {
          ctx: {
            width: imgWidth,
            height: imgHeight
          },
          img: arr
        };
      },
      async drawScene() {
        const { gl, program, container } = this;
        gl.clearColor(0.1, 0.1, 0.1, 1);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        if (!this.letter) {
          return;
        }
        const SDF_SCALE = this.glyphType == 1 ? window.devicePixelRatio : 1;
        let glyphs = null;
        if (this.glyphType == 1) {
          glyphs = this.localGlyphs;
        } else {
          glyphs = this.remoteGlyphs;
        }
        const glyph = glyphs[0];
        const rs = this.createImage(glyph, SDF_SCALE);

        const u_Sampler = gl.getUniformLocation(program, 'u_sampler2D');
        const texture = gl.createTexture();
        this.loadTexture(gl, texture, rs.img, u_Sampler, rs.ctx);

        const factor = window.devicePixelRatio;
        const border = 3;
        const fontScale = this.fontSize / 24;
        const fontWidth = (glyph.width + 2 * border) * fontScale;
        const fontHeight = (glyph.height + 2 * border) * fontScale;
        
        // 文字顶点和纹理坐标
        const anchorX = 0 + fontScale * glyph.left;
        const anchorY = 100 + fontScale * glyph.top;//因为纹理已经翻转了，所以正常+top即可
        const verticesTexture = new Float32Array([
         2 * anchorX * factor / container.width, 2 *anchorY * factor / container.height, 0, 1.0,
         2 * (anchorX + fontWidth)  * factor / container.width, 2 * anchorY * factor / container.height, 1.0, 1.0,
         2 * anchorX * factor / container.width, 2 * (anchorY - fontHeight) * factor / container.height, 0.0, 0.0,
         2 * (anchorX + fontWidth) * factor / container.width, 2 * (anchorY - fontHeight) * factor / container.height, 1.0, 0.0
        ]);
        const buffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
        gl.bufferData(gl.ARRAY_BUFFER, verticesTexture, gl.STATIC_DRAW);

        gl.uniform1f(gl.getUniformLocation(program, 'u_gamma'), 0.05 / fontScale); // 增加抗锯齿效果
        gl.uniform1f(gl.getUniformLocation(program, 'u_buffer'), this.u_buffer);
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
      }
    },
    async mounted() {
      const { container } = this.$refs;
      const gl = container.getContext('webgl2');
      if (!gl) {
        return;
      }
      this.gl = gl;
      this.container = container;
      twgl.resizeCanvasToDisplaySize(gl.canvas, window.devicePixelRatio)
      gl.viewport(0, 0, container.width, container.height);
      this.program = twgl.createProgramInfo(gl, [vertexShaderSource, fragmentShaderSource]).program;
      gl.useProgram(this.program);

      const letter = '家';
      this.localGlyphs = await this.getGlyphByTinyGlyph(letter, 2);
      this.remoteGlyphs = await this.getGlyph(letter);
      this.drawScene();
    },
    unmounted() {
    }
  };
</script>
<template>
  <div id="ctn">
    <div class="glyphs" style="position:relative;">
      <canvas class="gl" width='400' height='300' ref="container"></canvas>
      <div class="fonts" v-show="showDomText == 1" :style="{top: domFontTop + 'px', left: domFontLeft + 'px', fontSize: fontSize + 'px', fontFamily: fontFamily}">
        {{letter}}
      </div>
    </div>
    <div class="btns">
      <p>
        本例默认以<a href="https://github.com/adobe-fonts/source-han-sans/releases/download/2.004R/SourceHanSansCN.zip" target="blank" >思源黑体</a>演示，需提前安装
      </p>
      <div>
      <input type="range" style="width:300px" step="0.01" min="0.1" max="1" id="buffer" v-model="u_buffer" @input="drawScene" /> Buffer: {{u_buffer}}
      <input type="range" style="width:300px" v-model="fontSize" step="1" min="12" max="200" id="fontSize" @input="drawScene" /> fontSize: {{fontSize}}px
      </div>
      <p>
      <input type="checkbox" id="showDomText" v-model="showDomText" true-value="1" false-value="0"  />
      <label for="showDomText"> 显示对照DOM文本 </label>
      </p>
      <div v-show="showDomText == 1">
        <input type="range" style="width:300px" v-model="domFontLeft" step="1" min="0" max="800" @input="drawScene" /> left坐标: {{domFontLeft}}px
        <input type="range" style="width:300px" v-model="domFontTop" step="1" min="-100" max="300" @input="drawScene" /> top坐标: {{domFontTop}}px
      </div>
      <p> 数据源 </p>
      <div>
        <input type="radio" id="one" value="1" v-model.number="glyphType" @change="drawScene" />
        <label for="one"> 本地字体 </label>
        <input type="radio" :disabled="fontFamily !=='Source Han Sans CN Normal'" id="two" value="2" v-model.number="glyphType" @change="drawScene" />
        <label for="two">远程字体(当前只支持思源黑体)</label>
      </div>
      <div>
        <p>
        本地/远程top对齐存在差异，需减去一个常量调和:
        </p>
        <input type="range" style="width:300px" v-model="baselineAdjustment" step="0.5" min="26" max="30" /> {{baselineAdjustment}}
      </div>
      <div>
        <p>
        切换字体
        </p>
        <input type="radio" id="sourceHan" value="Source Han Sans CN Normal" v-model="fontFamily" />
        <label for="sourceHan"> 思源黑体 </label>
        <input type="radio" id="kaiti" value="STKaiti" v-model="fontFamily" />
        <label for="kaiti"> 楷体 </label>
        <input type="radio" id="yahei" value="Microsoft YaHei" v-model="fontFamily" />
        <label for="yahei"> 微软雅黑 </label>
        <input type="radio" id="xingkai" value="STXingkaiSC-Light" v-model="fontFamily" />
        <label for="xingkai"> 行楷 </label>
      </div>
      <div>
        <p>
        切换文字
        </p>
        <input type="text" v-model="letter" @input="drawScene" />：当前示例仅支持单个文字
      </div>
    </div>
  </div>

</template>
<style scoped>
#ctn {
  display: flex;
}
canvas.gl {
  width: 800px;
  height: 400px;
}
.fonts {
  position: absolute;
  /*font-family: "STKaiti";*/
  font-family: "Source Han Sans CN Normal";
  font-size: 96px;
  color:red;
  border:1px solid white;
}
.btns {
  padding: 10px;
}
</style>
