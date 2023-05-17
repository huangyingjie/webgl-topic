precision mediump float;
varying vec4 v_Color;
varying float v_range;
varying float v_outerRange;
varying float v_innerRange;

void main() {
  gl_FragColor = v_Color;
  // 使用alpha混合，效果不错；但在深色背景下，混合后仍有较明显边界
  float AAblur = 1. - smoothstep(v_innerRange, v_outerRange, abs(v_range));
  gl_FragColor.a *= AAblur;
}
