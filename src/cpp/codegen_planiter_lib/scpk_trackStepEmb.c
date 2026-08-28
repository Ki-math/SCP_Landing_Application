/*
 * File: scpk_trackStepEmb.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 00:13:12
 */

/* Include Files */
#include "scpk_trackStepEmb.h"
#include "dynamics6.h"
#include "eye.h"
#include "gncCore_lib_emxutil.h"
#include "gncCore_lib_rtwutil.h"
#include "gncCore_lib_types.h"
#include "mod.h"
#include "rt_nonfinite.h"
#include "rt_nonfinite.h"
#include <emmintrin.h>
#include <math.h>
#include <string.h>

/* Function Declarations */
static int b_pipgCsc(const double Pd_data[], const double jc_data[],
                     const emxArray_real_T *ir, const emxArray_real_T *vv,
                     const double d_data[], double neq, double m, double n,
                     const double lb_data[], const double ub_data[],
                     const struct5_T *o, double z0_data[], int *z0_size,
                     int *iters);

static double b_residCsc(const double Pd_data[], const double jc_data[],
                         const emxArray_real_T *ir, const emxArray_real_T *vv,
                         const double d_data[], double neq, double m, double n,
                         const double lb_data[], const double ub_data[],
                         const double z_data[], const double w_data[],
                         double *rd);

/* Function Definitions */
/*
 * PIPGCSC  PIPG (pipg_mex.cpp / planIterEmb と同一アルゴリズム, CSC明示ループ).
 *
 * Arguments    : const double Pd_data[]
 *                const double jc_data[]
 *                const emxArray_real_T *ir
 *                const emxArray_real_T *vv
 *                const double d_data[]
 *                double neq
 *                double m
 *                double n
 *                const double lb_data[]
 *                const double ub_data[]
 *                const struct5_T *o
 *                double z0_data[]
 *                int *z0_size
 *                int *iters
 * Return Type  : int
 */
static int b_pipgCsc(const double Pd_data[], const double jc_data[],
                     const emxArray_real_T *ir, const emxArray_real_T *vv,
                     const double d_data[], double neq, double m, double n,
                     const double lb_data[], const double ub_data[],
                     const struct5_T *o, double z0_data[], int *z0_size,
                     int *iters)
{
  __m128d r;
  double tmpn_data[1260];
  double x_data[1260];
  double zPrev_data[1260];
  double tmpm_data[840];
  double w_data[840];
  const double *ir_data;
  const double *vv_data;
  double be;
  double d;
  double lam;
  double s;
  double sig;
  double zv;
  int b_loop_ub_tmp;
  int it;
  int j;
  int k;
  int loop_ub_tmp;
  int scalarLB;
  int st;
  int tmpm_tmp;
  bool bad;
  bool exitg1;
  vv_data = vv->data;
  ir_data = ir->data;
  loop_ub_tmp = (int)m;
  if (loop_ub_tmp - 1 >= 0) {
    memset(&w_data[0], 0, (unsigned int)loop_ub_tmp * sizeof(double));
  }
  st = 0;
  d = rt_roundd_snf(o->maxIter);
  if (d < 2.147483648E+9) {
    if (d >= -2.147483648E+9) {
      *iters = (int)d;
    } else {
      *iters = MIN_int32_T;
    }
  } else if (d >= 2.147483648E+9) {
    *iters = MAX_int32_T;
  } else {
    *iters = 0;
  }
  lam = 0.0;
  b_loop_ub_tmp = (int)n;
  zv = sqrt(n);
  sig = 0.0;
  for (j = 0; j < b_loop_ub_tmp; j++) {
    d = fabs(Pd_data[j]);
    if (d > lam) {
      lam = d;
    }
    x_data[j] = 1.0 / zv;
    tmpn_data[j] = 0.0;
  }
  it = 0;
  exitg1 = false;
  while ((!exitg1) && (it <= (int)o->powerIter - 1)) {
    if (loop_ub_tmp - 1 >= 0) {
      memset(&tmpm_data[0], 0, (unsigned int)loop_ub_tmp * sizeof(double));
    }
    for (j = 0; j < b_loop_ub_tmp; j++) {
      if (x_data[j] != 0.0) {
        scalarLB = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
        for (k = 0; k < scalarLB; k++) {
          zv = jc_data[j] + (double)k;
          tmpm_tmp = (int)ir_data[(int)zv - 1] - 1;
          tmpm_data[tmpm_tmp] += vv_data[(int)zv - 1] * x_data[j];
        }
      }
    }
    sig = 0.0;
    for (j = 0; j < b_loop_ub_tmp; j++) {
      s = 0.0;
      scalarLB = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
      for (k = 0; k < scalarLB; k++) {
        zv = jc_data[j] + (double)k;
        s += vv_data[(int)zv - 1] * tmpm_data[(int)ir_data[(int)zv - 1] - 1];
      }
      tmpn_data[j] = s;
      sig += s * s;
    }
    sig = sqrt(sig);
    if (sig < 2.2204460492503131E-16) {
      sig = 0.0;
      exitg1 = true;
    } else {
      scalarLB = ((int)n / 2) << 1;
      tmpm_tmp = scalarLB - 2;
      for (j = 0; j <= tmpm_tmp; j += 2) {
        r = _mm_loadu_pd(&tmpn_data[j]);
        _mm_storeu_pd(&x_data[j], _mm_div_pd(r, _mm_set1_pd(sig)));
      }
      for (j = scalarLB; j < b_loop_ub_tmp; j++) {
        x_data[j] = tmpn_data[j] / sig;
      }
      it++;
    }
  }
  sig = 2.0 / (lam + sqrt(lam * lam + 4.0 * o->omega * sig));
  be = o->omega * sig;
  bad = ((!rtIsInf(sig)) && (!rtIsNaN(sig)));
  if ((!bad) || (sig <= 0.0)) {
    st = 4;
  } else {
    int k2;
    it = *z0_size;
    if (it - 1 >= 0) {
      memcpy(&x_data[0], &z0_data[0], (unsigned int)it * sizeof(double));
      memcpy(&zPrev_data[0], &z0_data[0], (unsigned int)it * sizeof(double));
    }
    k2 = 0;
    int exitg2;
    do {
      exitg2 = 0;
      if (k2 <= (int)o->maxIter - 1) {
        __m128d r1;
        for (j = 0; j < b_loop_ub_tmp; j++) {
          s = 0.0;
          scalarLB = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
          for (k = 0; k < scalarLB; k++) {
            zv = jc_data[j] + (double)k;
            s += vv_data[(int)zv - 1] * w_data[(int)ir_data[(int)zv - 1] - 1];
          }
          d = x_data[j];
          zv = d - sig * (Pd_data[j] * d + s);
          d = lb_data[j];
          if (zv < d) {
            zv = d;
          } else {
            d = ub_data[j];
            if (zv > d) {
              zv = d;
            }
          }
          tmpn_data[j] = zv;
        }
        if (loop_ub_tmp - 1 >= 0) {
          memset(&tmpm_data[0], 0, (unsigned int)loop_ub_tmp * sizeof(double));
        }
        for (j = 0; j < b_loop_ub_tmp; j++) {
          lam = 2.0 * tmpn_data[j] - x_data[j];
          if (lam != 0.0) {
            scalarLB = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
            for (k = 0; k < scalarLB; k++) {
              zv = jc_data[j] + (double)k;
              tmpm_tmp = (int)ir_data[(int)zv - 1] - 1;
              tmpm_data[tmpm_tmp] += vv_data[(int)zv - 1] * lam;
            }
          }
        }
        for (k = 0; k < loop_ub_tmp; k++) {
          zv = w_data[k] + be * (tmpm_data[k] - d_data[k]);
          if (((double)k + 1.0 > neq) && (zv < 0.0)) {
            zv = 0.0;
          }
          tmpm_data[k] = zv;
        }
        scalarLB = ((int)n / 2) << 1;
        tmpm_tmp = scalarLB - 2;
        for (j = 0; j <= tmpm_tmp; j += 2) {
          r = _mm_loadu_pd(&x_data[j]);
          r1 = _mm_loadu_pd(&tmpn_data[j]);
          _mm_storeu_pd(&x_data[j],
                        _mm_add_pd(_mm_mul_pd(_mm_set1_pd(1.0 - o->rho), r),
                                   _mm_mul_pd(_mm_set1_pd(o->rho), r1)));
        }
        for (j = scalarLB; j < b_loop_ub_tmp; j++) {
          x_data[j] = (1.0 - o->rho) * x_data[j] + o->rho * tmpn_data[j];
        }
        scalarLB = ((int)m / 2) << 1;
        tmpm_tmp = scalarLB - 2;
        for (k = 0; k <= tmpm_tmp; k += 2) {
          r = _mm_loadu_pd(&w_data[k]);
          r1 = _mm_loadu_pd(&tmpm_data[k]);
          _mm_storeu_pd(&w_data[k],
                        _mm_add_pd(_mm_mul_pd(_mm_set1_pd(1.0 - o->rho), r),
                                   _mm_mul_pd(_mm_set1_pd(o->rho), r1)));
        }
        for (k = scalarLB; k < loop_ub_tmp; k++) {
          w_data[k] = (1.0 - o->rho) * w_data[k] + o->rho * tmpm_data[k];
        }
        if (b_mod((double)k2 + 1.0, o->checkEvery) == 0.0) {
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
            k = 0;
            exitg1 = false;
            while ((!exitg1) && (k <= (int)m - 1)) {
              if (rtIsInf(tmpm_data[k]) || rtIsNaN(tmpm_data[k])) {
                bad = true;
                exitg1 = true;
              } else {
                k++;
              }
            }
          }
          if (bad) {
            st = 4;
            if ((double)k2 + 1.0 < 2.147483648E+9) {
              *iters = k2 + 1;
            } else {
              *iters = MAX_int32_T;
            }
            *z0_size = it;
            if (it - 1 >= 0) {
              memcpy(&z0_data[0], &zPrev_data[0],
                     (unsigned int)it * sizeof(double));
            }
            exitg2 = 1;
          } else {
            it = (int)n;
            if (b_loop_ub_tmp - 1 >= 0) {
              memcpy(&zPrev_data[0], &tmpn_data[0],
                     (unsigned int)b_loop_ub_tmp * sizeof(double));
            }
            zv = b_residCsc(Pd_data, jc_data, ir, vv, d_data, neq, m, n,
                            lb_data, ub_data, x_data, w_data, &lam);
            if ((zv < o->tolPri) && (lam < o->tolDua) &&
                (!(o->fixedIter > 0.0))) {
              st = 1;
              if ((double)k2 + 1.0 < 2.147483648E+9) {
                *iters = k2 + 1;
              } else {
                *iters = MAX_int32_T;
              }
              for (j = 0; j < b_loop_ub_tmp; j++) {
                d = x_data[j];
                z0_data[j] = d;
                zv = lb_data[j];
                if (d < zv) {
                  z0_data[j] = zv;
                } else {
                  zv = ub_data[j];
                  if (d > zv) {
                    z0_data[j] = zv;
                  }
                }
              }
              exitg2 = 1;
            } else {
              k2++;
            }
          }
        } else {
          k2++;
        }
      } else {
        for (j = 0; j < b_loop_ub_tmp; j++) {
          d = x_data[j];
          z0_data[j] = d;
          zv = lb_data[j];
          if (d < zv) {
            z0_data[j] = zv;
          } else {
            zv = ub_data[j];
            if (d > zv) {
              z0_data[j] = zv;
            }
          }
        }
        zv = b_residCsc(Pd_data, jc_data, ir, vv, d_data, neq, m, n, lb_data,
                        ub_data, z0_data, w_data, &lam);
        if ((zv < o->tolPri) && (lam < o->tolDua)) {
          st = 1;
        }
        exitg2 = 1;
      }
    } while (exitg2 == 0);
  }
  return st;
}

/*
 * Arguments    : const double Pd_data[]
 *                const double jc_data[]
 *                const emxArray_real_T *ir
 *                const emxArray_real_T *vv
 *                const double d_data[]
 *                double neq
 *                double m
 *                double n
 *                const double lb_data[]
 *                const double ub_data[]
 *                const double z_data[]
 *                const double w_data[]
 *                double *rd
 * Return Type  : double
 */
static double b_residCsc(const double Pd_data[], const double jc_data[],
                         const emxArray_real_T *ir, const emxArray_real_T *vv,
                         const double d_data[], double neq, double m, double n,
                         const double lb_data[], const double ub_data[],
                         const double z_data[], const double w_data[],
                         double *rd)
{
  double Ctw_data[1260];
  double Cz_data[840];
  const double *ir_data;
  const double *vv_data;
  double a;
  double d;
  double rda;
  double rp;
  double rpa;
  double sDua;
  int Cz_tmp;
  int i;
  int i1;
  int j;
  int k;
  int loop_ub;
  vv_data = vv->data;
  ir_data = ir->data;
  loop_ub = (int)m;
  if (loop_ub - 1 >= 0) {
    memset(&Cz_data[0], 0, (unsigned int)loop_ub * sizeof(double));
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
  for (Cz_tmp = 0; Cz_tmp < loop_ub; Cz_tmp++) {
    d = fabs(Cz_data[Cz_tmp]);
    if (d > a) {
      a = d;
    }
    d = fabs(d_data[Cz_tmp]);
    if (d > a) {
      a = d;
    }
  }
  rp = rpa / a;
  rda = 0.0;
  sDua = 1.0;
  for (j = 0; j < i; j++) {
    rpa = 0.0;
    i1 = (int)((jc_data[j + 1] - 1.0) + (1.0 - jc_data[j]));
    for (k = 0; k < i1; k++) {
      a = jc_data[j] + (double)k;
      rpa += vv_data[(int)a - 1] * w_data[(int)ir_data[(int)a - 1] - 1];
    }
    Ctw_data[j] = rpa;
  }
  for (j = 0; j < i; j++) {
    double d1;
    double g_tmp;
    d = z_data[j];
    g_tmp = Pd_data[j] * d;
    d1 = Ctw_data[j];
    rpa = g_tmp + d1;
    if ((d <= lb_data[j] + 1.0E-12) && (rpa > 0.0)) {
      rpa = 0.0;
    }
    if ((d >= ub_data[j] - 1.0E-12) && (rpa < 0.0)) {
      rpa = 0.0;
    }
    a = fabs(rpa);
    if (a > rda) {
      rda = a;
    }
    d = fabs(g_tmp);
    if (d > sDua) {
      sDua = d;
    }
    d = fabs(d1);
    if (d > sDua) {
      sDua = d;
    }
  }
  *rd = rda / sDua;
  return rp;
}

/*
 * TRACKSTEPEMB  追従MPC 1周期 (組み込み向け: 生成コード可能な単一関数).
 *
 *    [U0,Z,QCMD,ST,ITERS] = TRACKSTEPEMB(XCPHYS, XR, UR, ENGK, CFG, TP, ZWARM)
 *
 *    TRACK6STEP と同一の数学 (LTV追従QP + PIPG) を, MATLAB Coder
 * で純Cに落とせる 形 (スパース行列なし・トリプレット->CSC・明示ループ)
 * で実装したもの. 参照のサンプリング (時刻/高度ディスパッチ)
 * は呼び出し側で行う.
 *
 *    入力:
 *      XCPHYS 現在状態 (物理単位 14: [r_I(3); v_B(3); q(4); w_B(3); m(kg)])
 *      XR     参照状態 (無次元, 14 x H+1. 四元数は正規化済みであること)
 *      UR     参照制御 (無次元, 7 x H)
 *      ENGK   点火基数 (1 x H)
 *      CFG    機体定数 (scpk.model6 / modelFalcon9)
 *      TP     追従パラメータ (scpk.trackParams)
 *      ZWARM  前周期の解 (21*H x 1. 初回は zeros(21*H,1))
 *
 *    出力:
 *      U0     適用する制御 (無次元 [T_B(3); flap(4)])
 *      ZOUT   今回の解 (次周期のウォームスタート)
 *      QCMD   姿勢コマンド (方式2の内ループ用: MPC予測の次節点姿勢, 正規化済み)
 *      ST     QP状態 (1=converged, 0=maxIter, 4=numerical)
 *      ITERS  QP反復数
 *
 *    See also SCPK.TRACK6STEP, SCPK.TRACKPARAMS, SCPK.PLANITEREMB
 *
 * Arguments    : const double xcPhys[14]
 *                const double xr_data[]
 *                const int xr_size[2]
 *                const double ur_data[]
 *                const int ur_size[2]
 *                const double engk_data[]
 *                const int engk_size[2]
 *                const struct0_T *cfg
 *                const struct5_T *tp
 *                const double zWarm_data[]
 *                const int zWarm_size[1]
 *                double u0[7]
 *                double zOut_data[]
 *                int zOut_size[1]
 *                double qCmd[4]
 *                int *st
 *                int *iters
 * Return Type  : void
 */
void scpk_trackStepEmb(const double xcPhys[14], const double xr_data[],
                       const int xr_size[2], const double ur_data[],
                       const int ur_size[2], const double engk_data[],
                       const int engk_size[2], const struct0_T *cfg,
                       const struct5_T *tp, const double zWarm_data[],
                       const int zWarm_size[1], double u0[7],
                       double zOut_data[], int zOut_size[1], double qCmd[4],
                       int *st, int *iters)
{
  static double BdA_data[5880];
  static short ti_data[18480];
  static short tj_data[18480];
  __m128d r;
  __m128d r1;
  emxArray_real_T *AdA;
  emxArray_real_T *ir;
  emxArray_real_T *tv;
  emxArray_real_T *vv;
  double jc_data[1261];
  double Pd_data[1260];
  double cnt_data[1260];
  double lb_data[1260];
  double ub_data[1260];
  double SdA_data[840];
  double cdA_data[840];
  double d_data[840];
  double A[196];
  double Ad_tmp[196];
  double M[196];
  double Mp[196];
  double Phi[196];
  double b_Mp[196];
  double b_B[112];
  double b_Phi[112];
  double B[98];
  double dv[14];
  double sx[14];
  double xc[14];
  double xr[14];
  double e[7];
  double ur[7];
  double d;
  double d1;
  double hx;
  double s;
  double sinG;
  double *AdA_data;
  double *tv_data;
  double *vv_data;
  int H;
  int b_i;
  int c_i;
  int i;
  int j;
  int k;
  int nt;
  int nz;
  int ou_tmp;
  int r0;
  (void)xr_size;
  (void)engk_size;
  H = ur_size[1] - 1;
  sx[0] = cfg->sc.L;
  sx[1] = cfg->sc.L;
  sx[2] = cfg->sc.L;
  sx[3] = cfg->sc.V;
  sx[4] = cfg->sc.V;
  sx[5] = cfg->sc.V;
  sx[6] = 1.0;
  sx[7] = 1.0;
  sx[8] = 1.0;
  sx[9] = 1.0;
  s = 1.0 / cfg->sc.T;
  sx[10] = s;
  sx[11] = s;
  sx[12] = s;
  sx[13] = cfg->m0;
  for (i = 0; i <= 12; i += 2) {
    r = _mm_loadu_pd(&sx[i]);
    _mm_storeu_pd(&xc[i], _mm_div_pd(_mm_loadu_pd(&xcPhys[i]), r));
  }
  nz = 21 * ur_size[1];
  ou_tmp = 14 * ur_size[1];
  /*  変数: [zx_1..zx_H ; zu_0..zu_{H-1}] */
  /*  ---- コスト (対角) ---- */
  if (nz - 1 >= 0) {
    memset(&Pd_data[0], 0, (unsigned int)nz * sizeof(double));
  }
  b_i = ur_size[1];
  for (k = 0; k < b_i; k++) {
    memcpy(&Pd_data[k * 14], &tp->wx[0], 14U * sizeof(double));
    for (i = 0; i < 7; i++) {
      Pd_data[(ou_tmp + 7 * k) + i] = tp->rCtrl;
    }
  }
  for (i = 0; i <= 12; i += 2) {
    j = 14 * H + i;
    r = _mm_loadu_pd(&Pd_data[j]);
    _mm_storeu_pd(&Pd_data[j], _mm_mul_pd(r, _mm_set1_pd(tp->wTerm)));
  }
  H = (nz / 2) << 1;
  c_i = H - 2;
  for (j = 0; j <= c_i; j += 2) {
    r = _mm_loadu_pd(&Pd_data[j]);
    _mm_storeu_pd(&Pd_data[j], _mm_add_pd(r, _mm_set1_pd(tp->reg)));
  }
  for (j = H; j < nz; j++) {
    Pd_data[j] += tp->reg;
  }
  /*  ---- LTV離散化 (計画と同じ linDisc6All を sigma=1 で流用) ---- */
  /* LINDISC6ALL  全節点の線形化+ZOH離散化 (計画buildのホットループ,
   * コード生成対象). */
  /*  */
  /*    [AD,BD,SD,CD] = LINDISC6ALL(XL,UL,SIGL,PHASE,DTV,CFG) */
  /*  */
  /*    XL 14x(N+1) 線形化点状態, UL 7xN 制御, SIGL 1xnPh 時間膨張 (無次元), */
  /*    PHASE 1xN フェーズ番号, DTV 1xN 正規化刻み. */
  /*    自由終端時刻: sigma を追加制御として扱い, B列に f を足す (buildPlan6
   * と同一). */
  /*  */
  /*    出力: AD 14x14xN, BD 14x7xN, SD 14xN (sigma感度), CD 14xN. */
  /*  */
  /*    コード生成: codegen scpk.linDisc6All -args {...} (drivers/codegenBuild.m
   * 参照) */
  /*    buildPlan6 は linDisc6All_mex があれば自動でそれを使う (単一ソース). */
  /*  */
  /*    See also SCPK.BUILDPLAN6, SCPK.DYNAMICS6, SCPK.DISCRETIZE */
  emxInit_real_T(&AdA, 3);
  j = AdA->size[0] * AdA->size[1] * AdA->size[2];
  AdA->size[0] = 14;
  AdA->size[1] = 14;
  AdA->size[2] = ur_size[1];
  emxEnsureCapacity_real_T(AdA, j);
  AdA_data = AdA->data;
  if (b_i - 1 >= 0) {
    sinG = tp->dtau;
    hx = cfg->jacStep;
    d = 2.0 * cfg->jacStep;
  }
  for (k = 0; k < b_i; k++) {
    /* DYNAMICS6  スターシップ帰還の6自由度ダイナミクス (14状態) とヤコビアン.
     */
    /*  */
    /*    [F,A,B] = DYNAMICS6(X,U,CFG) は無次元化された状態微分 F と,
     * 状態/制御に */
    /*    関するヤコビアン A = df/dx, B = df/du を返す. */
    /*    [F,...] = DYNAMICS6(X,U,CFG,WB) は機体系風速 WB (無次元, 3x1)
     * を与える. */
    /*    空力は対気相対速度 v_rel = v_B - WB で評価される (省略時は無風). */
    /*  */
    /*    大気: cfg.atmIsa=1 のとき密度は ISA 標準大気 (パッド標高 cfg.hPad +
     * 高度) */
    /*    に従い, 空力係数の基準密度 cfg.rho との比で全空力項をスケールする. */
    /*    cfg.atmIsa=0 では一定密度 (従来どおり). */
    /*  */
    /*    状態 (14)   X = [r_I(3); v_B(3); q(4); w_B(3); mhat] */
    /*      r_I  慣性系位置 [高度; クロスレンジ; ダウンレンジ] */
    /*      v_B  機体軸速度  (プラントのセンサバスと同じ規約なので変換不要) */
    /*      q    四元数 スカラー先頭, R(q) は慣性 -> 機体 (Reb, smLanderModel
     * と同じ) */
    /*      w_B  機体軸角速度 */
    /*      mhat 質量 / m0 */
    /*  */
    /*    制御 (7)    U = [T_B(3); d_fr; d_fl; d_rr; d_rl] */
    /*      T_B  機体軸推力ベクトル. スロットルとジンバル角は配分則で作る */
    /*      d_*  フラップ舵角 (トリムからの偏差, 正規化) */
    /*  */
    /*    運動方程式 */
    /*      rdot_I = R(q)' * v_B */
    /*      vdot_B = (T_B + Faero_B)/mhat - w x v_B + R(q)*g_I */
    /*      qdot   = 0.5 * q (x) [0; w_B] */
    /*      wdot_B = J^-1 * (r_T x T_B + Maero_B - w x (J*w)) */
    /*      mdot   = -alpha * ||T_B|| */
    /*  */
    /*    ヤコビアンは中心差分で求める. 14x14 + 14x7 で 42 回の関数評価が要るが,
     */
    /*    1 回の評価が数百 flop なので N=15 でも SCP 反復あたり数十 kflop
     * で済む. */
    /*    解析ヤコビアンは四元数と空力が絡むと導出量が多く誤りやすいため, まず
     */
    /*    差分で正しさを担保する. コストが支配的になれば後で置き換える. */
    /*  NaN = cfg の風テーブルを使用 (計画/追従経路). */
    /*                                     %% プラントは wB
     * を明示指定して風を与える. */
    for (i = 0; i < 14; i++) {
      memset(&sx[0], 0, 14U * sizeof(double));
      sx[i] = hx;
      for (j = 0; j <= 12; j += 2) {
        r = _mm_loadu_pd(&sx[j]);
        _mm_storeu_pd(&xr[j],
                      _mm_add_pd(_mm_loadu_pd(&xr_data[j + 14 * k]), r));
      }
      dyn(xr, &ur_data[7 * k], cfg, dv);
      for (j = 0; j <= 12; j += 2) {
        r = _mm_loadu_pd(&sx[j]);
        _mm_storeu_pd(&xr[j],
                      _mm_sub_pd(_mm_loadu_pd(&xr_data[j + 14 * k]), r));
      }
      dyn(xr, &ur_data[7 * k], cfg, sx);
      for (j = 0; j <= 12; j += 2) {
        r = _mm_loadu_pd(&dv[j]);
        r1 = _mm_loadu_pd(&sx[j]);
        _mm_storeu_pd(&A[j + 14 * i],
                      _mm_div_pd(_mm_sub_pd(r, r1), _mm_set1_pd(d)));
      }
    }
    j = 7 * k + 2;
    r0 = 7 * k + 4;
    s = ur_data[7 * k + 6];
    for (i = 0; i < 7; i++) {
      for (c_i = 0; c_i < 7; c_i++) {
        e[c_i] = 0.0;
      }
      e[i] = hx;
      r = _mm_loadu_pd(&e[0]);
      _mm_storeu_pd(&ur[0], _mm_add_pd(_mm_loadu_pd(&ur_data[7 * k]), r));
      r = _mm_loadu_pd(&e[2]);
      _mm_storeu_pd(&ur[2], _mm_add_pd(_mm_loadu_pd(&ur_data[j]), r));
      r = _mm_loadu_pd(&e[4]);
      _mm_storeu_pd(&ur[4], _mm_add_pd(_mm_loadu_pd(&ur_data[r0]), r));
      ur[6] = s + e[6];
      dyn(&xr_data[14 * k], ur, cfg, dv);
      r = _mm_loadu_pd(&e[0]);
      _mm_storeu_pd(&ur[0], _mm_sub_pd(_mm_loadu_pd(&ur_data[7 * k]), r));
      r = _mm_loadu_pd(&e[2]);
      _mm_storeu_pd(&ur[2], _mm_sub_pd(_mm_loadu_pd(&ur_data[j]), r));
      r = _mm_loadu_pd(&e[4]);
      _mm_storeu_pd(&ur[4], _mm_sub_pd(_mm_loadu_pd(&ur_data[r0]), r));
      ur[6] = s - e[6];
      dyn(&xr_data[14 * k], ur, cfg, sx);
      for (H = 0; H <= 12; H += 2) {
        r = _mm_loadu_pd(&dv[H]);
        r1 = _mm_loadu_pd(&sx[H]);
        _mm_storeu_pd(&B[H + 14 * i],
                      _mm_div_pd(_mm_sub_pd(r, r1), _mm_set1_pd(d)));
      }
    }
    /* DISCRETIZE  線形時変系を ZOH 離散化する (expm 非依存). */
    /*  */
    /*    [AD,BD,CD] = DISCRETIZE(A,B,C,DT) は連続系 */
    /*        xdot = A*x + B*u + c */
    /*    を刻み DT で ZOH 離散化し, x(k+1) = AD*x(k) + BD*u(k) + CD を返す. */
    /*  */
    /*    行列指数を打ち切り級数で評価する: */
    /*        AD = sum_{i=0..N} (A*dt)^i / i! */
    /*        Phi = sum_{i=0..N} (A*dt)^i /(i+1)!   ->  BD = dt*Phi*B,  CD =
     * dt*Phi*c */
    /*    expm はコード生成できるが重く, 組み込みでは固定次数の級数で足りる. */
    /*    NTERM は既定 8 (dt*||A|| < 1 なら十分な精度). */
    eye(Ad_tmp);
    /*  sum M^i/i! */
    /*  sum M^i/(i+1)! */
    for (j = 0; j <= 194; j += 2) {
      r = _mm_loadu_pd(&A[j]);
      _mm_storeu_pd(&M[j], _mm_mul_pd(r, _mm_set1_pd(sinG)));
      r = _mm_loadu_pd(&Ad_tmp[j]);
      _mm_storeu_pd(&Phi[j], r);
      _mm_storeu_pd(&Mp[j], r);
    }
    for (i = 0; i < 8; i++) {
      for (j = 0; j < 14; j++) {
        for (r0 = 0; r0 < 14; r0++) {
          d1 = 0.0;
          for (H = 0; H < 14; H++) {
            d1 += Mp[j + 14 * H] * M[H + 14 * r0];
          }
          b_Mp[j + 14 * r0] = d1 / ((double)i + 1.0);
        }
      }
      for (j = 0; j <= 194; j += 2) {
        r = _mm_loadu_pd(&b_Mp[j]);
        _mm_storeu_pd(&Mp[j], r);
        r1 = _mm_loadu_pd(&Ad_tmp[j]);
        _mm_storeu_pd(&Ad_tmp[j], _mm_add_pd(r1, r));
        r1 = _mm_loadu_pd(&Phi[j]);
        _mm_storeu_pd(
            &Phi[j],
            _mm_add_pd(r1,
                       _mm_div_pd(r, _mm_set1_pd(((double)i + 1.0) + 1.0))));
      }
    }
    dyn(&xr_data[14 * k], &ur_data[7 * k], cfg, dv);
    memcpy(&b_B[0], &B[0], 98U * sizeof(double));
    memcpy(&b_B[98], &dv[0], 14U * sizeof(double));
    for (j = 0; j < 14; j++) {
      for (r0 = 0; r0 < 8; r0++) {
        d1 = 0.0;
        for (H = 0; H < 14; H++) {
          d1 += Phi[j + 14 * H] * b_B[H + 14 * r0];
        }
        b_Phi[j + 14 * r0] = d1;
      }
    }
    for (j = 0; j <= 110; j += 2) {
      r = _mm_loadu_pd(&b_Phi[j]);
      _mm_storeu_pd(&b_Phi[j], _mm_mul_pd(_mm_set1_pd(sinG), r));
    }
    for (j = 0; j < 14; j++) {
      d1 = 0.0;
      for (r0 = 0; r0 < 14; r0++) {
        d1 += -A[j + 14 * r0] * xr_data[r0 + 14 * k];
      }
      s = 0.0;
      for (r0 = 0; r0 < 7; r0++) {
        s += B[j + 14 * r0] * ur_data[r0 + 7 * k];
      }
      dv[j] = d1 - s;
    }
    for (j = 0; j < 14; j++) {
      d1 = 0.0;
      for (r0 = 0; r0 < 14; r0++) {
        d1 += Phi[j + 14 * r0] * dv[r0];
        H = r0 + 14 * j;
        AdA_data[H + 196 * k] = Ad_tmp[H];
      }
      cdA_data[j + 14 * k] = sinG * d1;
    }
    memcpy(&BdA_data[k * 98], &b_Phi[0], 98U * sizeof(double));
    memcpy(&SdA_data[k * 14], &b_Phi[98], 14U * sizeof(double));
  }
  /*  ---- 等式制約 G z = d (トリプレット組み立て) ---- */
  H = ur_size[1] * 308;
  emxInit_real_T(&tv, 1);
  j = tv->size[0];
  tv->size[0] = H;
  emxEnsureCapacity_real_T(tv, j);
  tv_data = tv->data;
  for (j = 0; j < H; j++) {
    ti_data[j] = 0;
    tj_data[j] = 0;
    tv_data[j] = 0.0;
  }
  if (ou_tmp - 1 >= 0) {
    memset(&d_data[0], 0, (unsigned int)ou_tmp * sizeof(double));
  }
  for (i = 0; i <= 12; i += 2) {
    r = _mm_loadu_pd(&xc[i]);
    _mm_storeu_pd(&sx[i], _mm_div_pd(_mm_sub_pd(r, _mm_loadu_pd(&xr_data[i])),
                                     _mm_loadu_pd(&tp->Dx[i])));
  }
  nt = -1;
  for (k = 0; k < b_i; k++) {
    r0 = 14 * k;
    /*     %% 参照の離散化残差 dk = (Ad xr_k + Bd ur_k + cd - xr_{k+1})./Dx */
    /*     %% I on zx_k */
    for (i = 0; i < 14; i++) {
      c_i = i + 14 * k;
      s = (SdA_data[c_i] + cdA_data[c_i]) - xr_data[i + 14 * (k + 1)];
      for (j = 0; j < 14; j++) {
        s += AdA_data[(i + 14 * j) + 196 * k] * xr_data[j + 14 * k];
      }
      for (j = 0; j < 7; j++) {
        s += BdA_data[(i + 14 * j) + 98 * k] * ur_data[j + 7 * k];
      }
      c_i = r0 + i;
      d_data[c_i] = s / tp->Dx[i];
      H = (nt + i) + 1;
      ti_data[H] = (short)(c_i + 1);
      tj_data[H] = (short)(c_i + 1);
      tv_data[H] = 1.0;
    }
    nt += 14;
    if (k + 1 == 1) {
      /*         %% 初期偏差は右辺へ: d += Ãd*dxc */
      for (i = 0; i < 14; i++) {
        s = 0.0;
        for (j = 0; j < 14; j++) {
          s += AdA_data[(i + 14 * j) + 196 * k] * tp->Dx[j] * sx[j];
        }
        c_i = r0 + i;
        d_data[c_i] += s / tp->Dx[i];
      }
    } else {
      /*         %% -Ãd on zx_{k-1} */
      for (i = 0; i < 14; i++) {
        for (j = 0; j < 14; j++) {
          s = -AdA_data[(i + 14 * j) + 196 * k] * tp->Dx[j] / tp->Dx[i];
          if (s != 0.0) {
            nt++;
            ti_data[nt] = (short)((r0 + i) + 1);
            tj_data[nt] = (short)((14 * (k - 1) + j) + 1);
            tv_data[nt] = s;
          }
        }
      }
    }
    /*     %% -B̃d on zu_k */
    for (i = 0; i < 14; i++) {
      for (j = 0; j < 7; j++) {
        s = -BdA_data[(i + 14 * j) + 98 * k] * tp->Du[j] / tp->Dx[i];
        if (s != 0.0) {
          nt++;
          ti_data[nt] = (short)((r0 + i) + 1);
          tj_data[nt] = (short)(((ou_tmp + 7 * k) + j) + 1);
          tv_data[nt] = s;
        }
      }
    }
  }
  emxFree_real_T(&AdA);
  /*  ---- 箱制約 (物理制約 - 参照) ---- */
  for (j = 0; j < nz; j++) {
    lb_data[j] = -1.0E+20;
    ub_data[j] = 1.0E+20;
  }
  sinG = sin(cfg->veh.tvcMax);
  for (k = 0; k < b_i; k++) {
    __m128d r2;
    __m128d r3;
    H = ou_tmp + 7 * k;
    d = engk_data[k];
    s = d * cfg->Tmax1;
    d1 = ur_data[7 * k];
    lb_data[H] = (d * cfg->Tmin1 - d1) / tp->Du[0];
    ub_data[H] = (s - d1) / tp->Du[0];
    s *= sinG;
    d1 = ur_data[7 * k + 1];
    lb_data[H + 1] = (-s - d1) / tp->Du[1];
    ub_data[H + 1] = (s - d1) / tp->Du[1];
    d1 = ur_data[7 * k + 2];
    lb_data[H + 2] = (-s - d1) / tp->Du[2];
    ub_data[H + 2] = (s - d1) / tp->Du[2];
    r = _mm_loadu_pd(&ur_data[7 * k + 3]);
    r1 = _mm_loadu_pd(&tp->Du[3]);
    r2 = _mm_set1_pd(-cfg->veh.flapTrim);
    _mm_storeu_pd(&lb_data[H + 3], _mm_div_pd(_mm_sub_pd(r2, r), r1));
    r3 = _mm_set1_pd(cfg->veh.flapMax - cfg->veh.flapTrim);
    _mm_storeu_pd(&ub_data[H + 3], _mm_div_pd(_mm_sub_pd(r3, r), r1));
    r = _mm_loadu_pd(&ur_data[7 * k + 5]);
    r1 = _mm_loadu_pd(&tp->Du[5]);
    _mm_storeu_pd(&lb_data[H + 5], _mm_div_pd(_mm_sub_pd(r2, r), r1));
    _mm_storeu_pd(&ub_data[H + 5], _mm_div_pd(_mm_sub_pd(r3, r), r1));
    if (d == 0.0) {
      _mm_storeu_pd(&lb_data[H],
                    _mm_div_pd(_mm_sub_pd(_mm_set1_pd(0.0),
                                          _mm_loadu_pd(&ur_data[7 * k])),
                               _mm_loadu_pd(&tp->Du[0])));
      r = _mm_loadu_pd(&lb_data[H]);
      _mm_storeu_pd(&ub_data[H], r);
      lb_data[H + 2] = (0.0 - d1) / tp->Du[2];
      ub_data[H + 2] = lb_data[H + 2];
    }
  }
  /*  ---- CSC化 -> PIPG (Ruizなし:
   * ウォームスタート保護のため許容誤差スケールのみ) ---- */
  /* TRI2CSC  トリプレット -> CSC (planIterEmb と同一). */
  if (nz - 1 >= 0) {
    memset(&cnt_data[0], 0, (unsigned int)nz * sizeof(double));
  }
  for (k = 0; k <= nt; k++) {
    H = tj_data[k] - 1;
    cnt_data[H]++;
  }
  memset(&jc_data[0], 0, (unsigned int)(nz + 1) * sizeof(double));
  jc_data[0] = 1.0;
  for (j = 0; j < nz; j++) {
    jc_data[j + 1] = jc_data[j] + cnt_data[j];
    cnt_data[j] = 0.0;
  }
  emxInit_real_T(&ir, 1);
  b_i = ir->size[0];
  ir->size[0] = nt + 1;
  emxEnsureCapacity_real_T(ir, b_i);
  AdA_data = ir->data;
  emxInit_real_T(&vv, 1);
  b_i = vv->size[0];
  vv->size[0] = nt + 1;
  emxEnsureCapacity_real_T(vv, b_i);
  vv_data = vv->data;
  for (b_i = 0; b_i <= nt; b_i++) {
    AdA_data[b_i] = 0.0;
    vv_data[b_i] = 0.0;
  }
  for (k = 0; k <= nt; k++) {
    H = tj_data[k] - 1;
    s = cnt_data[H];
    sinG = jc_data[H] + s;
    AdA_data[(int)sinG - 1] = ti_data[k];
    vv_data[(int)sinG - 1] = tv_data[k];
    cnt_data[H] = s + 1.0;
  }
  emxFree_real_T(&tv);
  zOut_size[0] = nz;
  if (nz - 1 >= 0) {
    memset(&zOut_data[0], 0, (unsigned int)nz * sizeof(double));
  }
  if ((zWarm_size[0] == nz) && (nz - 1 >= 0)) {
    memcpy(&zOut_data[0], &zWarm_data[0], (unsigned int)nz * sizeof(double));
  }
  *st = b_pipgCsc(Pd_data, jc_data, ir, vv, d_data, ou_tmp, ou_tmp, nz, lb_data,
                  ub_data, tp, zOut_data, &zOut_size[0], iters);
  emxFree_real_T(&vv);
  emxFree_real_T(&ir);
  /*  ---- 復元 ---- */
  r = _mm_loadu_pd(&zOut_data[ou_tmp]);
  _mm_storeu_pd(&u0[0], _mm_add_pd(_mm_loadu_pd(&ur_data[0]),
                                   _mm_mul_pd(r, _mm_loadu_pd(&tp->Du[0]))));
  r = _mm_loadu_pd(&zOut_data[ou_tmp + 2]);
  _mm_storeu_pd(&u0[2], _mm_add_pd(_mm_loadu_pd(&ur_data[2]),
                                   _mm_mul_pd(r, _mm_loadu_pd(&tp->Du[2]))));
  r = _mm_loadu_pd(&zOut_data[ou_tmp + 4]);
  _mm_storeu_pd(&u0[4], _mm_add_pd(_mm_loadu_pd(&ur_data[4]),
                                   _mm_mul_pd(r, _mm_loadu_pd(&tp->Du[4]))));
  u0[6] = ur_data[6] + zOut_data[ou_tmp + 6] * tp->Du[6];
  if (engk_data[0] == 0.0) {
    u0[0] = 0.0;
    u0[1] = 0.0;
    u0[2] = 0.0;
    /*  基数0 (空力降下) は推力ゼロ厳守 */
  }
  r = _mm_loadu_pd(&zOut_data[6]);
  _mm_storeu_pd(&qCmd[0], _mm_add_pd(_mm_loadu_pd(&xr_data[20]),
                                     _mm_mul_pd(r, _mm_loadu_pd(&tp->Dx[6]))));
  r = _mm_loadu_pd(&zOut_data[8]);
  _mm_storeu_pd(&qCmd[2], _mm_add_pd(_mm_loadu_pd(&xr_data[22]),
                                     _mm_mul_pd(r, _mm_loadu_pd(&tp->Dx[8]))));
  s = sqrt(((qCmd[0] * qCmd[0] + qCmd[1] * qCmd[1]) + qCmd[2] * qCmd[2]) +
           qCmd[3] * qCmd[3]);
  if (s > 1.0E-12) {
    r = _mm_loadu_pd(&qCmd[0]);
    r1 = _mm_set1_pd(s);
    _mm_storeu_pd(&qCmd[0], _mm_div_pd(r, r1));
    r = _mm_loadu_pd(&qCmd[2]);
    _mm_storeu_pd(&qCmd[2], _mm_div_pd(r, r1));
  }
}

/*
 * File trailer for scpk_trackStepEmb.c
 *
 * [EOF]
 */
