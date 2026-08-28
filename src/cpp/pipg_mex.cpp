/* pipg_mex.cpp — PIPG (箱制約付き凸QP) の手書きC++実装 + MEXラッパ.
 *
 * 設計方針 (ライブラリフリー・組み込み移植):
 *   - 依存は <math.h> 相当のみ. BLAS/LAPACK/STLコンテナ不使用.
 *   - 行列は CSC 疎形式 (MATLAB ネイティブ) を直接走査. 密演算なし.
 *   - コスト行列 P は対角ベクトルとして受ける (計画QP・追従QPとも対角).
 *   - ループ内メモリ確保ゼロ. バッファは起動時に一括確保.
 *   - アルゴリズム・判定は +scpk/solveQPEmb.m と同一 (等価性テストで担保).
 *
 * 呼び出し (MATLAB):
 *   [z,status,iters,resPri,resDua,w] = pipg_mex(Pdiag,q,C,d,neq,lb,ub,opt,z0,w0)
 *     Pdiag : n x 1  対角コスト
 *     C     : m x n  疎 (= [G; A], 等式が先頭 neq 行)
 *     d     : m x 1  (= [g; b])
 *     opt   : struct maxIter,fixedIter,tolPri,tolDua,omega,rho,checkEvery,
 *                    powerIter,certAfter,certTol,certEps
 *   status: 0 maxIter / 1 converged / 2 primalInfeasible / 3 dualInfeasible
 *           / 4 numericalFailure
 *
 * 組み込み移植: mexFunction 以外 (namespace pipg) をそのまま流用する.
 */
#include "mex.h"
#include <math.h>
#include <string.h>

namespace pipg {

typedef mwIndex idx_t;

struct Csc {                 /* CSC 疎行列 (所有しない) */
    idx_t m, n;
    const idx_t *ir, *jc;    /* 行インデックス / 列ポインタ */
    const double *pr;        /* 値 */
};

/* y = C*x  (scatter, 列走査) */
static void cscMul(const Csc &C, const double *x, double *y) {
    for (idx_t i = 0; i < C.m; ++i) y[i] = 0.0;
    for (idx_t j = 0; j < C.n; ++j) {
        const double xj = x[j];
        if (xj == 0.0) continue;
        for (idx_t k = C.jc[j]; k < C.jc[j+1]; ++k) y[C.ir[k]] += C.pr[k]*xj;
    }
}

/* y = C'*x (gather, 列走査) */
static void cscTMul(const Csc &C, const double *x, double *y) {
    for (idx_t j = 0; j < C.n; ++j) {
        double s = 0.0;
        for (idx_t k = C.jc[j]; k < C.jc[j+1]; ++k) s += C.pr[k]*x[C.ir[k]];
        y[j] = s;
    }
}

static double normInf(const double *v, idx_t n) {
    double s = 0.0;
    for (idx_t i = 0; i < n; ++i) { double a = fabs(v[i]); if (a > s) s = a; }
    return s;
}
static double norm2(const double *v, idx_t n) {
    double s = 0.0;
    for (idx_t i = 0; i < n; ++i) s += v[i]*v[i];
    return sqrt(s);
}
static bool allFinite(const double *v, idx_t n) {
    for (idx_t i = 0; i < n; ++i) if (!mxIsFinite(v[i])) return false;
    return true;
}
static inline double clip(double v, double lo, double hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

struct Opt {
    int maxIter, fixedIter, checkEvery, powerIter, certAfter;
    double tolPri, tolDua, omega, rho, certTol, certEps;
};

struct Work {                /* 事前確保バッファ */
    double *zb, *wb, *zn, *wn, *zPrev, *wPrev, *zc;
    double *tn, *tm, *dzL, *dwL;   /* 汎用 n / m ベクトル, 最終差分 */
};

/* 主・双対の相対残差 (solveQPEmb と同一の定義) */
static void residuals(const double *Pd, const double *q, const Csc &C,
                      const double *d, idx_t neq, const double *lb, const double *ub,
                      const double *z, const double *w, Work &W,
                      double *rp, double *rd) {
    cscMul(C, z, W.tm);                       /* tm = C z */
    double rpa = 0.0;
    for (idx_t i = 0; i < neq; ++i) { double a = fabs(W.tm[i]-d[i]); if (a>rpa) rpa=a; }
    for (idx_t i = neq; i < C.m; ++i) { double a = W.tm[i]-d[i]; if (a>rpa) rpa=a; }
    double sPri = normInf(W.tm, C.m);
    double dn = normInf(d, C.m);
    if (dn > sPri) sPri = dn;
    if (1.0 > sPri) sPri = 1.0;
    *rp = rpa/sPri;
    cscTMul(C, w, W.tn);                      /* tn = C' w */
    double sCw = normInf(W.tn, C.n);
    double rda = 0.0, sPz = 0.0;
    for (idx_t j = 0; j < C.n; ++j) {
        double Pz = Pd[j]*z[j];
        double gr = Pz + q[j] + W.tn[j];
        double pz = fabs(Pz); if (pz > sPz) sPz = pz;
        double a = fabs(z[j] - clip(z[j]-gr, lb[j], ub[j]));
        if (a > rda) rda = a;
    }
    double sDua = sPz;
    double qn = normInf(q, C.n); if (qn > sDua) sDua = qn;
    if (sCw > sDua) sDua = sCw;
    if (1.0 > sDua) sDua = 1.0;
    *rd = rda/sDua;
}

/* 実行不可能性の証明書 (0=なし, 2=primalInf, 3=dualInf) */
static int certCheck(const double *Pd, const double *q, const Csc &C,
                     const double *d, idx_t neq, const double *lb, const double *ub,
                     const double *dz, const double *dw, const Opt &o, Work &W) {
    double ndw = normInf(dw, C.m);
    if (ndw > o.certTol) {
        bool ok = true;
        for (idx_t i = neq; i < C.m; ++i)
            if (dw[i] < -o.certTol*ndw) { ok = false; break; }
        if (ok) {
            cscTMul(C, dw, W.tn);            /* v = C' dw */
            double sup = 0.0;  bool bad = false;
            for (idx_t j = 0; j < C.n; ++j) {
                double a = -W.tn[j]*lb[j], b = -W.tn[j]*ub[j];
                double s = a > b ? a : b;
                if (!mxIsFinite(s)) { bad = true; break; }
                sup += s;
            }
            if (!bad) {
                double dTw = 0.0;
                for (idx_t i = 0; i < C.m; ++i) dTw += d[i]*dw[i];
                if (dTw + sup < -o.certTol*ndw) return 2;
            }
        }
    }
    double ndz = normInf(dz, C.n);
    if (ndz > o.certTol) {
        bool ok = true;
        for (idx_t j = 0; j < C.n; ++j)
            if (fabs(Pd[j]*dz[j]) > o.certEps*ndz) { ok = false; break; }
        if (ok) {
            cscMul(C, dz, W.tm);             /* Cd = C dz */
            for (idx_t i = 0; i < neq && ok; ++i)
                if (fabs(W.tm[i]) > o.certEps*ndz) ok = false;
            for (idx_t i = neq; i < C.m && ok; ++i)
                if (W.tm[i] > o.certEps*ndz) ok = false;
        }
        if (ok) {
            bool rec = true;
            for (idx_t j = 0; j < C.n; ++j) {
                if (dz[j] >  o.certEps*ndz && mxIsFinite(ub[j])) { rec = false; break; }
                if (dz[j] < -o.certEps*ndz && mxIsFinite(lb[j])) { rec = false; break; }
            }
            if (rec) {
                double qdz = 0.0;
                for (idx_t j = 0; j < C.n; ++j) qdz += q[j]*dz[j];
                if (qdz < -o.certTol*ndz) return 3;
            }
        }
    }
    return 0;
}

/* PIPG 本体. 戻り値 = status コード. */
static int solve(const double *Pd, const double *q, const Csc &C, const double *d,
                 idx_t neq, const double *lb, const double *ub, const Opt &o,
                 double *z, double *w, Work &W,
                 int *itersOut, double *rpOut, double *rdOut) {
    const idx_t n = C.n, m = C.m;
    *itersOut = o.maxIter;  *rpOut = mxGetInf();  *rdOut = mxGetInf();

    /* 入力検証 */
    if (!allFinite(Pd,n) || !allFinite(q,n) || !allFinite(C.pr, C.jc[n]) ||
        !allFinite(d,m)) return 4;
    for (idx_t j = 0; j < n; ++j)
        if (mxIsNaN(lb[j]) || mxIsNaN(ub[j]) || lb[j] > ub[j]) return 4;

    /* ステップ幅: lam = max|Pd| (対角なので厳密), sig はべき乗法 */
    double lam = normInf(Pd, n);
    double sig = 0.0;
    for (idx_t j = 0; j < n; ++j) W.tn[j] = 1.0/sqrt((double)n);
    for (int it = 0; it < o.powerIter; ++it) {
        cscMul(C, W.tn, W.tm);
        cscTMul(C, W.tm, W.zc);              /* zc = C'C tn */
        sig = norm2(W.zc, n);
        if (sig < 2.2e-16) { sig = 0.0; break; }
        for (idx_t j = 0; j < n; ++j) W.tn[j] = W.zc[j]/sig;
    }
    double al = 2.0/(lam + sqrt(lam*lam + 4.0*o.omega*sig));
    double be = o.omega*al;
    if (!mxIsFinite(al) || !mxIsFinite(be) || al <= 0.0) {
        for (idx_t j = 0; j < n; ++j) z[j] = clip(z[j], lb[j], ub[j]);
        return 4;
    }

    memcpy(W.zb, z, n*sizeof(double));  memcpy(W.wb, w, m*sizeof(double));
    memcpy(W.zPrev, z, n*sizeof(double));  memcpy(W.wPrev, w, m*sizeof(double));
    memset(W.dzL, 0, n*sizeof(double));  memset(W.dwL, 0, m*sizeof(double));
    int status = 0;

    for (int k = 1; k <= o.maxIter; ++k) {
        /* zn = clip(zb - al*(P zb + q + C' wb)) */
        cscTMul(C, W.wb, W.tn);
        for (idx_t j = 0; j < n; ++j)
            W.zn[j] = clip(W.zb[j] - al*(Pd[j]*W.zb[j] + q[j] + W.tn[j]), lb[j], ub[j]);
        /* wn = wb + be*(C(2 zn - zb) - d), 不等式行は >= 0 に射影 */
        for (idx_t j = 0; j < n; ++j) W.zc[j] = 2.0*W.zn[j] - W.zb[j];
        cscMul(C, W.zc, W.tm);
        for (idx_t i = 0; i < m; ++i) {
            double v = W.wb[i] + be*(W.tm[i] - d[i]);
            if (i >= neq && v < 0.0) v = 0.0;
            W.wn[i] = v;
        }
        for (idx_t j = 0; j < n; ++j) W.zb[j] = (1.0-o.rho)*W.zb[j] + o.rho*W.zn[j];
        for (idx_t i = 0; i < m; ++i) W.wb[i] = (1.0-o.rho)*W.wb[i] + o.rho*W.wn[i];

        if (k % o.checkEvery == 0) {
            if (!allFinite(W.zn,n) || !allFinite(W.wn,m)) {
                *itersOut = k;
                for (idx_t j = 0; j < n; ++j) z[j] = clip(W.zPrev[j], lb[j], ub[j]);
                return 4;
            }
            for (idx_t j = 0; j < n; ++j) W.dzL[j] = W.zn[j] - W.zPrev[j];
            for (idx_t i = 0; i < m; ++i) W.dwL[i] = W.wn[i] - W.wPrev[i];
            memcpy(W.zPrev, W.zn, n*sizeof(double));
            memcpy(W.wPrev, W.wn, m*sizeof(double));
            for (idx_t j = 0; j < n; ++j) W.zc[j] = clip(W.zb[j], lb[j], ub[j]);
            double rp, rd;
            residuals(Pd, q, C, d, neq, lb, ub, W.zc, W.wb, W, &rp, &rd);
            if (rp < o.tolPri && rd < o.tolDua && !o.fixedIter) {
                *itersOut = k;  *rpOut = rp;  *rdOut = rd;
                memcpy(z, W.zc, n*sizeof(double));  memcpy(w, W.wb, m*sizeof(double));
                return 1;
            }
            if (!o.fixedIter && k >= o.certAfter) {
                int cs = certCheck(Pd, q, C, d, neq, lb, ub, W.dzL, W.dwL, o, W);
                if (cs > 0) {
                    *itersOut = k;
                    memcpy(z, W.zn, n*sizeof(double));  memcpy(w, W.wn, m*sizeof(double));
                    return cs;
                }
            }
        }
    }
    for (idx_t j = 0; j < n; ++j) z[j] = clip(W.zb[j], lb[j], ub[j]);
    memcpy(w, W.wb, m*sizeof(double));
    double rp, rd;
    residuals(Pd, q, C, d, neq, lb, ub, z, w, W, &rp, &rd);
    *rpOut = rp;  *rdOut = rd;
    if (rp < o.tolPri && rd < o.tolDua) status = 1;
    else if (o.fixedIter) {
        int cs = certCheck(Pd, q, C, d, neq, lb, ub, W.dzL, W.dwL, o, W);
        if (cs > 0) status = cs;
    }
    return status;
}

} /* namespace pipg */


/* ---------------- MEX ラッパ ---------------- */
static double getOptField(const mxArray *s, const char *name) {
    const mxArray *f = mxGetField(s, 0, name);
    if (!f) mexErrMsgIdAndTxt("pipg:opt", "opt.%s がありません", name);
    return mxGetScalar(f);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs != 10)
        mexErrMsgIdAndTxt("pipg:nrhs",
            "使い方: [z,status,iters,rp,rd,w] = pipg_mex(Pdiag,q,C,d,neq,lb,ub,opt,z0,w0)");
    if (!mxIsSparse(prhs[2]))
        mexErrMsgIdAndTxt("pipg:sparse", "C は疎行列で渡してください");

    pipg::Csc C;
    C.m = mxGetM(prhs[2]);  C.n = mxGetN(prhs[2]);
    C.ir = mxGetIr(prhs[2]);  C.jc = mxGetJc(prhs[2]);  C.pr = mxGetPr(prhs[2]);
    const double *Pd = mxGetPr(prhs[0]);
    const double *q  = mxGetPr(prhs[1]);
    const double *d  = mxGetPr(prhs[3]);
    pipg::idx_t neq  = (pipg::idx_t)mxGetScalar(prhs[4]);
    const double *lb = mxGetPr(prhs[5]);
    const double *ub = mxGetPr(prhs[6]);

    pipg::Opt o;
    o.maxIter   = (int)getOptField(prhs[7], "maxIter");
    o.fixedIter = (int)getOptField(prhs[7], "fixedIter");
    o.tolPri    = getOptField(prhs[7], "tolPri");
    o.tolDua    = getOptField(prhs[7], "tolDua");
    o.omega     = getOptField(prhs[7], "omega");
    o.rho       = getOptField(prhs[7], "rho");
    o.checkEvery= (int)getOptField(prhs[7], "checkEvery");
    o.powerIter = (int)getOptField(prhs[7], "powerIter");
    o.certAfter = (int)getOptField(prhs[7], "certAfter");
    o.certTol   = getOptField(prhs[7], "certTol");
    o.certEps   = getOptField(prhs[7], "certEps");

    const pipg::idx_t n = C.n, m = C.m;
    plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL);
    double *z = mxGetPr(plhs[0]);
    memcpy(z, mxGetPr(prhs[8]), n*sizeof(double));
    mxArray *wOut = mxCreateDoubleMatrix(m, 1, mxREAL);
    double *w = mxGetPr(wOut);
    memcpy(w, mxGetPr(prhs[9]), m*sizeof(double));

    /* バッファ一括確保 */
    pipg::Work W;
    W.zb = (double*)mxMalloc(n*sizeof(double));
    W.zn = (double*)mxMalloc(n*sizeof(double));
    W.zPrev = (double*)mxMalloc(n*sizeof(double));
    W.zc = (double*)mxMalloc(n*sizeof(double));
    W.tn = (double*)mxMalloc(n*sizeof(double));
    W.dzL = (double*)mxMalloc(n*sizeof(double));
    W.wb = (double*)mxMalloc(m*sizeof(double));
    W.wn = (double*)mxMalloc(m*sizeof(double));
    W.wPrev = (double*)mxMalloc(m*sizeof(double));
    W.tm = (double*)mxMalloc(m*sizeof(double));
    W.dwL = (double*)mxMalloc(m*sizeof(double));

    int iters = 0;  double rp = 0.0, rd = 0.0;
    int status = pipg::solve(Pd, q, C, d, neq, lb, ub, o, z, w, W, &iters, &rp, &rd);

    mxFree(W.zb); mxFree(W.zn); mxFree(W.zPrev); mxFree(W.zc); mxFree(W.tn);
    mxFree(W.dzL); mxFree(W.wb); mxFree(W.wn); mxFree(W.wPrev); mxFree(W.tm); mxFree(W.dwL);

    if (nlhs > 1) plhs[1] = mxCreateDoubleScalar((double)status);
    if (nlhs > 2) plhs[2] = mxCreateDoubleScalar((double)iters);
    if (nlhs > 3) plhs[3] = mxCreateDoubleScalar(rp);
    if (nlhs > 4) plhs[4] = mxCreateDoubleScalar(rd);
    if (nlhs > 5) plhs[5] = wOut; else mxDestroyArray(wOut);
}
