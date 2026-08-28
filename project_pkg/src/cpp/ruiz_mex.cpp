/* ruiz_mex.cpp — Ruiz 平衡化のスケール係数計算 (ホットループのC化).
 *
 * scpk.precondition と同一の反復 (15回の行/列ノルム更新) を CSC 上で行い,
 * 累積スケール (col, rowAcc) とコストスケール cs を返す. スケールの適用
 * (疎行列の掛け算) は MATLAB 側で1回だけ行う.
 *
 *   [col, rowAcc, cs] = ruiz_mex(C, Pdiag, nIter)
 *     C     : m x n 疎 (= [G; A])
 *     Pdiag : n x 1 コスト対角
 *     col   : n x 1 列スケール (z = col .* zhat)
 *     rowAcc: m x 1 行スケール (g_hat = g ./ rowAcc)
 *     cs    : コストスケール
 */
#include "mex.h"
#include <math.h>
#include <string.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs != 3) mexErrMsgIdAndTxt("ruiz:nrhs", "使い方: [col,rowAcc,cs]=ruiz_mex(C,Pdiag,nIter)");
    if (!mxIsSparse(prhs[0])) mexErrMsgIdAndTxt("ruiz:sp", "C は疎行列");
    mwIndex m = mxGetM(prhs[0]), n = mxGetN(prhs[0]);
    const mwIndex *ir = mxGetIr(prhs[0]), *jc = mxGetJc(prhs[0]);
    const double *pr = mxGetPr(prhs[0]);
    const double *Pd0 = mxGetPr(prhs[1]);
    int nIter = (int)mxGetScalar(prhs[2]);
    mwIndex nnz = jc[n];

    double *v   = (double*)mxMalloc(nnz*sizeof(double));   /* スケール済み |C| */
    double *pd  = (double*)mxMalloc(n*sizeof(double));     /* スケール済み |P| 対角 */
    double *rn  = (double*)mxMalloc(m*sizeof(double));
    double *cn  = (double*)mxMalloc(n*sizeof(double));
    plhs[0] = mxCreateDoubleMatrix(n,1,mxREAL);  double *col = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(m,1,mxREAL);  double *row = mxGetPr(plhs[1]);
    for (mwIndex k = 0; k < nnz; ++k) v[k] = fabs(pr[k]);
    for (mwIndex j = 0; j < n; ++j) { pd[j] = fabs(Pd0[j]); col[j] = 1.0; }
    for (mwIndex i = 0; i < m; ++i) row[i] = 1.0;

    for (int it = 0; it < nIter; ++it) {
        /* 行ノルム rn_i = sqrt(max_j |C_ij|), 下限 1e-12 */
        for (mwIndex i = 0; i < m; ++i) rn[i] = 0.0;
        for (mwIndex j = 0; j < n; ++j)
            for (mwIndex k = jc[j]; k < jc[j+1]; ++k)
                if (v[k] > rn[ir[k]]) rn[ir[k]] = v[k];
        for (mwIndex i = 0; i < m; ++i) rn[i] = sqrt(rn[i] > 1e-12 ? rn[i] : 1e-12);
        /* 列ノルム cn_j = sqrt(max(max_i |C_ij|, |P_jj|)), 下限 1e-12 */
        for (mwIndex j = 0; j < n; ++j) {
            double s = pd[j];
            for (mwIndex k = jc[j]; k < jc[j+1]; ++k) if (v[k] > s) s = v[k];
            cn[j] = sqrt(s > 1e-12 ? s : 1e-12);
        }
        /* スケール適用 (値のみ) と累積 */
        for (mwIndex j = 0; j < n; ++j)
            for (mwIndex k = jc[j]; k < jc[j+1]; ++k)
                v[k] /= rn[ir[k]]*cn[j];
        for (mwIndex j = 0; j < n; ++j) { pd[j] /= cn[j]*cn[j]; col[j] /= cn[j]; }
        for (mwIndex i = 0; i < m; ++i) row[i] *= rn[i];
    }
    double pmax = 0.0;
    for (mwIndex j = 0; j < n; ++j) if (pd[j] > pmax) pmax = pd[j];
    double cs = 1.0/(pmax > 1e-12 ? pmax : 1e-12);
    if (nlhs > 2) plhs[2] = mxCreateDoubleScalar(cs);
    mxFree(v); mxFree(pd); mxFree(rn); mxFree(cn);
}
