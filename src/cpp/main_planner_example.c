/* main_planner_example.c — 計画SCP 1反復 (scpk_planIterEmb) の呼び出し例.
 *
 * 実データ (Starship着陸問題, 収束済み解を初期推定) で 1反復を実行し,
 * cold (ウォームスタートなし) と warm (前回の内部状態 zOut を再利用) を比較する.
 * 実運用の 100ms 周期再計画は warm 呼び出しの繰り返しに相当する.
 *
 * ビルド (パッケージ直下で. gnc/ の全 .c とまとめてコンパイル):
 *   gcc -O2 -Ignc -Iexamples examples/main_planner_example.c gnc/*.c \
 *       -o planner_demo -lm
 * 実行:
 *   ./planner_demo
 */
#include <stdio.h>
#include <time.h>
#include "scpk_planIterEmb.h"
#include "gncCore_lib_emxAPI.h"
#include "gncCore_lib_initialize.h"
#include "gncCore_lib_terminate.h"
#include "plan_example_data.h"

static double run_once(const struct0_T *cfg, const struct3_T *pp,
                       const struct4_T *qp, emxArray_real_T *zWarm,
                       emxArray_real_T *zOut, int *st, int *iters,
                       double ss[8], int ss_size[2])
{
    static double xs[14*201], us[7*200], gs[200];
    int xs_size[2], us_size[2], gs_size[2];
    double nu, step;
    clock_t t0 = clock();
    scpk_planIterEmb(ex_x0nd, ex_xT,
                     ex_xl, ex_xl_size, ex_ul, ex_ul_size,
                     ex_gl, ex_gl_size, ex_sigl, ex_sigl_size,
                     ex_phase, ex_phase_size, ex_eng, ex_eng_size,
                     ex_dtv, ex_dtv_size, ex_tiltN, ex_tiltN_size,
                     cfg, pp, qp, zWarm,
                     xs, xs_size, us, us_size, gs, gs_size,
                     ss, ss_size, st, iters, &nu, &step, zOut);
    return (double)(clock() - t0) * 1000.0 / CLOCKS_PER_SEC;
}

int main(void)
{
    static struct0_T cfg;
    static struct3_T pp;
    static struct4_T qp;
    double ss[8], tCold, tWarm;
    int ss_size[2], st, iters, i;

    gncCore_lib_initialize();
    fill_cfg(&cfg);  fill_pp(&pp);  fill_qp(&qp);

    /* --- cold: ウォームスタートなし (空の zWarm) --- */
    emxArray_real_T *zWarm = emxCreate_real_T(0, 1);
    emxArray_real_T *zOut  = emxCreate_real_T(0, 1);
    tCold = run_once(&cfg, &pp, &qp, zWarm, zOut, &st, &iters, ss, ss_size);
    printf("cold : status=%d iters=%d  %.1f ms\n", st, iters, tCold);

    /* --- warm: 前回の zOut を次の初期値に (再計画サイクルの形) --- */
    tWarm = run_once(&cfg, &pp, &qp, zOut, zWarm, &st, &iters, ss, ss_size);
    printf("warm : status=%d iters=%d  %.1f ms\n", st, iters, tWarm);

    printf("sigma (フェーズ時間, 無次元) = [");
    for (i = 0; i < ss_size[1]; ++i) printf(" %.3f", ss[i]);
    printf(" ]\n");
    printf("status: 1=converged 0=maxIter 2/3=infeasible 4=numerical\n");

    emxDestroyArray_real_T(zWarm);
    emxDestroyArray_real_T(zOut);
    gncCore_lib_terminate();
    return (st == 1) ? 0 : 1;
}
