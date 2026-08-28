/* main_tracker_example.c — 追従MPC (scpk_trackStepEmb) 単体の呼び出し例.
 *
 * 計画解 (plan_example_data.h の高密度参照) からホライズン窓を切り出し,
 * 追従MPCを cold / warm で1周期ずつ解く. 実運用では warm 呼び出しを
 * 制御周期 (既定 100 ms) ごとに繰り返す.
 *
 * ビルド (パッケージ直下で):
 *   gcc -O2 -Ignc -Iguidance -Iexamples examples/main_tracker_example.c \
 *       gnc/*.c guidance/*.c -o tracker_demo -lm
 * 実行:
 *   ./tracker_demo
 */
#include <stdio.h>
#include <time.h>
#include "scpk_trackStepEmb.h"
#include "gncCore_lib_initialize.h"
#include "gncCore_lib_terminate.h"
#include "plan_example_data.h"
#include "gnc_guidance.h"

int main(void)
{
    static struct0_T cfg;
    static struct5_T tp;
    static double xr[14*61], ur[7*60], engk[60];
    static double zw[1300], zo[1300];
    double xc[14], sx[14], u0[7], qCmd[4];
    int xr_size[2], ur_size[2], engk_size[2], zw_size[1], zo_size[1];
    int st, iters, i, H;
    double t0 = 2.0, tCold, tWarm;
    clock_t c0;

    gncCore_lib_initialize();
    fill_cfg(&cfg);  fill_tp(&tp);
    H = ex_H;

    /* 参照テーブル (計画解の高密度化データ) */
    gnc_ref_t ref;
    ref.t = ex_ref_t;  ref.x = ex_ref_x;  ref.u = ex_ref_u;  ref.eng = ex_ref_eng;
    ref.n = ex_ref_t_size[1];  ref.nu = ex_ref_u_size[1];

    /* ホライズン窓の切り出し (t0 から dtMpc 刻み) */
    gnc_ref_window(&ref, t0, ex_dtMpc, H, xr, ur, engk);
    xr_size[0] = 14;  xr_size[1] = H + 1;
    ur_size[0] = 7;   ur_size[1] = H;
    engk_size[0] = 1; engk_size[1] = H;

    /* 現在状態 = 参照初期 (物理単位へ変換) */
    sx[0]=ex_scL; sx[1]=ex_scL; sx[2]=ex_scL;
    sx[3]=ex_scV; sx[4]=ex_scV; sx[5]=ex_scV;
    sx[6]=1; sx[7]=1; sx[8]=1; sx[9]=1;
    sx[10]=1.0/ex_scT; sx[11]=1.0/ex_scT; sx[12]=1.0/ex_scT; sx[13]=ex_m0;
    for (i = 0; i < 14; i++) xc[i] = xr[i] * sx[i];

    /* cold (ウォームスタートなし) */
    for (i = 0; i < 21*H; i++) zw[i] = 0.0;
    zw_size[0] = 21*H;
    c0 = clock();
    scpk_trackStepEmb(xc, xr, xr_size, ur, ur_size, engk, engk_size,
                      &cfg, &tp, zw, zw_size, u0, zo, zo_size, qCmd, &st, &iters);
    tCold = (double)(clock() - c0) * 1000.0 / CLOCKS_PER_SEC;
    printf("cold : status=%d iters=%d  %.1f ms\n", st, iters, tCold);

    /* warm (前周期の解を再利用. 実運用の周期呼び出しの形) */
    c0 = clock();
    scpk_trackStepEmb(xc, xr, xr_size, ur, ur_size, engk, engk_size,
                      &cfg, &tp, zo, zo_size, u0, zw, zw_size, qCmd, &st, &iters);
    tWarm = (double)(clock() - c0) * 1000.0 / CLOCKS_PER_SEC;
    printf("warm : status=%d iters=%d  %.1f ms\n", st, iters, tWarm);

    printf("u0 (無次元) = [ %.4f %.4f %.4f | %.3f %.3f %.3f %.3f ]\n",
           u0[0], u0[1], u0[2], u0[3], u0[4], u0[5], u0[6]);
    printf("qCmd = [ %.4f %.4f %.4f %.4f ]\n", qCmd[0], qCmd[1], qCmd[2], qCmd[3]);
    printf("status: 1=converged 0=maxIter(固定反復モードでは正常) 4=numerical\n");

    gncCore_lib_terminate();
    return (st == 4) ? 1 : 0;
}
