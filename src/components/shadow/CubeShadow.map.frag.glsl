#ifdef GL_ES
precision mediump float;
#endif

void main() {
  vec4 bitShift = vec4(1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0);
  vec4 bitMask = vec4(1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0, 0.0);
  vec4 depth = fract(gl_FragCoord.z * bitShift);
  depth -= depth.gbaa * bitMask;
  //gl_FragColor = depth;
  gl_FragColor = vec4(gl_FragCoord.z, 0, 0, 0);
}
