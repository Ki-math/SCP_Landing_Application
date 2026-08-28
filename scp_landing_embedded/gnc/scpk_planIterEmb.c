/*
 * File: scpk_planIterEmb.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 22:18:33
 */

/* Include Files */
#include "scpk_planIterEmb.h"
#include "abs.h"
#include "gncCore_lib_emxutil.h"
#include "gncCore_lib_rtwutil.h"
#include "gncCore_lib_types.h"
#include "linDisc6All.h"
#include "mod.h"
#include "rt_nonfinite.h"
#include "rt_nonfinite.h"
#include <emmintrin.h>
#include <math.h>
#include <string.h>

/* Function Declarations */
static int pipgCsc(const emxArray_real_T *Pd, const emxArray_real_T *q,
                   const emxArray_real_T *jc, const emxArray_real_T *ir,
                   const emxArray_real_T *vv, const emxArray_real_T *d,
                   double neq, double m, double n, const emxArray_real_T *lb,
                   const emxArray_real_T *ub, const struct4_T *o,
                   emxArray_real_T *z0, int *iters);

static double residCsc(const emxArray_real_T *Pd, const emxArray_real_T *q,
                       const emxArray_real_T *jc, const emxArray_real_T *ir,
                       const emxArray_real_T *vv, const emxArray_real_T *d,
                       double neq, double m, double n,
                       const emxArray_real_T *lb, const emxArray_real_T *ub,
                       const emxArray_real_T *z, const emxArray_real_T *w,
                       double *rd);

static double ruizCsc(const emxArray_real_T *jc, const emxArray_real_T *ir,
                      const emxArray_real_T *vv, double m, double n,
                      const emxArray_real_T *Pd, emxArray_real_T *colS,
                      emxArray_real_T *rowS);

static void tri2csc(const double ti[90000], const double tj[90000],
                    const double tv[90000], double nt, double n,
                    emxArray_real_T *jc, emxArray_real_T *ir,
                    emxArray_real_T *vv);

/* Function Definitions */
/*
 * PIPGCSC  PIPG (pipg_mex.cpp / solveQPEmb と同一アルゴリズム, CSC明示ループ).
 *
 * Arguments    : const emxArray_real_T *Pd
 *                const emxArray_real_T *q
 *                const emxArray_real_T *jc
 *                const emxArray_real_T *ir
 *                const emxArray_real_T *vv
 *                const emxArray_real_T *d
 *                double neq
 *                double m
 *                double n
 *                const emxArray_real_T *lb
 *                const emxArray_real_T *ub
 *                const struct4_T *o
 *                emxArray_real_T *z0
 *                int *iters
 * Return Type  : int
 */
static int pipgCsc(const emxArray_real_T *Pd, const emxArray_real_T *q,
                   const emxArray_real_T *jc, const emxArray_real_T *ir,
                   const emxArray_real_T *vv, const emxArray_real_T *d,
                   double neq, double m, double n, const emxArray_real_T *lb,
                   const emxArray_real_T *ub, const struct4_T *o,
                   emxArray_real_T *z0, int *iters)
{
  __m128d r;
  emxArray_real_T *tmpm;
  emxArray_real_T *tmpn;
  emxArray_real_T *w;
  emxArray_real_T *x;
  emxArray_real_T *zPrev;
  const double *Pd_data;
  const double *d_data;
  const double *ir_data;
  const double *jc_data;
  const double *lb_data;
  const double *q_data;
  const double *ub_data;
  const double *vv_data;
  double al;
  double b_k;
  double be;
  double lam;
  double s;
  double sig;
  double *tmpm_data;
  double *tmpn_data;
  double *w_data;
  double *x_data;
  double *z0_data;
  double *zPrev_data;
  int b_loop_ub_tmp;
  int i;
  int it;
  int j;
  int k;
  int loop_ub_tmp;
  int st;
  int tmpm_tmp;
  bool bad;
  bool exitg1;
  z0_data = z0->data;
  ub_data = ub->data;
  lb_data = lb->data;
  d_data = d->data;
  vv_data = vv->data;
  ir_data = ir->data;
  jc_data = jc->data;
  q_data = q->data;
  Pd_data = Pd->data;
  emxInit_real_T(&w, 1);
  loop_ub_tmp = (int)m;
  i = w->size[0];
  w->size[0] = (int)m;
  emxEnsureCapacity_real_T(w, i);
  w_data = w->data;
  for (i = 0; i < loop_ub_tmp; i++) {
    w_data[i] = 0.0;
  }
  st = 0;
  sig = rt_roundd_snf(o->maxIter);
  if (sig < 2.147483648E+9) {
    if (sig >= -2.147483648E+9) {
      *iters = (int)sig;
    } else {
      *iters = MIN_int32_T;
    }
  } else if (sig >= 2.147483648E+9) {
    *iters = MAX_int32_T;
  } else {
    *iters = 0;
  }
  lam = 0.0;
  b_loop_ub_tmp = (int)n;
  for (j = 0; j < b_loop_ub_tmp; j++) {
    sig = fabs(Pd_data[j]);
    if (sig > lam) {
      lam = sig;
    }
  }
  sig = sqrt(n);
  emxInit_real_T(&x, 1);
  i = x->size[0];
  x->size[0] = (int)n;
  emxEnsureCapacity_real_T(x, i);
  x_data = x->data;
  for (i = 0; i < b_loop_ub_tmp; i++) {
    x_data[i] = 1.0 / sig;
  }
  sig = 0.0;
  emxInit_real_T(&tmpn, 1);
  i = tmpn->size[0];
  tmpn->size[0] = (int)n;
  emxEnsureCapacity_real_T(tmpn, i);
  tmpn_data = tmpn->data;
  for (i = 0; i < b_loop_ub_tmp; i++) {
    tmpn_data[i] = 0.0;
  }
  it = 0;
  emxInit_real_T(&tmpm, 1);
  exitg1 = false;
  while ((!exitg1) && (it <= (int)o->powerIter - 1)) {
    i = tmpm->size[0];
    tmpm->size[0] = (int)m;
    emxEnsureCapacity_real_T(tmpm, i);
    tmpm_data = tmpm->data;
    for (i = 0; i < loop_ub_tmp; i++) {
      tmpm_data[i] = 0.0;
    }
    for (j = 0; j < b_loop_ub_tmp; j++) {
      if (x_data[j] != 0.0) {
        i = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
        for (k = 0; k < i; k++) {
          b_k = jc_data[j] + (double)k;
          tmpm_tmp = (int)ir_data[(int)b_k - 1] - 1;
          tmpm_data[tmpm_tmp] += vv_data[(int)b_k - 1] * x_data[j];
        }
      }
    }
    i = tmpn->size[0];
    tmpn->size[0] = (int)n;
    emxEnsureCapacity_real_T(tmpn, i);
    tmpn_data = tmpn->data;
    sig = 0.0;
    for (j = 0; j < b_loop_ub_tmp; j++) {
      s = 0.0;
      i = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
      for (k = 0; k < i; k++) {
        b_k = jc_data[j] + (double)k;
        s += vv_data[(int)b_k - 1] * tmpm_data[(int)ir_data[(int)b_k - 1] - 1];
      }
      tmpn_data[j] = s;
      sig += s * s;
    }
    sig = sqrt(sig);
    if (sig < 2.2204460492503131E-16) {
      sig = 0.0;
      exitg1 = true;
    } else {
      tmpm_tmp = ((int)n / 2) << 1;
      k = tmpm_tmp - 2;
      for (j = 0; j <= k; j += 2) {
        r = _mm_loadu_pd(&tmpn_data[j]);
        _mm_storeu_pd(&x_data[j], _mm_div_pd(r, _mm_set1_pd(sig)));
      }
      for (j = tmpm_tmp; j < b_loop_ub_tmp; j++) {
        x_data[j] = tmpn_data[j] / sig;
      }
      it++;
    }
  }
  al = 2.0 / (lam + sqrt(lam * lam + 4.0 * o->omega * sig));
  be = o->omega * al;
  bad = ((!rtIsInf(al)) && (!rtIsNaN(al)));
  emxInit_real_T(&zPrev, 1);
  if ((!bad) || (al <= 0.0)) {
    st = 4;
  } else {
    tmpm_tmp = z0->size[0];
    i = x->size[0];
    x->size[0] = tmpm_tmp;
    emxEnsureCapacity_real_T(x, i);
    x_data = x->data;
    i = zPrev->size[0];
    zPrev->size[0] = tmpm_tmp;
    emxEnsureCapacity_real_T(zPrev, i);
    zPrev_data = zPrev->data;
    for (i = 0; i < tmpm_tmp; i++) {
      x_data[i] = z0_data[i];
      zPrev_data[i] = z0_data[i];
    }
    it = 0;
    int exitg2;
    do {
      exitg2 = 0;
      if (it <= (int)o->maxIter - 1) {
        __m128d r1;
        /*  zn = clip(zb - al*(P zb + q + C' wb)) */
        for (j = 0; j < b_loop_ub_tmp; j++) {
          s = 0.0;
          i = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
          for (k = 0; k < i; k++) {
            b_k = jc_data[j] + (double)k;
            s += vv_data[(int)b_k - 1] * w_data[(int)ir_data[(int)b_k - 1] - 1];
          }
          sig = x_data[j] - al * ((Pd_data[j] * x_data[j] + q_data[j]) + s);
          if (sig < lb_data[j]) {
            sig = lb_data[j];
          } else if (sig > ub_data[j]) {
            sig = ub_data[j];
          }
          tmpn_data[j] = sig;
        }
        /*  wn = wb + be*(C(2 zn - zb) - d) */
        i = tmpm->size[0];
        tmpm->size[0] = (int)m;
        emxEnsureCapacity_real_T(tmpm, i);
        tmpm_data = tmpm->data;
        for (i = 0; i < loop_ub_tmp; i++) {
          tmpm_data[i] = 0.0;
        }
        for (j = 0; j < b_loop_ub_tmp; j++) {
          sig = 2.0 * tmpn_data[j] - x_data[j];
          if (sig != 0.0) {
            i = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
            for (k = 0; k < i; k++) {
              b_k = jc_data[j] + (double)k;
              tmpm_tmp = (int)ir_data[(int)b_k - 1] - 1;
              tmpm_data[tmpm_tmp] += vv_data[(int)b_k - 1] * sig;
            }
          }
        }
        for (i = 0; i < loop_ub_tmp; i++) {
          sig = w_data[i] + be * (tmpm_data[i] - d_data[i]);
          if (((double)i + 1.0 > neq) && (sig < 0.0)) {
            sig = 0.0;
          }
          tmpm_data[i] = sig;
        }
        tmpm_tmp = ((int)n / 2) << 1;
        k = tmpm_tmp - 2;
        for (j = 0; j <= k; j += 2) {
          r = _mm_loadu_pd(&x_data[j]);
          r1 = _mm_loadu_pd(&tmpn_data[j]);
          _mm_storeu_pd(&x_data[j],
                        _mm_add_pd(_mm_mul_pd(_mm_set1_pd(1.0 - o->rho), r),
                                   _mm_mul_pd(_mm_set1_pd(o->rho), r1)));
        }
        for (j = tmpm_tmp; j < b_loop_ub_tmp; j++) {
          x_data[j] = (1.0 - o->rho) * x_data[j] + o->rho * tmpn_data[j];
        }
        tmpm_tmp = ((int)m / 2) << 1;
        k = tmpm_tmp - 2;
        for (i = 0; i <= k; i += 2) {
          r = _mm_loadu_pd(&w_data[i]);
          r1 = _mm_loadu_pd(&tmpm_data[i]);
          _mm_storeu_pd(&w_data[i],
                        _mm_add_pd(_mm_mul_pd(_mm_set1_pd(1.0 - o->rho), r),
                                   _mm_mul_pd(_mm_set1_pd(o->rho), r1)));
        }
        for (i = tmpm_tmp; i < loop_ub_tmp; i++) {
          w_data[i] = (1.0 - o->rho) * w_data[i] + o->rho * tmpm_data[i];
        }
        if (b_mod((double)it + 1.0, o->checkEvery) == 0.0) {
          bad = false;
          j = 0;
          exitg1 = false;
          while ((!exitg1) && (j <= (int)n - 1)) {
            if (rtIsInf(tmpn_data[j]) || rtIsNaN(tmpn_data[j])) {
              bad = true;
              exitg1 = true;
            } else {
              j++;
            }
          }
          if (!bad) {
            i = 0;
            exitg1 = false;
            while ((!exitg1) && (i <= (int)m - 1)) {
              if (rtIsInf(tmpm_data[i]) || rtIsNaN(tmpm_data[i])) {
                bad = true;
                exitg1 = true;
              } else {
                i++;
              }
            }
          }
          if (bad) {
            st = 4;
            if ((double)it + 1.0 < 2.147483648E+9) {
              *iters = it + 1;
            } else {
              *iters = MAX_int32_T;
            }
            tmpm_tmp = zPrev->size[0];
            i = z0->size[0];
            z0->size[0] = zPrev->size[0];
            emxEnsureCapacity_real_T(z0, i);
            z0_data = z0->data;
            for (i = 0; i < tmpm_tmp; i++) {
              z0_data[i] = zPrev_data[i];
            }
            exitg2 = 1;
          } else {
            i = zPrev->size[0];
            zPrev->size[0] = (int)n;
            emxEnsureCapacity_real_T(zPrev, i);
            zPrev_data = zPrev->data;
            for (i = 0; i < b_loop_ub_tmp; i++) {
              zPrev_data[i] = tmpn_data[i];
            }
            /*  残差 */
            sig = residCsc(Pd, q, jc, ir, vv, d, neq, m, n, lb, ub, x, w, &lam);
            if ((sig < o->tolPri) && (lam < o->tolDua) &&
                (!(o->fixedIter > 0.0))) {
              st = 1;
              if ((double)it + 1.0 < 2.147483648E+9) {
                *iters = it + 1;
              } else {
                *iters = MAX_int32_T;
              }
              for (j = 0; j < b_loop_ub_tmp; j++) {
                z0_data[j] = x_data[j];
                if (x_data[j] < lb_data[j]) {
                  z0_data[j] = lb_data[j];
                } else if (x_data[j] > ub_data[j]) {
                  z0_data[j] = ub_data[j];
                }
              }
              exitg2 = 1;
            } else {
              it++;
            }
          }
        } else {
          it++;
        }
      } else {
        for (j = 0; j < b_loop_ub_tmp; j++) {
          z0_data[j] = x_data[j];
          if (x_data[j] < lb_data[j]) {
            z0_data[j] = lb_data[j];
          } else if (x_data[j] > ub_data[j]) {
            z0_data[j] = ub_data[j];
          }
        }
        sig = residCsc(Pd, q, jc, ir, vv, d, neq, m, n, lb, ub, z0, w, &lam);
        if ((sig < o->tolPri) && (lam < o->tolDua)) {
          st = 1;
        }
        exitg2 = 1;
      }
    } while (exitg2 == 0);
  }
  emxFree_real_T(&zPrev);
  emxFree_real_T(&tmpn);
  emxFree_real_T(&tmpm);
  emxFree_real_T(&x);
  emxFree_real_T(&w);
  return st;
}

/*
 * Arguments    : const emxArray_real_T *Pd
 *                const emxArray_real_T *q
 *                const emxArray_real_T *jc
 *                const emxArray_real_T *ir
 *                const emxArray_real_T *vv
 *                const emxArray_real_T *d
 *                double neq
 *                double m
 *                double n
 *                const emxArray_real_T *lb
 *                const emxArray_real_T *ub
 *                const emxArray_real_T *z
 *                const emxArray_real_T *w
 *                double *rd
 * Return Type  : double
 */
static double residCsc(const emxArray_real_T *Pd, const emxArray_real_T *q,
                       const emxArray_real_T *jc, const emxArray_real_T *ir,
                       const emxArray_real_T *vv, const emxArray_real_T *d,
                       double neq, double m, double n,
                       const emxArray_real_T *lb, const emxArray_real_T *ub,
                       const emxArray_real_T *z, const emxArray_real_T *w,
                       double *rd)
{
  emxArray_real_T *Cz;
  const double *Pd_data;
  const double *d_data;
  const double *ir_data;
  const double *jc_data;
  const double *lb_data;
  const double *q_data;
  const double *ub_data;
  const double *vv_data;
  const double *w_data;
  const double *z_data;
  double a;
  double b_d;
  double rda;
  double rp;
  double rpa;
  double sDua;
  double *Cz_data;
  int Cz_tmp;
  int i;
  int i1;
  int j;
  int k;
  int loop_ub_tmp;
  w_data = w->data;
  z_data = z->data;
  ub_data = ub->data;
  lb_data = lb->data;
  d_data = d->data;
  vv_data = vv->data;
  ir_data = ir->data;
  jc_data = jc->data;
  q_data = q->data;
  Pd_data = Pd->data;
  emxInit_real_T(&Cz, 1);
  loop_ub_tmp = (int)m;
  i = Cz->size[0];
  Cz->size[0] = (int)m;
  emxEnsureCapacity_real_T(Cz, i);
  Cz_data = Cz->data;
  for (i = 0; i < loop_ub_tmp; i++) {
    Cz_data[i] = 0.0;
  }
  i = (int)n;
  for (j = 0; j < i; j++) {
    if (z_data[j] != 0.0) {
      i1 = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
      for (k = 0; k < i1; k++) {
        a = jc_data[j] + (double)k;
        Cz_tmp = (int)ir_data[(int)a - 1] - 1;
        Cz_data[Cz_tmp] += vv_data[(int)a - 1] * z_data[j];
      }
    }
  }
  rpa = 0.0;
  i1 = (int)neq;
  for (Cz_tmp = 0; Cz_tmp < i1; Cz_tmp++) {
    a = fabs(Cz_data[Cz_tmp] - d_data[Cz_tmp]);
    if (a > rpa) {
      rpa = a;
    }
  }
  i1 = (int)(m + (1.0 - (neq + 1.0)));
  for (Cz_tmp = 0; Cz_tmp < i1; Cz_tmp++) {
    a = (neq + 1.0) + (double)Cz_tmp;
    a = Cz_data[(int)a - 1] - d_data[(int)a - 1];
    if (a > rpa) {
      rpa = a;
    }
  }
  a = 1.0;
  for (Cz_tmp = 0; Cz_tmp < loop_ub_tmp; Cz_tmp++) {
    b_d = fabs(Cz_data[Cz_tmp]);
    if (b_d > a) {
      a = b_d;
    }
    b_d = fabs(d_data[Cz_tmp]);
    if (b_d > a) {
      a = b_d;
    }
  }
  emxFree_real_T(&Cz);
  rp = rpa / a;
  rda = 0.0;
  sDua = 1.0;
  for (j = 0; j < i; j++) {
    double s;
    s = 0.0;
    i1 = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
    for (k = 0; k < i1; k++) {
      a = jc_data[j] + (double)k;
      s += vv_data[(int)a - 1] * w_data[(int)ir_data[(int)a - 1] - 1];
    }
    rpa = Pd_data[j] * z_data[j];
    a = z_data[j] - ((rpa + q_data[j]) + s);
    if (a < lb_data[j]) {
      a = lb_data[j];
    } else if (a > ub_data[j]) {
      a = ub_data[j];
    }
    a = fabs(z_data[j] - a);
    if (a > rda) {
      rda = a;
    }
    b_d = fabs(rpa);
    if (b_d > sDua) {
      sDua = b_d;
    }
    b_d = fabs(q_data[j]);
    if (b_d > sDua) {
      sDua = b_d;
    }
    b_d = fabs(s);
    if (b_d > sDua) {
      sDua = b_d;
    }
  }
  *rd = rda / sDua;
  return rp;
}

/*
 * RUIZCSC  Ruiz 平衡化 (ruiz_mex.cpp と同一).
 *
 * Arguments    : const emxArray_real_T *jc
 *                const emxArray_real_T *ir
 *                const emxArray_real_T *vv
 *                double m
 *                double n
 *                const emxArray_real_T *Pd
 *                emxArray_real_T *colS
 *                emxArray_real_T *rowS
 * Return Type  : double
 */
static double ruizCsc(const emxArray_real_T *jc, const emxArray_real_T *ir,
                      const emxArray_real_T *vv, double m, double n,
                      const emxArray_real_T *Pd, emxArray_real_T *colS,
                      emxArray_real_T *rowS)
{
  emxArray_real_T *cn;
  emxArray_real_T *pd;
  emxArray_real_T *rn;
  emxArray_real_T *va;
  double dv[2];
  const double *ir_data;
  const double *jc_data;
  double cs;
  double *cn_data;
  double *colS_data;
  double *pd_data;
  double *rn_data;
  double *rowS_data;
  double *va_data;
  int b_loop_ub_tmp;
  int i;
  int it;
  int j;
  int k;
  int loop_ub;
  int loop_ub_tmp;
  int scalarLB_tmp;
  int vectorUB_tmp;
  ir_data = ir->data;
  jc_data = jc->data;
  emxInit_real_T(&pd, 1);
  b_abs(vv, pd);
  pd_data = pd->data;
  emxInit_real_T(&va, 1);
  loop_ub = pd->size[0];
  i = va->size[0];
  va->size[0] = pd->size[0];
  emxEnsureCapacity_real_T(va, i);
  va_data = va->data;
  for (i = 0; i < loop_ub; i++) {
    va_data[i] = pd_data[i];
  }
  b_abs(Pd, pd);
  pd_data = pd->data;
  loop_ub_tmp = (int)n;
  i = colS->size[0];
  colS->size[0] = (int)n;
  emxEnsureCapacity_real_T(colS, i);
  colS_data = colS->data;
  for (i = 0; i < loop_ub_tmp; i++) {
    colS_data[i] = 1.0;
  }
  b_loop_ub_tmp = (int)m;
  i = rowS->size[0];
  rowS->size[0] = (int)m;
  emxEnsureCapacity_real_T(rowS, i);
  rowS_data = rowS->data;
  for (i = 0; i < b_loop_ub_tmp; i++) {
    rowS_data[i] = 1.0;
  }
  emxInit_real_T(&rn, 1);
  i = rn->size[0];
  rn->size[0] = (int)m;
  emxEnsureCapacity_real_T(rn, i);
  emxInit_real_T(&cn, 1);
  scalarLB_tmp = ((int)m / 2) << 1;
  vectorUB_tmp = scalarLB_tmp - 2;
  for (it = 0; it < 15; it++) {
    __m128d r;
    double d;
    loop_ub = rn->size[0];
    i = rn->size[0];
    rn->size[0] = loop_ub;
    emxEnsureCapacity_real_T(rn, i);
    rn_data = rn->data;
    for (i = 0; i < loop_ub; i++) {
      rn_data[i] = 0.0;
    }
    for (j = 0; j < loop_ub_tmp; j++) {
      i = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
      for (k = 0; k < i; k++) {
        cs = jc_data[j] + (double)k;
        d = va_data[(int)cs - 1];
        loop_ub = (int)ir_data[(int)cs - 1] - 1;
        if (d > rn_data[loop_ub]) {
          rn_data[loop_ub] = d;
        }
      }
    }
    for (loop_ub = 0; loop_ub <= vectorUB_tmp; loop_ub += 2) {
      dv[0] = fmax(rn_data[loop_ub], 1.0E-12);
      dv[1] = fmax(rn_data[loop_ub + 1], 1.0E-12);
      r = _mm_loadu_pd(&dv[0]);
      _mm_storeu_pd(&rn_data[loop_ub], _mm_sqrt_pd(r));
    }
    for (loop_ub = scalarLB_tmp; loop_ub < b_loop_ub_tmp; loop_ub++) {
      rn_data[loop_ub] = sqrt(fmax(rn_data[loop_ub], 1.0E-12));
    }
    i = cn->size[0];
    cn->size[0] = (int)n;
    emxEnsureCapacity_real_T(cn, i);
    cn_data = cn->data;
    for (j = 0; j < loop_ub_tmp; j++) {
      cs = pd_data[j];
      i = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
      for (k = 0; k < i; k++) {
        d = va_data[(int)(jc_data[j] + (double)k) - 1];
        if (d > cs) {
          cs = d;
        }
      }
      cn_data[j] = sqrt(fmax(cs, 1.0E-12));
    }
    for (j = 0; j < loop_ub_tmp; j++) {
      i = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
      for (k = 0; k < i; k++) {
        cs = jc_data[j] + (double)k;
        va_data[(int)cs - 1] /=
            rn_data[(int)ir_data[(int)cs - 1] - 1] * cn_data[j];
      }
      pd_data[j] /= cn_data[j] * cn_data[j];
      colS_data[j] /= cn_data[j];
    }
    for (loop_ub = 0; loop_ub <= vectorUB_tmp; loop_ub += 2) {
      __m128d r1;
      r = _mm_loadu_pd(&rowS_data[loop_ub]);
      r1 = _mm_loadu_pd(&rn_data[loop_ub]);
      _mm_storeu_pd(&rowS_data[loop_ub], _mm_mul_pd(r, r1));
    }
    for (loop_ub = scalarLB_tmp; loop_ub < b_loop_ub_tmp; loop_ub++) {
      rowS_data[loop_ub] *= rn_data[loop_ub];
    }
  }
  emxFree_real_T(&cn);
  emxFree_real_T(&rn);
  emxFree_real_T(&va);
  cs = 1.0E-12;
  for (j = 0; j < loop_ub_tmp; j++) {
    if (pd_data[j] > cs) {
      cs = pd_data[j];
    }
  }
  emxFree_real_T(&pd);
  return 1.0 / cs;
}

/*
 * TRI2CSC  トリプレット -> CSC (列カウント + 前置和 + scatter).
 *
 * Arguments    : const double ti[90000]
 *                const double tj[90000]
 *                const double tv[90000]
 *                double nt
 *                double n
 *                emxArray_real_T *jc
 *                emxArray_real_T *ir
 *                emxArray_real_T *vv
 * Return Type  : void
 */
static void tri2csc(const double ti[90000], const double tj[90000],
                    const double tv[90000], double nt, double n,
                    emxArray_real_T *jc, emxArray_real_T *ir,
                    emxArray_real_T *vv)
{
  emxArray_real_T *cnt;
  double *cnt_data;
  double *ir_data;
  double *jc_data;
  double *vv_data;
  int b_loop_ub_tmp;
  int cnt_tmp;
  int k;
  int loop_ub_tmp;
  emxInit_real_T(&cnt, 1);
  loop_ub_tmp = (int)n;
  k = cnt->size[0];
  cnt->size[0] = (int)n;
  emxEnsureCapacity_real_T(cnt, k);
  cnt_data = cnt->data;
  for (k = 0; k < loop_ub_tmp; k++) {
    cnt_data[k] = 0.0;
  }
  b_loop_ub_tmp = (int)nt;
  for (k = 0; k < b_loop_ub_tmp; k++) {
    cnt_tmp = (int)tj[k] - 1;
    cnt_data[cnt_tmp]++;
  }
  cnt_tmp = (int)(n + 1.0);
  k = jc->size[0];
  jc->size[0] = (int)(n + 1.0);
  emxEnsureCapacity_real_T(jc, k);
  jc_data = jc->data;
  for (k = 0; k < cnt_tmp; k++) {
    jc_data[k] = 0.0;
  }
  jc_data[0] = 1.0;
  for (cnt_tmp = 0; cnt_tmp < loop_ub_tmp; cnt_tmp++) {
    jc_data[cnt_tmp + 1] = jc_data[cnt_tmp] + cnt_data[cnt_tmp];
  }
  k = cnt->size[0];
  cnt->size[0] = (int)n;
  emxEnsureCapacity_real_T(cnt, k);
  cnt_data = cnt->data;
  for (k = 0; k < loop_ub_tmp; k++) {
    cnt_data[k] = 0.0;
  }
  k = ir->size[0];
  ir->size[0] = (int)nt;
  emxEnsureCapacity_real_T(ir, k);
  ir_data = ir->data;
  for (k = 0; k < b_loop_ub_tmp; k++) {
    ir_data[k] = 0.0;
  }
  k = vv->size[0];
  vv->size[0] = (int)nt;
  emxEnsureCapacity_real_T(vv, k);
  vv_data = vv->data;
  for (k = 0; k < b_loop_ub_tmp; k++) {
    vv_data[k] = 0.0;
  }
  for (k = 0; k < b_loop_ub_tmp; k++) {
    double p;
    double p_tmp;
    cnt_tmp = (int)tj[k] - 1;
    p_tmp = cnt_data[cnt_tmp];
    p = jc_data[cnt_tmp] + p_tmp;
    ir_data[(int)p - 1] = ti[k];
    vv_data[(int)p - 1] = tv[k];
    cnt_data[cnt_tmp] = p_tmp + 1.0;
  }
  emxFree_real_T(&cnt);
  /*  行数は検査用 (未使用) */
}

/*
 * PLANITEREMB  計画SCPの1反復を単一関数で実行 (組み込み/フルC生成用).
 *
 *    [XS,US,GS,SS,ST,ITERS,NU,STEP] = PLANITEREMB(...)
 *
 *    処理: 線形化+離散化 -> QP組立(トリプレット->CSC) -> Ruiz -> PIPG -> 復元.
 *    buildPlan6 + precondition + solveQP と同一の数学 (等価性はテストで担保).
 *    疎行列型を使わず全て明示ループ/配列で書く (生成Cが手書き同等の速度).
 *
 *    入力 (全て数値):
 *      X0ND 14x1 初期状態(モデル無次元), XT 12x1 終端目標
 *      XL 14x(N+1), UL 7xN, GL 1xN, SIGL 1xnPh  線形化点
 *      PHASE 1xN, ENG 1xN, DTV 1xN, TILTN 1x(N+1) 傾斜上限[rad] (179deg=無効)
 *      CFG   scpk.model6 の struct
 *      PP    計画パラメータ (scpk.planParams で生成; 数値のみ)
 *      QP    PIPG設定 (maxIter,fixedIter,tolPri,tolDua,omega,rho,checkEvery,
 *              powerIter,certAfter,certTol,certEps)
 *    出力: 更新された線形化点 XS/US/GS/SS, QPステータス ST (0-4), 反復数,
 *          仮想制御和 NU, ステップ幅 STEP (許容誤差単位).
 *
 *    See also SCPK.PLANPARAMS, SCPK.PLAN6FT, SCPK.BUILDPLAN6
 *
 * Arguments    : const double x0nd[14]
 *                const double xT[12]
 *                const double xl_data[]
 *                const int xl_size[2]
 *                const double ul_data[]
 *                const int ul_size[2]
 *                const double gl_data[]
 *                const int gl_size[2]
 *                const double sigl_data[]
 *                const int sigl_size[2]
 *                const double phase_data[]
 *                const int phase_size[2]
 *                const double eng_data[]
 *                const int eng_size[2]
 *                const double dtv_data[]
 *                const int dtv_size[2]
 *                const double tiltN_data[]
 *                const int tiltN_size[2]
 *                const struct0_T *cfg
 *                const struct3_T *pp
 *                const struct4_T *qp
 *                const emxArray_real_T *zWarm
 *                double xs_data[]
 *                int xs_size[2]
 *                double us_data[]
 *                int us_size[2]
 *                double gs_data[]
 *                int gs_size[2]
 *                double ss_data[]
 *                int ss_size[2]
 *                int *st
 *                int *iters
 *                double *nu
 *                double *step
 *                emxArray_real_T *zOut
 * Return Type  : void
 */
void scpk_planIterEmb(
    const double x0nd[14], const double xT[12], const double xl_data[],
    const int xl_size[2], const double ul_data[], const int ul_size[2],
    const double gl_data[], const int gl_size[2], const double sigl_data[],
    const int sigl_size[2], const double phase_data[], const int phase_size[2],
    const double eng_data[], const int eng_size[2], const double dtv_data[],
    const int dtv_size[2], const double tiltN_data[], const int tiltN_size[2],
    const struct0_T *cfg, const struct3_T *pp, const struct4_T *qp,
    const emxArray_real_T *zWarm, double xs_data[], int xs_size[2],
    double us_data[], int us_size[2], double gs_data[], int gs_size[2],
    double ss_data[], int ss_size[2], int *st, int *iters, double *nu,
    double *step, emxArray_real_T *zOut)
{
  static double ti[90000];
  static double tj[90000];
  static double tv[90000];
  static const signed char iv[12] = {1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13};
  __m128d b_r;
  __m128d r1;
  __m128d r2;
  emxArray_real_T *Ad;
  emxArray_real_T *Bd;
  emxArray_real_T *Dc;
  emxArray_real_T *Pd;
  emxArray_real_T *Pd2;
  emxArray_real_T *colS;
  emxArray_real_T *d;
  emxArray_real_T *d2;
  emxArray_real_T *ir;
  emxArray_real_T *jc;
  emxArray_real_T *lb;
  emxArray_real_T *lb2;
  emxArray_real_T *q;
  emxArray_real_T *q2;
  emxArray_real_T *rowS;
  emxArray_real_T *ub;
  emxArray_real_T *ub2;
  emxArray_real_T *vv;
  double Sd_data[2800];
  double cd_data[2800];
  double Dx[14];
  double Du[7];
  double dv[2];
  double dv1[2];
  double dv2[2];
  const double *zWarm_data;
  double Dc_tmp;
  double Dsig;
  double Du_tmp;
  double Dx_tmp;
  double a;
  double ang;
  double b;
  double b_Dx_tmp;
  double nRing;
  double ncone;
  double v;
  double *Dc_data;
  double *Pd2_data;
  double *Pd_data;
  double *colS_data;
  double *d_data;
  double *ir_data;
  double *jc_data;
  double *lb2_data;
  double *q2_data;
  double *q_data;
  double *rowS_data;
  double *ub2_data;
  double *ub_data;
  double *vv_data;
  int Sd_size[2];
  int cd_size[2];
  int N_tmp;
  int b_i;
  int i;
  unsigned int ic;
  int idxT;
  int j;
  int k;
  int nGT;
  int nt;
  int nz;
  int oep;
  int og;
  int osg0;
  int ou_tmp;
  int ovm;
  int ovm_tmp;
  int ovp;
  int r;
  int rI;
  int ti_tmp;
  int tj_tmp;
  int v_tmp;
  (void)xl_size;
  (void)gl_size;
  (void)phase_size;
  (void)eng_size;
  (void)dtv_size;
  (void)tiltN_size;
  zWarm_data = zWarm->data;
  N_tmp = ul_size[1];
  /*  ---- スケール ---- */
  Dx_tmp = pp->tolPos / cfg->sc.L;
  Dx[0] = Dx_tmp;
  b_Dx_tmp = pp->tolVel / cfg->sc.V;
  Dx[3] = b_Dx_tmp;
  Dx[1] = Dx_tmp;
  Dx[4] = b_Dx_tmp;
  Dx[2] = Dx_tmp;
  Dx[5] = b_Dx_tmp;
  Dx[6] = pp->tolQuat;
  Dx[7] = pp->tolQuat;
  Dx[8] = pp->tolQuat;
  Dx[9] = pp->tolQuat;
  Dx[13] = pp->tolMass / cfg->m0;
  b_Dx_tmp = pp->tolRate * 3.1415926535897931 / 180.0 * cfg->sc.T;
  Dx[10] = b_Dx_tmp;
  Du_tmp = pp->tolThr / cfg->Fs;
  Du[0] = Du_tmp;
  Dx[11] = b_Dx_tmp;
  Du[1] = Du_tmp;
  Dx[12] = b_Dx_tmp;
  Du[2] = Du_tmp;
  Du[3] = pp->tolFlap;
  Du[4] = pp->tolFlap;
  Du[5] = pp->tolFlap;
  Du[6] = pp->tolFlap;
  Dsig = pp->tolSig / cfg->sc.T;
  /*  ---- 変数レイアウト ---- */
  /*  x: 1..nx*(N+1) */
  ou_tmp = 14 * (ul_size[1] + 1);
  /*  u */
  og = ou_tmp + 7 * ul_size[1];
  /*  g */
  ovp = og + ul_size[1];
  ovm_tmp = 10 * ul_size[1];
  ovm = ovp + ovm_tmp;
  osg0 = ovm + ovm_tmp;
  /*  sigma */
  oep = osg0 + sigl_size[1];
  /*  softGlide スラック */
  idxT = 1;
  for (k = 0; k < N_tmp; k++) {
    if (phase_data[k] >= pp->phaseTight) {
      idxT++;
    }
  }
  nGT = 0;
  if (pp->softGlide > 0.0) {
    nGT = idxT << 4;
  }
  nz = (oep + nGT) + 24;
  /*  ---- 線形化+離散化 ---- */
  emxInit_real_T(&Ad, 3);
  emxInit_real_T(&Bd, 3);
  linDisc6All(xl_data, ul_data, ul_size, sigl_data, phase_data, dtv_data, cfg,
              Ad, Bd, Sd_data, Sd_size, cd_data, cd_size);
  Dc_data = Bd->data;
  ub_data = Ad->data;
  /*  ---- コスト (P対角, q) ---- */
  emxInit_real_T(&Pd, 1);
  i = Pd->size[0];
  Pd->size[0] = nz;
  emxEnsureCapacity_real_T(Pd, i);
  Pd_data = Pd->data;
  for (i = 0; i < nz; i++) {
    Pd_data[i] = pp->reg;
  }
  if (pp->wTilt > 0.0) {
    /*  傾斜正則化: 直立想定ノードの q3,q4 (buildPlan6 と同一) */
    for (k = 0; k <= N_tmp; k++) {
      if (tiltN_data[k] <= 0.3490658503988659) {
        r = k * 14 + 8;
        Pd_data[r] += pp->wTilt;
        r = k * 14 + 9;
        Pd_data[r] += pp->wTilt;
      }
    }
  }
  emxInit_real_T(&q, 1);
  i = q->size[0];
  q->size[0] = nz;
  emxEnsureCapacity_real_T(q, i);
  q_data = q->data;
  for (i = 0; i < nz; i++) {
    q_data[i] = 0.0;
  }
  q_data[14 * ul_size[1] + 13] = 0.0 - pp->wFuel;
  /*  終端質量 (x(:,N+1) の14成分目) */
  for (b_i = 0; b_i < ovm_tmp; b_i++) {
    q_data[ovp + b_i] = pp->lamVC;
    q_data[ovm + b_i] = pp->lamVC;
  }
  for (b_i = 0; b_i < 12; b_i++) {
    r = oep + b_i;
    q_data[r] = pp->lamTerm;
    q_data[r + 12] = pp->lamTerm;
  }
  for (b_i = 0; b_i < nGT; b_i++) {
    q_data[(oep + b_i) + 24] = pp->lamGlide;
  }
  /*  ---- 等式 (トリプレット) ---- */
  memset(&ti[0], 0, 90000U * sizeof(double));
  memset(&tj[0], 0, 90000U * sizeof(double));
  memset(&tv[0], 0, 90000U * sizeof(double));
  emxInit_real_T(&d, 1);
  r = (((((ou_tmp + 40 * ul_size[1]) + (idxT << 4)) + ul_size[1]) +
        ((ul_size[1] + 1) << 3)) +
       12 * ul_size[1]) +
      12;
  i = d->size[0];
  d->size[0] = r;
  emxEnsureCapacity_real_T(d, i);
  d_data = d->data;
  for (i = 0; i < r; i++) {
    d_data[i] = 0.0;
  }
  /*  [g; b] (上限確保) */
  /*  x0 */
  for (b_i = 0; b_i < 14; b_i++) {
    ti[b_i] = (double)b_i + 1.0;
    tj[b_i] = (double)b_i + 1.0;
    tv[b_i] = 1.0;
    d_data[b_i] = x0nd[b_i] / Dx[b_i];
  }
  nt = 13;
  /*  動力学 */
  for (k = 0; k < N_tmp; k++) {
    r = 14 * (k + 1);
    for (b_i = 0; b_i < 14; b_i++) {
      ti_tmp = (nt + b_i) + 1;
      b = (r + b_i) + 1;
      ti[ti_tmp] = b;
      tj[ti_tmp] = b;
      tv[ti_tmp] = 1.0;
      /*  x_{k+1} */
    }
    nt += 14;
    for (b_i = 0; b_i < 14; b_i++) {
      for (j = 0; j < 14; j++) {
        v = -ub_data[(b_i + 14 * j) + 196 * k] * Dx[j] / Dx[b_i];
        if (v != 0.0) {
          nt++;
          ti[nt] = (r + b_i) + 1;
          tj[nt] = (14 * k + j) + 1;
          tv[nt] = v;
        }
      }
      for (j = 0; j < 7; j++) {
        v = -Dc_data[(b_i + 14 * j) + 98 * k] * Du[j] / Dx[b_i];
        if (v != 0.0) {
          nt++;
          ti[nt] = (r + b_i) + 1;
          tj[nt] = ((ou_tmp + 7 * k) + j) + 1;
          tv[nt] = v;
        }
      }
      a = Dx[b_i];
      v_tmp = b_i + 14 * k;
      v = -Sd_data[v_tmp] * Dsig / a;
      if (v != 0.0) {
        nt++;
        ti[nt] = (r + b_i) + 1;
        tj[nt] = (double)osg0 + phase_data[k];
        tv[nt] = v;
      }
      d_data[r + b_i] = cd_data[v_tmp] / a;
    }
    for (j = 0; j < 10; j++) {
      /*  仮想制御 (行4..13) */
      nt++;
      ti_tmp = (r + j) + 4;
      ti[nt] = ti_tmp;
      tj[nt] = ((ovp + 10 * k) + j) + 1;
      b = Dx[j + 3];
      tv[nt] = -1.0 / b;
      nt++;
      ti[nt] = ti_tmp;
      tj[nt] = ((ovm + 10 * k) + j) + 1;
      tv[nt] = 1.0 / b;
    }
  }
  emxFree_real_T(&Bd);
  emxFree_real_T(&Ad);
  /*  終端 (12成分) */
  for (b_i = 0; b_i < 12; b_i++) {
    signed char i1;
    r = (ou_tmp + b_i) + 1;
    nt++;
    ti[nt] = r;
    i1 = iv[b_i];
    tj[nt] = 14 * N_tmp + i1;
    tv[nt] = Dx[i1 - 1];
    nt++;
    ti[nt] = r;
    tj_tmp = oep + b_i;
    tj[nt] = tj_tmp + 1;
    tv[nt] = -1.0;
    nt++;
    ti[nt] = r;
    tj[nt] = tj_tmp + 13;
    tv[nt] = 1.0;
    d_data[r - 1] = xT[b_i];
  }
  /*  ---- 不等式 (行番号は neq からの続き) ---- */
  rI = ou_tmp + 12;
  /*  推力錐の方向 (coneDirs と同一の生成則) */
  b = sqrt(pp->nCone / 3.0);
  if (b < 4.503599627370496E+15) {
    if (b >= 0.5) {
      b = floor(b + 0.5);
    } else if (b > -0.5) {
      b *= 0.0;
    } else {
      b = ceil(b - 0.5);
    }
  }
  nRing = fmax(1.0, b);
  v = fmax(3.0, floor((pp->nCone - 1.0) / nRing));
  ncone = nRing * v + 1.0;
  emxInit_real_T(&Dc, 2);
  i = (int)(nRing * v + 1.0);
  v_tmp = Dc->size[0] * Dc->size[1];
  Dc->size[0] = (int)ncone;
  Dc->size[1] = 3;
  emxEnsureCapacity_real_T(Dc, v_tmp);
  Dc_data = Dc->data;
  r = (int)ncone * 3;
  for (v_tmp = 0; v_tmp < r; v_tmp++) {
    Dc_data[v_tmp] = 0.0;
  }
  Dc_data[0] = 1.0;
  Dc_data[Dc->size[0]] = 0.0;
  Dc_data[Dc->size[0] * 2] = 0.0;
  ic = 1U;
  v_tmp = (int)nRing;
  r = (int)((v - 1.0) + 1.0);
  for (b_i = 0; b_i < v_tmp; b_i++) {
    a = pp->coneHalf * ((double)b_i + 1.0) / nRing;
    Dc_tmp = sin(a);
    a = cos(a);
    for (j = 0; j < r; j++) {
      b = 6.2831853071795862 * (double)j / v +
          3.1415926535897931 * ((double)b_i + 1.0) / nRing;
      ic++;
      Dc_data[(int)ic - 1] = a;
      Dc_data[((int)ic + Dc->size[0]) - 1] = Dc_tmp * cos(b);
      Dc_data[((int)ic + Dc->size[0] * 2) - 1] = Dc_tmp * sin(b);
    }
  }
  b = cos(cfg->veh.tvcMax);
  for (k = 0; k < N_tmp; k++) {
    for (v_tmp = 0; v_tmp < i; v_tmp++) {
      /*  錐 */
      v = Dc_data[v_tmp] * Du_tmp;
      if (v != 0.0) {
        nt++;
        ti[nt] = (rI + v_tmp) + 1;
        tj[nt] = (ou_tmp + 7 * k) + 1;
        tv[nt] = v;
      }
      v = Dc_data[v_tmp + Dc->size[0]] * Du_tmp;
      if (v != 0.0) {
        nt++;
        ti[nt] = (rI + v_tmp) + 1;
        tj[nt] = (ou_tmp + 7 * k) + 2;
        tv[nt] = v;
      }
      v = Dc_data[v_tmp + Dc->size[0] * 2] * Du_tmp;
      if (v != 0.0) {
        nt++;
        ti[nt] = (rI + v_tmp) + 1;
        tj[nt] = (ou_tmp + 7 * k) + 3;
        tv[nt] = v;
      }
      nt++;
      ti_tmp = rI + v_tmp;
      ti[nt] = ti_tmp + 1;
      tj[nt] = (og + k) + 1;
      tv[nt] = -pp->coneShrink * Du_tmp;
      d_data[ti_tmp] = 0.0;
    }
    rI += (int)ncone;
    rI++;
    /*  ジンバル */
    nt++;
    ti[nt] = rI;
    tj_tmp = ou_tmp + 7 * k;
    tj[nt] = (double)tj_tmp + 1.0;
    tv[nt] = -Du_tmp;
    nt++;
    ti[nt] = rI;
    r = (og + k) + 1;
    tj[nt] = r;
    tv[nt] = b * Du_tmp;
    d_data[rI - 1] = 0.0;
    a = ul_data[7 * k];
    Dc_tmp = ul_data[7 * k + 1];
    ang = ul_data[7 * k + 2];
    nRing = sqrt((a * a + Dc_tmp * Dc_tmp) + ang * ang);
    /*  ロスレス線形化 */
    if (nRing < 1.0E-9) {
      nRing = 1.0E-9;
    }
    for (j = 0; j < 2; j++) {
      v_tmp = -2 * j + 1;
      v = (double)v_tmp * (a / nRing) * Du_tmp;
      if (v != 0.0) {
        nt++;
        ti[nt] = (rI + j) + 1;
        tj[nt] = tj_tmp + 1;
        tv[nt] = v;
      }
      v = (double)v_tmp * (Dc_tmp / nRing) * Du_tmp;
      if (v != 0.0) {
        nt++;
        ti[nt] = (rI + j) + 1;
        tj[nt] = tj_tmp + 2;
        tv[nt] = v;
      }
      v = (double)v_tmp * (ang / nRing) * Du_tmp;
      if (v != 0.0) {
        nt++;
        ti[nt] = (rI + j) + 1;
        tj[nt] = tj_tmp + 3;
        tv[nt] = v;
      }
      nt++;
      ti_tmp = rI + j;
      ti[nt] = ti_tmp + 1;
      tj[nt] = r;
      tv[nt] = -(double)v_tmp * Du_tmp;
      d_data[ti_tmp] = pp->lcTol;
    }
    rI += 2;
  }
  emxFree_real_T(&Dc);
  /*  傾斜角/グライドスロープ (phaseTight ノード + 終端) */
  b = sqrt((1.0 - cos(pp->tiltMax)) / 2.0);
  nRing = tan(pp->glideSlope);
  v = 0.0;
  for (tj_tmp = 0; tj_tmp <= N_tmp; tj_tmp++) {
    bool on;
    if (tj_tmp + 1 <= N_tmp) {
      on = (phase_data[tj_tmp] >= pp->phaseTight);
    } else {
      on = (idxT - 1 > 0);
    }
    if (on) {
      a = Dx[8];
      ncone = Dx[9];
      Dc_tmp = 14.0 * (((double)tj_tmp + 1.0) - 1.0);
      for (v_tmp = 0; v_tmp < 8; v_tmp++) {
        /*  傾斜 */
        ang = 6.2831853071795862 * (((double)v_tmp + 1.0) - 1.0) / 8.0;
        v++;
        nt++;
        r = rI + v_tmp;
        ti[nt] = r + 1;
        tj[nt] = Dc_tmp + 9.0;
        tv[nt] = cos(ang) * a;
        nt++;
        ti[nt] = r + 1;
        tj[nt] = Dc_tmp + 10.0;
        tv[nt] = sin(ang) * ncone;
        d_data[r] = b;
      }
      rI += 8;
      Dc_tmp = 14.0 * (((double)tj_tmp + 1.0) - 1.0);
      for (v_tmp = 0; v_tmp < 8; v_tmp++) {
        /*  グライド (softならスラック) */
        ang = 6.2831853071795862 * (((double)v_tmp + 1.0) - 1.0) / 8.0;
        v++;
        nt++;
        r = rI + v_tmp;
        ti[nt] = r + 1;
        tj[nt] = Dc_tmp + 2.0;
        tv[nt] = nRing * cos(ang) * Dx_tmp;
        nt++;
        ti[nt] = r + 1;
        tj[nt] = Dc_tmp + 3.0;
        tv[nt] = nRing * sin(ang) * Dx_tmp;
        nt++;
        ti[nt] = r + 1;
        tj[nt] = Dc_tmp + 1.0;
        tv[nt] = -Dx_tmp;
        if (pp->softGlide > 0.0) {
          nt++;
          ti[nt] = r + 1;
          tj[nt] = (((double)oep + 12.0) + 12.0) + v;
          tv[nt] = -1.0;
        }
        d_data[r] = 0.0;
      }
      rI += 8;
    }
  }
  /*  高度の単調降下 */
  if (pp->monoDescent > 0.0) {
    for (k = 0; k < N_tmp; k++) {
      nt++;
      r = rI + k;
      ti[nt] = r + 1;
      tj[nt] = 14.0 * ((double)k + 1.0) + 1.0;
      tv[nt] = Dx_tmp;
      nt++;
      ti[nt] = r + 1;
      tj[nt] = 14.0 * (((double)k + 1.0) - 1.0) + 1.0;
      tv[nt] = -Dx_tmp;
      d_data[r] = 0.0;
    }
    if (ul_size[1] - 1 >= 0) {
      rI += ul_size[1];
    }
  }
  /*  アクチュエータレート制約 (buildPlan6 と同一: 舵面 flapRate, 推力方向
   * tvcRate小角近似) */
  if (pp->rateLim > 0.0) {
    for (k = 0; k <= N_tmp - 2; k++) {
      b = dtv_data[k] * sigl_data[(int)phase_data[k] - 1];
      nRing = cfg->veh.flapRate * cfg->sc.T * b;
      for (b_i = 0; b_i < 4; b_i++) {
        a = Du[b_i + 3];
        nt++;
        ti[nt] = rI + 1;
        tj_tmp = ((ou_tmp + 7 * (k + 1)) + b_i) + 4;
        tj[nt] = tj_tmp;
        tv[nt] = a;
        nt++;
        ti[nt] = rI + 1;
        r = ((ou_tmp + 7 * k) + b_i) + 4;
        tj[nt] = r;
        tv[nt] = -a;
        d_data[rI] = nRing;
        nt++;
        ti[nt] = rI + 2;
        tj[nt] = tj_tmp;
        tv[nt] = -a;
        nt++;
        ti[nt] = rI + 2;
        tj[nt] = r;
        tv[nt] = a;
        d_data[rI + 1] = nRing;
        rI += 2;
      }
      a = eng_data[k];
      if ((a > 0.0) && (eng_data[k + 1] == a)) {
        b *= a * cfg->Tmax1 * (cfg->veh.tvcRate * cfg->sc.T);
        nt++;
        ti[nt] = rI + 1;
        r = ou_tmp + 7 * (k + 1);
        tj[nt] = r + 2;
        tv[nt] = Du_tmp;
        nt++;
        ti[nt] = rI + 1;
        v_tmp = ou_tmp + 7 * k;
        tj[nt] = v_tmp + 2;
        tv[nt] = -Du_tmp;
        d_data[rI] = b;
        nt++;
        ti[nt] = rI + 2;
        tj[nt] = r + 2;
        tv[nt] = -Du_tmp;
        nt++;
        ti[nt] = rI + 2;
        tj[nt] = v_tmp + 2;
        tv[nt] = Du_tmp;
        d_data[rI + 1] = b;
        rI += 2;
        nt++;
        ti[nt] = rI + 1;
        tj[nt] = r + 3;
        tv[nt] = Du_tmp;
        nt++;
        ti[nt] = rI + 1;
        tj[nt] = v_tmp + 3;
        tv[nt] = -Du_tmp;
        d_data[rI] = b;
        nt++;
        ti[nt] = rI + 2;
        tj[nt] = r + 3;
        tv[nt] = -Du_tmp;
        nt++;
        ti[nt] = rI + 2;
        tj[nt] = v_tmp + 3;
        tv[nt] = Du_tmp;
        d_data[rI + 1] = b;
        rI += 2;
      }
    }
  }
  /*  ノード毎 傾斜スケジュール */
  for (tj_tmp = 0; tj_tmp <= N_tmp; tj_tmp++) {
    a = tiltN_data[tj_tmp];
    if (!(a >= 3.1066860685499065)) {
      b = sqrt((1.0 - cos(a)) / 2.0);
      a = Dx[8];
      ncone = Dx[9];
      Dc_tmp = 14.0 * (((double)tj_tmp + 1.0) - 1.0);
      for (v_tmp = 0; v_tmp < 8; v_tmp++) {
        ang = 6.2831853071795862 * (((double)v_tmp + 1.0) - 1.0) / 8.0;
        nt++;
        r = rI + v_tmp;
        ti[nt] = r + 1;
        tj[nt] = Dc_tmp + 9.0;
        tv[nt] = cos(ang) * a;
        nt++;
        ti[nt] = r + 1;
        tj[nt] = Dc_tmp + 10.0;
        tv[nt] = sin(ang) * ncone;
        d_data[r] = b;
      }
      rI += 8;
    }
  }
  /*  ---- 箱制約 ---- */
  emxInit_real_T(&lb, 1);
  i = lb->size[0];
  lb->size[0] = nz;
  emxEnsureCapacity_real_T(lb, i);
  Dc_data = lb->data;
  emxInit_real_T(&ub, 1);
  i = ub->size[0];
  ub->size[0] = nz;
  emxEnsureCapacity_real_T(ub, i);
  ub_data = ub->data;
  for (i = 0; i < nz; i++) {
    Dc_data[i] = rtMinusInf;
    ub_data[i] = rtInf;
  }
  v = (cfg->hmin - pp->hMargin / cfg->sc.L) / Dx_tmp;
  b_r = _mm_loadu_pd(&Dx[10]);
  for (k = 0; k <= N_tmp; k++) {
    Dc_data[14 * k] = v;
    tj_tmp = k;
    if (k + 1 > N_tmp) {
      tj_tmp = N_tmp - 1;
    }
    if (phase_data[tj_tmp] >= pp->phaseTight) {
      b = pp->wMaxTight;
    } else {
      b = pp->wMaxFlip;
    }
    i = 14 * k + 10;
    a = -b * cfg->sc.T;
    _mm_storeu_pd(&Dc_data[i], _mm_div_pd(_mm_set1_pd(a), b_r));
    ncone = b * cfg->sc.T;
    _mm_storeu_pd(&ub_data[i], _mm_div_pd(_mm_set1_pd(ncone), b_r));
    r = 14 * k + 12;
    Dc_data[r] = a / b_Dx_tmp;
    ub_data[r] = ncone / b_Dx_tmp;
    Dc_data[14 * k + 13] = cfg->veh.dryMass / cfg->m0 / Dx[13];
    if ((pp->bellyHold > 0.0) && (phase_data[tj_tmp] == 1.0)) {
      nRing = pp->qBelly[0] / Dx[6];
      r = 14 * k + 6;
      Dc_data[r] = fmax(Dc_data[r], nRing - pp->bellyHold);
      ub_data[r] = fmin(ub_data[r], nRing + pp->bellyHold);
      nRing = pp->qBelly[1] / Dx[7];
      r = 14 * k + 7;
      Dc_data[r] = fmax(Dc_data[r], nRing - pp->bellyHold);
      ub_data[r] = fmin(ub_data[r], nRing + pp->bellyHold);
      nRing = pp->qBelly[2] / Dx[8];
      r = 14 * k + 8;
      Dc_data[r] = fmax(Dc_data[r], nRing - pp->bellyHold);
      ub_data[r] = fmin(ub_data[r], nRing + pp->bellyHold);
      nRing = pp->qBelly[3] / Dx[9];
      r = 14 * k + 9;
      Dc_data[r] = fmax(Dc_data[r], nRing - pp->bellyHold);
      ub_data[r] = fmin(ub_data[r], nRing + pp->bellyHold);
    }
    if (k + 1 >= 2) {
      if (pp->useDrBox > 0.0) {
        r = 14 * k + 2;
        Dc_data[r] = fmax(Dc_data[r], pp->drBox[0] / cfg->sc.L / Dx_tmp);
        ub_data[r] = fmin(ub_data[r], pp->drBox[1] / cfg->sc.L / Dx_tmp);
      }
      if (pp->crMax > 0.0) {
        r = 14 * k + 1;
        Dc_data[r] = fmax(Dc_data[r], -pp->crMax / cfg->sc.L / Dx_tmp);
        ub_data[r] = fmin(ub_data[r], pp->crMax / cfg->sc.L / Dx_tmp);
      }
    }
  }
  for (k = 0; k < N_tmp; k++) {
    a = eng_data[k];
    b = a * cfg->Tmax1;
    if ((phase_data[k] >= pp->phaseTight) && (pp->thrMaxTight > 0.0)) {
      b = fmin(b, b * pp->thrMaxTight);
    }
    r = og + k;
    Dc_data[r] = a * cfg->Tmin1 / Du_tmp;
    ub_data[r] = b / Du_tmp;
    r = ou_tmp + 7 * k;
    Dc_data[r] = 0.0;
    b_r = _mm_loadu_pd(&Du[3]);
    r1 = _mm_set1_pd(-cfg->veh.flapTrim);
    _mm_storeu_pd(&Dc_data[r + 3], _mm_div_pd(r1, b_r));
    r2 = _mm_set1_pd(cfg->veh.flapMax - cfg->veh.flapTrim);
    _mm_storeu_pd(&ub_data[r + 3], _mm_div_pd(r2, b_r));
    b_r = _mm_loadu_pd(&Du[5]);
    _mm_storeu_pd(&Dc_data[r + 5], _mm_div_pd(r1, b_r));
    _mm_storeu_pd(&ub_data[r + 5], _mm_div_pd(r2, b_r));
  }
  i = sigl_size[1];
  tj_tmp = (sigl_size[1] / 2) << 1;
  ti_tmp = tj_tmp - 2;
  for (j = 0; j <= ti_tmp; j += 2) {
    v_tmp = osg0 + j;
    b_r = _mm_set1_pd(cfg->sc.T);
    r1 = _mm_set1_pd(Dsig);
    _mm_storeu_pd(
        &Dc_data[v_tmp],
        _mm_div_pd(_mm_div_pd(_mm_loadu_pd(&pp->sigMin[j]), b_r), r1));
    _mm_storeu_pd(
        &ub_data[v_tmp],
        _mm_div_pd(_mm_div_pd(_mm_loadu_pd(&pp->sigMax[j]), b_r), r1));
  }
  for (j = tj_tmp; j < i; j++) {
    r = osg0 + j;
    Dc_data[r] = pp->sigMin[j] / cfg->sc.T / Dsig;
    ub_data[r] = pp->sigMax[j] / cfg->sc.T / Dsig;
  }
  for (b_i = 0; b_i < ovm_tmp; b_i++) {
    Dc_data[ovp + b_i] = 0.0;
    Dc_data[ovm + b_i] = 0.0;
  }
  for (b_i = 0; b_i < 12; b_i++) {
    r = oep + b_i;
    Dc_data[r] = 0.0;
    Dc_data[r + 12] = 0.0;
  }
  for (b_i = 0; b_i < nGT; b_i++) {
    Dc_data[(oep + b_i) + 24] = 0.0;
  }
  /*  トラストリージョン (境界方式) */
  for (k = 0; k <= N_tmp; k++) {
    for (b_i = 0; b_i < 14; b_i++) {
      r = b_i + 14 * k;
      nRing = xl_data[r] / Dx[b_i];
      Dc_data[r] = fmax(Dc_data[r], nRing - pp->trX);
      ub_data[r] = fmin(ub_data[r], nRing + pp->trX);
    }
  }
  for (k = 0; k < N_tmp; k++) {
    for (b_i = 0; b_i < 7; b_i++) {
      nRing = ul_data[b_i + 7 * k] / Du[b_i];
      r = (ou_tmp + 7 * k) + b_i;
      Dc_data[r] = fmax(Dc_data[r], nRing - pp->trU);
      ub_data[r] = fmin(ub_data[r], nRing + pp->trU);
    }
    r = og + k;
    b = gl_data[k] / Du_tmp;
    Dc_data[r] = fmax(Dc_data[r], b - pp->trU);
    ub_data[r] = fmin(ub_data[r], b + pp->trU);
  }
  for (j = 0; j <= ti_tmp; j += 2) {
    b_r = _mm_div_pd(_mm_loadu_pd(&sigl_data[j]), _mm_set1_pd(Dsig));
    r1 = _mm_set1_pd(pp->trSig);
    _mm_storeu_pd(&dv[0], _mm_sub_pd(b_r, r1));
    v_tmp = osg0 + j;
    dv1[0] = fmax(Dc_data[v_tmp], dv[0]);
    dv1[1] = fmax(Dc_data[v_tmp + 1], dv[1]);
    r2 = _mm_loadu_pd(&dv1[0]);
    _mm_storeu_pd(&Dc_data[v_tmp], r2);
    _mm_storeu_pd(&dv2[0], _mm_add_pd(b_r, r1));
    dv1[0] = fmin(ub_data[v_tmp], dv2[0]);
    dv1[1] = fmin(ub_data[v_tmp + 1], dv2[1]);
    b_r = _mm_loadu_pd(&dv1[0]);
    _mm_storeu_pd(&ub_data[v_tmp], b_r);
  }
  for (j = tj_tmp; j < i; j++) {
    nRing = sigl_data[j] / Dsig;
    r = osg0 + j;
    Dc_data[r] = fmax(Dc_data[r], nRing - pp->trSig);
    ub_data[r] = fmin(ub_data[r], nRing + pp->trSig);
  }
  /*  ---- トリプレット -> CSC ---- */
  emxInit_real_T(&vv, 1);
  emxInit_real_T(&jc, 1);
  emxInit_real_T(&ir, 1);
  tri2csc(ti, tj, tv, nt + 1, nz, jc, ir, vv);
  vv_data = vv->data;
  ir_data = ir->data;
  jc_data = jc->data;
  /*  ---- Ruiz スケーリング ---- */
  emxInit_real_T(&colS, 1);
  emxInit_real_T(&rowS, 1);
  b = ruizCsc(jc, ir, vv, rI, nz, Pd, colS, rowS);
  rowS_data = rowS->data;
  colS_data = colS->data;
  emxInit_real_T(&Pd2, 1);
  v_tmp = Pd2->size[0];
  Pd2->size[0] = nz;
  emxEnsureCapacity_real_T(Pd2, v_tmp);
  Pd2_data = Pd2->data;
  emxInit_real_T(&q2, 1);
  v_tmp = q2->size[0];
  q2->size[0] = nz;
  emxEnsureCapacity_real_T(q2, v_tmp);
  q2_data = q2->data;
  emxInit_real_T(&lb2, 1);
  v_tmp = lb2->size[0];
  lb2->size[0] = nz;
  emxEnsureCapacity_real_T(lb2, v_tmp);
  lb2_data = lb2->data;
  emxInit_real_T(&ub2, 1);
  v_tmp = ub2->size[0];
  ub2->size[0] = nz;
  emxEnsureCapacity_real_T(ub2, v_tmp);
  ub2_data = ub2->data;
  for (j = 0; j < nz; j++) {
    v_tmp = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
    for (r = 0; r < v_tmp; r++) {
      nRing = jc_data[j] + (double)r;
      vv_data[(int)nRing - 1] = vv_data[(int)nRing - 1] /
                                rowS_data[(int)ir_data[(int)nRing - 1] - 1] *
                                colS_data[j];
    }
    Pd2_data[j] = b * Pd_data[j] * (colS_data[j] * colS_data[j]);
    q2_data[j] = b * q_data[j] * colS_data[j];
    lb2_data[j] = Dc_data[j] / colS_data[j];
    ub2_data[j] = ub_data[j] / colS_data[j];
  }
  emxFree_real_T(&ub);
  emxFree_real_T(&lb);
  emxFree_real_T(&q);
  emxInit_real_T(&d2, 1);
  v_tmp = d2->size[0];
  d2->size[0] = rI;
  emxEnsureCapacity_real_T(d2, v_tmp);
  Dc_data = d2->data;
  r = (rI / 2) << 1;
  v_tmp = r - 2;
  for (b_i = 0; b_i <= v_tmp; b_i += 2) {
    b_r = _mm_loadu_pd(&d_data[b_i]);
    r1 = _mm_loadu_pd(&rowS_data[b_i]);
    _mm_storeu_pd(&Dc_data[b_i], _mm_div_pd(b_r, r1));
  }
  for (b_i = r; b_i < rI; b_i++) {
    Dc_data[b_i] = d_data[b_i] / rowS_data[b_i];
  }
  emxFree_real_T(&rowS);
  emxFree_real_T(&d);
  /*  ---- PIPG (ウォームスタート: 前回の無スケール解 zWarm を今回のスケールへ)
   * ---- */
  v_tmp = Pd->size[0];
  Pd->size[0] = nz;
  emxEnsureCapacity_real_T(Pd, v_tmp);
  Pd_data = Pd->data;
  for (v_tmp = 0; v_tmp < nz; v_tmp++) {
    Pd_data[v_tmp] = 0.0;
  }
  if (zWarm->size[0] == nz) {
    v_tmp = Pd->size[0];
    Pd->size[0] = nz;
    emxEnsureCapacity_real_T(Pd, v_tmp);
    Pd_data = Pd->data;
    r = (nz / 2) << 1;
    v_tmp = r - 2;
    for (j = 0; j <= v_tmp; j += 2) {
      b_r = _mm_loadu_pd(&colS_data[j]);
      _mm_storeu_pd(&Pd_data[j], _mm_div_pd(_mm_loadu_pd(&zWarm_data[j]), b_r));
    }
    for (j = r; j < nz; j++) {
      Pd_data[j] = zWarm_data[j] / colS_data[j];
    }
  }
  *st = pipgCsc(Pd2, q2, jc, ir, vv, d2, ou_tmp + 12, rI, nz, lb2, ub2, qp, Pd,
                iters);
  Pd_data = Pd->data;
  emxFree_real_T(&ir);
  emxFree_real_T(&jc);
  emxFree_real_T(&d2);
  emxFree_real_T(&ub2);
  emxFree_real_T(&lb2);
  emxFree_real_T(&q2);
  emxFree_real_T(&Pd2);
  emxFree_real_T(&vv);
  /*  ---- 復元 ---- */
  v_tmp = zOut->size[0];
  zOut->size[0] = nz;
  emxEnsureCapacity_real_T(zOut, v_tmp);
  Dc_data = zOut->data;
  r = (nz / 2) << 1;
  v_tmp = r - 2;
  for (j = 0; j <= v_tmp; j += 2) {
    b_r = _mm_loadu_pd(&colS_data[j]);
    r1 = _mm_loadu_pd(&Pd_data[j]);
    _mm_storeu_pd(&Dc_data[j], _mm_mul_pd(b_r, r1));
  }
  for (j = r; j < nz; j++) {
    Dc_data[j] = colS_data[j] * Pd_data[j];
  }
  emxFree_real_T(&colS);
  emxFree_real_T(&Pd);
  /*  次回サイクルのウォームスタート用 */
  xs_size[0] = 14;
  xs_size[1] = ul_size[1] + 1;
  memset(&xs_data[0], 0, (unsigned int)ou_tmp * sizeof(double));
  us_size[0] = 7;
  us_size[1] = ul_size[1];
  gs_size[0] = 1;
  gs_size[1] = ul_size[1];
  ss_size[0] = 1;
  ss_size[1] = sigl_size[1];
  for (k = 0; k <= N_tmp; k++) {
    for (b_i = 0; b_i <= 12; b_i += 2) {
      v_tmp = 14 * k + b_i;
      b_r = _mm_loadu_pd(&Dc_data[v_tmp]);
      r1 = _mm_loadu_pd(&Dx[b_i]);
      _mm_storeu_pd(&xs_data[v_tmp], _mm_mul_pd(b_r, r1));
    }
    v_tmp = 14 * k + 6;
    a = xs_data[v_tmp];
    Dc_tmp = xs_data[14 * k + 7];
    r = 14 * k + 8;
    ang = xs_data[r];
    b = xs_data[14 * k + 9];
    b = sqrt(((a * a + Dc_tmp * Dc_tmp) + ang * ang) + b * b);
    if (b > 2.2204460492503131E-16) {
      b_r = _mm_loadu_pd(&xs_data[v_tmp]);
      r1 = _mm_set1_pd(b);
      _mm_storeu_pd(&xs_data[v_tmp], _mm_div_pd(b_r, r1));
      b_r = _mm_loadu_pd(&xs_data[r]);
      _mm_storeu_pd(&xs_data[r], _mm_div_pd(b_r, r1));
    }
  }
  for (k = 0; k < N_tmp; k++) {
    v_tmp = ou_tmp + 7 * k;
    b_r = _mm_loadu_pd(&Dc_data[v_tmp]);
    r1 = _mm_loadu_pd(&Du[0]);
    _mm_storeu_pd(&us_data[7 * k], _mm_mul_pd(b_r, r1));
    b_r = _mm_loadu_pd(&Dc_data[v_tmp + 2]);
    r1 = _mm_loadu_pd(&Du[2]);
    _mm_storeu_pd(&us_data[7 * k + 2], _mm_mul_pd(b_r, r1));
    b_r = _mm_loadu_pd(&Dc_data[v_tmp + 4]);
    r1 = _mm_loadu_pd(&Du[4]);
    _mm_storeu_pd(&us_data[7 * k + 4], _mm_mul_pd(b_r, r1));
    us_data[7 * k + 6] = Dc_data[v_tmp + 6] * Du[6];
    gs_data[k] = Dc_data[og + k] * Du_tmp;
  }
  for (j = 0; j <= ti_tmp; j += 2) {
    b_r = _mm_loadu_pd(&Dc_data[osg0 + j]);
    _mm_storeu_pd(&ss_data[j], _mm_mul_pd(b_r, _mm_set1_pd(Dsig)));
  }
  for (j = tj_tmp; j < i; j++) {
    ss_data[j] = Dc_data[osg0 + j] * Dsig;
  }
  *nu = 0.0;
  for (b_i = 0; b_i < ovm_tmp; b_i++) {
    a = Dc_data[ovp + b_i];
    if (a > 0.0) {
      *nu += a;
    }
    a = Dc_data[ovm + b_i];
    if (a > 0.0) {
      *nu += a;
    }
  }
  *step = 0.0;
  for (k = 0; k <= N_tmp; k++) {
    for (b_i = 0; b_i < 14; b_i++) {
      v_tmp = b_i + 14 * k;
      a = fabs(xs_data[v_tmp] - xl_data[v_tmp]) / Dx[b_i];
      if (a > *step) {
        *step = a;
      }
    }
  }
  for (j = 0; j < i; j++) {
    a = fabs(ss_data[j] - sigl_data[j]) / Dsig;
    if (a > *step) {
      *step = a;
    }
  }
}

/*
 * File trailer for scpk_planIterEmb.c
 *
 * [EOF]
 */
