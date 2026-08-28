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
#include <math.h>

#define VF_DT_PLANT 0.01
#define VF_THR_EFF  0.97

/* プラント1ステップ (RK4, 無次元状態. main_gnc_example.c と同一) */
static void vf_plant_step(double x[14], const double u[7], const struct0_T *cfg,
                          double hP)
{
    double up[7], k1[14], k2[14], k3[14], k4[14], xt[14];
    int i;
    for (i = 0; i < 7; i++) up[i] = u[i];
    up[0] *= VF_THR_EFF;  up[1] *= VF_THR_EFF;  up[2] *= VF_THR_EFF;
    dyn(x, up, cfg, k1);
    for (i = 0; i < 14; i++) xt[i] = x[i] + 0.5*hP*k1[i];
    dyn(xt, up, cfg, k2);
    for (i = 0; i < 14; i++) xt[i] = x[i] + 0.5*hP*k2[i];
    dyn(xt, up, cfg, k3);
    for (i = 0; i < 14; i++) xt[i] = x[i] + hP*k3[i];
    dyn(xt, up, cfg, k4);
    for (i = 0; i < 14; i++) x[i] += hP/6.0*(k1[i] + 2*k2[i] + 2*k3[i] + k4[i]);
    {
        double nq = sqrt(x[6]*x[6]+x[7]*x[7]+x[8]*x[8]+x[9]*x[9]);
        if (nq > 1e-12) { for (i = 6; i < 10; i++) x[i] /= nq; }
    }
}

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

    /* ---- 3. GNC閉ループ (MPC周期ごとに t と状態14をログ) ---- */
    {
        static double xr[14*61], ur[7*60], engk[60], zw[1300], zo[1300];
        double x[14], xc[14], sx[14], u0[7], qCmd[4];
        int xr_size[2], ur_size[2], engk_size[2], zw_size[1], zo_size[1];
        int st2, it2, sub, k, H = ex_H, nSub;
        double t = 0.0, tEnd;
        FILE *f = openOut(dir, "verify_gnc.txt");
        if (!f) { printf("verify_gnc.txt を開けません\n"); return 2; }
        gnc_ref_t ref;
        ref.t = ex_ref_t;  ref.x = ex_ref_x;  ref.u = ex_ref_u;  ref.eng = ex_ref_eng;
        ref.n = ex_ref_t_size[1];  ref.nu = ex_ref_u_size[1];
        tEnd = ex_ref_t[ref.n-1] + 10.0;
        sx[0]=ex_scL; sx[1]=ex_scL; sx[2]=ex_scL;
        sx[3]=ex_scV; sx[4]=ex_scV; sx[5]=ex_scV;
        sx[6]=1; sx[7]=1; sx[8]=1; sx[9]=1;
        sx[10]=1.0/ex_scT; sx[11]=1.0/ex_scT; sx[12]=1.0/ex_scT; sx[13]=ex_m0;
        for (i = 0; i < 14; i++) x[i] = ex_ref_x[i];
        for (i = 0; i < 21*H; i++) zw[i] = 0.0;
        zw_size[0] = 21*H;
        for (i = 0; i < 7; i++) u0[i] = 0.0;
        xr_size[0] = 14;  xr_size[1] = H + 1;
        ur_size[0] = 7;   ur_size[1] = H;
        engk_size[0] = 1; engk_size[1] = H;
        nSub = (int)(ex_dtCtrl/VF_DT_PLANT + 0.5);   /* 実行周期100msで回す */
        while (t < tEnd) {
            double msMpc;
            clock_t cM;
            gnc_ref_window(&ref, t, ex_dtMpc, H, xr, ur, engk);
            for (i = 0; i < 14; i++) xc[i] = x[i] * sx[i];
            cM = clock();
            scpk_trackStepEmb(xc, xr, xr_size, ur, ur_size, engk, engk_size,
                              &cfg, &tp, zw, zw_size, u0, zo, zo_size,
                              qCmd, &st2, &it2);
            msMpc = (double)(clock() - cM) * 1000.0 / CLOCKS_PER_SEC;
            fprintf(f, "%.17g", t);
            for (i = 0; i < 14; i++) fprintf(f, " %.17g", x[i]);
            fprintf(f, " %.6g\n", msMpc);
            for (i = 0; i < zo_size[0]; i++) zw[i] = zo[i];
            zw_size[0] = zo_size[0];
            for (sub = 0; sub < nSub; sub++) {
                vf_plant_step(x, u0, &cfg, VF_DT_PLANT/ex_scT);
                t += VF_DT_PLANT;
                if (x[0]*ex_scL <= ex_tdAlt) break;
            }
            if (x[0]*ex_scL <= ex_tdAlt) break;
        }
        fprintf(f, "%.17g", t);
        for (i = 0; i < 14; i++) fprintf(f, " %.17g", x[i]);
        fprintf(f, " 0\n");
        fclose(f);
        printf("gnc  : 接地 t=%.1fs 水平%.2fm -> verify_gnc.txt\n",
               t, ex_scL*sqrt(x[1]*x[1]+x[2]*x[2]));
    }

    gncCore_lib_terminate();
    return 0;
}
