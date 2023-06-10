<script setup>
  import Desc from '@/components/Desc.vue';
  const path = [[0, 210], [200, 200], [400, 400], [600, 200], [800, 210], [700, 300]];
  //const path = [[0, 200], [200, 200],];
</script>
<script>
import vertexShaderSource from './LineJoinCap.vert.glsl';
import fragmentShaderSource from './LineJoinCap.frag.glsl';
import { mat4, vec4 } from 'gl-matrix'
import Stats from 'stats.js';
import { mul } from '@/util/matrix.js'
import * as twgl from 'twgl.js';


const CAP_ROUND = 0;
// 存在默认抗锯齿问题
const CAP_BUTT = 1;
const CAP_SQUARE = 2;
const JOIN_ROUND = 0;
const JOIN_BEVEL = 1;
const JOIN_MITER = 2;
export default {
  methods: {
    initArrayBuffer(gl, program, data, size, attribute) {
      const buffer = gl.createBuffer();
      if (!buffer) {
        return false;
      }
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW);
      const attributeLocation = gl.getAttribLocation(program, attribute);
      gl.enableVertexAttribArray(attributeLocation);
      gl.vertexAttribPointer(attributeLocation, size, gl.FLOAT, false, 0, 0);
      return attributeLocation;
    },
    getCircleDir(n) {
      const result = [];
      for (let i = 1; i <= n + 1; i++) {
        result.push([0, 0]);
        result.push([i, 0]);
        result.push([i + 1, 0]);
      }
      result.push([0, 0]);
      result.push([n + 2, 0]);
      result.push([1, 0]);
      return result;
    },
    getCapDir(capType) {
      const { path, getCircleDir } = this;
      const vertices = [];
      // webgl不支持动态设置数组size，所以必须手动同步shader
      const capRoundVerticeNum = 10;
      vertices[CAP_ROUND] = getCircleDir(capRoundVerticeNum);
      vertices[CAP_SQUARE] = [
        [0, 0],
        [1, 0],
        [2, 0],
        [0, 0],
        [2, 0],
        [3, 0],
        [0, 0],
        [3, 0],
        [4, 0],
      ];
      vertices[CAP_BUTT] = vertices[CAP_SQUARE].slice();
      return vertices[capType];
    },
    getJoinDir(joinType) {
      const { path, getCircleDir } = this;
      const vertices = [];
      // webgl不支持动态设置数组size，所以必须手动同步shader
      const capRoundVerticeNum = 10;
      vertices[JOIN_ROUND] = getCircleDir(capRoundVerticeNum);
      vertices[JOIN_MITER] = [
        [0, 0],
        [1, 0],
        [2, 0],
        [0, 0],
        [2, 0],
        [3, 0],
        [0, 0],
        [3, 0],
        [4, 0],
        [0, 0],
        [4, 0],
        [1, 0],
      ];
      vertices[JOIN_BEVEL] = vertices[JOIN_MITER].slice();
      return vertices[joinType];
    }
  },
  // 希望在一个shader、一次drawcall中完成line/cap/join的绘制；
  // 通过实例化渲染，通过传入3组不同的顶点方向参数，组合起来l
  mounted() {
    const { container } = this.$refs;
    const gl = container.getContext('webgl', { antialias: false }) || container.getContext('experimental-webgl');
    if (!gl) {
      return;
    }

    const instanceExt = gl.getExtension('ANGLE_instanced_arrays');
    twgl.resizeCanvasToDisplaySize(gl.canvas, window.devicePixelRatio)
    //gl.clearColor(1.0, 1.0, 1.0, 1.0);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.viewport(0, 0, container.width, container.height);

    const modelMatrix = mat4.create();

    const viewMatrix = mat4.create();
    mat4.lookAt(viewMatrix, [0,0,4], [0,0,0], [0,1,0]);

    const projectMatrix = mat4.create();
    mat4.perspective(projectMatrix, 30 * Math.PI / 180, container.width/container.height, 1, 100);

    const { getCapDir, getJoinDir, project, initArrayBuffer, path } = this;

    function drawLine(gl, program) {
      let capType = CAP_ROUND;
      let joinType = JOIN_ROUND;

      gl.useProgram(lineProgram);
      gl.clear(gl.COLOR_BUFFER_BIT);
      function flatten(array) {
        return array.reduce((rs, next) => rs.concat(next), []);
      }

      let positions = path.slice();
      // 设置宽度
      gl.uniform1f(gl.getUniformLocation(program, 'thickness'), 40); // 过厚则出现折叠自相交现象
      gl.uniform1f(gl.getUniformLocation(program, 'miterlimit'), 15);
      gl.uniform1i(gl.getUniformLocation(program, 'joinType'), joinType);
      gl.uniform1i(gl.getUniformLocation(program, 'capType'), capType);
      gl.uniform1f(gl.getUniformLocation(program, 'aspect'), container.width / container.height);
      gl.uniform2fv(gl.getUniformLocation(program, 'resolution'), [container.width, container.height]);
      gl.uniform1f(gl.getUniformLocation(program, 'dpr'), window.devicePixelRatio);

      gl.uniformMatrix4fv(gl.getUniformLocation(program, 'model'), false, modelMatrix);
      gl.uniformMatrix4fv(gl.getUniformLocation(program, 'view'), false, viewMatrix);
      gl.uniformMatrix4fv(gl.getUniformLocation(program, 'projection'), false, projectMatrix);

      let loc = initArrayBuffer(gl, program, new Float32Array(flatten(positions)), 2, 'position');
      instanceExt.vertexAttribDivisorANGLE(loc, 1);

      const nextVertices = path.slice(1).concat([path.at(-1)]);
      loc = initArrayBuffer(gl, program, new Float32Array(flatten(nextVertices)), 2, 'next');
      instanceExt.vertexAttribDivisorANGLE(loc, 1);

      const lastVertices = path.slice(2).concat([path.at(-1), path.at(-1)]);
      loc = initArrayBuffer(gl, program, new Float32Array(flatten(lastVertices)), 2, 'last');
      instanceExt.vertexAttribDivisorANGLE(loc, 1);

      const prevVertices = [path[0]].concat(path.slice(0, path.length - 1));
      loc = initArrayBuffer(gl, program, new Float32Array(flatten(prevVertices)), 2, 'previous');
      instanceExt.vertexAttribDivisorANGLE(loc, 1);

      const colorVertices = [];
      for (let i = 0; i < positions.length; i++) {
        colorVertices.push(0.0, 0.0, 1.0);
      }
      loc = initArrayBuffer(gl, program, new Float32Array(colorVertices), 3, 'a_Color');
      instanceExt.vertexAttribDivisorANGLE(loc, 1);

      const lineVS = [
        [0, -1],
        [1, -1],
        [1, 1],
        [0, -1],
        [1, 1],
        [0, 1],
      ];
      const joinVS = getJoinDir(joinType);
      const capVS = getCapDir(capType);
      const lineDir = lineVS.concat(new Array(joinVS.length + capVS.length).fill([0, 0]));
      loc = initArrayBuffer(gl, program, new Float32Array(flatten(lineDir)), 2, 'lineDir');
      instanceExt.vertexAttribDivisorANGLE(loc, 0);

      const joinDir = new Array(lineVS.length).fill([0, 0])
        .concat(joinVS)
        .concat(new Array(capVS.length).fill([0, 0]));
      loc = initArrayBuffer(gl, program, new Float32Array(flatten(joinDir)), 2, 'joinDir');
      instanceExt.vertexAttribDivisorANGLE(loc, 0);

      const capDir = new Array(lineVS.length + joinVS.length).fill([0, 0])
        .concat(capVS);
      loc = initArrayBuffer(gl, program, new Float32Array(flatten(capDir)), 2, 'capDir');
      instanceExt.vertexAttribDivisorANGLE(loc, 0);
      
      const count = lineDir.length;// 顶点数
      const offset = 0;
      const instanceNum = positions.length;
      instanceExt.drawArraysInstancedANGLE(gl.TRIANGLES, 0, count, instanceNum);
    }
    const lineProgram = twgl.createProgramInfo(gl, [vertexShaderSource, fragmentShaderSource]).program;

    function drawScene (gl) {
      // 通过颜色混合来减轻抗锯齿的白色瑕疵。
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
      drawLine(gl, lineProgram);
      gl.disable(gl.BLEND);
    }
    var stats = new Stats();
    stats.showPanel( 0 ); // 0: fps, 1: ms, 2: mb, 3+: custom
    this.$refs.stats.appendChild( stats.dom );
    stats.dom.style.position = 'absolute';
    stats.dom.style.left = '';
    stats.dom.style.right = '0';
    this.statsDom = stats.dom;
    drawScene(gl);
  }
}

</script>
<template>
  <div id="ctn">
    <canvas ref="container"></canvas>
    <Desc sourceUrl="/line/antialise/LineJoinCap.vue">
      WebGL绘制线段，采用矩形来模拟。本案例具备以下特性：
      <p>
      只有一次DrawCall、linecap/linejoin计算全部在GPU进行、线段宽度恒定不变、没有discard语句、支持抗锯齿。
      </p>
      <p>
      优势：主流绘制方式，如<el-link href="https://wwwtyro.net/2019/11/18/instanced-lines.html">instanced-lines</el-link>，如果利用GPU渲染，至少采用2次drawcall，而一次drawcall的又必须在CPU计算，难以兼顾。
      与此同时，再加上抗锯齿需求，则更加复杂，各家均未考虑，只是启用浏览器抗锯齿而已。
      </p>
      <p>
      <el-link type="success" href="https://zhuanlan.zhihu.com/p/623520101" target="_blank">说明文档：绘制线段</el-link>
      </p>
      <p>
      <el-link type="success" href="https://zhuanlan.zhihu.com/p/629892061" target="_blank">说明文档：线段抗锯齿</el-link>
      </p>
    </Desc>
    <div id="stats" ref="stats"></div>
  </div>
</template>
<style scoped>
#ctn {
  position:relative;
}
canvas {
  width: 800px;
  height: 400px;
}
</style>
