/* pipg_core.hpp — PIPG (箱制約付き凸QP) 純C++コア. 依存: <math.h> 相当のみ.
 *
 * MATLAB/MEX に依存しない単一ヘッダ実装. ターゲット環境へはこのファイルを
 * 持って行くだけでよい (mex ラッパは pipg_mex.cpp 側).
 *
 * 問題形式:  min 0.5 z'Pz + q'z  s.t. Cz {=,<=} d (先頭 neq 行が等式),
 *            lb <= z <= ub.  P は対角 (pd ベクトルで渡す), C は CSC 疎.
 *
 * エントリポイント (C リンケージ):
 *   int pipg_solve_csc(pd, q, n, m, neq, jc, ir, pr, d, lb, ub,
 *                      &opt, z, w, &iters, &resPri, &resDua);
 *   返り値 status: 0 maxIter / 1 converged / 2 primalInfeasible /
 *                  3 dualInfeasible / 4 numericalFailure
 *   z, w は入出力 (ウォームスタート / 解). 呼び出し側がバッファを所有する.
 *
 * 検証: MATLAB 参照実装 (scpk.solveQP) とビット一致 (buildPIPG.m).
 */
#ifndef PIPG_CORE_HPP
#define PIPG_CORE_HPP

#include <math.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

namespace pipg {

typedef int32_t idx_t;

struct Csc {                 /* CSC 疎行列 (所有しない) */
    idx_t m, n;
    const idx_t *ir, *jc;    /* 行インデックス / 列ポインタ (0始まり) */
    const double *pr;        /* 値 */
};

struct Opt {
    int maxIter, fixedIter, checkEvery, powerIter, certAfter;
    double tolPri, tolDua, omega, rho, certTol, certEps;
};

struct Work {                /* 事前確保バッファ (init/free 参照) */
    double *zb, *wb, *zn, *wn, *zPrev, *wPrev, *zc;
    double *tn, *tm, *dzL, *dwL;
};

inline int workInit(Work &W, idx_t n, idx_t m) {
    W.zb=(double*)malloc(n*sizeof(double)); W.zn=(double*)malloc(n*sizeof(double));
    W.zPrev=(double*)malloc(n*sizeof(double)); W.zc=(double*)malloc(n*sizeof(double));
    W.tn=(double*)malloc(n*sizeof(double)); W.dzL=(double*)malloc(n*sizeof(double));
    W.wb=(double*)malloc(m*sizeof(double)); W.wn=(double*)malloc(m*sizeof(double));
    W.wPrev=(double*)malloc(m*sizeof(double)); W.tm=(double*)malloc(m*sizeof(double));
    W.dwL=(double*)malloc(m*sizeof(double));
    return (W.zb&&W.zn&&W.zPrev&&W.zc&&W.tn&&W.dzL&&W.wb&&W.wn&&W.wPrev&&W.tm&&W.dwL) ? 0 : -1;
}
inline void workFree(Work &W) {
    free(W.zb); free(W.zn); free(W.zPrev); free(W.zc); free(W.tn); free(W.dzL);
    free(W.wb); free(W.wn); free(W.wPrev); free(W.tm); free(W.dwL);
}

inline void cscMul(const Csc &C, const double *x, double *y) {
    for (idx_t i = 0; i < C.m; ++i) y[i] = 0.0;
    for (idx_t j = 0; j < C.n; ++j) {
        const double xj = x[j];
        if (xj == 0.0) continue;
        for (idx_t k = C.jc[j]; k < C.jc[j+1]; ++k) y[C.ir[k]] += C.pr[k]*xj;
    }
}
inline void cscTMul(const Csc &C, const double *x, double *y) {
    for (idx_t j = 0; j < C.n; ++j) {
        double s = 0.0;
        for (idx_t k = C.jc[j]; k < C.jc[j+1]; ++k) s += C.pr[k]*x[C.ir[k]];
        y[j] = s;
    }
}
inline double normInf(const double *v, idx_t n) {
    double s = 0.0;
    for (idx_t i = 0; i < n; ++i) { double a = fabs(v[i]); if (a > s) s = a; }
    return s;
}
inline double norm2(const double *v, idx_t n) {
    double s = 0.0;
    for (idx_t i = 0; i < n; ++i) s += v[i]*v[i];
    return sqrt(s);
}
inline bool isFin(double v) { return v == v && v < 1e308 && v > -1e308; }
inline bool allFinite(const double *v, idx_t n) {
    for (idx_t i = 0; i < n; ++i) if (!isFin(v[i])) return false;
    return true;
}
inline double clip(double v, double lo, double hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

inline void residuals(const double *Pd, const double *q, const Csc &C,
                      const double *d, idx_t neq, const double *lb, const double *ub,
                      const double *z, const double *w, Work &W,
                      double *rp, double *rd) {
    cscMul(C, z, W.tm);
    double rpa = 0.0;
    for (idx_t i = 0; i < neq; ++i) { double a = fabs(W.tm[i]-d[i]); if (a>rpa) rpa=a; }
    for (idx_t i = neq; i < C.m; ++i) { double a = W.tm[i]-d[i]; if (a>rpa) rpa=a; }
    double sPri = normInf(W.tm, C.m);
    double dn = normInf(d, C.m);
    if (dn > sPri) sPri = dn;
    if (1.0 > sPri) sPri = 1.0;
    *rp = rpa/sPri;
    cscTMul(C, w, W.tn);
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

inline int certCheck(const double *Pd, const double *q, const Csc &C,
                     const double *d, idx_t neq, const double *lb, const double *ub,
                     const double *dz, const double *dw, const Opt &o, Work &W) {
    double ndw = normInf(dw, C.m);
    if (ndw > o.certTol) {
        bool ok = true;
        for (idx_t i = neq; i < C.m; ++i)
            if (dw[i] < -o.certTol*ndw) { ok = false; break; }
        if (ok) {
            cscTMul(C, dw, W.tn);
            double sup = 0.0;  bool bad = false;
            for (idx_t j = 0; j < C.n; ++j) {
                double a = -W.tn[j]*lb[j], b = -W.tn[j]*ub[j];
                double s = a > b ? a : b;
                if (!isFin(s)) { bad = true; break; }
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
            cscMul(C, dz, W.tm);
            for (idx_t i = 0; i < neq && ok; ++i)
                if (fabs(W.tm[i]) > o.certEps*ndz) ok = false;
            for (idx_t i = neq; i < C.m && ok; ++i)
                if (W.tm[i] > o.certEps*ndz) ok = false;
        }
        if (ok) {
            bool rec = true;
            for (idx_t j = 0; j < C.n; ++j) {
                if (dz[j] >  o.certEps*ndz && isFin(ub[j])) { rec = false; break; }
                if (dz[j] < -o.certEps*ndz && isFin(lb[j])) { rec = false; break; }
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

/* PIPG 本体. z, w は入出力 (ウォームスタート). */
inline int solve(const double *Pd, const double *q, const Csc &C, const double *d,
                 idx_t neq, const double *lb, const double *ub, const Opt &o,
                 double *z, double *w, Work &W,
                 int *itersOut, double *rpOut, double *rdOut) {
    const idx_t n = C.n, m = C.m;
    *itersOut = o.maxIter;  *rpOut = 1e308;  *rdOut = 1e308;

    if (!allFinite(Pd,n) || !allFinite(q,n) || !allFinite(C.pr, C.jc[n]) ||
        !allFinite(d,m)) return 4;
    for (idx_t j = 0; j < n; ++j)
        if (lb[j] != lb[j] || ub[j] != ub[j] || lb[j] > ub[j]) return 4;

    double lam = normInf(Pd, n);
    double sig = 0.0;
    for (idx_t j = 0; j < n; ++j) W.tn[j] = 1.0/sqrt((double)n);
    for (int it = 0; it < o.powerIter; ++it) {
        cscMul(C, W.tn, W.tm);
        cscTMul(C, W.tm, W.zc);
        sig = norm2(W.zc, n);
        if (sig < 2.2e-16) { sig = 0.0; break; }
        for (idx_t j = 0; j < n; ++j) W.tn[j] = W.zc[j]/sig;
    }
    double al = 2.0/(lam + sqrt(lam*lam + 4.0*o.omega*sig));
    double be = o.omega*al;
    if (!isFin(al) || al <= 0.0) {
        for (idx_t j = 0; j < n; ++j) z[j] = clip(z[j], lb[j], ub[j]);
        return 4;
    }

    memcpy(W.zb, z, n*sizeof(double));  memcpy(W.wb, w, m*sizeof(double));
    memcpy(W.zPrev, z, n*sizeof(double));  memcpy(W.wPrev, w, m*sizeof(double));
    memset(W.dzL, 0, n*sizeof(double));  memset(W.dwL, 0, m*sizeof(double));
    int status = 0;

    for (int k = 1; k <= o.maxIter; ++k) {
        cscTMul(C, W.wb, W.tn);
        for (idx_t j = 0; j < n; ++j) {
            double zv = W.zb[j] - al*(Pd[j]*W.zb[j] + q[j] + W.tn[j]);
            W.zn[j] = clip(zv, lb[j], ub[j]);
        }
        for (idx_t j = 0; j < n; ++j) W.zc[j] = 2.0*W.zn[j] - W.zb[j];
        cscMul(C, W.zc, W.tm);
        for (idx_t i = 0; i < m; ++i) {
            double wv = W.wb[i] + be*(W.tm[i] - d[i]);
            if (i >= neq && wv < 0.0) wv = 0.0;
            W.wn[i] = wv;
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

/* ---------- C リンケージのエントリポイント ---------- */
extern "C" inline int pipg_solve_csc(
    const double *Pd, const double *q, int32_t n, int32_t m, int32_t neq,
    const int32_t *jc, const int32_t *ir, const double *pr,
    const double *d, const double *lb, const double *ub,
    const pipg::Opt *opt, double *z, double *w,
    int *iters, double *resPri, double *resDua)
{
    pipg::Csc C;  C.m = m;  C.n = n;  C.ir = ir;  C.jc = jc;  C.pr = pr;
    pipg::Work W;
    if (pipg::workInit(W, n, m) != 0) return 4;
    int st = pipg::solve(Pd, q, C, d, neq, lb, ub, *opt, z, w, W, iters, resPri, resDua);
    pipg::workFree(W);
    return st;
}

#endif /* PIPG_CORE_HPP */
