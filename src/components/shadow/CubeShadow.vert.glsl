attribute vec3 a_position;
attribute vec3 a_normal; // 法向量
attribute vec4 a_color;
uniform float u_scaleFactor;
uniform mat4 u_normalMatrix;
uniform mat4 u_mvpMatrix;
uniform mat4 u_modelMatrix;
uniform mat4 u_mvpLightMatrix;
varying vec4 v_color;
varying vec4 worldPosition;
varying vec3 v_normal;
varying vec4 v_positionFromLight;
varying vec2 v_texCoords;

void main() {
  vec3 scaled_position = a_position * u_scaleFactor;
  gl_Position = u_mvpMatrix * vec4(scaled_position, 1.0);
  worldPosition = u_modelMatrix * vec4(scaled_position, 1.0);
  v_normal = normalize(vec3(u_normalMatrix * vec4(a_normal, 1.0)));
  v_color = a_color;
  v_positionFromLight = u_mvpLightMatrix * vec4(scaled_position, 1.0);
}
