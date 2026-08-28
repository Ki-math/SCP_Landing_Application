/* main_verify.c — 等価性検証用: 生成コードの結果をファイルへ全桁出力する.
 *
 * MATLAB側 (util/verifyEmbedded.m) が同一入力で参照実装を実行し, 本プログラム
 * の出力と数値一致を突き合わせる. 実行内容:
 *   1. 計画SCP 1反復 (scpk_planIterEmb, cold) -> verify_plan.txt
 *   2. 追従MPC 1周期 (gnc_ref_window で窓生成 + scpk_trackStepEmb, cold)
 *      -> verify_track.txt
 *   3. GNC閉ループ (追従MPC + RK4プラント, 推力効率0.97, 着陸まで)
 *      -> verify_gnc.txt (MPC周期ごとの状態軌跡. プロット比較用)
 *
 * ビルド (パッケージ直下で):
 *   gcc -O2 -Ignc -Iguidance -Iexamples examples/main_verify.c \
 *       gnc/*.c guidance/*.c -o verify_demo -lm
 * 実行:
 *   ./verify_demo [出力ディレクトリ]
 */
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "scpk_planIterEmb.h"
#include "scpk_trackStepEmb.h"
#include "gncCore_lib_emxAPI.h"
#include "gncCore_lib_initialize.h"
#include "gncCore_lib_terminate.h"
#include "dynamics6.h"
#include "plan_example_data.h"
#include "gnc_guidance.h"
#include "gnc_attitude.h"
#include <math.h>
#include "gnc_loop.h"    /* 完全構成のGNC閉ループ (方式1/2, ディスパッチ, 速度FB, カットオフ) */

#define VF_THR_EFF  0.97

static FILE *openOut(const char *dir, const char *name)
{
    char path[1024];
    if (dir && dir[0]) snprintf(path, sizeof(path), "%s/%s", dir, name);
    else               snprintf(path, sizeof(path), "%s", name);
    return fopen(path, "w");
}

static void dump(FILE *f, const char *tag, const double *v, int n)
{
    int i;
    fprintf(f, "%s %d\n", tag, n);
    for (i = 0; i < n; i++) fprintf(f, "%.17g\n", v[i]);
}

int main(int argc, char **argv)
{
    const char *dir = (argc > 1) ? argv[1] : "";
    static struct0_T cfg;
    static struct3_T pp;
    static struct4_T qp;
    static struct5_T tp;
    int st, iters, i;

    gncCore_lib_initialize();
    fill_cfg(&cfg);  fill_pp(&pp);  fill_qp(&qp);  fill_tp(&tp);

    /* ---- 1. 計画SCP 1反復 (cold) ---- */
    {
        static double xs[14*201], us[7*200], gs[200];
        double ss[8], nu, step;
        int xs_size[2], us_size[2], gs_size[2], ss_size[2];
        emxArray_real_T *zWarm = emxCreate_real_T(0, 1);
        emxArray_real_T *zOut  = emxCreate_real_T(0, 1);
        double tCold, tWarm, ms;
        int r, st9, it9;
        double nu9, step9;
        clock_t c0;
        FILE *f = openOut(dir, "verify_plan.txt");
        if (!f) { printf("verify_plan.txt を開けません\n"); return 2; }
        c0 = clock();
        scpk_planIterEmb(ex_x0nd, ex_xT,
                         ex_xl, ex_xl_size, ex_ul, ex_ul_size,
                         ex_gl, ex_gl_size, ex_sigl, ex_sigl_size,
                         ex_phase, ex_phase_size, ex_eng, ex_eng_size,
                         ex_dtv, ex_dtv_size, ex_tiltN, ex_tiltN_size,
                         &cfg, &pp, &qp, zWarm,
                         xs, xs_size, us, us_size, gs, gs_size,
                         ss, ss_size, &st, &iters, &nu, &step, zOut);
        tCold = (double)(clock() - c0) * 1000.0 / CLOCKS_PER_SEC;
        /* warm 実行時間 (5回の最小値: 再計画サイクルの実運用形) */
        tWarm = 1e30;
        for (r = 0; r < 5; r++) {
            static double xs9[14*201], us9[7*200], gs9[200];
            double ss9[8];
            int xs9s[2], us9s[2], gs9s[2], ss9s[2];
            c0 = clock();
            scpk_planIterEmb(ex_x0nd, ex_xT,
                             ex_xl, ex_xl_size, ex_ul, ex_ul_size,
                             ex_gl, ex_gl_size, ex_sigl, ex_sigl_size,
                             ex_phase, ex_phase_size, ex_eng, ex_eng_size,
                             ex_dtv, ex_dtv_size, ex_tiltN, ex_tiltN_size,
                             &cfg, &pp, &qp, zOut,
                             xs9, xs9s, us9, us9s, gs9, gs9s,
                             ss9, ss9s, &st9, &it9, &nu9, &step9, zWarm);
            ms = (double)(clock() - c0) * 1000.0 / CLOCKS_PER_SEC;
            if (ms < tWarm) tWarm = ms;
        }
        fprintf(f, "st %d\niters %d\nnu %.17g\nstep %.17g\n", st, iters, nu, step);
        fprintf(f, "tColdMs %.6g\ntWarmMs %.6g\n", tCold, tWarm);
        dump(f, "xs", xs, xs_size[0]*xs_size[1]);
        dump(f, "us", us, us_size[0]*us_size[1]);
        dump(f, "ss", ss, ss_size[1]);
        fclose(f);
        emxDestroyArray_real_T(zWarm);
        emxDestroyArray_real_T(zOut);
        printf("plan : st=%d iters=%d nu=%.3e -> verify_plan.txt\n", st, iters, nu);
    }

    /* ---- 2. 追従MPC 1周期 (cold, 窓は guidance/gnc_ref_window で生成) ---- */
    {
        static double xr[14*61], ur[7*60], engk[60], zw[1300], zo[1300];
        double xc[14], sx[14], u0[7], qCmd[4];
        int xr_size[2], ur_size[2], engk_size[2], zw_size[1], zo_size[1];
        int H = ex_H;
        double t0 = 2.0;
        FILE *f = openOut(dir, "verify_track.txt");
        if (!f) { printf("verify_track.txt を開けません\n"); return 2; }
        gnc_ref_t ref;
        ref.t = ex_ref_t;  ref.x = ex_ref_x;  ref.u = ex_ref_u;  ref.eng = ex_ref_eng;
        ref.n = ex_ref_t_size[1];  ref.nu = ex_ref_u_size[1];
        gnc_ref_window(&ref, t0, ex_dtMpc, H, xr, ur, engk);
        sx[0]=ex_scL; sx[1]=ex_scL; sx[2]=ex_scL;
        sx[3]=ex_scV; sx[4]=ex_scV; sx[5]=ex_scV;
        sx[6]=1; sx[7]=1; sx[8]=1; sx[9]=1;
        sx[10]=1.0/ex_scT; sx[11]=1.0/ex_scT; sx[12]=1.0/ex_scT; sx[13]=ex_m0;
        for (i = 0; i < 14; i++) xc[i] = xr[i] * sx[i];
        for (i = 0; i < 21*H; i++) zw[i] = 0.0;
        zw_size[0] = 21*H;
        xr_size[0] = 14;  xr_size[1] = H + 1;
        ur_size[0] = 7;   ur_size[1] = H;
        engk_size[0] = 1; engk_size[1] = H;
        scpk_trackStepEmb(xc, xr, xr_size, ur, ur_size, engk, engk_size,
                          &cfg, &tp, zw, zw_size, u0, zo, zo_size, qCmd, &st, &iters);
        fprintf(f, "st %d\niters %d\n", st, iters);
        dump(f, "u0", u0, 7);
        dump(f, "qCmd", qCmd, 4);
        dump(f, "xr", xr, 14*(H+1));   /* 窓生成 (guidance) の等価性も見る */
        dump(f, "ur", ur, 7*H);
        fclose(f);
        printf("track: st=%d iters=%d -> verify_track.txt\n", st, iters);
    }

    /* ---- 3. GNC閉ループ (完全構成: 方式は ex_ctlInner に従う) ---- */
    {
        FILE *f = openOut(dir, "verify_gnc.txt");
        gnc_result_t r;
        if (!f) { printf("verify_gnc.txt を開けません\n"); return 2; }
        r = gnc_run(&cfg, &tp, VF_THR_EFF, f);
        fclose(f);
        printf("gnc  : 方式%d 接地 t=%.1fs 水平%.2fm -> verify_gnc.txt\n",
               ex_ctlInner ? 2 : 1, r.t,
               ex_scL*sqrt(r.x[1]*r.x[1] + r.x[2]*r.x[2]));
    }

    gncCore_lib_terminate();
    return 0;
}
