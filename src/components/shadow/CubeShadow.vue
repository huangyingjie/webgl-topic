<script setup>
</script>
<script>
import * as twgl from 'twgl.js'
import vertexShaderSource from './CubeShadow.vert.glsl';
import fragmentShaderSource from './CubeShadow.frag.glsl';
import vertexMapShaderSource from './CubeShadow.map.vert.glsl';
import fragmentMapShaderSource from './CubeShadow.map.frag.glsl';
import { mat4, vec3 } from 'gl-matrix'
import { mul } from '@/util/matrix.js'

let rad = 20;
let map_rad = 0; 
const OFFSET_HEIGHT = 1024 * 2;
const OFFSET_WIDTH = 1024 * 2;
const SCALE_FACTOR = 0.3;
let LIGHT_X = 0.0;
const LIGHT_Y = 0.4;
const LIGHT_Z = 18.9; // Z值越大，则光源越远
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
      return true;
    },
    initCubeColors(gl, program) {
      gl.uniform3f(
        gl.getUniformLocation(program, 'u_lightPosition'),
        LIGHT_X, LIGHT_Y, LIGHT_Z
      ); // 点光源位置很重要，一定要在物体外部
      gl.uniform3f(
        gl.getUniformLocation(program, 'u_lightColor'),
        ...vec3.normalize([], [0.9 , 0.9, 0.9])
      );
      gl.uniform3f(
        gl.getUniformLocation(program, 'u_ambientColor'),
        0.4 , 0.4, 0.4
      );
      // 颜色和顶点一一对应
      var colors = new Float32Array([     // Colors
        0.4, 0.4, 1.0,  0.4, 0.4, 1.0,  0.4, 0.4, 1.0,  0.4, 0.4, 1.0,  // v0-v1-v2-v3 front(blue)
        0.4, 1.0, 0.4,  0.4, 1.0, 0.4,  0.4, 1.0, 0.4,  0.4, 1.0, 0.4,  // v0-v3-v4-v5 right(green)
        1.0, 0.4, 0.4,  1.0, 0.4, 0.4,  1.0, 0.4, 0.4,  1.0, 0.4, 0.4,  // v0-v5-v6-v1 up(red)
        1.0, 1.0, 0.4,  1.0, 1.0, 0.4,  1.0, 1.0, 0.4,  1.0, 1.0, 0.4,  // v1-v6-v7-v2 left
        1.0, 1.0, 1.0,  1.0, 1.0, 1.0,  1.0, 1.0, 1.0,  1.0, 1.0, 1.0,  // v7-v4-v3-v2 down
        0.4, 1.0, 0.0,  0.4, 1.0, 0.0,  0.4, 1.0, 0.0,  0.4, 1.0, 0.0   // v4-v7-v6-v5 back
      ]);
      this.initArrayBuffer(gl, program, colors, 3, 'a_color');
    },
    setGeometry(gl, program) {
      // Create a cube
      //    v6----- v5
      //   /|      /|
      //  v1------v0|
      //  | |     | |
      //  | |v7---|-|v4
      //  |/      |/
      //  v2------v3
      // 颜色和顶点一一对应
      var vertices = new Float32Array([   // Vertex coordinates
         1.0, 1.0, 1.0,  -1.0, 1.0, 1.0,  -1.0,-1.0, 1.0,   1.0,-1.0, 1.0,  // v0-v1-v2-v3 front
         1.0, 1.0, 1.0,   1.0,-1.0, 1.0,   1.0,-1.0,-1.0,   1.0, 1.0,-1.0,  // v0-v3-v4-v5 right
         1.0, 1.0, 1.0,   1.0, 1.0,-1.0,  -1.0, 1.0,-1.0,  -1.0, 1.0, 1.0,  // v0-v5-v6-v1 up
        -1.0, 1.0, 1.0,  -1.0, 1.0,-1.0,  -1.0,-1.0,-1.0,  -1.0,-1.0, 1.0,  // v1-v6-v7-v2 left
        -1.0,-1.0,-1.0,   1.0,-1.0,-1.0,   1.0,-1.0, 1.0,  -1.0,-1.0, 1.0,  // v7-v4-v3-v2 down
         1.0,-1.0,-1.0,  -1.0,-1.0,-1.0,  -1.0, 1.0,-1.0,   1.0, 1.0,-1.0   // v4-v7-v6-v5 back
      ]);
      this.initArrayBuffer(gl, program, vertices, 3, 'a_position');

      const indices = new Uint8Array([       // Indices of the vertices
         0, 1, 2,   0, 2, 3,    // front
         4, 5, 6,   4, 6, 7,    // right
         8, 9,10,   8,10,11,    // up
        12,13,14,  12,14,15,    // left
        16,17,18,  16,18,19,    // down
        20,21,22,  20,22,23     // back
      ]);
      const indexBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW);
      return indices;
    },
    initFrameBufferObject(gl) {
      const fbo = gl.createFramebuffer();
      const texture = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, OFFSET_WIDTH, OFFSET_HEIGHT, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
      fbo.texture = texture;

      const depthBuffer = gl.createRenderbuffer();
      gl.bindRenderbuffer(gl.RENDERBUFFER, depthBuffer);
      gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, OFFSET_WIDTH, OFFSET_HEIGHT);

      gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
      // 关联点
      gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depthBuffer);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);

      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      gl.bindTexture(gl.TEXTURE_2D, null);
      gl.bindRenderbuffer(gl.RENDERBUFFER, null);
      return fbo;
    },
    initPlaneModelMatrix() {
      //map_rad++;
      const modelMatrix = mat4.create();
      mat4.fromRotation(modelMatrix, map_rad * Math.PI / 180, [0, 0, 1]);
      return modelMatrix;
    },
    initModelMatrix() {
      //rad++;
      const modelMatrix = mat4.create();
      mat4.fromRotation(modelMatrix, rad * Math.PI / 180, [1, 0, 0]);
      return modelMatrix;
    },
    initViewMatrix() {
      const viewMatrix = mat4.create();
      mat4.lookAt(viewMatrix, [1, 1, 4], [0,0,0], [0,1,0]);
      return viewMatrix;
    },
    initViewLightMatrix() {
      const viewLightMatrix = mat4.create();
      mat4.lookAt(viewLightMatrix, [LIGHT_X, LIGHT_Y, LIGHT_Z], [0,0,0], [0,1,0]);
      return viewLightMatrix;
    },
    initProjectMatrix() {
      const projectMatrix = mat4.create();
      mat4.perspective(projectMatrix, 30 * Math.PI / 180, 1, 1, 100)
      return projectMatrix;
    },
    drawCube(gl, program, modelMatrix, mvpMatrix, mvpLightMatrix) {
      const { setGeometry, initArrayBuffer } = this;
      const indices = setGeometry(gl, program);
      this.initCubeColors(gl, program);

      const u_mvpMatrix = gl.getUniformLocation(program, 'u_mvpMatrix');
      gl.uniformMatrix4fv(u_mvpMatrix, false, mvpMatrix);

      const u_modelMatrix = gl.getUniformLocation(program, 'u_modelMatrix');
      gl.uniformMatrix4fv(u_modelMatrix, false, modelMatrix);

      // Cube和plane需要各自不同的mvpLightMatrix，因为各自的model、project都不一定相同
      const u_mvpLightMatrix = gl.getUniformLocation(program, 'u_mvpLightMatrix');
      gl.uniformMatrix4fv(u_mvpLightMatrix, false, mvpLightMatrix);
      // 法向量
      var normals = new Float32Array([    // Normal
        0.0, 0.0, 1.0,   0.0, 0.0, 1.0,   0.0, 0.0, 1.0,   0.0, 0.0, 1.0,  // v0-v1-v2-v3 front
        1.0, 0.0, 0.0,   1.0, 0.0, 0.0,   1.0, 0.0, 0.0,   1.0, 0.0, 0.0,  // v0-v3-v4-v5 right
        0.0, 1.0, 0.0,   0.0, 1.0, 0.0,   0.0, 1.0, 0.0,   0.0, 1.0, 0.0,  // v0-v5-v6-v1 up
       -1.0, 0.0, 0.0,  -1.0, 0.0, 0.0,  -1.0, 0.0, 0.0,  -1.0, 0.0, 0.0,  // v1-v6-v7-v2 left
        0.0,-1.0, 0.0,   0.0,-1.0, 0.0,   0.0,-1.0, 0.0,   0.0,-1.0, 0.0,  // v7-v4-v3-v2 down
        0.0, 0.0,-1.0,   0.0, 0.0,-1.0,   0.0, 0.0,-1.0,   0.0, 0.0,-1.0   // v4-v7-v6-v5 back
      ]);
      initArrayBuffer(gl, program, normals, 3, 'a_normal');

      const normalMatrix = mat4.transpose(mat4.create(), mat4.invert(mat4.create(), modelMatrix));
      gl.uniformMatrix4fv(gl.getUniformLocation(program, 'u_normalMatrix'), false, normalMatrix);

      gl.uniform1f(gl.getUniformLocation(program, 'u_scaleFactor'), SCALE_FACTOR);

      gl.drawElements(gl.TRIANGLES, indices.length, gl.UNSIGNED_BYTE, 0);
    },
    drawPlane(gl, program, mvpMatrix) {
      const { initArrayBuffer } = this;
      var vertices = new Float32Array([   // Vertex coordinates
         1.0, 1.0, -5.0,  -1.0, 1.0, -5.0,  -1.0,-1.0, -5.0,   1.0,-1.0, -5.0,  // v0-v1-v2-v3 front
      ]);
      initArrayBuffer(gl, program, vertices, 3, 'a_position');
      const indices = new Uint8Array([       // Indices of the vertices
         0, 1, 2,   0, 2, 3,    // front
      ]);
      const indexBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW);
      gl.uniform1f(gl.getUniformLocation(program, 'u_scaleFactor'), 1.0);

      const u_mvpMatrix = gl.getUniformLocation(program, 'u_mvpMatrix');
      gl.uniformMatrix4fv(u_mvpMatrix, false, mvpMatrix);

      gl.drawElements(gl.TRIANGLES, indices.length, gl.UNSIGNED_BYTE, 0);
    },
    drawCubeMap(gl, program, mvpMatrix) {
      const { setGeometry, initArrayBuffer } = this;
      const indices = setGeometry(gl, program);

      const u_mvpMatrix = gl.getUniformLocation(program, 'u_mvpMatrix');
      gl.uniformMatrix4fv(u_mvpMatrix, false, mvpMatrix);

      gl.uniform1f(gl.getUniformLocation(program, 'u_scaleFactor'), SCALE_FACTOR);

      gl.drawElements(gl.TRIANGLES, indices.length, gl.UNSIGNED_BYTE, 0);
    }
  },
  unmounted() {
  },
  async mounted() {
    const { container } = this.$refs;
    const gl = container.getContext('webgl') || container.getContext('experimental-webgl');
    if (!gl) {
      return;
    }
    twgl.resizeCanvasToDisplaySize(gl.canvas, window.devicePixelRatio)
    const fbo = this.initFrameBufferObject(gl);

    //gl.viewport(0, 0, container.width, container.height);
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);

    const programMap = twgl.createProgramInfo(gl, [vertexMapShaderSource, fragmentMapShaderSource]).program;
    // 创建program
    const program= twgl.createProgramInfo(gl, [vertexShaderSource, fragmentShaderSource]).program;

    let PESPECT = 30;
    let VIEW_X = 0.5;
    let view_oprate = 'plus';
    var tick = () => {
      gl.useProgram(programMap);
      gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
      gl.viewport(0, 0, OFFSET_WIDTH, OFFSET_HEIGHT);
      gl.clearColor(0.0, 0.0, 0.0, 1.0);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

      if (VIEW_X <= -1.5) {
        view_oprate = 'plus';
      } else if (VIEW_X >= 1.5) {
        view_oprate = 'minus';
      }
      if (view_oprate === 'plus') {
        VIEW_X += 0.01;
        LIGHT_X += 0.01;
      } else {
        VIEW_X -= 0.01;
        LIGHT_X -= 0.01;
      }

      const modelMatrix = this.initModelMatrix();
      const viewMatrix = this.initViewMatrix();
      const viewLightMatrix = this.initViewLightMatrix();
      const projectMapMatrix = this.initProjectMatrix();
      const mvpLightMatrix = mul(mat4, [ projectMapMatrix, viewLightMatrix, modelMatrix ]);

      this.drawCubeMap(gl, programMap, mvpLightMatrix);

      const modelPlaneMatrix = this.initPlaneModelMatrix();
      const mvpPlaneLightMatrix = mul(mat4, [ projectMapMatrix, viewLightMatrix, modelPlaneMatrix ]);

      this.drawPlane(gl, programMap, mvpPlaneLightMatrix);

      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      gl.useProgram(program);

      gl.viewport(0, 0, container.width, container.height);
      gl.clearColor(0.0, 0.0, 0.0, 1.0);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, fbo.texture);
      gl.uniform1i(gl.getUniformLocation(program, 'u_shadowMap'), 0);

      const projectMatrix = mat4.create();
      //PESPECT++;
      mat4.perspective(projectMatrix, 30 * Math.PI / 180, 1, 1, 100)
      //const projectCubeMatrix = mat4.create();
      //mat4.perspective(projectCubeMatrix, PESPECT * Math.PI / 180, 1, 1, 100)
      const viewCubeMatrix = mat4.create();
      mat4.lookAt(viewCubeMatrix, [VIEW_X, 1, 4], [0,0,0], [0,1,0]);

      const mvpMatrix = mul(mat4, [ projectMatrix, viewCubeMatrix, modelPlaneMatrix ]);
      this.drawCube(gl, program, modelMatrix, mvpMatrix, mvpLightMatrix);
      var colors = new Float32Array([   // Vertex coordinates
        1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
        //0.4, 0.4, 1.0,  0.4, 0.4, 1.0,  0.4, 0.4, 1.0,  0.4, 0.4, 1.0,  // v0-v1-v2-v3 front(blue)
      ]);
      this.initArrayBuffer(gl, program, colors, 3, 'a_color');
      const u_mvpLightMatrix = gl.getUniformLocation(program, 'u_mvpLightMatrix');
      gl.uniformMatrix4fv(u_mvpLightMatrix, false, mvpPlaneLightMatrix);
      
      const mvpPlaneMatrix = mul(mat4, [ projectMatrix, viewCubeMatrix, modelPlaneMatrix ]);
      this.drawPlane(gl, program, mvpPlaneMatrix);
      requestAnimationFrame(tick);
    }
    tick();
  }
}

</script>
<template>
  <canvas width='400' height='300' ref="container"></canvas>
</template>
<style scoped>
canvas {
  width: 400px;
  height: 400px;
}
</style>
