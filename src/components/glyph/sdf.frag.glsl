#version 300 es
#ifdef GL_ES
precision mediump float;
#endif

in vec2 v_textCoord;
uniform sampler2D u_sampler2D;
uniform vec4 u_color;
uniform float u_buffer;
uniform float u_gamma;
out vec4 fragColor;

void main() {
  float dist = texture(u_sampler2D, v_textCoord).r;
  // dist小于u_buffer - u_gamma是0，大于 u_buffer + u_gamma是1
  float alpha = smoothstep(u_buffer - u_gamma, u_buffer + u_gamma, dist);
  fragColor = vec4(u_color.rgb, alpha * u_color.a);
}
