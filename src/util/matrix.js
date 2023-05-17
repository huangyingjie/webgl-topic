/**
 * matrixs顺序：变换矩阵在左，源矩阵在右。
 * 该函数从前到后顺序读取矩阵并相乘。
 * WebGL矩阵元素是列主序，gl-matrix算法是mul(out, a, b)，其中：`out = b的行*a的列`，换算为列主序，则为`out= b的列*a的行`
 * 由此可知，a是变换矩阵，b是源矩阵
 * 而reduce传入顺序是把结果作为变换矩阵，下一个元素作为源矩阵，所以正确的传入顺序和矩阵左乘逻辑相同
 * 即：投影 * 视图 * 模型
 */
function mul(mat, matrixs) {
  return matrixs.reduce((m, next) => {
    return mat.mul(mat.create(), m, next);
  });
}
export { mul };
