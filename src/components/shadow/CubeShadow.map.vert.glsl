attribute vec3 a_position;
uniform mat4 u_mvpMatrix;
uniform float u_scaleFactor;

void main() {
  vec3 scaled_position = a_position * u_scaleFactor;
  gl_Position = u_mvpMatrix * vec4(scaled_position, 1.0);
}
