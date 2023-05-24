#version 300 es
in vec4 a_position;
in vec2 a_textCoord;
out vec2 v_textCoord;

void main() {
  gl_Position = vec4(a_position.xy, a_position.z, 1.);
  v_textCoord = a_textCoord;
}
