precision lowp float;

uniform vec3 u_lightPosition; //光源位置
uniform vec3 u_lightColor; //光照颜色
uniform vec3 u_ambientColor; //环境光照入射颜色
uniform sampler2D u_shadowMap;
varying vec4 v_color;
varying vec4 worldPosition;
varying vec3 v_normal;
varying vec4 v_positionFromLight;

float unpackDepth(const in vec4 depth) {
  vec4 bitShift = vec4(1.0, 1.0/(256.0), 1.0/(256.0 * 256.0), 1.0/(256.0 * 256.0 * 256.0));
  return dot(depth, bitShift);
}

void main() {
  // 裁剪坐标转纹理坐标（[-1, 1] => [0, 1]）
  vec3 shadowCoord = vec3((v_positionFromLight.xyz / v_positionFromLight.w) / 2.0 + 0.5);
  vec4 shadowColor = texture2D(u_shadowMap, shadowCoord.xy);
  //float depth = shadowColor.r;
  float depth = unpackDepth(shadowColor);

  vec3 lightDirection = normalize(vec3(u_lightPosition - worldPosition.xyz));
  float nDotL = max(dot(normalize(v_normal), lightDirection), 0.0);
  vec3 ambientColor = u_ambientColor * v_color.rgb;
  vec3 diffuseColor = u_lightColor * v_color.rgb * nDotL;
  vec4 fragColor = vec4(diffuseColor + ambientColor, v_color.a);

  //float factor = (depth < 0.99) ? 0.7 : 1.0;
  // 纹理精度为10位，shadowCoord.z精度位16位，存在精度损失导致depth比shadowCoord.z小；
  // 所以需要补上精度差(> pow(2,-10))
  float factor = (shadowCoord.z > depth + 0.0015) ? 0.7 : 1.0;
  gl_FragColor = vec4(fragColor.rgb * factor, fragColor.a);
}
