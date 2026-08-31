/* gnc_loop.h — 完全構成のGNC閉ループ (examples 共有, ヘッダオンリー).
 *
 * MATLAB実装 (runClosedLoopReplan.m) と同一の構成・演算順序:
 *   点火ディスパッチ (refSyncAlt) -> 追従MPC (scpk_trackStepEmb, dtCtrl周期)
 *   -> 10ms層: 鉛直速度FB / 着陸コミット (latFreeze) / 姿勢内ループ+アクチュエータ
 *      (ex_ctlInner=1 のとき) / エンジンカットオフ -> プラント RK4 (dtPlant)
 * 制御方式・誘導設定は plan_example_data.h の ex_ctl* 定数 (機体テンプレート由来).
 * オンライン再計画は含まない (scpk_planIterEmb を誤差トリガで呼び ref を
 * 差し替えれば追加できる).
 *
 * 使い方: plan_example_data.h / gnc_guidance.h / gnc_attitude.h /
 *         scpk_trackStepEmb.h / dynamics6.h を include した後にこのファイルを
 *         include し, gnc_run(&cfg, &tp, thrEff, logf) を呼ぶ.
 */
#ifndef GNC_LOOP_H
#define GNC_LOOP_H

#include <math.h>
#include <time.h>

typedef struct {
    double t;           /* 接地時刻 [s] */
    double x[14];       /* 接地状態 (無次元) */
    int    nMpc;        /* MPC実行回数 */
    double msMean, msMax;   /* MPC実行時間 [ms] */
} gnc_result_t;

/* 慣性系鉛直速度 [無次元] (上+) */
static double gnc_vI1(const double x[14])
{
    const double q0=x[6], q1=x[7], q2=x[8], q3=x[9];
    return (1.0-2.0*(q2*q2+q3*q3))*x[3] + 2.0*(q1*q2-q0*q3)*x[4]
         + 2.0*(q1*q3+q0*q2)*x[5];
}

/* プラント1ステップ (RK4, 推力効率 thrEff を指令に乗算) */
static void gnc_plant_step(double x[14], const double u[7],
                           const struct0_T *cfg, double thrEff, double hP)
{
    double up[7], k1[14], k2[14], k3[14], k4[14], xt[14];
    int i;
    for (i = 0; i < 7; i++) up[i] = u[i];
    up[0] *= thrEff;  up[1] *= thrEff;  up[2] *= thrEff;
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

/* GNC閉ループ本体. logf が非NULLなら MPC周期ごとに "t x(14) mpcMs" を出力 */
static gnc_result_t gnc_run(const struct0_T *cfg, const struct5_T *tp,
                            double thrEff, FILE *logf)
{
    static double xr[14*61], ur[7*60], engk[60], zw[1300], zo[1300];
    double x[14], xc[14], sx[14], u0[7], uMPC[7], u[7], qCmd[4], xrNow[14], xrVel[14];
    int xr_size[2], ur_size[2], engk_size[2], zw_size[1], zo_size[1];
    int st, iters, i, sub, H = ex_H, nSub, cutDone = 0, burnStarted = 0, s;
    double t = 0.0, tEnd, tpRef, tpRaw, tpEng, tpVel, engNow;
    double TcN = 0.0, dvF = 0.0, Tint = 0.0, burnRefShift = 0.0;
    double T1a, lam, msMpc, tIgn = 0.0, engIgn = 0.0, burnFactor = 1.0;
    clock_t cM;
    gnc_result_t res;
    gnc_ref_t ref;
    gnc_alt_tab_t altTab;
    gnc_inner_cfg_t ic;
    gnc_inner_state_t ist;

    ref.t = ex_ref_t;  ref.x = ex_ref_x;  ref.u = ex_ref_u;  ref.eng = ex_ref_eng;
    ref.n = ex_ref_t_size[1];  ref.nu = ex_ref_u_size[1];
    tEnd = ex_ref_t[ref.n-1] + 20.0;
    gnc_alt_table(&ref, ex_scL, &altTab);
    if (ex_suicideBurn) {
        for (i = 0; i < ref.nu; i++) {
            if (ref.eng[i] > 0.0) {
                double vDown, hRem, mRef, aBrake, dStop;
                tIgn = ref.t[i];
                engIgn = ref.eng[i];
                vDown = fmax(-gnc_vI1(&ref.x[14*i])*ex_scV, 0.0);
                hRem = fmax(ref.x[14*i]*ex_scL - ex_tdAlt, 0.0);
                mRef = ref.x[14*i+13]*ex_m0;
                aBrake = engIgn*ex_Tmax1*ex_Fs*ex_suicideNomEff/mRef - 9.80665;
                dStop = fmax(vDown*vDown - ex_suicideVtd*ex_suicideVtd, 0.0) /
                        (2.0*fmax(aBrake, 1e-12));
                if (hRem > 0.0 && dStop > 1e-12 && aBrake > 0.0)
                    burnFactor = hRem/dStop;
                else
                    engIgn = 0.0;
                break;
            }
        }
    }

    ic.wnAtt = ex_wnAtt;  ic.ztAtt = ex_ztAtt;
    ic.tauThr = ex_tauThr;  ic.wnGim = 2.0*3.14159265358979323846*ex_fGim;
    ic.ztGim = ex_ztGim;  ic.tauFlap = ex_tauFlap;
    ic.actRateLim = ex_actRateLim;  ic.tvcRate = ex_tvcRate;  ic.flapRate = ex_flapRate;
    ic.Lrt = ex_Lrt;  ic.Jyy = ex_Jyy;  ic.Jzz = ex_Jzz;
    ic.Fs = ex_Fs;  ic.tvcMax = ex_tvcMax;  ic.scT = ex_scT;
    gnc_inner_init(&ist);

    sx[0]=ex_scL; sx[1]=ex_scL; sx[2]=ex_scL;
    sx[3]=ex_scV; sx[4]=ex_scV; sx[5]=ex_scV;
    sx[6]=1; sx[7]=1; sx[8]=1; sx[9]=1;
    sx[10]=1.0/ex_scT; sx[11]=1.0/ex_scT; sx[12]=1.0/ex_scT; sx[13]=ex_m0;

    for (i = 0; i < 14; i++) x[i] = ex_x0nd[i];   /* 初期状態 = 計画のx0 (厳密値) */
    for (i = 0; i < 21*H; i++) zw[i] = 0.0;
    zw_size[0] = 21*H;
    for (i = 0; i < 7; i++) { u0[i] = 0.0; uMPC[i] = 0.0; u[i] = 0.0; }
    xr_size[0] = 14;  xr_size[1] = H + 1;
    ur_size[0] = 7;   ur_size[1] = H;
    engk_size[0] = 1; engk_size[1] = H;
    res.nMpc = 0;  res.msMean = 0.0;  res.msMax = 0.0;
    nSub = (int)(ex_dtCtrl/ex_dtPlant + 0.5);

    for (s = 0; ; s++) {
        /* --- 参照時刻 (点火ディスパッチ or 時刻同期) --- */
        tpRaw = ex_refSyncAlt ? gnc_dispatch_time(&altTab, x[0]*ex_scL) : t;
        tpRef = tpRaw;
        tpEng = tpRaw;
        if (burnStarted) {
            double ctrlShift = fmin(burnRefShift, 0.0) +
                               ex_suicideRefBlend*fmax(burnRefShift, 0.0);
            tpRef = fmin(fmax(tpRaw - ctrlShift, ref.t[0]), ref.t[ref.n-1]);
            tpEng = fmin(fmax(tpRaw - burnRefShift, ref.t[0]), ref.t[ref.n-1]);
        }
        engNow = gnc_ref_eng(&ref, tpEng);
        if (ex_suicideBurn && engIgn > 0.0 && !burnStarted) {
            double vDown = fmax(-gnc_vI1(x)*ex_scV, 0.0);
            double hRem = fmax(x[0]*ex_scL - ex_tdAlt, 0.0);
            double mass = x[13]*ex_m0;
            double aBrake = engIgn*ex_Tmax1*ex_Fs*thrEff/mass - 9.80665;
            double dStop = fmax(vDown*vDown - ex_suicideVtd*ex_suicideVtd, 0.0) /
                           (2.0*fmax(aBrake, 1e-12));
            int burnRequired = hRem <= ex_suicideMargin*burnFactor*dStop;
            int canStart = burnRequired && tpRaw >= tIgn - ex_suicideAdvanceMax;
            if (canStart) {
                double ctrlShift;
                burnStarted = 1;
                burnRefShift = tpRaw - tIgn;
                ctrlShift = fmin(burnRefShift, 0.0) +
                            ex_suicideRefBlend*fmax(burnRefShift, 0.0);
                tpRef = fmin(fmax(tpRaw - ctrlShift, ref.t[0]), ref.t[ref.n-1]);
                tpEng = tIgn;
                engNow = engIgn;
            } else
                engNow = 0.0;
        }
        gnc_ref_state(&ref, tpRef, xrNow);
        tpVel = tpRaw;
        if (burnStarted) {
            double velShift = fmin(burnRefShift, 0.0) +
                              ex_suicideVelBlend*fmax(burnRefShift, 0.0);
            tpVel = fmin(fmax(tpRaw - velShift, ref.t[0]), ref.t[ref.n-1]);
        }
        gnc_ref_state(&ref, tpVel, xrVel);
        /* --- 追従MPC (dtCtrl 周期) --- */
        if (s % nSub == 0) {
            if (t >= tEnd) break;
            gnc_ref_window(&ref, tpRef, ex_dtMpc, H, xr, ur, engk);
            for (i = 0; i < 14; i++) xc[i] = x[i] * sx[i];
            cM = clock();
            scpk_trackStepEmb(xc, xr, xr_size, ur, ur_size, engk, engk_size,
                              cfg, tp, zw, zw_size, uMPC, zo, zo_size,
                              qCmd, &st, &iters);
            msMpc = (double)(clock() - cM) * 1000.0 / CLOCKS_PER_SEC;
            res.msMean += msMpc;  if (msMpc > res.msMax) res.msMax = msMpc;
            res.nMpc++;
            for (i = 0; i < zo_size[0]; i++) zw[i] = zo[i];
            zw_size[0] = zo_size[0];
            if (!ex_ctlInner) for (i = 0; i < 7; i++) u[i] = uMPC[i];
            if (logf) {
                fprintf(logf, "%.17g", t);
                for (i = 0; i < 14; i++) fprintf(logf, " %.17g", x[i]);
                fprintf(logf, " %.6g\n", msMpc);
            }
        }
        /* --- 鉛直速度FB (10ms層, 参照 v(h) への推力トリム) --- */
        if (ex_velFB > 0.0 && engNow > 0.0) {
            double dv1 = (xrVel[3] - x[3])*ex_scV;      /* 機体x速度誤差 [m/s] */
            double mph = x[13]*ex_m0, lim;
            dvF += ex_dtPlant/0.3*(dv1 - dvF);
            Tint += ex_velFBi*mph*dvF/ex_Fs*ex_dtPlant;
            lim = 0.15*engNow*ex_Tmax1;
            if (Tint >  lim) Tint =  lim;
            if (Tint < -lim) Tint = -lim;
            T1a = uMPC[0] + ex_velFB*mph*dvF/ex_Fs + Tint;
            if (T1a < engNow*ex_Tmin1) T1a = engNow*ex_Tmin1;
            if (T1a > engNow*ex_Tmax1) T1a = engNow*ex_Tmax1;
        } else {
            T1a = uMPC[0];
        }
        /* --- 着陸コミット係数 --- */
        if (ex_latFreezeAlt > 0.0) {
            lam = (x[0]*ex_scL - ex_tdAlt)/(ex_latFreezeAlt - ex_tdAlt);
            if (lam < 0.0) lam = 0.0;
            if (lam > 1.0) lam = 1.0;
        } else {
            lam = 1.0;
        }
        if (!ex_ctlInner) {
            for (i = 0; i < 7; i++) u[i] = uMPC[i];
            u[0] = T1a;
            if (lam < 1.0) {
                /* コミット域: 直立への姿勢戻し + レートダンピング (MATLAB実装と同一) */
                const double kdw = 2.0, kA = 1.5;
                double w2 = x[11]/ex_scT, w3 = x[12]/ex_scT;
                double sgn = (x[6] >= 0.0) ? 1.0 : -1.0;
                double e2 = -2.0*sgn*x[8], e3 = -2.0*sgn*x[9];
                double aD2 = kA*e2 - kdw*w2, aD3 = kA*e3 - kdw*w3;
                double T2d = -aD3*ex_Jzz/ex_Lrt/ex_Fs;
                double T3d =  aD2*ex_Jyy/ex_Lrt/ex_Fs;
                u[1] = lam*u[1] + (1.0-lam)*T2d;
                u[2] = lam*u[2] + (1.0-lam)*T3d;
            }
            if (engNow == 0.0) { u[0] = 0.0; u[1] = 0.0; u[2] = 0.0; }
        } else {
            /* --- 方式2: 姿勢内ループ + アクチュエータ (10ms) --- */
            double qC[4], uM[7], nqC;
            TcN = sqrt(T1a*T1a + uMPC[1]*uMPC[1] + uMPC[2]*uMPC[2])*ex_Fs;
            for (i = 0; i < 7; i++) uM[i] = uMPC[i];
            for (i = 0; i < 4; i++) qC[i] = qCmd[i];
            if (lam < 1.0) {
                /* 着陸コミット: 姿勢コマンドを直立へフェードし横FFを絞る */
                qC[0] = lam*qCmd[0] + (1.0-lam);
                qC[1] = lam*qCmd[1];  qC[2] = lam*qCmd[2];  qC[3] = lam*qCmd[3];
                nqC = sqrt(qC[0]*qC[0]+qC[1]*qC[1]+qC[2]*qC[2]+qC[3]*qC[3]);
                if (nqC > 1e-12) for (i = 0; i < 4; i++) qC[i] /= nqC;
                uM[1] *= lam;  uM[2] *= lam;
            }
            gnc_inner_step(&ic, &ist, qC, TcN, uM, x, ex_dtPlant, u);
            if (ex_suicideBurn && !burnStarted) {
                ist.Tm = 0.0;
                u[0] = 0.0; u[1] = 0.0; u[2] = 0.0;
            }
        }
        /* --- エンジンカットオフ (ホバースラム: 低高度で停止したら落下着地) --- */
        if (ex_cutoffAlt > 0.0 && !cutDone && engNow > 0.0 &&
            x[0]*ex_scL < ex_tdAlt + ex_cutoffAlt &&
            gnc_vI1(x)*ex_scV > ex_cutoffV) {
            cutDone = 1;
        }
        if (cutDone) { u[0] = 0.0; u[1] = 0.0; u[2] = 0.0; }
        /* --- プラント (dtPlant) --- */
        gnc_plant_step(x, u, cfg, thrEff, ex_dtPlant/ex_scT);
        t += ex_dtPlant;
        if (x[0]*ex_scL <= ex_tdAlt) break;
        if (t >= tEnd) break;
    }
    if (logf) {
        fprintf(logf, "%.17g", t);
        for (i = 0; i < 14; i++) fprintf(logf, " %.17g", x[i]);
        fprintf(logf, " 0\n");
    }
    if (res.nMpc > 0) res.msMean /= res.nMpc;
    res.t = t;
    for (i = 0; i < 14; i++) res.x[i] = x[i];
    return res;
}

#endif /* GNC_LOOP_H */
