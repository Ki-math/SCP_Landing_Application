/*
 * File: linDisc6All.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 22:18:33
 */

/* Include Files */
#include "linDisc6All.h"
#include "dynamics6.h"
#include "eye.h"
#include "gncCore_lib_emxutil.h"
#include "gncCore_lib_types.h"
#include "rt_nonfinite.h"
#include <emmintrin.h>
#include <string.h>

/* Function Definitions */
/*
 * LINDISC6ALL  全節点の線形化+ZOH離散化 (計画buildのホットループ,
 * コード生成対象).
 *
 *    [AD,BD,SD,CD] = LINDISC6ALL(XL,UL,SIGL,PHASE,DTV,CFG)
 *
 *    XL 14x(N+1) 線形化点状態, UL 7xN 制御, SIGL 1xnPh 時間膨張 (無次元),
 *    PHASE 1xN フェーズ番号, DTV 1xN 正規化刻み.
 *    自由終端時刻: sigma を追加制御として扱い, B列に f を足す (buildPlan6
 * と同一).
 *
 *    出力: AD 14x14xN, BD 14x7xN, SD 14xN (sigma感度), CD 14xN.
 *
 *    コード生成: codegen scpk.linDisc6All -args {...} (drivers/codegenBuild.m
 * 参照) buildPlan6 は linDisc6All_mex があれば自動でそれを使う (単一ソース).
 *
 *    See also SCPK.BUILDPLAN6, SCPK.DYNAMICS6, SCPK.DISCRETIZE
 *
 * Arguments    : const double xl_data[]
 *                const double ul_data[]
 *                const int ul_size[2]
 *                const double sigl_data[]
 *                const double phase_data[]
 *                const double dtv_data[]
 *                const struct0_T *cfg
 *                emxArray_real_T *Ad
 *                emxArray_real_T *Bd
 *                double Sd_data[]
 *                int Sd_size[2]
 *                double cd_data[]
 *                int cd_size[2]
 * Return Type  : void
 */
void linDisc6All(const double xl_data[], const double ul_data[],
                 const int ul_size[2], const double sigl_data[],
                 const double phase_data[], const double dtv_data[],
                 const struct0_T *cfg, emxArray_real_T *Ad, emxArray_real_T *Bd,
                 double Sd_data[], int Sd_size[2], double cd_data[],
                 int cd_size[2])
{
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
  double e[14];
  double xl[14];
  double b_e[7];
  double ul[7];
  double d;
  double hx;
  double *Ad_data;
  double *Bd_data;
  int b_i;
  int c_i;
  int i;
  int i1;
  int i2;
  int k;
  i = Ad->size[0] * Ad->size[1] * Ad->size[2];
  Ad->size[0] = 14;
  Ad->size[1] = 14;
  i1 = ul_size[1];
  Ad->size[2] = ul_size[1];
  emxEnsureCapacity_real_T(Ad, i);
  Ad_data = Ad->data;
  i = Bd->size[0] * Bd->size[1] * Bd->size[2];
  Bd->size[0] = 14;
  Bd->size[1] = 7;
  Bd->size[2] = ul_size[1];
  emxEnsureCapacity_real_T(Bd, i);
  Bd_data = Bd->data;
  Sd_size[0] = 14;
  Sd_size[1] = ul_size[1];
  cd_size[0] = 14;
  cd_size[1] = ul_size[1];
  if (i1 - 1 >= 0) {
    hx = cfg->jacStep;
    d = 2.0 * cfg->jacStep;
  }
  for (k = 0; k < i1; k++) {
    __m128d r;
    __m128d r1;
    double d1;
    double dtv;
    double ul_tmp;
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
    for (b_i = 0; b_i < 14; b_i++) {
      memset(&e[0], 0, 14U * sizeof(double));
      e[b_i] = hx;
      for (i = 0; i <= 12; i += 2) {
        r = _mm_loadu_pd(&e[i]);
        _mm_storeu_pd(&xl[i],
                      _mm_add_pd(_mm_loadu_pd(&xl_data[i + 14 * k]), r));
      }
      dyn(xl, &ul_data[7 * k], cfg, dv);
      for (i = 0; i <= 12; i += 2) {
        r = _mm_loadu_pd(&e[i]);
        _mm_storeu_pd(&xl[i],
                      _mm_sub_pd(_mm_loadu_pd(&xl_data[i + 14 * k]), r));
      }
      dyn(xl, &ul_data[7 * k], cfg, e);
      for (i = 0; i <= 12; i += 2) {
        r = _mm_loadu_pd(&dv[i]);
        r1 = _mm_loadu_pd(&e[i]);
        _mm_storeu_pd(&A[i + 14 * b_i],
                      _mm_div_pd(_mm_sub_pd(r, r1), _mm_set1_pd(d)));
      }
    }
    i = 7 * k + 2;
    i2 = 7 * k + 4;
    ul_tmp = ul_data[7 * k + 6];
    for (b_i = 0; b_i < 7; b_i++) {
      for (c_i = 0; c_i < 7; c_i++) {
        b_e[c_i] = 0.0;
      }
      b_e[b_i] = hx;
      r = _mm_loadu_pd(&b_e[0]);
      _mm_storeu_pd(&ul[0], _mm_add_pd(_mm_loadu_pd(&ul_data[7 * k]), r));
      r = _mm_loadu_pd(&b_e[2]);
      _mm_storeu_pd(&ul[2], _mm_add_pd(_mm_loadu_pd(&ul_data[i]), r));
      r = _mm_loadu_pd(&b_e[4]);
      _mm_storeu_pd(&ul[4], _mm_add_pd(_mm_loadu_pd(&ul_data[i2]), r));
      ul[6] = ul_tmp + b_e[6];
      dyn(&xl_data[14 * k], ul, cfg, dv);
      r = _mm_loadu_pd(&b_e[0]);
      _mm_storeu_pd(&ul[0], _mm_sub_pd(_mm_loadu_pd(&ul_data[7 * k]), r));
      r = _mm_loadu_pd(&b_e[2]);
      _mm_storeu_pd(&ul[2], _mm_sub_pd(_mm_loadu_pd(&ul_data[i]), r));
      r = _mm_loadu_pd(&b_e[4]);
      _mm_storeu_pd(&ul[4], _mm_sub_pd(_mm_loadu_pd(&ul_data[i2]), r));
      ul[6] = ul_tmp - b_e[6];
      dyn(&xl_data[14 * k], ul, cfg, e);
      for (c_i = 0; c_i <= 12; c_i += 2) {
        r = _mm_loadu_pd(&dv[c_i]);
        r1 = _mm_loadu_pd(&e[c_i]);
        _mm_storeu_pd(&B[c_i + 14 * b_i],
                      _mm_div_pd(_mm_sub_pd(r, r1), _mm_set1_pd(d)));
      }
    }
    ul_tmp = sigl_data[(int)phase_data[k] - 1];
    for (i = 0; i <= 96; i += 2) {
      r = _mm_loadu_pd(&B[i]);
      _mm_storeu_pd(&B[i], _mm_mul_pd(_mm_set1_pd(ul_tmp), r));
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
    dtv = dtv_data[k];
    eye(Ad_tmp);
    /*  sum M^i/i! */
    /*  sum M^i/(i+1)! */
    for (i = 0; i <= 194; i += 2) {
      r = _mm_loadu_pd(&A[i]);
      _mm_storeu_pd(&M[i], _mm_mul_pd(_mm_mul_pd(_mm_set1_pd(ul_tmp), r),
                                      _mm_set1_pd(dtv)));
      r = _mm_loadu_pd(&Ad_tmp[i]);
      _mm_storeu_pd(&Phi[i], r);
      _mm_storeu_pd(&Mp[i], r);
    }
    for (b_i = 0; b_i < 8; b_i++) {
      for (i = 0; i < 14; i++) {
        for (i2 = 0; i2 < 14; i2++) {
          d1 = 0.0;
          for (c_i = 0; c_i < 14; c_i++) {
            d1 += Mp[i + 14 * c_i] * M[c_i + 14 * i2];
          }
          b_Mp[i + 14 * i2] = d1 / ((double)b_i + 1.0);
        }
      }
      for (i = 0; i <= 194; i += 2) {
        r = _mm_loadu_pd(&b_Mp[i]);
        _mm_storeu_pd(&Mp[i], r);
        r1 = _mm_loadu_pd(&Ad_tmp[i]);
        _mm_storeu_pd(&Ad_tmp[i], _mm_add_pd(r1, r));
        r1 = _mm_loadu_pd(&Phi[i]);
        _mm_storeu_pd(
            &Phi[i],
            _mm_add_pd(r1,
                       _mm_div_pd(r, _mm_set1_pd(((double)b_i + 1.0) + 1.0))));
      }
    }
    dyn(&xl_data[14 * k], &ul_data[7 * k], cfg, dv);
    memcpy(&b_B[0], &B[0], 98U * sizeof(double));
    memcpy(&b_B[98], &dv[0], 14U * sizeof(double));
    for (i = 0; i < 14; i++) {
      for (i2 = 0; i2 < 8; i2++) {
        d1 = 0.0;
        for (c_i = 0; c_i < 14; c_i++) {
          d1 += Phi[i + 14 * c_i] * b_B[c_i + 14 * i2];
        }
        b_Phi[i + 14 * i2] = d1;
      }
    }
    for (i = 0; i <= 110; i += 2) {
      r = _mm_loadu_pd(&b_Phi[i]);
      _mm_storeu_pd(&b_Phi[i], _mm_mul_pd(_mm_set1_pd(dtv), r));
    }
    for (i = 0; i < 14; i++) {
      double d2;
      d1 = 0.0;
      for (i2 = 0; i2 < 14; i2++) {
        d1 += -ul_tmp * A[i + 14 * i2] * xl_data[i2 + 14 * k];
      }
      d2 = 0.0;
      for (i2 = 0; i2 < 7; i2++) {
        d2 += B[i + 14 * i2] * ul_data[i2 + 7 * k];
      }
      xl[i] = d1 - d2;
    }
    for (i = 0; i < 14; i++) {
      d1 = 0.0;
      for (i2 = 0; i2 < 14; i2++) {
        d1 += Phi[i + 14 * i2] * xl[i2];
        c_i = i2 + 14 * i;
        Ad_data[c_i + 196 * k] = Ad_tmp[c_i];
      }
      cd_data[i + 14 * k] = dtv * d1;
    }
    for (i = 0; i < 98; i++) {
      Bd_data[i + k * 98] = b_Phi[i];
    }
    memcpy(&Sd_data[k * 14], &b_Phi[98], 14U * sizeof(double));
  }
}

/*
 * File trailer for linDisc6All.c
 *
 * [EOF]
 */
