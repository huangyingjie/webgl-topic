attribute vec3 position;
attribute vec2 lineDir;
attribute vec2 joinDir;
attribute vec2 capDir;
attribute vec3 next;
attribute vec3 last;
attribute vec3 previous;
attribute vec4 a_Color;
uniform mat4 projection;
uniform mat4 model;
uniform mat4 view;
uniform float aspect;
uniform vec2 resolution;

uniform float miterlimit;
uniform float thickness;
uniform int capType;
uniform int joinType;
uniform float dpr;

varying vec4 v_Color;
// 用于抗锯齿
varying float v_range;
varying float v_outerRange;
varying float v_innerRange;

vec3 toWorld(vec3 point) {
  float x = point.x;
  float y = point.y;
  float width = resolution.x;
  float height = resolution.y;
  float xWidth = 2.0 * x * dpr / width - 1.0;
  float yHeight = 2.0 * y * dpr / height - 1.0;
  return vec3(xWidth, yHeight, point.z);
}
#define PI 3.1415926538


vec2 getCapSquare(vec2 dirToCap, vec2 baseNormal, float halfWidth, float factor) {
  // 负号保证方向为逆时针
  vec2 capdir1 = baseNormal * halfWidth;
  vec2 capdir2 = dirToCap * halfWidth * factor + capdir1;
  vec2 capdir3 = dirToCap * halfWidth * factor - capdir1;
  vec2 capdir4 = -capdir1;
  vec2 roundDirs[5];
  // 因为如果roundDirs[0]不是vec2(0, 0), 逐顶点运算时，顶点有意设置的0在此处无效；
  roundDirs[0] = vec2(0, 0);
  roundDirs[1] = capdir1;
  roundDirs[2] = capdir2;
  roundDirs[3] = capdir3;
  roundDirs[4] = capdir4;

  int index = int(capDir.x);
  for (int i = 0; i <= 4; i++) {
    if (index == i) {
      // 直接写roundDirs[index]报错，不允许传入attribute或uniform变量，只能模拟。
      // 也可以考虑从2d纹理中取值 TODO
      return roundDirs[i];
    }
  }
}
vec2 getJoinBevel(vec2 dirBC, vec2 dirAB, float halfWidth, bool isBevel) {
  // 4个顶点、2个三角形拼接而成
  //vec2 dirAB = normalize(currentScreen - previousScreen);
  vec2 ABN = vec2(-dirAB.y, dirAB.x);
  vec2 tangent = normalize(dirAB + dirBC);
  vec2 miter = vec2(-tangent.y, tangent.x); // 向上垂线
  
  float sigma = sign(dot(dirAB - dirBC, miter));
  // linejoin
  vec2 BCN = vec2(-dirBC.y, dirBC.x);
  vec2 startNormal = BCN;
  vec2 endNormal = ABN;
  vec2 dir = miter;
  if (sigma < 0.) {
    startNormal = -ABN;
    endNormal = -BCN;
    dir = -miter;
  }
  vec2 joindir0 = startNormal * halfWidth;
  vec2 joindir2 = endNormal * halfWidth;
  float miterLength = halfWidth / dot(miter, ABN);
  float limitLength = miterlimit * dpr / resolution.y;
  if (isBevel) {
    miterLength = halfWidth * dot(miter, ABN);
  } else if (miterLength > limitLength) {
    miterLength = max(limitLength, halfWidth * dot(miter, ABN));
  }
  vec2 joindir1 = dir * miterLength;

  vec2 roundDirs[5];
  // 因为如果roundDirs[0]不是vec2(0, 0), 逐顶点运算时，顶点有意设置的0在此处无效；
  roundDirs[0] = vec2(0, 0);
  roundDirs[1] = joindir0;
  roundDirs[2] = joindir1;
  roundDirs[3] = joindir2;
  roundDirs[4] = -dir * halfWidth / dot(miter, ABN);

  int index = int(joinDir.x);

  // 三角形两端一正一负，另一点为0的插值能够满足要求
  if (index == 4) {
    v_range += -1.0 * halfWidth * 1.00;
  } else {
    v_range += clamp(joinDir.x, 0., 1.) * halfWidth * 1.00;
  }
  for (int i = 0; i <= 4; i++) {
    if (index == i) {
      // 直接写roundDirs[index]报错，不允许传入attribute或uniform变量，只能模拟。
      return roundDirs[i];
    }
  }
}

vec2 getCapRoundDir(vec2 baseNormal, float halfWidth, vec2 dirIndex, float radian) {
  const int capRoundVerticeNum = 10;
  vec2 roundDirs[capRoundVerticeNum + 3];
  // 为什么影响到了线段？
  // 因为如果roundDirs[0]不是vec2(0, 0), 逐顶点运算时，有意设置的0在此处无效；
  roundDirs[0] = vec2(0, 0);
  for (int i = 1; i <= capRoundVerticeNum + 1; i++) {
    float angle = float(i - 1) * radian / float(capRoundVerticeNum);
    mat2 rotateMatrix = mat2(
      cos(angle), sin(angle),
      -sin(angle), cos(angle)
    );
    // 要先旋转后乘以thickness
    //vec2 baseDir = vec2(-2., 0.);
    // vec2参数为引用传递，必须复制一份
    vec2 baseDir = vec2(baseNormal);
    baseDir = rotateMatrix * baseDir;
    baseDir *= halfWidth;
    roundDirs[i] = baseDir;
  }
  int index = int(dirIndex.x);
  for (int i = 0; i <= capRoundVerticeNum + 2; i++) {
    if (index == i) {
      // 直接写roundDirs[index]报错，不允许传入attribute或uniform变量，只能模拟。
      // 也可以考虑从2d纹理中取值 TODO
      return roundDirs[i];
    }
  }
  return vec2(0., 0.);
}
vec2 getJoinRoundDir(vec2 baseNormal, float halfWidth, vec2 dirIndex, float radian, vec2 miter) {
  const int capRoundVerticeNum = 10;
  vec2 roundDirs[capRoundVerticeNum + 3];
  // 如果roundDirs[0]不是vec2(0, 0), 逐顶点运算时，有意设置的0在此处无效；
  roundDirs[0] = vec2(0, 0);
  for (int i = 1; i <= capRoundVerticeNum + 1; i++) {
    float angle = float(i - 1) * radian / float(capRoundVerticeNum);
    mat2 rotateMatrix = mat2(
      cos(angle), sin(angle),
      -sin(angle), cos(angle)
    );
    // 要先旋转后乘以thickness
    vec2 baseDir = rotateMatrix * baseNormal;
    baseDir *= halfWidth;
    roundDirs[i] = baseDir;
  }
  roundDirs[capRoundVerticeNum + 2] = -miter;
  int index = int(dirIndex.x);
  // 三角形两端一正一负，另一点为0的插值能够满足要求
  if (index == capRoundVerticeNum + 2) {
    v_range += -1.0 * halfWidth;
  } else {
    v_range += clamp(joinDir.x, 0., 1.) * halfWidth;
  }
  for (int i = 0; i <= capRoundVerticeNum + 2; i++) {
    if (index == i) {
      // 直接写roundDirs[index]报错，不允许传入attribute或uniform变量，只能模拟。
      return roundDirs[i];
    }
  }
  return vec2(0., 0.);
}

void main() {
  v_Color = a_Color;
  vec2 aspectVec = vec2(aspect, 1.0);
  mat4 projViewModel = projection * view * model;
  vec4 previousProjected = projViewModel * vec4(toWorld(previous), 1.0);
  vec4 currentProjected = projViewModel * vec4(toWorld(position), 1.0);
  vec4 nextProjected = projViewModel * vec4(toWorld(next), 1.0);
  vec4 lastProjected = projViewModel * vec4(toWorld(last), 1.0);


  // 只是除以w则进入NDC space，但乘以aspectVec后，则可模拟screen空间
  vec2 currentScreen = currentProjected.xy / currentProjected.w * aspectVec;
  vec2 previousScreen = previousProjected.xy / previousProjected.w * aspectVec;
  vec2 nextScreen = nextProjected.xy / nextProjected.w * aspectVec;
  vec2 lastScreen = lastProjected.xy / lastProjected.w * aspectVec;


  // 抗锯齿参数
  float deltaWidth = 2. * dpr / resolution.y;
  float halfWidth = deltaWidth + 0.5 * thickness * dpr / resolution.y;
  v_outerRange = halfWidth;
  v_innerRange = halfWidth - 2. * deltaWidth;

  // 绘制线段矩形
  vec2 pos = vec2(lineDir.x, lineDir.y);
  vec2 pA = previousScreen;
  vec2 pB = currentScreen;
  vec2 pC = nextScreen;

  if (lineDir.x == 1.) {
    pA = lastScreen;
    pB = nextScreen;
    pC = currentScreen;
    pos = vec2(0., -lineDir.y);
  }
  vec2 basePoint = pB;
  vec2 dirBCScreen = pC - pB;
  if (pB == pC) {
    dirBCScreen = pB - pA;
  }
  vec2 dirBC = normalize(dirBCScreen);
  vec2 BCN = vec2(-dirBC.y, dirBC.x);

  vec2 dirABScreen = pB - pA;
  if (pA == pB) {
    dirABScreen = pC - pB;
  }
  vec2 dirAB = normalize(dirABScreen);
  vec2 ABN = vec2(-dirAB.y, dirAB.x);
  vec2 baseNormal = pos.y * BCN * halfWidth;
  vec2 tangent = normalize(dirAB + dirBC);
  vec2 miter = vec2(-tangent.y, tangent.x); // 向上垂线
  float sigma = sign(dot(dirAB - dirBC, miter));
  if (sigma != sign(pos.y)) {
    // linejoin
    if (!(currentScreen == previousScreen && lineDir.x == 0.)) {
      baseNormal = pos.y * miter * halfWidth / dot(miter, ABN);
    }
  }
  basePoint += baseNormal;
  v_range += lineDir.y * halfWidth;


  int CAP_ROUND = 0;
  int CAP_BUTT = 1;
  int CAP_SQUARE = 2;
  int JOIN_ROUND = 0;
  int JOIN_BEVEL = 1;
  int JOIN_MITER = 2;
  // 绘制cap
  if (currentScreen == previousScreen || currentScreen == nextScreen) {
    vec2 dirToSquare = -dirBC;
    vec2 dirToRound = BCN;
    vec2 baseNormal = BCN;
    if (currentScreen == nextScreen) {
      dirToSquare = dirAB;
      baseNormal = ABN;
      dirToRound = -ABN;
    }
    if (capType == CAP_SQUARE) {
      basePoint += getCapSquare(dirToSquare, baseNormal, halfWidth, 1.);
      // 为什么必须`+=` ? 否则会覆盖line的range
      v_range += clamp(capDir.x, 0., 1.) * halfWidth * 1.00;
    } else if (capType == CAP_BUTT) {
      basePoint += getCapSquare(dirToSquare, baseNormal, halfWidth, 0.3);
      v_range += clamp(capDir.x, 0., 1.) * halfWidth * 1.00;
    } else if (capType == CAP_ROUND) {
      basePoint += getCapRoundDir(dirToRound, halfWidth, capDir, PI);
      v_range += clamp(capDir.x, 0., 1.) * halfWidth;
    }
  } else {
    // 绘制join
    // 拼接join三角形
    // 此处lineDir的值均为0，所以实质上是从currentScreen开始绘制
    vec2 dirAB = normalize(currentScreen - previousScreen);
    if (joinType == JOIN_MITER) {
      basePoint += getJoinBevel(dirBC, dirAB, halfWidth, false);
    } else if (joinType == JOIN_BEVEL){
      basePoint += getJoinBevel(dirBC, dirAB, halfWidth, true);
    } else if (joinType == JOIN_ROUND){
      vec2 ABN = vec2(-dirAB.y, dirAB.x);
      vec2 tangent = normalize(dirAB + dirBC);
      vec2 miter = vec2(-tangent.y, tangent.x); // 向上垂线
      
      float sigma = sign(dot(dirAB - dirBC, miter));
      // linejoin
      vec2 BCN = vec2(-dirBC.y, dirBC.x);
      float miterLength = halfWidth / dot(miter, ABN);
      vec2 dirStart = BCN;
      vec2 dirEnd= ABN;
      vec2 dir = dirStart;
      if (sigma < 0.) {
        dir = -dirEnd;
      }
      basePoint += getJoinRoundDir(normalize(dir), halfWidth, joinDir, acos(dot(dirStart, dirEnd)), sigma * miter * miterLength);
    }
  }

  gl_Position = vec4(basePoint / aspectVec * currentProjected.w, currentProjected.z, currentProjected.w);
}
