/*
 * File: dynamics6.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 19:09:09
 */

/* Include Files */
#include "dynamics6.h"
#include "gncCore_lib_types.h"
#include "rt_nonfinite.h"
#include "rt_nonfinite.h"
#include <emmintrin.h>
#include <math.h>
#include <string.h>

/* Function Declarations */
static double rt_powd_snf(double u0, double u1);

/* Function Definitions */
/*
 * Arguments    : double u0
 *                double u1
 * Return Type  : double
 */
static double rt_powd_snf(double u0, double u1)
{
  double y;
  if (rtIsNaN(u0) || rtIsNaN(u1)) {
    y = rtNaN;
  } else {
    double d;
    y = fabs(u0);
    d = fabs(u1);
    if (rtIsInf(u1)) {
      if (y == 1.0) {
        y = 1.0;
      } else if (y > 1.0) {
        if (u1 > 0.0) {
          y = rtInf;
        } else {
          y = 0.0;
        }
      } else if (u1 > 0.0) {
        y = 0.0;
      } else {
        y = rtInf;
      }
    } else if (d == 0.0) {
      y = 1.0;
    } else if (d == 1.0) {
      if (u1 > 0.0) {
        y = u0;
      } else {
        y = 1.0 / u0;
      }
    } else if (u1 == 2.0) {
      y = u0 * u0;
    } else if ((u1 == 0.5) && (u0 >= 0.0)) {
      y = sqrt(u0);
    } else if ((u0 < 0.0) && (u1 > floor(u1))) {
      y = rtNaN;
    } else {
      y = pow(u0, u1);
    }
  }
  return y;
}

/*
 * DYN  状態微分の本体.
 *
 * Arguments    : const double x[14]
 *                const double u[7]
 *                const struct0_T *cfg
 *                double f[14]
 * Return Type  : void
 */
void dyn(const double x[14], const double u[7], const struct0_T *cfg,
         double f[14])
{
  __m128d r;
  __m128d r1;
  double R[9];
  double Fa[3];
  double b_x[3];
  double wB[3];
  double R_tmp;
  double V;
  double fRho;
  double hq;
  double mh;
  double qs;
  double wy;
  double wz;
  int ii;
  mh = fmax(x[13], cfg->mhatMin);
  /*  --- 回転行列 R(q): 慣性 -> 機体 --- */
  hq = x[9] * x[9];
  wy = x[8] * x[8];
  R[0] = 1.0 - 2.0 * (wy + hq);
  wz = x[7] * x[8];
  fRho = x[6] * x[9];
  R[3] = 2.0 * (wz + fRho);
  V = x[7] * x[9];
  R_tmp = x[6] * x[8];
  R[6] = 2.0 * (V - R_tmp);
  R[1] = 2.0 * (wz - fRho);
  wz = x[7] * x[7];
  R[4] = 1.0 - 2.0 * (wz + hq);
  hq = x[8] * x[9];
  fRho = x[6] * x[7];
  R[7] = 2.0 * (hq + fRho);
  R[2] = 2.0 * (V + R_tmp);
  R[5] = 2.0 * (hq - fRho);
  R[8] = 1.0 - 2.0 * (wz + wy);
  /*  --- 風 (wB=NaN のとき cfg の風テーブルから計算: 計画・追従MPC用) --- */
  /*  既知の風況を計画モデルに入れることで, コースト等の制御力が無い区間の */
  /*  風ドリフトをフィードフォワードで織り込む (残差はフィードバックが吸収). */
  wB[0] = 0.0;
  wB[1] = 0.0;
  wB[2] = 0.0;
  if (cfg->wOn > 0.0) {
    bool exitg1;
    hq = fmin(fmax(x[0] * cfg->sc.L, cfg->wTabH[0]), cfg->wTabH[7]);
    wy = cfg->wTabY[7];
    wz = cfg->wTabZ[7];
    ii = 0;
    exitg1 = false;
    while ((!exitg1) && (ii < 7)) {
      V = cfg->wTabH[ii + 1];
      if (hq <= V) {
        hq = (hq - cfg->wTabH[ii]) / fmax(V - cfg->wTabH[ii], 1.0E-9);
        wy = cfg->wTabY[ii] + hq * (cfg->wTabY[ii + 1] - cfg->wTabY[ii]);
        wz = cfg->wTabZ[ii] + hq * (cfg->wTabZ[ii + 1] - cfg->wTabZ[ii]);
        exitg1 = true;
      } else {
        ii++;
      }
    }
    V = 0.0 / cfg->sc.V;
    R_tmp = wy / cfg->sc.V;
    hq = wz / cfg->sc.V;
    r = _mm_loadu_pd(&R[0]);
    r = _mm_mul_pd(r, _mm_set1_pd(V));
    r1 = _mm_loadu_pd(&R[3]);
    r1 = _mm_mul_pd(r1, _mm_set1_pd(R_tmp));
    r = _mm_add_pd(r, r1);
    r1 = _mm_loadu_pd(&R[6]);
    r1 = _mm_mul_pd(r1, _mm_set1_pd(hq));
    r = _mm_add_pd(r, r1);
    _mm_storeu_pd(&wB[0], r);
    wB[2] = (R[2] * V + R[5] * R_tmp) + R[8] * hq;
    /*  慣性系風 -> 機体系 (無次元) */
  }
  r = _mm_loadu_pd(&wB[0]);
  _mm_storeu_pd(&wB[0], _mm_sub_pd(_mm_loadu_pd(&x[3]), r));
  wB[2] = x[5] - wB[2];
  /*  対気相対速度 (空力のみに使用) */
  /*  --- 空力 (機体軸成分ごとの抗力 + フラップ. 対気速度 va で評価) --- */
  hq = wB[1] * wB[1];
  wy = wB[2] * wB[2];
  wz = (wB[0] * wB[0] + hq) + wy;
  V = sqrt(wz + cfg->vEps);
  /*  大気密度比: ISA (cfg.atmIsa=1) なら 高度に応じて rhoISA/cfg.rho を乗じる
   */
  if (cfg->atmIsa > 0.0) {
    fRho = 1.225 *
           rt_powd_snf(
               (288.15 - 0.0065 * fmin(fmax(cfg->hPad + x[0] * cfg->sc.L, 0.0),
                                       11000.0)) /
                   288.15,
               4.2561) /
           cfg->rho;
  } else {
    fRho = 1.0;
  }
  /*  成分抗力: 各機体軸の速度成分に比例. 一様円柱なので CG
   * まわりのモーメントは持たない */
  Fa[0] = -fRho * (cfg->cx * V * wB[0]);
  Fa[1] = -fRho * (cfg->cy * V * wB[1]);
  Fa[2] = -fRho * (cfg->cz * V * wB[2]);
  /*  揚力は別項として足さない. 成分抗力 -[cx*V*vx; cy*V*vy; cz*V*vz] は */
  /*  cx ~= cy のとき合力が速度と平行にならず, その垂直成分が揚力になる. */
  /*  迎角ちょうど 90deg では vx=0 で揚力が消えるが, これは対称な円柱として */
  /*  物理的に正しい. 実機も迎角を 90deg から外して揚力を得る. */
  /*  操縦翼面. cfg.surfMode で機体のデバイスを切替: */
  /*    1 = ベリーフラップ (Starship): 迎角依存 |sin(alpha)| で減衰 */
  /*        (テールダウンでは流れに沿うので効きが消える) */
  /*    2 = グリッドフィン (Falcon9): 軸流でも効く (迎角依存なし) */
  if (cfg->surfMode >= 2.0) {
    qs = fRho * wz / cfg->V2ref;
  } else {
    qs = fRho * (wz / cfg->V2ref) * (sqrt(hq + wy) / V);
  }
  if (rtIsNaN(wB[0])) {
    hq = rtNaN;
  } else if (wB[0] < 0.0) {
    hq = -1.0;
  } else {
    hq = (wB[0] > 0.0);
  }
  Fa[0] -= cfg->cFlapDrag * qs * V * hq * fabs(wB[0]) / fmax(V, cfg->vEps);
  /*  --- 推力 --- */
  /*  --- 微分 --- */
  memset(&f[0], 0, 14U * sizeof(double));
  b_x[0] = x[5] * x[11] - x[4] * x[12];
  b_x[1] = x[3] * x[12] - x[5] * x[10];
  b_x[2] = x[4] * x[10] - x[3] * x[11];
  f[6] = -0.5 * ((x[7] * x[10] + x[8] * x[11]) + x[9] * x[12]);
  f[7] = 0.5 * ((x[6] * x[10] + x[8] * x[12]) - x[9] * x[11]);
  f[8] = 0.5 * ((x[6] * x[11] + x[9] * x[10]) - x[7] * x[12]);
  f[9] = 0.5 * ((x[6] * x[12] + x[7] * x[11]) - x[8] * x[10]);
  /*  フラップの寄与 Ma は実測同定が角加速度なので Jinv を通さず直接加える. */
  /*  モーメント扱いすると Jinv (対角 3073) 倍だけ過大になる. */
  V = x[3];
  R_tmp = x[4];
  hq = x[5];
  wy = x[10];
  wz = x[11];
  fRho = x[12];
  for (ii = 0; ii < 3; ii++) {
    f[ii] = (R[3 * ii] * V + R[3 * ii + 1] * R_tmp) + R[3 * ii + 2] * hq;
    f[ii + 3] = ((u[ii] + Fa[ii]) / mh - b_x[ii]) +
                ((R[ii] * cfg->gI[0] + R[ii + 3] * cfg->gI[1]) +
                 R[ii + 6] * cfg->gI[2]);
    wB[ii] = (cfg->J[ii] * wy + cfg->J[ii + 3] * wz) + cfg->J[ii + 6] * fRho;
  }
  Fa[0] = cfg->rT[1] * u[2] - u[1] * cfg->rT[2];
  Fa[1] = u[0] * cfg->rT[2] - cfg->rT[0] * u[2];
  Fa[2] = cfg->rT[0] * u[1] - u[0] * cfg->rT[1];
  b_x[0] = wB[2] * x[11] - wB[1] * x[12];
  b_x[1] = wB[0] * x[12] - wB[2] * x[10];
  b_x[2] = wB[1] * x[10] - wB[0] * x[11];
  V = u[3];
  R_tmp = u[4];
  hq = u[5];
  wy = u[6];
  r = _mm_loadu_pd(&Fa[0]);
  r1 = _mm_loadu_pd(&b_x[0]);
  r = _mm_sub_pd(r, r1);
  _mm_storeu_pd(&Fa[0], r);
  r = _mm_loadu_pd(&cfg->Bflap[0]);
  r = _mm_mul_pd(r, _mm_set1_pd(V));
  r1 = _mm_loadu_pd(&cfg->Bflap[3]);
  r1 = _mm_mul_pd(r1, _mm_set1_pd(R_tmp));
  r = _mm_add_pd(r, r1);
  r1 = _mm_loadu_pd(&cfg->Bflap[6]);
  r1 = _mm_mul_pd(r1, _mm_set1_pd(hq));
  r = _mm_add_pd(r, r1);
  r1 = _mm_loadu_pd(&cfg->Bflap[9]);
  r1 = _mm_mul_pd(r1, _mm_set1_pd(wy));
  r = _mm_add_pd(r, r1);
  _mm_storeu_pd(&b_x[0], r);
  Fa[2] -= b_x[2];
  b_x[2] = ((cfg->Bflap[2] * V + cfg->Bflap[5] * R_tmp) + cfg->Bflap[8] * hq) +
           cfg->Bflap[11] * wy;
  V = Fa[0];
  R_tmp = Fa[1];
  hq = Fa[2];
  r = _mm_loadu_pd(&cfg->Jinv[0]);
  r = _mm_mul_pd(r, _mm_set1_pd(V));
  r1 = _mm_loadu_pd(&cfg->Jinv[3]);
  r1 = _mm_mul_pd(r1, _mm_set1_pd(R_tmp));
  r = _mm_add_pd(r, r1);
  r1 = _mm_loadu_pd(&cfg->Jinv[6]);
  r1 = _mm_mul_pd(r1, _mm_set1_pd(hq));
  r = _mm_add_pd(r, r1);
  r1 = _mm_loadu_pd(&b_x[0]);
  r1 = _mm_mul_pd(r1, _mm_set1_pd(qs));
  r = _mm_add_pd(r, r1);
  _mm_storeu_pd(&f[10], r);
  f[12] = ((cfg->Jinv[2] * V + cfg->Jinv[5] * R_tmp) + cfg->Jinv[8] * hq) +
          b_x[2] * qs;
  f[13] = -cfg->alpha *
          sqrt(((u[0] * u[0] + u[1] * u[1]) + u[2] * u[2]) + cfg->tEps);
}

/*
 * File trailer for dynamics6.c
 *
 * [EOF]
 */
