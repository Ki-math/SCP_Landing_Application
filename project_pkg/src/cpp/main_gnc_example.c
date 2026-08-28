/* main_gnc_example.c — 生成コード部品を組み合わせた誘導制御ループの統合例.
 *
 * 構成 (すべて純C, MATLAB非依存):
 *   参照サンプリング (guidance)  ->  追従MPC scpk_trackStepEmb (gnc, 100ms)
 *   -> 推力効率誤差つきプラント (gnc の力学 dyn() を RK4 積分, 10ms)
 * 点火ディスパッチ (gnc_alt_table / gnc_dispatch_time) と鉛直速度FB
 * (gnc_velfb_*) もここから同様に使える (ホバースラム機向け. 本例は
 * Starship 計画データのため時刻同期 + FBなしで回す).
 *
 * オンライン再計画を足す場合は, scpk_planIterEmb を誤差トリガで呼び,
 * 返った解で参照テーブルを差し替えればよい (main_planner_example.c 参照).
 *
 * ビルド (パッケージ直下で):
 *   gcc -O2 -Ignc -Iguidance -Iexamples examples/main_gnc_example.c \
 *       gnc/*.c guidance/*.c -o gnc_demo -lm
 * 実行:
 *   ./gnc_demo
 */
#include <stdio.h>
#include <math.h>
#include <time.h>
#include "scpk_trackStepEmb.h"
#include "gncCore_lib_initialize.h"
#include "gncCore_lib_terminate.h"
#include "dynamics6.h"          /* dyn(): 6自由度力学 (生成コード) */
#include "plan_example_data.h"
#include "gnc_guidance.h"

#define DT_PLANT 0.01           /* プラント積分刻み [s] */
#define THR_EFF  0.97           /* 外乱: 推力効率 (実推力 = 指令 x 0.97) */

/* プラント1ステップ (RK4, 無次元状態. 推力効率誤差を指令に乗せる) */
static void plant_step(double x[14], const double u[7], const struct0_T *cfg,
                       double hP)
{
    double up[7], k1[14], k2[14], k3[14], k4[14], xt[14];
    int i;
    for (i = 0; i < 7; i++) up[i] = u[i];
    up[0] *= THR_EFF;  up[1] *= THR_EFF;  up[2] *= THR_EFF;
    dyn(x, up, cfg, k1);
    for (i = 0; i < 14; i++) xt[i] = x[i] + 0.5*hP*k1[i];
    dyn(xt, up, cfg, k2);
    for (i = 0; i < 14; i++) xt[i] = x[i] + 0.5*hP*k2[i];
    dyn(xt, up, cfg, k3);
    for (i = 0; i < 14; i++) xt[i] = x[i] + hP*k3[i];
    dyn(xt, up, cfg, k4);
    for (i = 0; i < 14; i++) x[i] += hP/6.0*(k1[i] + 2*k2[i] + 2*k3[i] + k4[i]);
    /* 四元数正規化 */
    {
        double nq = sqrt(x[6]*x[6]+x[7]*x[7]+x[8]*x[8]+x[9]*x[9]);
        if (nq > 1e-12) { for (i = 6; i < 10; i++) x[i] /= nq; }
    }
}

int main(void)
{
    static struct0_T cfg;
    static struct5_T tp;
    static double xr[14*61], ur[7*60], engk[60], zw[1300], zo[1300];
    double x[14], xc[14], u0[7], qCmd[4], sx[14];
    int xr_size[2], ur_size[2], engk_size[2], zw_size[1], zo_size[1];
    int st, iters, i, H, sub, nMpc = 0;
    double t = 0.0, tEnd, mpcMs = 0.0, mpcMax = 0.0, ms;
    clock_t c0;

    gncCore_lib_initialize();
    fill_cfg(&cfg);  fill_tp(&tp);
    H = ex_H;

    gnc_ref_t ref;
    ref.t = ex_ref_t;  ref.x = ex_ref_x;  ref.u = ex_ref_u;  ref.eng = ex_ref_eng;
    ref.n = ex_ref_t_size[1];  ref.nu = ex_ref_u_size[1];
    tEnd = ex_ref_t[ref.n-1] + 10.0;

    /* 点火ディスパッチ表 (ホバースラム機なら tp0 = gnc_dispatch_time(...) を使う) */
    gnc_alt_tab_t altTab;
    gnc_alt_table(&ref, ex_scL, &altTab);

    sx[0]=ex_scL; sx[1]=ex_scL; sx[2]=ex_scL;
    sx[3]=ex_scV; sx[4]=ex_scV; sx[5]=ex_scV;
    sx[6]=1; sx[7]=1; sx[8]=1; sx[9]=1;
    sx[10]=1.0/ex_scT; sx[11]=1.0/ex_scT; sx[12]=1.0/ex_scT; sx[13]=ex_m0;

    for (i = 0; i < 14; i++) x[i] = ex_ref_x[i];     /* 初期状態 = 計画初期 */
    for (i = 0; i < 21*H; i++) zw[i] = 0.0;
    zw_size[0] = 21*H;
    for (i = 0; i < 7; i++) u0[i] = 0.0;

    xr_size[0] = 14;  xr_size[1] = H + 1;
    ur_size[0] = 7;   ur_size[1] = H;
    engk_size[0] = 1; engk_size[1] = H;

    printf("GNC統合ループ開始 (追従MPC %.0f ms 周期, プラント %.0f ms, 推力効率 %.2f)\n",
           ex_dtMpc*1000.0, DT_PLANT*1000.0, THR_EFF);
    while (t < tEnd) {
        /* --- 追従MPC (時刻同期. ホバースラムなら gnc_dispatch_time で高度同期) --- */
        gnc_ref_window(&ref, t, ex_dtMpc, H, xr, ur, engk);
        for (i = 0; i < 14; i++) xc[i] = x[i] * sx[i];
        c0 = clock();
        scpk_trackStepEmb(xc, xr, xr_size, ur, ur_size, engk, engk_size,
                          &cfg, &tp, zw, zw_size, u0, zo, zo_size, qCmd, &st, &iters);
        ms = (double)(clock() - c0) * 1000.0 / CLOCKS_PER_SEC;
        mpcMs += ms;  if (ms > mpcMax) mpcMax = ms;  nMpc++;
        for (i = 0; i < zo_size[0]; i++) zw[i] = zo[i];
        zw_size[0] = zo_size[0];

        /* --- プラント (10 ms x 周期分) --- */
        for (sub = 0; sub < (int)(ex_dtMpc/DT_PLANT + 0.5); sub++) {
            plant_step(x, u0, &cfg, DT_PLANT/ex_scT);
            t += DT_PLANT;
            if (x[0]*ex_scL <= ex_tdAlt) break;
        }
        if (x[0]*ex_scL <= ex_tdAlt) break;
    }

    /* --- 接地状態 --- */
    {
        double q0=x[6], q1=x[7], q2=x[8], q3=x[9];
        double R[3][3], vI[3];
        double tilt = acos(fmax(-1.0, fmin(1.0, 1.0-2.0*(q2*q2+q3*q3))))*180.0/M_PI;
        R[0][0]=1-2*(q2*q2+q3*q3); R[0][1]=2*(q1*q2+q0*q3); R[0][2]=2*(q1*q3-q0*q2);
        R[1][0]=2*(q1*q2-q0*q3); R[1][1]=1-2*(q1*q1+q3*q3); R[1][2]=2*(q2*q3+q0*q1);
        R[2][0]=2*(q1*q3+q0*q2); R[2][1]=2*(q2*q3-q0*q1); R[2][2]=1-2*(q1*q1+q2*q2);
        for (i = 0; i < 3; i++)
            vI[i] = (R[0][i]*x[3] + R[1][i]*x[4] + R[2][i]*x[5]) * ex_scV;
        printf("接地 t=%.1fs: 水平 %.2f m | 鉛直速度 %+.2f m/s | 傾斜 %.2f deg\n",
               t, ex_scL*sqrt(x[1]*x[1]+x[2]*x[2]), vI[0], tilt);
        printf("追従MPC %d回: 平均 %.1f ms / 最大 %.1f ms\n", nMpc, mpcMs/nMpc, mpcMax);
        gncCore_lib_terminate();
        return (ex_scL*sqrt(x[1]*x[1]+x[2]*x[2]) < 30.0 && fabs(vI[0]) < 8.0) ? 0 : 1;
    }
}
