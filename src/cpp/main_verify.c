/* main_verify.c — 等価性検証用: 生成コードの結果をファイルへ全桁出力する.
 *
 * MATLAB側 (util/verifyEmbedded.m) が同一入力で参照実装を実行し, 本プログラム
 * の出力と数値一致を突き合わせる. 実行内容:
 *   1. 計画SCP 1反復 (scpk_planIterEmb, cold) -> verify_plan.txt
 *   2. 追従MPC 1周期 (gnc_ref_window で窓生成 + scpk_trackStepEmb, cold)
 *      -> verify_track.txt
 *
 * ビルド (パッケージ直下で):
 *   gcc -O2 -Ignc -Iguidance -Iexamples examples/main_verify.c \
 *       gnc/*.c guidance/*.c -o verify_demo -lm
 * 実行:
 *   ./verify_demo [出力ディレクトリ]
 */
#include <stdio.h>
#include <string.h>
#include "scpk_planIterEmb.h"
#include "scpk_trackStepEmb.h"
#include "gncCore_lib_emxAPI.h"
#include "gncCore_lib_initialize.h"
#include "gncCore_lib_terminate.h"
#include "plan_example_data.h"
#include "gnc_guidance.h"

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
        FILE *f = openOut(dir, "verify_plan.txt");
        if (!f) { printf("verify_plan.txt を開けません\n"); return 2; }
        scpk_planIterEmb(ex_x0nd, ex_xT,
                         ex_xl, ex_xl_size, ex_ul, ex_ul_size,
                         ex_gl, ex_gl_size, ex_sigl, ex_sigl_size,
                         ex_phase, ex_phase_size, ex_eng, ex_eng_size,
                         ex_dtv, ex_dtv_size, ex_tiltN, ex_tiltN_size,
                         &cfg, &pp, &qp, zWarm,
                         xs, xs_size, us, us_size, gs, gs_size,
                         ss, ss_size, &st, &iters, &nu, &step, zOut);
        fprintf(f, "st %d\niters %d\nnu %.17g\nstep %.17g\n", st, iters, nu, step);
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

    gncCore_lib_terminate();
    return 0;
}
